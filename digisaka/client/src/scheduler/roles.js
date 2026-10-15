// Reads the signed-in user's email and roles from the Supabase access token. Display logic only:
// the servers verify the token and enforce access.
export const TECHNICAL_USER_ROLES = ['administrator', 'domain_expert', 'plant_pathologist'];

export function profileFromToken(token) {
  try {
    const part = String(token).split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
    const p = JSON.parse(atob(part.padEnd(Math.ceil(part.length / 4) * 4, '=')));
    const roles = Array.isArray(p.app_metadata?.roles) ? p.app_metadata.roles.filter((r) => typeof r === 'string') : [];
    return { email: typeof p.email === 'string' ? p.email : '', roles };
  } catch { return { email: '', roles: [] }; }
}

export const isTechnicalUser = (roles) => roles.some((r) => TECHNICAL_USER_ROLES.includes(r));
