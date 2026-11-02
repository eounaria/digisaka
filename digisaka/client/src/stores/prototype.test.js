import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { setTokenProvider } from '../api.js';
import { usePrototypeStore } from './prototype.js';

const json = (status, body) => ({ status, ok: status < 400, json: async () => body });
const BASE = '/api/v1/scheduler/prototype/lines/L04/weeks/2026-W24';
const sample = { line_id: 'L04', week: '2026-W24', products: [{ id: 'mancozeb' }], selected_option_id: 'mancozeb', sample: true };
let fetchMock;

beforeEach(() => {
  vi.stubEnv('VITE_STUB_SAMPLES', '1');
  setActivePinia(createPinia());
  setTokenProvider(() => 'TOK');
  fetchMock = vi.fn();
  vi.stubGlobal('fetch', fetchMock);
});
afterEach(() => {
  vi.unstubAllGlobals();
  vi.unstubAllEnvs();
  setTokenProvider(() => null);
});

describe('stub prototype data', () => {
  it('loads prototype data for the selected line and week', async () => {
    fetchMock.mockResolvedValue(json(200, sample));
    const store = usePrototypeStore();
    await store.load('L04', '2026-W24');
    expect(fetchMock.mock.calls[0][0]).toBe(BASE);
    expect(store).toMatchObject({ phase: 'ready', data: sample });
  });

  it('does not request prototype data when the stub flag is off', async () => {
    vi.stubEnv('VITE_STUB_SAMPLES', '');
    const store = usePrototypeStore();
    await store.load('L04', '2026-W24');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('persists a selected prototype product through the stub endpoint', async () => {
    fetchMock
      .mockResolvedValueOnce(json(200, sample))
      .mockResolvedValueOnce(json(200, { selected_option_id: 'chlorothalonil', sample: true }));
    const store = usePrototypeStore();
    await store.load('L04', '2026-W24');
    expect(await store.select('chlorothalonil')).toBe(true);
    expect(fetchMock.mock.calls[1][0]).toBe(`${BASE}/selection`);
    expect(JSON.parse(fetchMock.mock.calls[1][1].body)).toEqual({ option_id: 'chlorothalonil' });
    expect(store.data.selected_option_id).toBe('chlorothalonil');
  });

  it('confirms multiple sample products locally without changing the scheduler proposal', async () => {
    fetchMock.mockResolvedValueOnce(json(200, {
      ...sample,
      products: [{ id: 'mancozeb' }, { id: 'chlorothalonil' }],
    }));
    const store = usePrototypeStore();
    await store.load('L04', '2026-W24');
    expect(store.confirmSample('mancozeb')).toBe(true);
    expect(store.confirmSample('chlorothalonil')).toBe(true);
    expect(store.confirmSample('mancozeb')).toBe(true);
    expect(store.confirmedOptionIds).toEqual(['mancozeb', 'chlorothalonil']);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    store.removeSample('mancozeb');
    expect(store.confirmedOptionIds).toEqual(['chlorothalonil']);
  });

  it('rejects unknown products from local sample confirmation', async () => {
    fetchMock.mockResolvedValueOnce(json(200, sample));
    const store = usePrototypeStore();
    await store.load('L04', '2026-W24');
    expect(store.confirmSample('missing')).toBe(false);
    expect(store.error).toContain('not available in the prototype catalog');
  });

  it('surfaces selection failures', async () => {
    fetchMock
      .mockResolvedValueOnce(json(200, sample))
      .mockResolvedValueOnce(json(400, { error: 'invalid_option', detail: 'Choose a product from the prototype catalog.' }));
    const store = usePrototypeStore();
    await store.load('L04', '2026-W24');
    expect(await store.select('missing')).toBe(false);
    expect(store.error).toContain('Choose a product from the prototype catalog');
  });
});
