import { defineStore } from 'pinia';
import { api } from '../api.js';
import { messageFor } from '../helpers/messages.js';

const base = '/api/v1/scheduler';

// Each line's status (latest cycle, proposals, recorded applications) from the scheduler.
export const useLinesStore = defineStore('lines', {
  state: () => ({ statuses: [], loading: false, error: '', loaded: false }),
  getters: {
    withProposals: (s) => s.statuses.filter((l) => l.proposals?.length),
  },
  actions: {
    async load() {
      this.loading = true; this.error = '';
      try {
        const ids = (await api.get(`${base}/lines`)).lines ?? [];
        // One line failing to load must not hide the others.
        const results = await Promise.allSettled(ids.map((id) => api.get(`${base}/lines/${encodeURIComponent(id)}`)));
        this.statuses = results.map((r, i) => (r.status === 'fulfilled'
          ? r.value
          : { line_id: ids[i], proposals: [], applications: [], latest_cycle: null, human_review_required: false, error: messageFor(r.reason) }));
      } catch (e) { this.error = messageFor(e); this.statuses = []; }
      finally { this.loading = false; this.loaded = true; }
    },
    byId(id) { return this.statuses.find((l) => l.line_id === id); },
  },
});

// Proposals newest week first, each with the date it was applied, if recorded.
export function proposalRows(line) {
  const applied = new Map((line.applications ?? []).map((a) => [a.proposal_id, a.applied_on]));
  return [...(line.proposals ?? [])]
    .sort((a, b) => b.week.localeCompare(a.week))
    .map((p) => ({ ...p, appliedOn: applied.get(p.proposal_id) ?? null }));
}
