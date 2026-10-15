import { defineStore } from 'pinia';
import { api } from '../api.js';
import { messageFor } from '../helpers/messages.js';

export const POLL_MS = 2000;
export const POLL_LIMIT = 90; // about three minutes; a cycle normally takes ~25 s
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const base = '/api/v1/scheduler';
const e = encodeURIComponent;

const PHASE_OF_OUTCOME = { human_review_required: 'review', continue_monitoring: 'monitoring' };

// Closes a line-week and follows its cycle. phase: idle, closing, running, proposal, monitoring, review, failed, timeout, error.
export const useCycleStore = defineStore('cycle', {
  state: () => ({ phase: 'idle', cycle: null, error: '', busy: false, run: 0 }),
  actions: {
    reset() { this.run++; Object.assign(this, { phase: 'idle', cycle: null, error: '', busy: false }); },
    stop() { this.run++; },
    async close(line, week, wait = sleep) {
      if (this.busy) return;
      this.run++; const run = this.run;
      Object.assign(this, { busy: true, error: '', phase: 'closing', cycle: null });
      try {
        this.cycle = await api.post(`${base}/lines/${e(line)}/weeks/${e(week)}/close`);
        this.busy = false;
        await this._poll(run, wait);
      } catch (err) {
        if (run === this.run) Object.assign(this, { phase: 'idle', error: messageFor(err) });
      } finally { if (run === this.run) this.busy = false; }
    },
    async retry(wait = sleep) {
      if (this.busy || !this.cycle) return;
      const id = this.cycle.cycle_id; this.run++; const run = this.run;
      Object.assign(this, { busy: true, error: '' });
      try {
        this.cycle = await api.post(`${base}/cycles/${e(id)}/retry`);
        this.busy = false;
        await this._poll(run, wait);
      } catch (err) {
        if (run === this.run) Object.assign(this, { phase: 'failed', error: messageFor(err) });
      } finally { if (run === this.run) this.busy = false; }
    },
    // Check again after a timeout or error.
    resume(wait = sleep) { this.run++; return this._poll(this.run, wait); },
    async _poll(run, wait) {
      const id = this.cycle.cycle_id;
      let failures = 0;
      try {
        for (let i = 0; i < POLL_LIMIT; i++) {
          if (run !== this.run) return;
          try { this.cycle = await api.get(`${base}/cycles/${e(id)}`); failures = 0; }
          catch (err) {
            // Tolerate a blip mid-poll; give up after three in a row.
            if (err.code === 'unknown_cycle' || ++failures >= 3) throw err;
            await wait(POLL_MS); continue;
          }
          if (run !== this.run) return;
          const c = this.cycle;
          if (c.status === 'failed') { this.phase = 'failed'; return; }
          if (c.status !== 'running') { this.phase = PHASE_OF_OUTCOME[c.outcome] ?? 'proposal'; return; }
          this.phase = 'running';
          if (i === POLL_LIMIT - 1) break;
          await wait(POLL_MS);
        }
        if (run === this.run) this.phase = 'timeout';
      } catch (err) { if (run === this.run) Object.assign(this, { phase: 'error', error: messageFor(err) }); }
    },
  },
});
