// Stand-in for the scheduler API under /api/v1/scheduler: lines, history, evidence, scans and cycles.
import { BASE, fail, ok, authed, isValidWeek, nextWindow } from './common.js';
import { proposalRoutes, summaryOf } from './proposals.js';

// The canned answer for an image is chosen by its name; anything unrecognised is a stage 2 leaf.
const SCENARIOS = ['healthy', 'not_leaf', 'referral', 'rescan', 'unavailable'];
const scenarioOf = (name) => SCENARIOS.find((s) => String(name).toLowerCase().includes(s)) ?? 'stage2';
const CHECKLIST = ['Dark streaks on the leaf underside', 'Yellow halo around the spots'];

// What closing a week ends in, decided by the line. L06 fails on its first run only.
const PLANS = {
  L04: { outcome: 'proposal' },
  L05: { outcome: 'human_review_required', reason: 'missing_feed_value' },
  L06: { outcome: 'continue_monitoring', reason: 'disease_not_worsening', failFirst: true },
};
const DEFAULT_PLAN = { outcome: 'continue_monitoring', reason: 'disease_not_worsening' };
const FAILURE_REASON = 'The weather feed did not respond in time.';

const newest = (cycles) => [...cycles].sort((a, b) => b.week.localeCompare(a.week)).at(0) ?? null;

