// Drives the real auth store against the in-process stub, so a stub change that breaks sign-in fails here.
import { describe, it, expect, beforeAll, afterAll, beforeEach, afterEach, vi } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { createStub } from '../../../stub/server.js';
import { useAuthStore } from '../stores/auth.js';

let server, base;
beforeAll(async () => {
  server = createStub();
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  base = `http://127.0.0.1:${server.address().port}`;
});
afterAll(() => server.close());
beforeEach(() => {
  setActivePinia(createPinia());
  const m = new Map();
  vi.stubGlobal('sessionStorage', { getItem: (k) => m.get(k) ?? null, setItem: (k, v) => m.set(k, v), removeItem: (k) => m.delete(k) });
  vi.stubEnv('VITE_SUPABASE_URL', base);
  vi.stubEnv('VITE_SUPABASE_ANON_KEY', 'stub-anon-key');
});
afterEach(() => { vi.unstubAllEnvs(); vi.unstubAllGlobals(); });

describe('auth store against the stub', () => {
  it('signs in a practitioner', async () => {
    const auth = useAuthStore();
    await auth.signIn('farmer@digisaka.test', 'pw');
    expect(auth).toMatchObject({ signedIn: true, email: 'farmer@digisaka.test', practitioner: true, technicalUser: false });
  });
  it('signs in a Technical User and a dual-role user', async () => {
    const admin = useAuthStore();
    await admin.signIn('admin@digisaka.test', 'pw');
    expect(admin).toMatchObject({ technicalUser: true, practitioner: false });
    await admin.signIn('both@digisaka.test', 'pw');
    expect(admin).toMatchObject({ technicalUser: true, practitioner: true });
  });
  it('shows the wrong-credentials message for a bad password or unknown email', async () => {
    const auth = useAuthStore();
    await expect(auth.signIn('farmer@digisaka.test', 'wrong')).rejects.toThrow('Wrong email or password.');
    await expect(auth.signIn('nobody@digisaka.test', 'pw')).rejects.toThrow('Wrong email or password.');
    expect(auth.signedIn).toBe(false);
  });
});
