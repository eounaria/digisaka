import { defineStore } from 'pinia';
import { api } from '../api.js';
import { fileToPayload } from '../helpers/image.js';
import { isoWeekOf, isValidWeek } from '../helpers/week.js';
import { messageFor } from '../helpers/messages.js';

export const MAX_LEAVES = 8;
const OUTCOMES = { treatment_result: 'Treatment result', healthy: 'Healthy', referral: 'Referral', not_leaf: 'Not a leaf' };

// What the user does next for one QA answer.
export function phaseOf(answer) {
  if (answer.outcome) return 'done';
  if (answer.next_action === 're_scan') return 'rescan';
  if (answer.symptom_checklist?.length) return 'confirm';
  return 'waiting';
}
export const outcomeLabel = (o) => OUTCOMES[o] ?? o;

const path = (line, week) => `/api/v1/scheduler/lines/${encodeURIComponent(line)}/weeks/${encodeURIComponent(week)}`;
let nextId = 1;

export const useScanStore = defineStore('scan', {
  state: () => ({ line: '', week: isoWeekOf(new Date()), leaves: [], notice: '', assessing: false, log: [] }),
  getters: {
    weekOk: (s) => isValidWeek(s.week),
    canAssess: (s) => isValidWeek(s.week) && !!s.line && !s.assessing && s.leaves.some((l) => l.phase === 'queued' || l.phase === 'failed'),
  },
  actions: {
    // Changing the line or week starts a fresh set: sessions belong to one line-week.
    select(line, week) {
      if (line === this.line && week === this.week) return;
      this.line = line; this.week = week; this.leaves = []; this.notice = ''; this.log = [];
    },
    addFiles(files) {
      this.notice = '';
      for (const file of files) {
        if (this.leaves.length >= MAX_LEAVES) { this.notice = `You can scan up to ${MAX_LEAVES} leaves at a time.`; break; }
        this.leaves.push({ id: nextId++, file, phase: 'queued', qaOutputId: null, stage: null, outcome: null, checklist: [], error: '' });
      }
    },
    remove(id) { if (!this.assessing) this.leaves = this.leaves.filter((l) => l.id !== id); },
    clear() { if (!this.assessing) this.leaves = []; },
    note(text, kind = '') { this.log.push({ text, kind }); },
    label(leaf) { return `Leaf ${String(this.leaves.indexOf(leaf) + 1).padStart(2, '0')}/${String(this.leaves.length).padStart(2, '0')}`; },
    _apply(leaf, answer) {
      leaf.qaOutputId = answer.qa_output_id;
      if ('stage' in answer) leaf.stage = answer.stage;
      leaf.outcome = answer.outcome ?? null;
      if (answer.symptom_checklist?.length) leaf.checklist = answer.symptom_checklist;
      leaf.phase = phaseOf(answer);
      const tag = this.label(leaf);
      if (leaf.phase === 'done') this.note(`${leaf.outcome === 'referral' || leaf.outcome === 'not_leaf' ? '✗' : '✓'} ${tag} — ${outcomeLabel(leaf.outcome)}${leaf.stage ? ` (${leaf.stage})` : ''}`, leaf.outcome === 'healthy' || leaf.outcome === 'treatment_result' ? 'ok' : 'bad');
      else if (leaf.phase === 'confirm') this.note(`→ ${tag} — suspected ${leaf.stage ?? 'stage'}, waiting for your confirmation`, 'step');
      else if (leaf.phase === 'rescan') this.note(`✗ ${tag} — symptoms not matched, retake the photo`, 'bad');
    },
    async _send(leaf, file, reuse) {
      leaf.error = ''; leaf.phase = 'uploading';
      this.note(`🤖 Agent → ${this.label(leaf)} — Black Sigatoka validation`, 'agent');
      try {
        const { img_name, img } = await fileToPayload(file);
        const body = { img_name, img, ...(reuse ? { qa_output_id: reuse } : {}) };
        this._apply(leaf, await api.post(`${path(this.line, this.week)}/diagnoses`, body));
      } catch (e) {
        leaf.phase = reuse ? 'rescan' : 'failed';
        leaf.error = messageFor(e);
        this.note(`✗ ${this.label(leaf)} — ${leaf.error}`, 'bad');
      }
    },
    // One leaf at a time: each upload waits for CV inference.
    async assess() {
      if (!this.canAssess) {
        if (!this.weekOk) this.notice = messageFor({ code: 'invalid_week' });
        return;
      }
      this.assessing = true; this.notice = ''; this.log = [];
      try {
        for (const leaf of this.leaves.filter((l) => l.phase === 'queued' || l.phase === 'failed')) await this._send(leaf, leaf.file);
      } finally { this.assessing = false; }
    },
    async confirm(id, confirmed) {
      const leaf = this.leaves.find((l) => l.id === id);
      if (!leaf || leaf.phase !== 'confirm') return;
      leaf.error = ''; leaf.phase = 'uploading';
      try {
        this._apply(leaf, await api.post(`/api/v1/scheduler/diagnoses/${encodeURIComponent(leaf.qaOutputId)}/confirm-symptoms`, { confirmed }));
      } catch (e) { leaf.phase = 'confirm'; leaf.error = messageFor(e); }
    },
    // A new image for a leaf whose confirmation was denied: same session.
    async rescan(id, file) {
      const leaf = this.leaves.find((l) => l.id === id);
      if (!leaf || leaf.phase !== 'rescan') return;
      leaf.file = file;
      await this._send(leaf, file, leaf.qaOutputId);
    },
  },
});
