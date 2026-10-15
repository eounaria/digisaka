// App-wide singletons for the scheduler screens: Supabase sign-in plus the API client that uses its token.
import { reactive } from 'vue';
import { createSupabaseAuth } from './supabaseAuth.js';
import { createSchedulerClient } from './client.js';

const fetchNow = (...args) => globalThis.fetch(...args);

export const supabase = createSupabaseAuth({
  fetch: fetchNow,
  url: import.meta.env.VITE_SUPABASE_URL,
  anonKey: import.meta.env.VITE_SUPABASE_ANON_KEY,
  storage: (() => { try { return globalThis.sessionStorage; } catch { return undefined; } })(),
});

// Reactive mirror so screens can react to sign-in and sign-out.
export const sessionState = reactive({ signedIn: supabase.isSignedIn() });

export const signIn = async (email, password) => { await supabase.signIn(email, password); sessionState.signedIn = true; };
export const signOut = () => { supabase.signOut(); sessionState.signedIn = false; };

let onSignedOut = () => {};
export const setSignedOutHandler = (fn) => { onSignedOut = fn; };

export const scheduler = createSchedulerClient({
  fetch: fetchNow,
  getToken: supabase.getToken,
  onUnauthorized: () => { signOut(); onSignedOut(); },
});
