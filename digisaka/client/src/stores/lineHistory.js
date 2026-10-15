import { defineStore } from 'pinia';
import { api } from '../api.js';
import { messageFor } from '../helpers/messages.js';
import { isValidWeek } from '../helpers/week.js';

// The last three weekly values of the chosen line, shown while picking a line to scan.
// phase: idle, loading, ready, error.
export const useLineHistoryStore = defineStore('lineHistory', {
  state: () => ({ phase: 'idle', lineId: '', week: '', weeks: [], error: '', run: 0 }),
  actions: {
    async load(lineId, week) {
      this.run++; const run = this.run;
      if (!lineId || !isValidWeek(week)) { Object.assign(this, { phase: 'idle', lineId: '', week: '', weeks: [], error: '' }); return; }
      Object.assign(this, { phase: 'loading', lineId, week, weeks: [], error: '' });
      try {
        const r = await api.get(`/api/v1/scheduler/lines/${encodeURIComponent(lineId)}/weeks/${encodeURIComponent(week)}/history`);
        if (run === this.run) Object.assign(this, { phase: 'ready', weeks: r.weeks ?? [] });
      } catch (err) {
        if (run === this.run) Object.assign(this, { phase: 'error', error: messageFor(err) });
      }
    },
  },
});
