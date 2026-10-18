// Treatment proposals: read one, decide it, record its application. Proposals live in each line's
// `proposals` (summary fields, plus `reason` and `constraints` for the detail view); decisions are kept
// apart so the line status stays the scheduler's summary shape.
import { BASE, fail, ok, authed, nextWeekKey } from './common.js';

export const DEFAULT_REASON = 'The disease is getting worse and rainfall is favourable for it.';
const TREATMENTS = { 'opt-protectant': { id: 'opt-protectant', name: 'Protectant fungicide spray' } };
const DATE = /^\d{4}-\d{2}-\d{2}$/;

const allProposals = (data) => Object.entries(data.lines).flatMap(([lineId, l]) => l.proposals.map((p) => ({ lineId, line: l, proposal: p })));

// proposed, approved, rejected or applied.
const statusOf = (data, line, p) => (line.applications.some((a) => a.proposal_id === p.proposal_id) ? 'applied' : data.decisions[p.proposal_id]?.decision ?? 'proposed');

// A proposal as the line status lists it.
export function summaryOf(data, line, p) {
  const { reason, constraints, ...summary } = p;
  return { ...summary, status: statusOf(data, line, p) };
}

export function proposalRoutes(store, { settleAll }) {
  const find = (id) => { settleAll(); return allProposals(store.data).find((x) => x.proposal.proposal_id === id); };
  const unknown = (id) => fail(404, 'unknown_proposal', `No proposal ${id}`);

  return [
    {
      method: 'GET', path: `${BASE}/cycles/:id/proposal`,
      handle: authed(({ params }) => {
        settleAll();
        const hit = allProposals(store.data).find((x) => x.proposal.cycle_id === params.id);
        if (!hit) return unknown(params.id);
        const { proposal: p } = hit;
        const decision = store.data.decisions[p.proposal_id];
        return ok({
          proposal_id: p.proposal_id,
          treatment: TREATMENTS[p.option_id],
          window: { start: p.window_start, end: p.window_end },
          reason: p.reason ?? DEFAULT_REASON,
          constraints: p.constraints ?? [],
          next_assessment: nextWeekKey(p.week),
          ...(decision ? { decision } : {}),
        });
      }),
    },
    {
      method: 'POST', path: `${BASE}/proposals/:id/decision`,
      handle: authed(({ params, body }) => {
        const hit = find(params.id);
        if (!hit) return unknown(params.id);
        if (!['approved', 'rejected'].includes(body?.decision)) return fail(400, 'validation_error', 'decision must be approved or rejected');
        if (store.data.decisions[params.id]) return fail(409, 'proposal_already_decided', 'This proposal was already decided');
        const note = typeof body.note === 'string' && body.note.trim() ? body.note.trim() : undefined;
        const decision = { decision: body.decision, ...(note ? { note } : {}) };
        store.data.decisions[params.id] = decision;
        return ok({ proposal_id: params.id, ...decision });
      }),
    },
    {
      method: 'POST', path: `${BASE}/proposals/:id/application`,
      handle: authed(({ params, body }) => {
        const hit = find(params.id);
        if (!hit) return unknown(params.id);
        if (!DATE.test(body?.applied_on ?? '')) return fail(400, 'validation_error', 'applied_on must be YYYY-MM-DD');
        if (hit.line.applications.some((a) => a.proposal_id === params.id)) return fail(409, 'application_already_recorded', 'The application was already recorded');
        if (store.data.decisions[params.id]?.decision !== 'approved') return fail(409, 'proposal_not_approved', 'Approve the proposal before recording its application');
        const application = { proposal_id: params.id, applied_on: body.applied_on };
        hit.line.applications.push(application);
        return { status: 201, body: application };
      }),
    },
  ];
}
