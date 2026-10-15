// Upload, symptom confirmation and re-scan for one line-week. State is a plain object so a view can pass a reactive one.
import { messageFor } from './client.js';

const OUTCOMES = { treatment_result: 'Treatment result', healthy: 'Healthy', referral: 'Referral', not_leaf: 'Not a leaf' };

export function phaseOf(answer) {
  if (answer.outcome) return 'done';
  if (answer.next_action === 're_scan') return 'rescan';
  if (answer.symptom_checklist?.length) return 'confirm';
  return 'waiting';
}

export function sessionLabel(s) {
  const stage = s.stage ? ` (${s.stage})` : '';
  if (!s.outcome) return `Waiting for confirmation${stage}`;
  return `${OUTCOMES[s.outcome] ?? s.outcome}${stage}`;
}

export function createScanFlow({ client, line, week, state = {} }) {
  Object.assign(state, { phase: 'idle', qaOutputId: null, stage: null, outcome: null, checklist: [], sessions: [], cycle: null, error: '', busy: false });

  function apply(answer) {
    state.qaOutputId = answer.qa_output_id;
    if ('stage' in answer) state.stage = answer.stage;
    state.outcome = answer.outcome ?? null;
    if (answer.symptom_checklist?.length) state.checklist = answer.symptom_checklist;
    state.phase = phaseOf(answer);
  }

  async function run(work) {
    if (state.busy) return;
    state.busy = true; state.error = '';
    try { await work(); }
    catch (e) { state.error = messageFor(e); }
    finally { state.busy = false; }
  }

  async function refresh() {
    try { const lw = await client.getLineWeek(line, week); state.sessions = lw.sessions; state.cycle = lw.cycle ?? null; }
    catch (e) { state.error = messageFor(e); }
  }

  return {
    state,
    refresh,
    upload: (payload) => run(async () => {
      const reuse = state.phase === 'rescan' ? state.qaOutputId : undefined;
      apply(await client.upload(line, week, payload, reuse));
      await refresh();
    }),
    close: () => run(async () => { state.cycle = await client.closeWeek(line, week); }),
    confirm: (confirmed) => run(async () => {
      apply(await client.confirmSymptoms(state.qaOutputId, confirmed));
      await refresh();
    }),
  };
}
