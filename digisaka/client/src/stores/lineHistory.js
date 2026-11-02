import { defineStore } from 'pinia';
import { api } from '../api.js';
import { messageFor } from '../helpers/messages.js';
import { isValidWeek } from '../helpers/week.js';

// The last three weekly values of the chosen line, shown while picking a line to scan.
// phase: idle, loading, ready, error.
export const useLineHistoryStore = defineStore('lineHistory', {
  state: () => ({
    phase: 'idle', lineId: '', week: '', weeks: [], error: '',
    lineStatus: null, statusError: '', evidence: null, evidenceError: '',
    appliedProposal: null, treatment: null, treatmentError: '', run: 0,
  }),
  actions: {
    async load(lineId, week) {
      this.run++; const run = this.run;
      if (!lineId || !isValidWeek(week)) {
        Object.assign(this, {
          phase: 'idle', lineId: '', week: '', weeks: [], error: '',
          lineStatus: null, statusError: '', evidence: null, evidenceError: '',
          appliedProposal: null, treatment: null, treatmentError: '',
        });
        return;
      }
      Object.assign(this, {
        phase: 'loading', lineId, week, weeks: [], error: '',
        lineStatus: null, statusError: '', evidence: null, evidenceError: '',
        appliedProposal: null, treatment: null, treatmentError: '',
      });

      const base = '/api/v1/scheduler';
      const e = encodeURIComponent;
      const [history, status] = await Promise.allSettled([
        api.get(`${base}/lines/${e(lineId)}/weeks/${e(week)}/history`),
        api.get(`${base}/lines/${e(lineId)}`),
      ]);
      if (run !== this.run) return;

      if (history.status === 'fulfilled') Object.assign(this, { phase: 'ready', weeks: history.value.weeks ?? [] });
      else Object.assign(this, { phase: 'error', error: messageFor(history.reason) });

      if (status.status === 'rejected') {
        this.statusError = messageFor(status.reason);
        return;
      }

      this.lineStatus = status.value;
      const cycle = status.value.latest_cycle;
      const latestCycle = cycle?.cycle_id && cycle.week <= week ? cycle : null;
      const applications = new Map((status.value.applications ?? []).map((a) => [a.proposal_id, a.applied_on]));
      const appliedProposal = (status.value.proposals ?? [])
        .filter((p) => p.status === 'applied' && p.week <= week)
        .sort((a, b) => b.week.localeCompare(a.week))[0] ?? null;
      this.appliedProposal = appliedProposal
        ? { ...appliedProposal, appliedOn: applications.get(appliedProposal.proposal_id) ?? null }
        : null;

      const requests = [];
      if (latestCycle && latestCycle.status !== 'running') {
        requests.push({
          kind: 'evidence',
          promise: api.get(`${base}/cycles/${e(latestCycle.cycle_id)}/evidence`),
        });
      }
      if (appliedProposal?.cycle_id) {
        requests.push({
          kind: 'treatment',
          promise: api.get(`${base}/cycles/${e(appliedProposal.cycle_id)}/proposal`),
        });
      }
      const details = await Promise.allSettled(requests.map(({ promise }) => promise));
      if (run !== this.run) return;

      details.forEach((result, index) => {
        const { kind } = requests[index];
        if (result.status === 'fulfilled') {
          if (kind === 'evidence') this.evidence = result.value;
          else this.treatment = result.value.treatment ?? null;
          return;
        }
        if (kind === 'evidence' && result.reason.code === 'unknown_evidence') return;
        if (kind === 'evidence') this.evidenceError = messageFor(result.reason);
        else this.treatmentError = messageFor(result.reason);
      });
    },
  },
});
