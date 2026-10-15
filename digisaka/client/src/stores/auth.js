import { defineStore } from 'pinia';

// Supabase sign-in (password grant over plain fetch, no SDK). The roles are read from the access token
// for display only; the servers verify the token and enforce access.
const KEY = 'digisaka.supabase.access_token';
export const TECHNICAL_USER_ROLES = ['administrator', 'domain_expert', 'plant_pathologist'];

const store = {
  get: () => { try { return globalThis.sessionStorage.getItem(KEY); } catch { return null; } },
  set: (v) => { try { v ? globalThis.sessionStorage.setItem(KEY, v) : globalThis.sessionStorage.removeItem(KEY); } catch { /* storage unavailable: the in-memory token still works */ } },
};

function profileFromToken(token) {
  try {
    const part = String(token).split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
    const p = JSON.parse(atob(part.padEnd(Math.ceil(part.length / 4) * 4, '=')));
    const roles = Array.isArray(p.app_metadata?.roles) ? p.app_metadata.roles.filter((r) => typeof r === 'string') : [];
    return { email: typeof p.email === 'string' ? p.email : '', roles };
  } catch { return { email: '', roles: [] }; }
}

export const useAuthStore = defineStore('auth', {
  state: () => {
    const token = store.get();
    return { token, ...(token ? profileFromToken(token) : { email: '', roles: [] }) };
  },
  getters: {
    signedIn: (s) => !!s.token,
    practitioner: (s) => s.roles.includes('practitioner'),
    technicalUser: (s) => s.roles.some((r) => TECHNICAL_USER_ROLES.includes(r)),
    initials: (s) => (s.email[0] || '?').toUpperCase(),
  },
  actions: {
    async signIn(email, password) {
      const url = import.meta.env.VITE_SUPABASE_URL, anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
      if (!url || !anonKey) throw new Error('Supabase is not configured. Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY.');
      let res;
      try {
        res = await globalThis.fetch(url.replace(/\/+$/, '') + '/auth/v1/token?grant_type=password', {
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
      // The refresh token is deliberately dropped.
      store.set(data.access_token);
      Object.assign(this, { token: data.access_token, ...profileFromToken(data.access_token) });
    },
    signOut() {
      store.set(null);
      Object.assign(this, { token: null, email: '', roles: [] });
    },
  },
});
