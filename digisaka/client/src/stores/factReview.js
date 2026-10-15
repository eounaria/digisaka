import { defineStore } from 'pinia';
import { api } from '../api.js';

export const PAGE = 25;
const root = (w) => `/api/v1/knowledge-maintenance/workflows/${encodeURIComponent(w)}`;

// The facts of one Knowledge Maintenance workflow at a review gate. Messages are the API's own.
export const useFactReviewStore = defineStore('factReview', {
  state: () => ({ workflowId: '', disposition: '', offset: 0, facts: [], total: 0, loading: false, busy: false, error: '', notice: '', run: 0 }),
  actions: {
    async load(workflowId, { disposition = this.disposition, offset = 0 } = {}) {
      this.run++; const run = this.run;
      Object.assign(this, { workflowId, disposition, offset, loading: true, error: '' });
      const q = new URLSearchParams(disposition ? { disposition } : {});
      q.set('limit', PAGE); q.set('offset', offset);
      try {
        const r = await api.get(`${root(workflowId)}/facts?${q}`);
        if (run === this.run) Object.assign(this, { facts: r.facts, total: r.total });
      } catch (err) { if (run === this.run) Object.assign(this, { facts: [], total: 0, error: err.message }); }
      finally { if (run === this.run) this.loading = false; }
    },
    goTo(offset) { return this.load(this.workflowId, { disposition: this.disposition, offset }); },
    reload() { return this.goTo(this.offset); },
    _patch(id, fields) { this.facts = this.facts.map((f) => (f.id === id ? { ...f, ...fields } : f)); },
    async _act(work) {
      if (this.busy) return false;
      this.busy = true; this.error = ''; this.notice = '';
      try { await work(); return true; }
      catch (err) { this.error = err.message; return false; }
      finally { this.busy = false; }
    },
    // decision is "accept" or "reject"; stage is the gate the workflow is at.
    async review(factId, decision, stage) {
      const fact = this.facts.find((f) => f.id === factId);
      const ok = await this._act(async () => {
        const r = await api.post(`${root(this.workflowId)}/facts/${encodeURIComponent(factId)}/review`, { lock_version: fact.lock_version, review_stage: stage, decision });
        this._patch(factId, { disposition: r.disposition, lock_version: r.lock_version, requires_action: false, claimed_by: null, claimed_at: null, claim_expires_at: null });
      });
      // A stale version means someone else got there first: show the real state again.
      if (!ok && this.error) { const msg = this.error; await this.reload(); this.error = msg; }
      return ok;
    },
    claim(factId) {
      return this._act(async () => {
        const r = await api.post(`${root(this.workflowId)}/facts/${encodeURIComponent(factId)}/claim`);
        this._patch(factId, { claimed_by: r.claimed_by, claimed_at: r.claimed_at, claim_expires_at: r.claim_expires_at });
        if (r.previous_holder) this.notice = 'You took over a colleague’s claim on this fact.';
      });
    },
    release(factId) {
      return this._act(async () => {
        const r = await api.post(`${root(this.workflowId)}/facts/${encodeURIComponent(factId)}/release`);
        this._patch(factId, { claimed_by: r.claimed_by, claimed_at: r.claimed_at, claim_expires_at: r.claim_expires_at });
      });
    },
  },
});
