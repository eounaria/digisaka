// Thin wrapper over the scheduler API (docs/api/FRONTEND_INTEGRATION.md in AI_NeSy_Framework).
const BASE = '/api/v1/scheduler';

export class SchedulerError extends Error {
  constructor(status, code, detail) {
    super(detail || code);
    this.name = 'SchedulerError';
    this.status = status;
    this.code = code;
    this.detail = detail;
  }
}

const MESSAGES = {
  unauthenticated: 'Your session expired. Sign in again.',
  forbidden: 'This account is not a Practitioner.',
  unknown_line: 'That line does not exist.',
  unknown_cycle: 'That cycle does not exist.',
  unknown_proposal: 'There is no proposal for this cycle.',
  unknown_session: 'That scan does not belong to this line-week.',
  week_not_verified: 'Finish at least one scan, including its symptom confirmation, before closing the week.',
  proposal_already_decided: 'This proposal was already decided.',
  proposal_not_approved: 'Approve the proposal before recording its application.',
  application_already_recorded: 'The application was already recorded.',
  cycle_running: 'The cycle is still running.',
  cycle_not_failed: 'Only a failed cycle can be retried.',
  cycle_slot_taken: 'Another cycle is already running for this line.',
  validation_error: 'The request was not accepted. Check the image and values and try again.',
  invalid_week: 'That is not a valid week. Use the form 2026-W24.',
  qa_unavailable: 'The QA service is unavailable. Try again shortly.',
  auth_unavailable: 'Sign-in could not be checked. Try again shortly.',
  network_error: 'Cannot reach the scheduler. Check that it is running.',
};
const GENERIC = 'Something went wrong. Try again.';

export const messageFor = (err) => (err instanceof SchedulerError && MESSAGES[err.code]) || GENERIC;

export function createSchedulerClient({ fetch, getToken, onUnauthorized }) {
  async function request(method, path, body) {
    const token = getToken();
    if (!token) {
      onUnauthorized();
      throw new SchedulerError(401, 'unauthenticated', 'Not signed in');
    }
    const headers = { Authorization: `Bearer ${token}` };
    if (body !== undefined) headers['Content-Type'] = 'application/json';
    let res;
    try {
      res = await fetch(BASE + path, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
    } catch {
      throw new SchedulerError(0, 'network_error', 'Network error');
    }
    const data = await res.json().catch(() => null);
    if (!res.ok) {
      if (res.status === 401) onUnauthorized();
      throw new SchedulerError(res.status, data?.error || `http_${res.status}`, data?.detail || '');
    }
    return data;
  }

  const e = encodeURIComponent;
  const week = (line, wk) => `/lines/${e(line)}/weeks/${e(wk)}`;
  return {
    listLines: () => request('GET', '/lines'),
    getLine: (line) => request('GET', `/lines/${e(line)}`),
    getLineWeek: (line, wk) => request('GET', week(line, wk)),
    upload: (line, wk, { img_name, img }, qaOutputId) =>
      request('POST', `${week(line, wk)}/diagnoses`, { img_name, img, ...(qaOutputId ? { qa_output_id: qaOutputId } : {}) }),
    confirmSymptoms: (qaOutputId, confirmed) => request('POST', `/diagnoses/${e(qaOutputId)}/confirm-symptoms`, { confirmed }),
    closeWeek: (line, wk) => request('POST', `${week(line, wk)}/close`),
    getCycle: (id) => request('GET', `/cycles/${e(id)}`),
    getProposal: (cycleId) => request('GET', `/cycles/${e(cycleId)}/proposal`),
    retryCycle: (id) => request('POST', `/cycles/${e(id)}/retry`),
    decide: (proposalId, decision, note) => request('POST', `/proposals/${e(proposalId)}/decision`, { decision, note }),
    recordApplication: (proposalId, appliedOn) => request('POST', `/proposals/${e(proposalId)}/application`, { applied_on: appliedOn }),
  };
}
