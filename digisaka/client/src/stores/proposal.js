import { defineStore } from 'pinia';
import { api } from '../api.js';
import { messageFor } from '../helpers/messages.js';

const base = '/api/v1/scheduler';
const e = encodeURIComponent;
const DATE = /^\d{4}-\d{2}-\d{2}$/;

// One line-week's proposal for the treatment detail screen.
// phase: idle, loading, ready, notfound, error. status: proposed, approved, rejected, applied.
export const useProposalStore = defineStore('proposal', {
  state: () => ({ phase: 'idle', lineId: '', week: '', proposal: null, cycle: null, appliedOn: null, error: '', busy: false, run: 0 }),
  getters: {
    status: (s) => (s.appliedOn ? 'applied' : s.proposal?.decision?.decision ?? 'proposed'),
    humanReview: (s) => s.cycle?.outcome === 'human_review_required',
  },
  actions: {
    async load(lineId, week) {
      this.run++; const run = this.run;
      Object.assign(this, { phase: 'loading', lineId, week, proposal: null, cycle: null, appliedOn: null, error: '', busy: false });
      try {
        const line = await api.get(`${base}/lines/${e(lineId)}`);
        const lp = (line.proposals ?? []).filter((p) => p.week === week).pop();
        if (!lp) { if (run === this.run) this.phase = 'notfound'; return; }
        const [proposal, cycle] = await Promise.all([
          api.get(`${base}/cycles/${e(lp.cycle_id)}/proposal`),
          api.get(`${base}/cycles/${e(lp.cycle_id)}`),
        ]);
        if (run !== this.run) return;
        const done = (line.applications ?? []).find((a) => a.proposal_id === proposal.proposal_id);
        Object.assign(this, { proposal, cycle, appliedOn: done?.applied_on ?? null, phase: 'ready' });
      } catch (err) {
        if (run !== this.run) return;
        Object.assign(this, err.code === 'unknown_line' || err.code === 'unknown_proposal' ? { phase: 'notfound' } : { phase: 'error', error: messageFor(err) });
      }
    },
    // Show the real state again after another tab got there first.
    async _reload() { try { await this.load(this.lineId, this.week); } catch { /* keep the message */ } },
    async _act(work) {
      if (this.busy) return;
      this.busy = true; this.error = ''; const run = this.run;
      try { await work(); }
      catch (err) {
        const msg = messageFor(err);
        if (err.code === 'proposal_already_decided' || err.code === 'application_already_recorded') {
          await this._reload();
          this.error = msg;
        } else if (run === this.run) this.error = msg;
      } finally { if (run === this.run) this.busy = false; }
    },
    decide(decision, note) {
      return this._act(async () => {
        const body = { decision, ...(note?.trim() ? { note: note.trim() } : {}) };
        await api.post(`${base}/proposals/${e(this.proposal.proposal_id)}/decision`, body);
        const [proposal, cycle] = await Promise.all([
          api.get(`${base}/cycles/${e(this.cycle.cycle_id)}/proposal`),
          api.get(`${base}/cycles/${e(this.cycle.cycle_id)}`),
        ]);
        Object.assign(this, { proposal, cycle });
      });
    },
    apply(appliedOn) {
      return this._act(async () => {
        if (!DATE.test(appliedOn ?? '')) { this.error = 'Enter the date as YYYY-MM-DD.'; return; }
        const r = await api.post(`${base}/proposals/${e(this.proposal.proposal_id)}/application`, { applied_on: appliedOn });
        this.appliedOn = r?.applied_on ?? appliedOn;
      });
    },
  },
});
