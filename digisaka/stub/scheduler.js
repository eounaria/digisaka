// Stand-in for the scheduler API under /api/v1/scheduler. Errors are the scheduler's flat {error, detail}.
import { userForToken } from './supabase.js';

const BASE = '/api/v1/scheduler';
const fail = (status, error, detail) => ({ status, body: { error, detail } });
const ok = (body) => ({ status: 200, body });

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
function isValidWeek(value) {
  const m = /^(\d{4})-W(\d{2})$/.exec(value);
  if (!m) return false;
  const year = Number(m[1]), week = Number(m[2]);
  const d = new Date(Date.UTC(year, 11, 28));
  d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
  const last = Math.ceil(((d - Date.UTC(d.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7);
  return week >= 1 && week <= last;
}

const newest = (cycles) => [...cycles].sort((a, b) => b.week.localeCompare(a.week)).at(0) ?? null;

export function schedulerRoutes(store) {
  const line = (id) => store.data.lines[id];
  const findCycle = (id) => {
    for (const [lineId, l] of Object.entries(store.data.lines)) {
      const cycle = l.cycles.find((c) => c.cycle_id === id);
      if (cycle) return { lineId, line: l, cycle };
    }
    return null;
  };
  const unknownLine = (id) => fail(404, 'unknown_line', `No line ${id}`);

  return [
    { method: 'GET', path: `${BASE}/lines`, handle: authed(() => ok({ lines: Object.keys(store.data.lines) })) },
    {
      method: 'GET', path: `${BASE}/lines/:id`,
      handle: authed(({ params }) => {
        const l = line(params.id);
        if (!l) return unknownLine(params.id);
        const latest = newest(l.cycles);
        return ok({
          line_id: params.id,
          proposals: l.proposals,
          applications: l.applications,
          latest_cycle: latest && { cycle_id: latest.cycle_id, week: latest.week, status: latest.status, outcome: latest.outcome, outcome_reason: latest.outcome_reason },
          human_review_required: latest?.outcome === 'human_review_required',
          weeks_assessed: l.cycles.length,
          leaves_scanned: l.leaves,
        });
      }),
    },
    {
      method: 'GET', path: `${BASE}/lines/:id/weeks/:week/history`,
      handle: authed(({ params }) => {
        const l = line(params.id);
        if (!l) return unknownLine(params.id);
        if (!isValidWeek(params.week)) return fail(400, 'invalid_week', `${params.week} is not a week key`);
        return ok({ line_id: params.id, week: params.week, weeks: l.weeks.filter((w) => w.week <= params.week).slice(-3) });
      }),
    },
    {
      method: 'GET', path: `${BASE}/cycles/:id/evidence`,
      handle: authed(({ params }) => {
        const found = findCycle(params.id);
        if (!found) return fail(404, 'unknown_cycle', `No cycle ${params.id}`);
        if (!found.cycle.evidence) return fail(404, 'unknown_evidence', `Cycle ${params.id} has no trend evidence`);
        return ok({
          cycle_id: params.id, line_id: found.lineId, week: found.cycle.week,
          weeks: found.line.weeks.filter((w) => w.week <= found.cycle.week),
          ...found.cycle.evidence,
        });
      }),
    },
  ];
}
