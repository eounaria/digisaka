// Pieces shared by the scheduler route files. Errors are the scheduler's flat {error, detail}.
import { userForToken } from './supabase.js';

export const BASE = '/api/v1/scheduler';
export const fail = (status, error, detail) => ({ status, body: { error, detail } });
export const ok = (body) => ({ status: 200, body });

// The scheduler wants a Practitioner: no token is 401, a Technical User without the role is 403.
export function authed(handle) {
  return (req) => {
    const user = userForToken((req.headers.authorization || '').replace(/^Bearer\s+/i, ''));
    if (!user) return fail(401, 'unauthenticated', 'Sign in to continue.');
    if (!user.roles.includes('practitioner')) return fail(403, 'forbidden', 'This account is not a Practitioner.');
    return handle(req);
  };
}

// ISO week keys such as 2026-W24; week 53 only exists in years whose 28 December falls in it.
export function isValidWeek(value) {
  const m = /^(\d{4})-W(\d{2})$/.exec(value);
  if (!m) return false;
  const year = Number(m[1]), week = Number(m[2]);
  const d = new Date(Date.UTC(year, 11, 28));
  d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
  const last = Math.ceil(((d - Date.UTC(d.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7);
  return week >= 1 && week <= last;
}

// Monday of the ISO week after `week`, and two days on: the window a new proposal offers.
export function nextWindow(week) {
  const [y, w] = [Number(week.slice(0, 4)), Number(week.slice(6))];
  const jan4 = new Date(Date.UTC(y, 0, 4));
  const monday = new Date(jan4.getTime() + (w * 7 - ((jan4.getUTCDay() || 7) - 1)) * 86400000);
  const iso = (d) => d.toISOString().slice(0, 10);
  return { start: iso(monday), end: iso(new Date(monday.getTime() + 2 * 86400000)) };
}


// The ISO week key of the week after `week`.
export function nextWeekKey(week) {
  const monday = new Date(`${nextWindow(week).start}T00:00:00Z`);
  const thursday = new Date(monday.getTime() + 3 * 86400000);
  const year = thursday.getUTCFullYear();
  return `${year}-W${String(Math.ceil(((thursday - Date.UTC(year, 0, 1)) / 86400000 + 1) / 7)).padStart(2, '0')}`;
}
