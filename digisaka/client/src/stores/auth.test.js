import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { useAuthStore } from './auth.js';

const jwt = (claims) => `h.${btoa(JSON.stringify(claims))}.s`;
const memoryStorage = () => { const m = new Map(); return { getItem: (k) => m.get(k) ?? null, setItem: (k, v) => m.set(k, v), removeItem: (k) => m.delete(k) }; };
const grant = (body, status = 200) => vi.fn(async () => ({ ok: status < 400, status, json: async () => body }));

beforeEach(() => {
  setActivePinia(createPinia());
  vi.stubGlobal('sessionStorage', memoryStorage());
  vi.stubEnv('VITE_SUPABASE_URL', 'https://proj.supabase.co/');
  vi.stubEnv('VITE_SUPABASE_ANON_KEY', 'anon');
});
afterEach(() => { vi.unstubAllGlobals(); vi.unstubAllEnvs(); });

describe('auth store sign-in', () => {
  it('signs in with the password grant and reads email and roles from the token', async () => {
    const f = grant({ access_token: jwt({ email: 'pat@farm.test', app_metadata: { roles: ['practitioner'] } }) });
    vi.stubGlobal('fetch', f);
    const auth = useAuthStore();
    await auth.signIn(' pat@farm.test ', 'pw');
    const [url, init] = f.mock.calls[0];
    expect(url).toBe('https://proj.supabase.co/auth/v1/token?grant_type=password');
    expect(init.headers.apikey).toBe('anon');
    expect(JSON.parse(init.body)).toEqual({ email: 'pat@farm.test', password: 'pw' });
    expect(auth).toMatchObject({ signedIn: true, email: 'pat@farm.test', practitioner: true, technicalUser: false, initials: 'P' });
  });

  it('knows a Technical User and someone with both roles', async () => {
    vi.stubGlobal('fetch', grant({ access_token: jwt({ email: 'dom@lab.test', app_metadata: { roles: ['domain_expert', 'practitioner'] } }) }));
    const auth = useAuthStore();
    await auth.signIn('dom@lab.test', 'pw');
    expect(auth).toMatchObject({ technicalUser: true, practitioner: true });
  });

  it('says wrong email or password for bad credentials and stays signed out', async () => {
    vi.stubGlobal('fetch', grant({ error: 'invalid_grant' }, 400));
    const auth = useAuthStore();
    await expect(auth.signIn('a@b.c', 'bad')).rejects.toThrow('Wrong email or password.');
    expect(auth.signedIn).toBe(false);
  });

  it('says it cannot reach the service when the network fails, and explains a missing configuration', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => { throw new Error('down'); }));
    const auth = useAuthStore();
    await expect(auth.signIn('a@b.c', 'pw')).rejects.toThrow('Cannot reach the sign-in service. Try again.');
    vi.stubEnv('VITE_SUPABASE_URL', '');
    await expect(auth.signIn('a@b.c', 'pw')).rejects.toThrow(/not configured/);
  });
});

describe('auth store session', () => {
  it('keeps the token across a reload of the store and clears it on sign-out', async () => {
    const token = jwt({ email: 'pat@farm.test', app_metadata: { roles: ['practitioner'] } });
    vi.stubGlobal('fetch', grant({ access_token: token }));
    await useAuthStore().signIn('pat@farm.test', 'pw');

    setActivePinia(createPinia());
    const again = useAuthStore();
    expect(again).toMatchObject({ signedIn: true, token, email: 'pat@farm.test' });

    again.signOut();
    expect(again).toMatchObject({ signedIn: false, token: null, email: '', practitioner: false });
    setActivePinia(createPinia());
    expect(useAuthStore().signedIn).toBe(false);
  });

  it('treats a token it cannot read as signed in with no roles, never a crash', () => {
    sessionStorage.setItem('digisaka.supabase.access_token', 'garbage');
    const auth = useAuthStore();
    expect(auth).toMatchObject({ signedIn: true, email: '', practitioner: false, technicalUser: false });
  });
});
