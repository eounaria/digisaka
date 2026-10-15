import { describe, it, expect, vi, afterEach } from 'vitest';
import { api, setTokenProvider, setUnauthorizedHandler } from './api.js';

const reply = (status, body = {}) => vi.fn(async () => ({ status, ok: status < 400, json: async () => body }));
afterEach(() => { vi.unstubAllGlobals(); setTokenProvider(() => null); setUnauthorizedHandler(() => {}); });

describe('admin api client', () => {
  it('sends the Supabase token as a bearer', async () => {
    const f = reply(200, { ok: 1 }); vi.stubGlobal('fetch', f); setTokenProvider(() => 'TOK');
    await api.get('/api/admin/documents'); await api.post('/api/admin/x', { a: 1 }); await api.upload('/api/admin/up', { type: 'image/png' });
    for (const [, init] of f.mock.calls) expect(init.headers.Authorization).toBe('Bearer TOK');
    expect(f.mock.calls[1][1].headers['Content-Type']).toBe('application/json');
  });
  it('sends no Authorization header when signed out', async () => {
    const f = reply(200); vi.stubGlobal('fetch', f);
    await api.get('/api/admin/x');
    expect(f.mock.calls[0][1].headers.Authorization).toBeUndefined();
  });
  it('calls the unauthorized handler on a 401 and still rejects', async () => {
    vi.stubGlobal('fetch', reply(401, { error: 'Sign in to continue.' })); const h = vi.fn(); setUnauthorizedHandler(h);
    await expect(api.get('/api/admin/x')).rejects.toMatchObject({ status: 401 });
    expect(h).toHaveBeenCalledOnce();
  });
});
