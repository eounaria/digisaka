// Supabase password grant used only by the scheduler screens. Plain fetch: no SDK, no Supabase writes.
const KEY = 'digisaka.supabase.access_token';

export function createSupabaseAuth({ fetch, url, anonKey, storage }) {
  let token = null;
  const read = () => { try { return storage.getItem(KEY); } catch { return null; } };
  const write = (v) => { try { v ? storage.setItem(KEY, v) : storage.removeItem(KEY); } catch { /* storage unavailable: keep the in-memory token */ } };
  token = read();

  return {
    getToken: () => token,
    isSignedIn: () => !!token,
    async signIn(email, password) {
      if (!url || !anonKey) throw new Error('Supabase is not configured. Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY.');
      let res;
      try {
        res = await fetch(url.replace(/\/+$/, '') + '/auth/v1/token?grant_type=password', {
          method: 'POST',
          headers: { apikey: anonKey, 'Content-Type': 'application/json' },
          body: JSON.stringify({ email: email.trim(), password }),
        });
      } catch {
        throw new Error('Cannot reach the sign-in service. Try again.');
      }
      const data = await res.json().catch(() => ({}));
      if (data.error === 'invalid_grant' || data.error_code === 'invalid_credentials') throw new Error('Wrong email or password.');
      if (!res.ok || !data.access_token) throw new Error('Sign-in failed. Try again.');
      token = data.access_token; // the refresh token is deliberately dropped
      write(token);
    },
    signOut() { token = null; write(null); },
  };
}
