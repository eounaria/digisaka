import { defineStore } from 'pinia';
import { api } from '../api.js';
import { messageFor } from '../helpers/messages.js';

export const useFarmStore = defineStore('farm', {
  state: () => ({ stats: { leavesScanned: 0, bulksAssessed: 0, leavesNeedingTreatment: 0 }, recent: [], loading: false, lines: [], linesError: '' }),
  actions: {
    async loadLines() {
      this.linesError = '';
      try { this.lines = (await api.get('/api/v1/scheduler/lines')).lines ?? []; }
      catch (e) { this.linesError = messageFor(e); }
    },
    async refresh() {
      this.loading = true;
      try {
        const [stats, bulks] = await Promise.all([api.get('/api/dashboard'), api.get('/api/bulks?limit=3')]);
        this.stats = stats; this.recent = bulks.bulks;
      } finally { this.loading = false; }
    },
  },
});
