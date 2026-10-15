import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { setTokenProvider } from '../api.js';
import { useLineHistoryStore } from './lineHistory.js';

const json = (status, body) => ({ status, ok: status < 400, json: async () => body });
const hist = (line, week) => ({ line_id: line, week, weeks: [{ week, yls: 5, yli: 3, rainfall_mm: 12 }] });
let fetchMock;

beforeEach(() => { setActivePinia(createPinia()); setTokenProvider(() => 'TOK'); fetchMock = vi.fn(); vi.stubGlobal('fetch', fetchMock); });
afterEach(() => { vi.unstubAllGlobals(); setTokenProvider(() => null); });

describe('line history store', () => {
  it('loads the last weeks of a line up to a week', async () => {
    fetchMock.mockResolvedValue(json(200, hist('L04', '2026-W24')));
    const s = useLineHistoryStore();
    await s.load('L04', '2026-W24');
    expect(fetchMock.mock.calls[0][0]).toBe('/api/v1/scheduler/lines/L04/weeks/2026-W24/history');
    expect(s).toMatchObject({ phase: 'ready', weeks: [{ week: '2026-W24', yls: 5 }] });
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
    fetchMock.mockImplementationOnce(() => new Promise((r) => { first = r; }));
    fetchMock.mockResolvedValueOnce(json(200, hist('L05', '2026-W24')));
    const s = useLineHistoryStore();
    const a = s.load('L04', '2026-W24');
    await s.load('L05', '2026-W24');
    first(json(200, hist('L04', '2026-W24')));
    await a;
    expect(s.lineId).toBe('L05');
    expect(s.weeks).toEqual(hist('L05', '2026-W24').weeks);
  });
});
