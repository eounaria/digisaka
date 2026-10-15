import { defineStore } from 'pinia';
import { api } from '../api.js';
import { messageFor } from '../helpers/messages.js';

// What the rules looked at for one cycle, for the evidence charts.
// phase: idle, loading, ready, none (the cycle has no trend stage), error.
export const useEvidenceStore = defineStore('evidence', {
  state: () => ({ phase: 'idle', evidence: null, error: '', run: 0 }),
  actions: {
    reset() { this.run++; Object.assign(this, { phase: 'idle', evidence: null, error: '' }); },
    async load(cycleId) {
      this.run++; const run = this.run;
      Object.assign(this, { phase: 'loading', evidence: null, error: '' });
      try {
        const evidence = await api.get(`/api/v1/scheduler/cycles/${encodeURIComponent(cycleId)}/evidence`);
        if (run === this.run) Object.assign(this, { phase: 'ready', evidence });
      } catch (err) {
        if (run !== this.run) return;
        Object.assign(this, err.code === 'unknown_evidence' ? { phase: 'none' } : { phase: 'error', error: messageFor(err) });
      }
    },
  },
});
