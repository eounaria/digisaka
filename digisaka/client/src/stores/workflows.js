import { defineStore } from 'pinia';
import { api } from '../api.js';

const base = '/api/v1/knowledge-maintenance/workflows';
const KEY = (owner) => `digisaka.km.workflows.${owner}`;

// The API cannot list workflows, so each user's submitted workflows are remembered in this browser.
const disk = {
  read: (owner) => { try { return JSON.parse(globalThis.localStorage.getItem(KEY(owner))) ?? []; } catch { return []; } },
  write: (owner, items) => { try { globalThis.localStorage.setItem(KEY(owner), JSON.stringify(items)); } catch { /* the in-memory list still works */ } },
};

const row = (w, title) => ({ id: w.workflow_id, title: title || `Workflow ${w.workflow_id.slice(0, 8)}`, state: w.state, createdAt: w.created_at });

// The Technical User's Knowledge Maintenance workflows. error is the API's own message.
export const useWorkflowsStore = defineStore('workflows', {
  state: () => ({ owner: '', items: [], busy: false, error: '' }),
  actions: {
    load(owner) { Object.assign(this, { owner, items: disk.read(owner), error: '' }); },
    _add(r) {
      this.items = [r, ...this.items.filter((i) => i.id !== r.id)];
      disk.write(this.owner, this.items);
    },
    async _run(work) {
      if (this.busy) return null;
      this.busy = true; this.error = '';
      try { return await work(); }
      catch (err) { this.error = err.message; return null; }
      finally { this.busy = false; }
    },
    submitText(title, content) {
      return this._run(async () => {
        const w = row(await api.post(base, { document: { title, content } }), title);
        this._add(w); return w;
      });
    },
    submitFile(file, title) {
      return this._run(async () => {
        const form = new FormData();
        if (title) form.set('title', title);
        form.set('file', file);
        const w = row(await api.postForm(base, form), title);
        this._add(w); return w;
      });
    },
    open(id) {
      return this._run(async () => {
        const clean = String(id).trim();
        const known = this.items.find((i) => i.id === clean);
        const w = row(await api.get(`${base}/${encodeURIComponent(clean)}`), known?.title);
        this._add(w); return w;
      });
    },
    // Keep the list in step with what the status screen has seen.
    setState(id, state) {
      const i = this.items.find((x) => x.id === id);
      if (!i || i.state === state) return;
      this.items = this.items.map((x) => (x.id === id ? { ...x, state } : x));
      disk.write(this.owner, this.items);
    },
    forget(id) { this.items = this.items.filter((i) => i.id !== id); disk.write(this.owner, this.items); },
  },
});
