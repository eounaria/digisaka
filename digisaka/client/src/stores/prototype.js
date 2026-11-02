import { defineStore } from 'pinia';
import { api } from '../api.js';
import { messageFor } from '../helpers/messages.js';
import { samplesEnabled } from '../helpers/stubSamples.js';

const base = '/api/v1/scheduler/prototype/lines';

export const usePrototypeStore = defineStore('prototype', {
  state: () => ({
    enabled: samplesEnabled(),
    phase: 'idle',
    lineId: '',
    week: '',
    data: null,
    confirmedOptionIds: [],
    error: '',
    busy: false,
    run: 0,
  }),
  actions: {
    async load(lineId, week) {
      if (!this.enabled) return;
      if (this.lineId === lineId && this.week === week && ['loading', 'ready'].includes(this.phase)) return;
      this.run++;
      const run = this.run;
      Object.assign(this, { phase: 'loading', lineId, week, data: null, confirmedOptionIds: [], error: '' });
      try {
        const data = await api.get(`${base}/${encodeURIComponent(lineId)}/weeks/${encodeURIComponent(week)}`);
        if (run === this.run) Object.assign(this, { phase: 'ready', data });
      } catch (err) {
        if (run === this.run) Object.assign(this, { phase: 'error', error: messageFor(err) });
      }
    },
    async select(optionId) {
      if (!this.enabled || !this.data) {
        this.error = 'Prototype product selection is unavailable.';
        return false;
      }
      if (this.busy) return false;
      this.busy = true;
      this.error = '';
      const run = this.run;
      try {
        const selected = await api.post(
          `${base}/${encodeURIComponent(this.lineId)}/weeks/${encodeURIComponent(this.week)}/selection`,
          { option_id: optionId },
        );
        if (run === this.run) {
          this.data.selected_option_id = selected.selected_option_id;
          this.data.sample = selected.sample;
        }
        return true;
      } catch (err) {
        if (run === this.run) this.error = messageFor(err);
        return false;
      } finally {
        if (run === this.run) this.busy = false;
      }
    },
    confirmSample(optionId) {
      if (!this.enabled || !this.data?.products.some((product) => product.id === optionId)) {
        this.error = 'That sample product is not available in the prototype catalog.';
        return false;
      }
      if (!Array.isArray(this.confirmedOptionIds)) this.confirmedOptionIds = [];
      if (!this.confirmedOptionIds.includes(optionId)) {
        this.confirmedOptionIds = [...this.confirmedOptionIds, optionId];
      }
      this.error = '';
      return true;
    },
    removeSample(optionId) {
      this.confirmedOptionIds = (this.confirmedOptionIds ?? []).filter((id) => id !== optionId);
    },
    reset() {
      this.run++;
      Object.assign(this, { phase: 'idle', lineId: '', week: '', data: null, confirmedOptionIds: [], error: '', busy: false });
    },
  },
});
