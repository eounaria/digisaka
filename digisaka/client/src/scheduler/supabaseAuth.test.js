import { describe, it, expect, vi } from 'vitest';
import { createSupabaseAuth } from './supabaseAuth.js';

function memoryStorage() {
  const m = new Map();
  return { getItem: (k) => m.get(k) ?? null, setItem: (k, v) => m.set(k, v), removeItem: (k) => m.delete(k) };
}
function make(response, storage = memoryStorage()) {
  const fetch = vi.fn(async () => response);
  const auth = createSupabaseAuth({ fetch, url: 'https://x.supabase.co/', anonKey: 'anon', storage });
  return { auth, fetch, storage };
}

describe('createSupabaseAuth', () => {
  it('signs in with the password grant and keeps only the access token', async () => {
    const { auth, fetch, storage } = make({ ok: true, status: 200, json: async () => ({ access_token: 'AT', refresh_token: 'RT', user: { email: 'a@b' } }) });
    await auth.signIn(' a@b ', 'pw');
    const [url, init] = fetch.mock.calls[0];
    expect(url).toBe('https://x.supabase.co/auth/v1/token?grant_type=password');
    expect(init.method).toBe('POST');
    expect(init.headers.apikey).toBe('anon');
    expect(JSON.parse(init.body)).toEqual({ email: 'a@b', password: 'pw' });
    expect(auth.getToken()).toBe('AT');
    expect(auth.isSignedIn()).toBe(true);
    expect(JSON.stringify([...Object.values(storage)])).not.toMatch(/RT/);
  });

  it('shows a clear message for a wrong password and stores nothing', async () => {
    const { auth } = make({ ok: false, status: 400, json: async () => ({ error: 'invalid_grant', error_description: 'Invalid login credentials' }) });
    await expect(auth.signIn('a@b', 'bad')).rejects.toThrow('Wrong email or password.');
    expect(auth.getToken()).toBeNull();
  });

  it('reports other failures without echoing the response body', async () => {
    const { auth } = make({ ok: false, status: 500, json: async () => ({ msg: 'internal secret' }) });
    const err = await auth.signIn('a@b', 'pw').catch((e) => e);
    expect(err.message).not.toMatch(/secret/);
    expect(err.message).toMatch(/try again/i);
  });

  it('fails clearly when Supabase is not configured', async () => {
    const auth = createSupabaseAuth({ fetch: vi.fn(), url: '', anonKey: '', storage: memoryStorage() });
    await expect(auth.signIn('a@b', 'pw')).rejects.toThrow(/not configured/i);
  });

  it('signs out by clearing the token', async () => {
    const { auth } = make({ ok: true, status: 200, json: async () => ({ access_token: 'AT' }) });
    await auth.signIn('a@b', 'pw');
    auth.signOut();
    expect(auth.getToken()).toBeNull();
    expect(auth.isSignedIn()).toBe(false);
  });

  it('survives a throwing storage', async () => {
    const storage = { getItem() { throw new Error('x'); }, setItem() { throw new Error('x'); }, removeItem() { throw new Error('x'); } };
    const { auth } = make({ ok: true, status: 200, json: async () => ({ access_token: 'AT' }) }, storage);
    await auth.signIn('a@b', 'pw');
    expect(auth.getToken()).toBe('AT');
    auth.signOut();
    expect(auth.getToken()).toBeNull();
  });

  it('restores a token already in storage', () => {
    const storage = memoryStorage();
    storage.setItem('digisaka.supabase.access_token', 'OLD');
    const { auth } = make({ ok: true, status: 200, json: async () => ({}) }, storage);
    expect(auth.getToken()).toBe('OLD');
  });
});
