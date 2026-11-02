import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { setTokenProvider } from '../api.js';
import { useLineHistoryStore } from './lineHistory.js';

const json = (status, body) => ({ status, ok: status < 400, json: async () => body });
const hist = (line, week) => ({ line_id: line, week, weeks: [{ week, yls: 5, yli: 3, rainfall_mm: 12 }] });
const lineStatus = (line, over = {}) => ({ line_id: line, proposals: [], applications: [], latest_cycle: null, ...over });
let fetchMock;

beforeEach(() => { setActivePinia(createPinia()); setTokenProvider(() => 'TOK'); fetchMock = vi.fn(); vi.stubGlobal('fetch', fetchMock); });
afterEach(() => { vi.unstubAllGlobals(); setTokenProvider(() => null); });

describe('line history store', () => {
  it('loads line history and the selected line status', async () => {
    fetchMock.mockImplementation((url) => Promise.resolve(url.endsWith('/history')
      ? json(200, hist('L04', '2026-W24'))
      : json(200, lineStatus('L04'))));
    const s = useLineHistoryStore();
    await s.load('L04', '2026-W24');
    expect(fetchMock.mock.calls.map(([url]) => url)).toEqual(expect.arrayContaining([
      '/api/v1/scheduler/lines/L04/weeks/2026-W24/history',
      '/api/v1/scheduler/lines/L04',
    ]));
    expect(s).toMatchObject({ phase: 'ready', weeks: [{ week: '2026-W24', yls: 5 }] });
    expect(s.lineStatus.line_id).toBe('L04');
  });
  it('stays idle without a line or a valid week', async () => {
    const s = useLineHistoryStore();
    await s.load('', '2026-W24');
    await s.load('L04', 'bad');
    expect(fetchMock).not.toHaveBeenCalled();
    expect(s.phase).toBe('idle');
  });
  it('shows a readable error on failure', async () => {
    fetchMock.mockResolvedValue(json(500, {}));
    const s = useLineHistoryStore();
    await s.load('L04', '2026-W24');
    expect(s).toMatchObject({ phase: 'error', error: expect.stringMatching(/Something went wrong/) });
  });
  it('keeps only the newest pick when answers arrive out of order', async () => {
    let first;
    fetchMock.mockImplementation((url) => {
      if (url.endsWith('L04/weeks/2026-W24/history')) return new Promise((r) => { first = r; });
      if (url.endsWith('L04')) return Promise.resolve(json(200, lineStatus('L04')));
      if (url.endsWith('L05/weeks/2026-W24/history')) return Promise.resolve(json(200, hist('L05', '2026-W24')));
      return Promise.resolve(json(200, lineStatus('L05')));
    });
    const s = useLineHistoryStore();
    const a = s.load('L04', '2026-W24');
    await s.load('L05', '2026-W24');
    first(json(200, hist('L04', '2026-W24')));
    await a;
    expect(s.lineId).toBe('L05');
    expect(s.weeks).toEqual(hist('L05', '2026-W24').weeks);
  });
  it('loads assessment evidence and the latest recorded treatment', async () => {
    const history = hist('L04', '2026-W24');
    const status = lineStatus('L04', {
      latest_cycle: { cycle_id: 'c-L04-23', week: '2026-W23', status: 'done' },
      proposals: [{ proposal_id: 'p-L04-23', cycle_id: 'c-L04-23', week: '2026-W23', status: 'applied' }],
      applications: [{ proposal_id: 'p-L04-23', applied_on: '2026-06-04' }],
    });
    const evidence = { cycle_id: 'c-L04-23', weeks: history.weeks, disease: { worsening: false }, rainfall: { favourable: true } };
    fetchMock.mockImplementation((url) => {
      if (url.endsWith('/history')) return Promise.resolve(json(200, history));
      if (url.endsWith('/lines/L04')) return Promise.resolve(json(200, status));
      if (url.endsWith('/cycles/c-L04-23/evidence')) return Promise.resolve(json(200, evidence));
      if (url.endsWith('/cycles/c-L04-23/proposal')) return Promise.resolve(json(200, { treatment: { name: 'Protectant spray' } }));
      return Promise.resolve(json(404, {}));
    });
    const s = useLineHistoryStore();
    await s.load('L04', '2026-W24');
    expect(s.evidence).toEqual(evidence);
    expect(s.appliedProposal).toMatchObject({ appliedOn: '2026-06-04' });
    expect(s.treatment).toEqual({ name: 'Protectant spray' });
    expect(s.statusError).toBe('');
    expect(s.evidenceError).toBe('');
    expect(s.treatmentError).toBe('');
  });
  it('treats a cycle without trend evidence as expected, not as a load error', async () => {
    fetchMock.mockImplementation((url) => {
      if (url.endsWith('/history')) return Promise.resolve(json(200, hist('L04', '2026-W24')));
      if (url.endsWith('/lines/L04')) return Promise.resolve(json(200, lineStatus('L04', {
        latest_cycle: { cycle_id: 'c-L04-24', week: '2026-W24', status: 'done' },
      })));
      return Promise.resolve(json(404, { error: 'unknown_evidence' }));
    });
    const s = useLineHistoryStore();
    await s.load('L04', '2026-W24');
    expect(s).toMatchObject({ phase: 'ready', evidence: null, evidenceError: '' });
  });
  it('does not use a later cycle or treatment for an earlier selected week', async () => {
    fetchMock.mockImplementation((url) => Promise.resolve(url.endsWith('/history')
      ? json(200, hist('L04', '2026-W22'))
      : json(200, lineStatus('L04', {
        latest_cycle: { cycle_id: 'future', week: '2026-W24', status: 'done' },
        proposals: [{ proposal_id: 'future-proposal', cycle_id: 'future', week: '2026-W24', status: 'applied' }],
      }))));
    const s = useLineHistoryStore();
    await s.load('L04', '2026-W22');
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(s).toMatchObject({ phase: 'ready', evidence: null, appliedProposal: null });
  });
});
