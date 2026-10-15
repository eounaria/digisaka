import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { setTokenProvider } from '../api.js';
import { useEvidenceStore } from './evidence.js';

const json = (status, body) => ({ status, ok: status < 400, json: async () => body });
const ev = { cycle_id: 'c1', line_id: 'L04', week: '2026-W24', weeks: [{ week: '2026-W24', yls: 5, yli: 3, rainfall_mm: 40 }], disease: { worsening: true }, rainfall: { favourable: true } };
let fetchMock;

beforeEach(() => { setActivePinia(createPinia()); setTokenProvider(() => 'TOK'); fetchMock = vi.fn(); vi.stubGlobal('fetch', fetchMock); });
afterEach(() => { vi.unstubAllGlobals(); setTokenProvider(() => null); });

describe('evidence store', () => {
  it('loads the evidence for a cycle', async () => {
    fetchMock.mockResolvedValue(json(200, ev));
    const s = useEvidenceStore();
    await s.load('c1');
    expect(fetchMock.mock.calls[0][0]).toBe('/api/v1/scheduler/cycles/c1/evidence');
    expect(s).toMatchObject({ phase: 'ready', evidence: ev });
  });
  it('treats unknown_evidence as none, not an error', async () => {
    fetchMock.mockResolvedValue(json(404, { error: 'unknown_evidence' }));
    const s = useEvidenceStore();
    await s.load('c1');
    expect(s).toMatchObject({ phase: 'none', error: '', evidence: null });
  });
  it('shows a readable error for other failures', async () => {
    fetchMock.mockResolvedValue(json(500, {}));
    const s = useEvidenceStore();
    await s.load('c1');
    expect(s).toMatchObject({ phase: 'error', error: expect.stringMatching(/Something went wrong/) });
  });
  it('ignores a slow answer from an earlier load', async () => {
    let first;
    fetchMock.mockImplementationOnce(() => new Promise((r) => { first = r; }));
    fetchMock.mockResolvedValueOnce(json(200, { ...ev, cycle_id: 'c2' }));
    const s = useEvidenceStore();
    const a = s.load('c1');
    await s.load('c2');
    first(json(200, ev));
    await a;
    expect(s.evidence.cycle_id).toBe('c2');
  });
  it('reset returns to idle and drops a pending answer', async () => {
    let first;
    fetchMock.mockImplementationOnce(() => new Promise((r) => { first = r; }));
    const s = useEvidenceStore();
    const a = s.load('c1');
    s.reset();
    first(json(200, ev));
    await a;
    expect(s).toMatchObject({ phase: 'idle', evidence: null });
  });
});
