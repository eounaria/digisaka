import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { setTokenProvider } from '../api.js';
import { useLinesStore, proposalRows } from './lines.js';

const json = (status, body) => ({ status, ok: status < 400, json: async () => body });
const status = (id, over = {}) => ({ line_id: id, proposals: [], applications: [], latest_cycle: null, human_review_required: false, ...over });
let fetchMock;
beforeEach(() => { setActivePinia(createPinia()); setTokenProvider(() => 'TOK'); fetchMock = vi.fn(); vi.stubGlobal('fetch', fetchMock); });
afterEach(() => { vi.unstubAllGlobals(); setTokenProvider(() => null); });

describe('lines store', () => {
  it('loads every line status and keeps those with proposals for the schedule list', async () => {
    const p = { proposal_id: 'p1', week: '2026-W24', status: 'proposed', option_id: 'o', window_start: '2026-06-15', window_end: '2026-06-17' };
    fetchMock.mockImplementation(async (url) => {
      if (url.endsWith('/lines')) return json(200, { lines: ['L03', 'L04'] });
      return json(200, status(url.endsWith('L04') ? 'L04' : 'L03', url.endsWith('L04') ? { proposals: [p] } : {}));
    });
    const s = useLinesStore();
    await s.load();
    expect(s.statuses.map((l) => l.line_id)).toEqual(['L03', 'L04']);
    expect(s.withProposals.map((l) => l.line_id)).toEqual(['L04']);
    expect(s.error).toBe('');
  });
  it('a line with no history is listed, not an error', async () => {
    fetchMock.mockImplementation(async (url) => (url.endsWith('/lines') ? json(200, { lines: ['L01'] }) : json(200, status('L01'))));
    const s = useLinesStore();
    await s.load();
    expect(s.statuses).toHaveLength(1);
    expect(s.error).toBe('');
  });
  it('one failing line does not hide the others', async () => {
    fetchMock.mockImplementation(async (url) => {
      if (url.endsWith('/lines')) return json(200, { lines: ['L01', 'L02'] });
      return url.endsWith('L01') ? json(404, { error: 'unknown_line', detail: 'x' }) : json(200, status('L02'));
    });
    const s = useLinesStore();
    await s.load();
    expect(s.statuses[0]).toMatchObject({ line_id: 'L01', error: 'That line does not exist.' });
    expect(s.statuses[1].error).toBeUndefined();
  });
  it('shows an error when the line list cannot be loaded', async () => {
    fetchMock.mockResolvedValue(json(403, { error: 'forbidden', detail: 'x' }));
    const s = useLinesStore();
    await s.load();
    expect(s.error).toBe('This account is not a Practitioner.');
    expect(s.loading).toBe(false);
  });
});

describe('proposalRows', () => {
  it('orders newest week first and adds the recorded application date', () => {
    const line = status('L04', {
      proposals: [{ proposal_id: 'a', week: '2026-W23' }, { proposal_id: 'b', week: '2026-W24' }],
      applications: [{ proposal_id: 'a', applied_on: '2026-06-10' }],
    });
    expect(proposalRows(line).map((r) => [r.proposal_id, r.appliedOn])).toEqual([['b', null], ['a', '2026-06-10']]);
  });
});
