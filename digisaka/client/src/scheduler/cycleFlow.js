// Polls a cycle, then drives the proposal decision and the application record.
import { messageFor } from './client.js';

export const POLL_MS = 2000;
export const POLL_LIMIT = 90; // about three minutes; a cycle normally takes ~25 s
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const DATE = /^\d{4}-\d{2}-\d{2}$/;

export function createCycleFlow({ client, cycleId, state = {}, wait = sleep }) {
  Object.assign(state, { phase: 'loading', cycle: null, proposal: null, appliedOn: null, error: '', busy: false });
  let id = cycleId, stopped = false;

  const phaseOfProposal = (p) => ({ approved: 'approved', rejected: 'rejected' }[p.decision?.decision] ?? 'proposal');

  async function loadProposal() {
    try { state.proposal = await client.getProposal(id); }
    catch (e) {
      if (e.code === 'unknown_proposal') { state.proposal = null; state.phase = 'review'; return; }
      throw e;
    }
    state.phase = phaseOfProposal(state.proposal);
    if (state.phase === 'approved') {
      try {
        const line = await client.getLine(state.cycle.line_id);
        const done = (line.applications ?? []).find((a) => a.proposal_id === state.proposal.proposal_id);
        if (done) { state.appliedOn = done.applied_on; state.phase = 'applied'; }
      } catch { /* the application record is optional detail: stay on 'approved' */ }
    }
  }

  async function poll() {
    state.error = '';
    try {
      let failures = 0;
      for (let i = 0; i < POLL_LIMIT; i++) {
        if (stopped) return;
        try { state.cycle = await client.getCycle(id); failures = 0; }
        catch (e) {
          // Tolerate a blip mid-poll; give up after three in a row.
          if (e.code === 'unknown_cycle' || ++failures >= 3) throw e;
          await wait(POLL_MS);
          continue;
        }
        if (stopped) return;
        if (state.cycle.status === 'failed') { state.phase = 'failed'; return; }
        if (state.cycle.status !== 'running') {
          if (state.cycle.outcome === 'human_review_required') { state.proposal = null; state.phase = 'review'; return; }
          await loadProposal();
          return;
        }
        state.phase = 'running';
        if (i === POLL_LIMIT - 1) break;
        await wait(POLL_MS);
      }
      if (!stopped) state.phase = 'timeout';
    } catch (e) { state.error = messageFor(e); state.phase = 'error'; }
  }

  async function act(work) {
    if (state.busy) return;
    state.busy = true; state.error = '';
    try { await work(); }
    catch (e) {
      state.error = messageFor(e);
      // Another tab got there first: show the real state instead of leaving dead buttons.
      if (e.code === 'proposal_already_decided' || e.code === 'application_already_recorded') {
        try { await loadProposal(); } catch { /* keep the message */ }
      }
    }
    finally { state.busy = false; }
  }

  return {
    state,
    start: () => { stopped = false; return poll(); },
    stop: () => { stopped = true; },
    retry: async () => {
      let started = false;
      await act(async () => { id = (await client.retryCycle(id)).cycle_id; started = true; });
      if (started && !stopped) await poll(); // stop() during the request must not restart polling
    },
    decide: (decision, note) => act(async () => {
      await client.decide(state.proposal.proposal_id, decision, note);
      await loadProposal();
    }),
    apply: (appliedOn) => act(async () => {
      if (!DATE.test(appliedOn ?? '')) { state.error = 'Enter the date as YYYY-MM-DD.'; return; }
      const r = await client.recordApplication(state.proposal.proposal_id, appliedOn);
      state.appliedOn = r.applied_on ?? appliedOn;
      state.phase = 'applied';
    }),
  };
}
