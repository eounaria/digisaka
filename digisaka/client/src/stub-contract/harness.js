// Shared setup for contract tests: the in-process stub, a fake clock for its cycle timer, and a signed-in
// auth store whose token the shared api.js sends. Relative store URLs are pointed at the stub, as the dev proxy does.
import { beforeAll, afterAll, beforeEach, afterEach, vi } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { createStub } from '../../../stub/server.js';
import { setTokenProvider } from '../api.js';
import { useAuthStore } from '../stores/auth.js';

export const CYCLE_MS = 3000;

export function useStub({ email = 'farmer@digisaka.test' } = {}) {
  const clock = { t: 1_000_000 };
  const ctx = { clock, base: '', signIn: null };
  let server;
  const realFetch = globalThis.fetch;
  beforeAll(async () => {
    server = createStub({ now: () => clock.t, cycleMs: CYCLE_MS, stepMs: CYCLE_MS });
    await new Promise((r) => server.listen(0, '127.0.0.1', r));
    ctx.base = `http://127.0.0.1:${server.address().port}`;
  });
  afterAll(() => server.close());
  beforeEach(async () => {
    await realFetch(`${ctx.base}/__stub/reset`, { method: 'POST' });
    setActivePinia(createPinia());
    const m = new Map();
    vi.stubGlobal('sessionStorage', { getItem: (k) => m.get(k) ?? null, setItem: (k, v) => m.set(k, v), removeItem: (k) => m.delete(k) });
    vi.stubEnv('VITE_SUPABASE_URL', ctx.base);
    vi.stubEnv('VITE_SUPABASE_ANON_KEY', 'stub-anon-key');
    const auth = useAuthStore();
    await auth.signIn(email, 'pw');
    setTokenProvider(() => auth.token);
    vi.stubGlobal('fetch', (url, init) => realFetch(String(url).startsWith('/') ? ctx.base + url : url, init));
  });
  afterEach(() => { vi.unstubAllGlobals(); vi.unstubAllEnvs(); setTokenProvider(() => null); });
  return ctx;
}
