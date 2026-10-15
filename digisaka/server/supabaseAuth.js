// Verifies a Supabase access token the way AI_NeSy does: ask the project who the token belongs to,
// then read the roles from app_metadata.roles. Failures never grant access.
export const TECHNICAL_USER_ROLES = ['administrator', 'domain_expert', 'plant_pathologist'];
const KNOWN_ROLES = new Set([...TECHNICAL_USER_ROLES, 'practitioner']);

const fail = (status, message) => Object.assign(new Error(message), { status });

const displayName = (meta, email) => {
  for (const key of ['display_name', 'full_name', 'name']) if (typeof meta?.[key] === 'string' && meta[key]) return meta[key];
  return email;
};

export function createSupabaseVerifier({ fetch = globalThis.fetch, url, anonKey }) {
  return async function verify(token) {
    if (!url || !anonKey) throw fail(503, 'Sign-in could not be checked.');
    let res;
    try {
      res = await fetch(`${url.replace(/\/$/, '')}/auth/v1/user`, { headers: { Authorization: `Bearer ${token}`, apikey: anonKey } });
    } catch { throw fail(503, 'Sign-in could not be checked.'); }
    if (res.status === 401 || res.status === 403) throw fail(401, 'Sign in to continue.');
    if (!res.ok) throw fail(503, 'Sign-in could not be checked.');
    const u = await res.json().catch(() => null);
    if (!u?.email) throw fail(503, 'Sign-in could not be checked.');
    const raw = u.app_metadata?.roles;
    const roles = Array.isArray(raw) ? raw.filter((r) => KNOWN_ROLES.has(r)) : [];
    return { email: u.email, name: displayName(u.user_metadata, u.email), roles };
  };
}
