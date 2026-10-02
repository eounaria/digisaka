import { defineStore } from 'pinia';
import { api } from '../api.js';

export const useFarmStore = defineStore('farm', {
  state: () => ({ stats: { leavesScanned: 0, bulksAssessed: 0, leavesNeedingTreatment: 0 }, recent: [], loading: false }),
  actions: {
    async refresh() {
      this.loading = true;
      try {
        const [stats, bulks] = await Promise.all([api.get('/api/dashboard'), api.get('/api/bulks?limit=3')]);
        this.stats = stats; this.recent = bulks.bulks;
      } finally { this.loading = false; }
    },
  },
});
