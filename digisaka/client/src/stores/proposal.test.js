import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { setTokenProvider } from '../api.js';
import { useProposalStore } from './proposal.js';

const json = (status, body) => ({ status, ok: status < 400, json: async () => body });
const B = '/api/v1/scheduler';
const lineStatus = (over = {}) => ({
  line_id: 'L04',
  proposals: [{ proposal_id: 'p1', cycle_id: 'c1', option_id: 'o1', status: 'proposed', week: '2026-W24', window_start: '2026-06-10', window_end: '2026-06-12' }],
  applications: [], ...over,
});
const prop = (decision) => ({ proposal_id: 'p1', treatment: { id: 't', name: 'Fungicide A' }, window: { start: '2026-06-10', end: '2026-06-12' }, reason: 'r', constraints: [], next_assessment: '2026-W25', ...(decision ? { decision: { decision } } : {}) });
const cyc = (over = {}) => ({ cycle_id: 'c1', line_id: 'L04', week: '2026-W24', status: 'done', outcome: 'proposal', outcome_reason: null, ...over });
let fetchMock;
const routes = (map) => fetchMock.mockImplementation(async (url, init) => {
  const hit = map[`${init.method} ${url.replace(B, '')}`];
  if (!hit) return json(500, {});
  const r = typeof hit === 'function' ? hit(init) : hit;
  return r;
});
const postBody = () => JSON.parse(fetchMock.mock.calls.find((c) => c[1].method === 'POST')[1].body);
const calls = () => fetchMock.mock.calls.map((c) => `${c[1].method} ${c[0].replace(B, '')}`);

beforeEach(() => { setActivePinia(createPinia()); setTokenProvider(() => 'TOK'); fetchMock = vi.fn(); vi.stubGlobal('fetch', fetchMock); });
afterEach(() => { vi.unstubAllGlobals(); setTokenProvider(() => null); });

const loaded = async (extra = {}) => {
  routes({ 'GET /lines/L04': json(200, lineStatus()), 'GET /cycles/c1/proposal': json(200, prop()), 'GET /cycles/c1': json(200, cyc()), ...extra });
  const s = useProposalStore();
  await s.load('L04', '2026-W24');
  return s;
};

describe('load', () => {
  it('loads the week proposal and cycle, status proposed', async () => {
    const s = await loaded();
    expect(s).toMatchObject({ phase: 'ready', status: 'proposed' });
    expect(s.proposal.treatment.name).toBe('Fungicide A');
  });
  it('shows applied when an application is recorded', async () => {
    const s = await loaded({ 'GET /lines/L04': json(200, lineStatus({ applications: [{ proposal_id: 'p1', applied_on: '2026-06-11' }] })), 'GET /cycles/c1/proposal': json(200, prop('approved')) });
    expect(s).toMatchObject({ status: 'applied', appliedOn: '2026-06-11' });
  });
  it('reports a week without a proposal as not found', async () => {
    routes({ 'GET /lines/L04': json(200, lineStatus()) });
    const s = useProposalStore();
    await s.load('L04', '2026-W20');
    expect(s.phase).toBe('notfound');
  });
  it('shows a readable error when the scheduler fails', async () => {
    routes({ 'GET /lines/L04': json(500, {}) });
    const s = useProposalStore();
    await s.load('L04', '2026-W24');
    expect(s).toMatchObject({ phase: 'error', error: expect.stringMatching(/Something went wrong/) });
  });
});

describe('decide', () => {
  it('approves with the note and refreshes', async () => {
    const s = await loaded();
    routes({ 'POST /proposals/p1/decision': json(200, {}), 'GET /cycles/c1/proposal': json(200, prop('approved')), 'GET /cycles/c1': json(200, cyc()) });
    await s.decide('approved', '  looks right ');
    expect(postBody()).toEqual({ decision: 'approved', note: 'looks right' });
    expect(s.status).toBe('approved');
  });
  it('reject ends in human review with the cycle reason', async () => {
    const s = await loaded();
    routes({ 'POST /proposals/p1/decision': json(200, {}), 'GET /cycles/c1/proposal': json(200, prop('rejected')), 'GET /cycles/c1': json(200, cyc({ outcome: 'human_review_required', outcome_reason: 'gate_e_rejected' })) });
    await s.decide('rejected');
    expect(postBody()).toEqual({ decision: 'rejected' });
    expect(s).toMatchObject({ status: 'rejected', humanReview: true });
    expect(s.cycle.outcome_reason).toBe('gate_e_rejected');
  });
  it('a repeat decision shows the scheduler message and the real state', async () => {
    const s = await loaded();
    routes({ 'POST /proposals/p1/decision': json(409, { error: 'proposal_already_decided' }), 'GET /lines/L04': json(200, lineStatus()), 'GET /cycles/c1/proposal': json(200, prop('approved')), 'GET /cycles/c1': json(200, cyc()) });
    await s.decide('approved');
    expect(s.error).toBe('This proposal was already decided.');
    expect(s.status).toBe('approved');
    expect(s.busy).toBe(false);
  });
  it('ignores a second call while one is in flight', async () => {
    const s = await loaded();
    let release; const gate = new Promise((r) => { release = r; });
    routes({ 'POST /proposals/p1/decision': () => gate.then(() => json(200, {})), 'GET /cycles/c1/proposal': json(200, prop('approved')), 'GET /cycles/c1': json(200, cyc()) });
    const a = s.decide('approved'); const b = s.decide('approved');
    release(); await Promise.all([a, b]);
    expect(calls().filter((c) => c.startsWith('POST'))).toHaveLength(1);
  });
});

describe('apply', () => {
  it('records the chosen date', async () => {
    const s = await loaded({ 'GET /cycles/c1/proposal': json(200, prop('approved')) });
    routes({ 'POST /proposals/p1/application': json(200, { applied_on: '2026-06-11' }) });
    await s.apply('2026-06-11');
    expect(postBody()).toEqual({ applied_on: '2026-06-11' });
    expect(s).toMatchObject({ status: 'applied', appliedOn: '2026-06-11' });
  });
  it('refuses a malformed date without calling the scheduler', async () => {
    const s = await loaded({ 'GET /cycles/c1/proposal': json(200, prop('approved')) });
    fetchMock.mockClear();
    await s.apply('11/06/2026');
    expect(fetchMock).not.toHaveBeenCalled();
    expect(s.error).toMatch(/YYYY-MM-DD/);
  });
  it('recording twice shows the scheduler message and the recorded date', async () => {
    const s = await loaded({ 'GET /cycles/c1/proposal': json(200, prop('approved')) });
    routes({
      'POST /proposals/p1/application': json(409, { error: 'application_already_recorded' }),
      'GET /lines/L04': json(200, lineStatus({ applications: [{ proposal_id: 'p1', applied_on: '2026-06-10' }] })),
      'GET /cycles/c1/proposal': json(200, prop('approved')), 'GET /cycles/c1': json(200, cyc()),
    });
    await s.apply('2026-06-11');
    expect(s.error).toBe('The application was already recorded.');
    expect(s).toMatchObject({ status: 'applied', appliedOn: '2026-06-10' });
  });
  it('shows the message when the proposal is not approved', async () => {
    const s = await loaded();
    routes({ 'POST /proposals/p1/application': json(409, { error: 'proposal_not_approved' }) });
    await s.apply('2026-06-11');
    expect(s.error).toMatch(/Approve the proposal/);
  });
});