export function schedulerRoutes(store, { now = Date.now, cycleMs = 4000 } = {}) {
  const line = (id) => store.data.lines[id];
  const findCycle = (id) => {
    if (store.data.runs[id]) return null;
    for (const [lineId, l] of Object.entries(store.data.lines)) {
      const cycle = l.cycles.find((c) => c.cycle_id === id);
      if (cycle) return { lineId, line: l, cycle };
    }
    return null;
  };
  const unknownLine = (id) => fail(404, 'unknown_line', `No line ${id}`);
  const lineWeek = (params) => {
    if (!line(params.id)) return unknownLine(params.id);
    if (!isValidWeek(params.week)) return fail(400, 'invalid_week', `${params.week} is not a week key`);
    return null;
  };

  // A closed week's cycle runs for cycleMs, then is done or failed. Settling is lazy, on the next read.
  const settle = (run) => {
    if (run.status !== 'running' || now() - run.startedAt < cycleMs) return run;
    const l = line(run.line_id);
    if (run.plan.failFirst && run.attempts === 1) {
      Object.assign(run, { status: 'failed', failure_reason: FAILURE_REASON });
      return run;
    }
    Object.assign(run, { status: 'done', outcome: run.plan.outcome, outcome_reason: run.plan.reason ?? null, failure_reason: null });
    l.cycles.push({ cycle_id: run.cycle_id, week: run.week, status: 'done', outcome: run.outcome, outcome_reason: run.outcome_reason, evidence: null });
    l.leaves += Object.values(store.data.diagnoses).filter((d) => d.line_id === run.line_id && d.week === run.week && d.verified).length;
    if (run.outcome === 'proposal') {
      const { start, end } = nextWindow(run.week);
      l.proposals.push({ proposal_id: `p-${run.line_id}-${run.week.slice(6)}`, cycle_id: run.cycle_id, option_id: 'opt-protectant', status: 'proposed', week: run.week, window_start: start, window_end: end });
    }
    return run;
  };
  const settleAll = () => Object.values(store.data.runs).forEach(settle);
  const runView = (r) => ({ cycle_id: r.cycle_id, line_id: r.line_id, week: r.week, status: r.status, outcome: r.outcome, outcome_reason: r.outcome_reason, failure_reason: r.failure_reason });
  const runsOf = (lineId) => Object.values(store.data.runs).filter((r) => r.line_id === lineId).map(settle);
  const verified = (lineId, week) => Object.values(store.data.diagnoses).some((d) => d.line_id === lineId && d.week === week && d.verified);
  const answer = (d) => ({ qa_output_id: d.id, outcome: d.outcome, stage: d.stage, ...(d.checklist ? { symptom_checklist: d.checklist } : {}), ...(d.next_action ? { next_action: d.next_action } : {}) });

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
          proposals: l.proposals.map((p) => summaryOf(store.data, l, p)),
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
        if (store.data.runs[params.id]) return fail(404, 'unknown_evidence', `Cycle ${params.id} has no trend evidence`);
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
    {
      method: 'POST', path: `${BASE}/lines/:id/weeks/:week/diagnoses`,
      handle: authed(({ params, body }) => {
        const bad = lineWeek(params);
        if (bad) return bad;
        if (!body?.img_name || !body?.img) return fail(400, 'validation_error', 'img_name and img are required');
        let scenario = scenarioOf(body.img_name);
        const key = `${params.id}/${params.week}/${body.img_name}`;
        // The QA service is down for the first upload of that image, then back.
        if (scenario === 'unavailable') {
          if (!store.data.uploads[key]) { store.data.uploads[key] = 1; return fail(503, 'qa_unavailable', 'The QA service is unavailable'); }
          scenario = 'stage2';
        }
        let d = body.qa_output_id && store.data.diagnoses[body.qa_output_id];
        if (body.qa_output_id && !d) return fail(404, 'unknown_session', `No scan ${body.qa_output_id}`);
        if (d && (d.line_id !== params.id || d.week !== params.week)) return fail(404, 'unknown_session', 'That scan belongs to another line-week');
        if (scenario === 'rescan' && d) scenario = 'stage2';
        d ??= (store.data.diagnoses[`qa-${store.data.nextId}`] = { id: `qa-${store.data.nextId++}`, line_id: params.id, week: params.week });
        Object.assign(d, { outcome: null, stage: null, checklist: null, next_action: null, verified: false });
        if (scenario === 'healthy') Object.assign(d, { outcome: 'healthy', verified: true });
        else if (scenario === 'not_leaf' || scenario === 'referral') d.outcome = scenario;
        else if (scenario === 'rescan') d.next_action = 're_scan';
        else Object.assign(d, { stage: 'Stage 2', checklist: CHECKLIST });
        return { status: 201, body: answer(d) };
      }),
    },
    {
      method: 'POST', path: `${BASE}/diagnoses/:id/confirm-symptoms`,
      handle: authed(({ params, body }) => {
        const d = store.data.diagnoses[params.id];
        if (!d) return fail(404, 'unknown_session', `No scan ${params.id}`);
        if (typeof body?.confirmed !== 'boolean') return fail(400, 'validation_error', 'confirmed must be true or false');
        if (d.checklist) {
          if (body.confirmed) Object.assign(d, { outcome: 'treatment_result', verified: true, checklist: null });
          else Object.assign(d, { next_action: 're_scan', checklist: null });
        }
        return ok(answer(d));
      }),
    },
    {
      method: 'POST', path: `${BASE}/lines/:id/weeks/:week/close`,
      handle: authed(({ params }) => {
        const bad = lineWeek(params);
        if (bad) return bad;
        const existing = runsOf(params.id).find((r) => r.week === params.week);
        const seeded = line(params.id).cycles.find((c) => c.week === params.week);
        if (existing) return { status: existing.status === 'running' ? 202 : 200, body: runView(existing) };
        if (seeded) return ok({ cycle_id: seeded.cycle_id, line_id: params.id, week: seeded.week, status: seeded.status, outcome: seeded.outcome, outcome_reason: seeded.outcome_reason, failure_reason: null });
        if (!verified(params.id, params.week)) return fail(409, 'week_not_verified', 'No verified scan for this line-week');
        if (runsOf(params.id).some((r) => r.status === 'running')) return fail(409, 'cycle_slot_taken', `A cycle is already running for ${params.id}`);
        const cycle_id = `c-${params.id}-${params.week.slice(6)}`;
        const run = { cycle_id, line_id: params.id, week: params.week, status: 'running', outcome: null, outcome_reason: null, failure_reason: null, startedAt: now(), attempts: 1, plan: PLANS[params.id] ?? DEFAULT_PLAN };
        store.data.runs[cycle_id] = run;
        return { status: 202, body: runView(run) };
      }),
    },
    {
      method: 'GET', path: `${BASE}/cycles/:id`,
      handle: authed(({ params }) => {
        if (store.data.runs[params.id]) return ok(runView(settle(store.data.runs[params.id])));
        const found = findCycle(params.id);
        if (!found) return fail(404, 'unknown_cycle', `No cycle ${params.id}`);
        const c = found.cycle;
        return ok({ cycle_id: c.cycle_id, line_id: found.lineId, week: c.week, status: c.status, outcome: c.outcome, outcome_reason: c.outcome_reason, failure_reason: null });
      }),
    },
    {
      method: 'POST', path: `${BASE}/cycles/:id/retry`,
      handle: authed(({ params }) => {
        const run = store.data.runs[params.id];
        if (!run) return findCycle(params.id) ? fail(409, 'cycle_not_failed', 'Only a failed cycle can be retried') : fail(404, 'unknown_cycle', `No cycle ${params.id}`);
        if (settle(run).status !== 'failed') return fail(409, 'cycle_not_failed', 'Only a failed cycle can be retried');
        if (runsOf(run.line_id).some((r) => r.status === 'running')) return fail(409, 'cycle_slot_taken', `A cycle is already running for ${run.line_id}`);
        Object.assign(run, { status: 'running', failure_reason: null, startedAt: now(), attempts: run.attempts + 1 });
        return { status: 202, body: runView(run) };
      }),
    },
    ...proposalRoutes(store, { settleAll }),
  ];
}
