import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { setTokenProvider } from '../api.js';
import { useFactReviewStore, PAGE } from './factReview.js';

const json = (status, body) => ({ status, ok: status < 400, json: async () => body });
const W = 'w1';
const base = `/api/v1/knowledge-maintenance/workflows/${W}`;
const fact = (id, extra = {}) => ({ id, disposition: 'pending', requires_action: true, lock_version: 0, claimed_by: null, claimed_at: null, claim_expires_at: null, ...extra });
const page = (facts, total = facts.length, offset = 0) => json(200, { facts, total, limit: PAGE, offset });
let fetchMock;

beforeEach(() => {
  setActivePinia(createPinia());
  setTokenProvider(() => 'TOK');
  fetchMock = vi.fn();
  vi.stubGlobal('fetch', fetchMock);
});
afterEach(() => { vi.unstubAllGlobals(); setTokenProvider(() => null); });

describe('loading facts', () => {
  it('asks for one page of the chosen disposition and keeps the total', async () => {
    fetchMock.mockResolvedValue(page([fact('f1'), fact('f2')], 98));
    const s = useFactReviewStore();
    await s.load(W, { disposition: 'pending' });
    expect(fetchMock.mock.calls[0][0]).toBe(`${base}/facts?disposition=pending&limit=${PAGE}&offset=0`);
    expect(s.facts).toHaveLength(2);
    expect(s.total).toBe(98);
    await s.goTo(PAGE);
    expect(fetchMock.mock.calls[1][0]).toContain(`offset=${PAGE}`);
  });
  it('leaves the disposition out for "all" and shows a load error', async () => {
    fetchMock.mockResolvedValueOnce(page([])).mockResolvedValueOnce(json(404, { error: { code: 'NOT_FOUND', message: 'Workflow not found', details: {} } }));
    const s = useFactReviewStore();
    await s.load(W, { disposition: '' });
    expect(fetchMock.mock.calls[0][0]).not.toContain('disposition');
    await s.load(W, { disposition: '' });
    expect(s.error).toBe('Workflow not found');
  });
});

describe('reviewing a fact', () => {
  it('sends the fact version and the stage, then updates the fact and the pending count', async () => {
    fetchMock.mockResolvedValueOnce(page([fact('f1'), fact('f2')], 2))
      .mockResolvedValueOnce(json(200, { fact_id: 'f1', disposition: 'accepted', lock_version: 1, review_decision_id: 'd1' }));
    const s = useFactReviewStore();
    await s.load(W, { disposition: 'pending' });
    expect(await s.review('f1', 'accept', 'extraction_review')).toBe(true);
    const [url, init] = fetchMock.mock.calls[1];
    expect(url).toBe(`${base}/facts/f1/review`);
    expect(JSON.parse(init.body)).toEqual({ lock_version: 0, review_stage: 'extraction_review', decision: 'accept' });
    expect(s.facts.find((f) => f.id === 'f1')).toMatchObject({ disposition: 'accepted', lock_version: 1, requires_action: false, claimed_by: null });
  });
  it('shows the API message on a stale version and reloads the page', async () => {
    fetchMock.mockResolvedValueOnce(page([fact('f1')]))
      .mockResolvedValueOnce(json(409, { error: { code: 'CONFLICT', message: 'The fact changed since it was read; reload and retry', details: {} } }))
      .mockResolvedValueOnce(page([fact('f1', { disposition: 'rejected', lock_version: 3 })]));
    const s = useFactReviewStore();
    await s.load(W, { disposition: '' });
    expect(await s.review('f1', 'reject', 'extraction_review')).toBe(false);
    expect(s.error).toMatch(/changed since it was read/);
    expect(s.facts[0]).toMatchObject({ disposition: 'rejected', lock_version: 3 });
  });
  it('ignores a second click while a call is in flight', async () => {
    let release; fetchMock.mockResolvedValueOnce(page([fact('f1')]));
    const s = useFactReviewStore(); await s.load(W, { disposition: '' });
    fetchMock.mockReturnValueOnce(new Promise((r) => { release = r; }));
    const a = s.review('f1', 'accept', 'extraction_review');
    expect(await s.review('f1', 'reject', 'extraction_review')).toBe(false);
    release(json(200, { fact_id: 'f1', disposition: 'accepted', lock_version: 1, review_decision_id: 'd' }));
    await a;
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });
});

describe('claims', () => {
  it('claims and releases a fact and shows who holds it', async () => {
    fetchMock.mockResolvedValueOnce(page([fact('f1')]))
      .mockResolvedValueOnce(json(200, { fact_id: 'f1', claimed_by: 'u1', claimed_at: 't0', claim_expires_at: 't1', previous_holder: null }))
      .mockResolvedValueOnce(json(200, { fact_id: 'f1', claimed_by: null, claimed_at: null, claim_expires_at: null, previous_holder: null }));
    const s = useFactReviewStore(); await s.load(W, { disposition: '' });
    await s.claim('f1');
    expect(fetchMock.mock.calls[1][0]).toBe(`${base}/facts/f1/claim`);
    expect(s.facts[0]).toMatchObject({ claimed_by: 'u1', claim_expires_at: 't1' });
    await s.release('f1');
    expect(s.facts[0].claimed_by).toBeNull();
  });
  it('tells you when you took over a colleague\'s claim', async () => {
    fetchMock.mockResolvedValueOnce(page([fact('f1', { claimed_by: 'u2' })]))
      .mockResolvedValueOnce(json(200, { fact_id: 'f1', claimed_by: 'u1', claimed_at: 't0', claim_expires_at: 't1', previous_holder: { user_id: 'u2', claimed_at: 't' } }));
    const s = useFactReviewStore(); await s.load(W, { disposition: '' });
    await s.claim('f1');
    expect(s.notice).toMatch(/took over/);
  });
  it('shows the API message when a claim is refused', async () => {
    fetchMock.mockResolvedValueOnce(page([fact('f1')]))
      .mockResolvedValueOnce(json(409, { error: { code: 'CONFLICT', message: 'Claims need a review gate and a fact that still needs action', details: {} } }));
    const s = useFactReviewStore(); await s.load(W, { disposition: '' });
    await s.claim('f1');
    expect(s.error).toMatch(/Claims need a review gate/);
  });
});
