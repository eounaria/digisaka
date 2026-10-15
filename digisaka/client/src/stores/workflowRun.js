import { defineStore } from 'pinia';
import { api } from '../api.js';

export const POLL_MS = 15000; // the API suggests 15 to 30 seconds while a GPU phase runs
export const GATES = ['awaiting_extraction_review', 'awaiting_final_approval'];
export const TERMINAL = ['completed', 'cancelled'];
const FAILED = ['failed', 'commit_failed'];
const base = '/api/v1/knowledge-maintenance/workflows';

// Waits, and while the tab is hidden keeps waiting until it is shown again.
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function patientWait(ms) {
  await sleep(ms);
  const d = globalThis.document;
  while (d?.hidden) await new Promise((r) => d.addEventListener('visibilitychange', r, { once: true }));
}

// Follows one Knowledge Maintenance workflow. phase: idle, loading, working, gate, done, failed, error.
export const useWorkflowRunStore = defineStore('workflowRun', {
  state: () => ({ phase: 'idle', workflow: null, error: '', run: 0, approving: false, approveError: '' }),
  actions: {
    stop() { this.run++; },
    // One look after a review: stay put while facts are waiting, follow the workflow once it moves on.
    async recheck(id, wait = patientWait) {
      const run = this.run;
      let w;
      try { w = await api.get(`${base}/${encodeURIComponent(id)}`); } catch { return; }
      if (run !== this.run) return;
      if (w.state === this.workflow?.state) { this.workflow = w; return; }
      await this.follow(id, wait);
    },
    // Final approval, or the retry of a failed commit (the same call). The API's refusal is shown as it is.
    async approve(id, wait = patientWait) {
      if (this.approving) return false;
      this.approving = true; this.approveError = '';
      try { await api.post(`${base}/${encodeURIComponent(id)}/approve`); }
      catch (err) { this.approveError = err.message; return false; }
      finally { this.approving = false; }
      await this.follow(id, wait);
      return true;
    },
    async follow(id, wait = patientWait) {
      this.run++; const run = this.run;
      Object.assign(this, { phase: 'loading', workflow: null, error: '' });
      let failures = 0;
      for (;;) {
        try { this.workflow = await api.get(`${base}/${encodeURIComponent(id)}`); failures = 0; }
        catch (err) {
          if (run !== this.run) return;
          // Tolerate a blip mid-poll; an unknown workflow or three misses in a row is final.
          if (err.status === 404 || ++failures >= 3) { Object.assign(this, { phase: 'error', error: err.message }); return; }
          await wait(POLL_MS); if (run !== this.run) return; continue;
        }
        if (run !== this.run) return;
        const state = this.workflow.state;
        if (GATES.includes(state)) { this.phase = 'gate'; return; }
        if (TERMINAL.includes(state)) { this.phase = 'done'; return; }
        if (FAILED.includes(state)) { this.phase = 'failed'; return; }
        this.phase = 'working';
        await wait(POLL_MS);
        if (run !== this.run) return;
      }
    },
  },
});
