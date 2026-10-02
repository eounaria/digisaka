<script setup>
import { ref, watch, computed } from 'vue';
import { api } from '../api.js';
import { useUseCaseStore } from '../stores/useCase.js';
import Icon from '../components/Icon.vue';
import Modal from './Modal.vue';
import Pill from './Pill.vue';
import SkeletonRows from './SkeletonRows.vue';
import GraphCanvas from './GraphCanvas.vue';
import UploadDocModal from './UploadDocModal.vue';
import { qs, useLoader, fmtDate, confidence, STAGE } from './util.js';

const SIZE = 25;
const TABS = [['extracted', 'Extraction'], ['corrected', 'Correction'], ['confirmed', 'Confirmation'], ['graph', 'Temporary Graph'], ['rejected', 'Rejected']];
const uc = useUseCaseStore();
const tab = ref('extracted'), q = ref(''), page = ref(0);
const rows = ref([]), total = ref(0), counts = ref({}), graph = ref(null), onto = ref({ classes: [], relations: [] });
const note = ref(null), uploading = ref(false), edit = ref(null), busy = ref(false);

const list = useLoader(() => api.get(`/api/admin/triples?${qs({ useCase: uc.slug, stage: tab.value, q: q.value.trim(), limit: SIZE, offset: page.value * SIZE })}`));
const pend = useLoader(() => api.get(`/api/admin/graph?${qs({ useCase: uc.slug, scope: 'pending' })}`));
async function load() {
  if (tab.value === 'graph') {
    const [g, c] = await Promise.all([pend.run(), api.get(`/api/admin/triples?${qs({ useCase: uc.slug, limit: 1 })}`).catch(() => null)]);
    if (g) graph.value = g;
    if (c) counts.value = c.counts;
    return;
  }
  const r = await list.run();
  if (r) { rows.value = r.triples; total.value = r.total; counts.value = r.counts; }
}
async function loadOntology() { try { onto.value = await api.get(`/api/admin/ontology?${qs({ useCase: uc.slug })}`); } catch { /* the edit form still works without suggestions */ } }
let t;
watch(q, () => { clearTimeout(t); t = setTimeout(() => { page.value = 0; load(); }, 250); });
watch(tab, () => { page.value = 0; note.value = null; load(); });
watch(() => uc.slug, () => { page.value = 0; load(); loadOntology(); }, { immediate: true });
watch(page, load);

const from = computed(() => (total.value ? page.value * SIZE + 1 : 0)), to = computed(() => Math.min((page.value + 1) * SIZE, total.value));
const error = computed(() => list.error.value || pend.error.value);
const pending = computed(() => (counts.value.extracted ?? 0) + (counts.value.corrected ?? 0));
const SUMMARY = computed(() => [['queued', 'Queued'], ['extracted', 'Extracted'], ['corrected', 'Corrected'], ['confirmed', 'Confirmed'], ['pendingTrace', 'Pending trace']].map(([k, l]) => [counts.value[k] ?? 0, l]));
const say = (text, err = false) => { note.value = { text, err }; };
async function guard(fn) { busy.value = true; try { await fn(); } catch (e) { say(e.message, true); } finally { busy.value = false; } }

const act = (r, action) => guard(async () => { await api.post(`/api/admin/triples/${r.id}/${action}`); note.value = null; await load(); });
const confirmAll = () => confirm(`Confirm all ${pending.value} pending relationships into the knowledge graph?`) && guard(async () => {
  const r = await api.post('/api/admin/triples/confirm-pending', { useCase: uc.slug });
  say(`Confirmed ${r.confirmed} relationship${r.confirmed === 1 ? '' : 's'}.`); await load();
});
const save = () => guard(async () => {
  const e = edit.value, body = { useCase: uc.slug, subject: e.subject, predicate: e.predicate, object: e.object, subjectClass: e.subjectClass || null, objectClass: e.objectClass || null };
  await (e.id ? api.put(`/api/admin/triples/${e.id}`, body) : api.post('/api/admin/triples', body));
  edit.value = null; say(e.id ? 'Correction saved.' : 'Relationship added.'); if (!e.id) tab.value = 'corrected'; else await load();
});
const onUploaded = (r) => {
  uploading.value = false; tab.value = 'extracted';
  say(extractionNote(r)); load();
};
function extractionNote(r) {
  const x = r.extraction, n = (k) => `${k} relationship${k === 1 ? '' : 's'}`;
  if (!x) return `Uploaded “${r.document.title}”.`;
  if (!x.found) return `Uploaded “${r.document.title}”, but no relationships were found. Check that the text uses the ontology’s relationship wording.`;
  return x.added ? `Found ${n(x.added)} in “${r.document.title}”${x.found > x.added ? ` (${x.found - x.added} already known)` : ''}.` : `All ${n(x.found)} in “${r.document.title}” were already known.`;
}
const blank = () => ({ subject: '', predicate: '', object: '', subjectClass: '', objectClass: '' });
const label = (r) => (r.stage === 'extracted' && r.confidence < 0.8 ? ['Needs correction', 'warn'] : STAGE[r.stage]);
</script>

<template>
  <header class="a-head"><h1>KG Processing</h1><p>Review what was extracted, correct it, and confirm it into the knowledge graph for {{ uc.current.label }}.</p></header>

  <div class="a-stats">
    <div v-for="[n, l] in SUMMARY" :key="l" class="a-stat"><b>{{ n }}</b><span>{{ l }}</span></div>
  </div>

  <div class="a-tabs" role="tablist" aria-label="Pipeline stage">
    <button v-for="[k, l] in TABS" :key="k" type="button" role="tab" :aria-selected="tab === k" @click="tab = k">{{ l }}</button>
  </div>
  <div class="a-toolbar">
    <label v-if="tab !== 'graph'" class="a-search"><Icon name="search" :size="16" /><input v-model="q" type="search" placeholder="Search subject, relationship or object" aria-label="Search relationships"></label>
    <span v-else class="a-grow"></span>
    <button type="button" class="a-btn" @click="edit = blank()">Add relationship</button>
    <button type="button" class="a-btn primary" @click="uploading = true"><Icon name="upload" :size="16" />Upload</button>
  </div>
  <p v-if="error" class="a-note err" role="alert">{{ error }}</p>
  <p v-if="note" class="a-note" :class="{ err: note.err }" role="status">{{ note.text }}</p>

  <section v-if="tab === 'graph'">
    <div class="gbar">
      <span class="a-muted">Relationships that are extracted or corrected but not yet confirmed.</span>
      <button type="button" class="a-btn primary" :disabled="!pending || busy" @click="confirmAll">Confirm all ({{ pending }})</button>
    </div>
    <GraphCanvas v-if="graph?.edges.length" :nodes="graph.nodes" :edges="graph.edges" :label="`${uc.current.label} temporary graph`" />
    <p v-else-if="!pend.loading.value" class="a-card a-empty">Nothing is waiting for confirmation.</p>
    <p v-if="graph?.truncated" class="a-muted">Showing the 150 most recent relationships.</p>
  </section>

  <template v-else>
    <div class="a-card">
      <div class="a-scroll">
        <table class="a-table a-sticky">
          <thead><tr><th>Status</th><th>Source</th><th>Extracted relationship</th><th>Confidence</th><th>Reviewer</th><th>Date</th><th>Action</th></tr></thead>
          <tbody>
            <SkeletonRows v-if="list.loading.value && !rows.length" :cols="7" />
            <tr v-for="r in rows" :key="r.id">
              <td><Pill :tone="label(r)[1]">{{ label(r)[0] }}</Pill></td>
              <td>{{ r.documentTitle ?? 'Manual entry' }}</td>
              <td class="rel"><b>{{ r.subject }}</b> <em>{{ r.predicate }}</em> <b>{{ r.object }}</b>
                <small v-if="r.subjectClass || r.objectClass">{{ r.subjectClass ?? '?' }} → {{ r.objectClass ?? '?' }}</small></td>
              <td><span class="a-chip">{{ confidence(r.confidence) }}</span></td>
              <td>{{ r.reviewer ?? 'Auto ingestion' }}</td>
              <td class="nw">{{ fmtDate(r.updatedAt) }}</td>
              <td><div class="a-actions nowrap">
                <template v-if="r.stage === 'extracted' || r.stage === 'corrected'">
                  <button type="button" class="a-mini" :disabled="busy" @click="edit = { ...r }">Edit</button>
                  <button type="button" class="a-mini solid" :disabled="busy" @click="act(r, 'confirm')">Confirm</button>
                  <button type="button" class="a-mini warn" :disabled="busy" @click="act(r, 'reject')">Reject</button>
                </template>
                <button v-else-if="r.stage === 'confirmed'" type="button" class="a-mini" :disabled="busy" @click="act(r, 'unconfirm')">Un-confirm</button>
                <button v-else type="button" class="a-mini" :disabled="busy" @click="act(r, 'restore')">Restore</button>
              </div></td>
            </tr>
          </tbody>
        </table>
        <p v-if="!list.loading.value && !rows.length" class="a-empty">{{ q ? 'No relationships match your search.' : 'Nothing here yet.' }}</p>
      </div>
      <footer class="a-foot">
        <span>{{ total ? `Showing ${from}–${to} of ${total}` : '' }}</span>
        <span class="a-pager"><button type="button" class="a-mini" :disabled="page === 0" @click="page--">Previous</button><button type="button" class="a-mini" :disabled="to >= total" @click="page++">Next</button></span>
      </footer>
    </div>
  </template>

  <UploadDocModal v-if="uploading" :use-case="uc.slug" @close="uploading = false" @done="onUploaded" />

  <Modal v-if="edit" :title="edit.id ? 'Correct relationship' : 'Add relationship'" @close="edit = null">
    <label class="a-field">Subject<input v-model="edit.subject" class="a-input" maxlength="80"></label>
    <label class="a-field">Relationship<input v-model="edit.predicate" class="a-input" maxlength="40" list="rel-labels"></label>
    <datalist id="rel-labels"><option v-for="r in onto.relations" :key="r.id" :value="r.label"></option></datalist>
    <label class="a-field">Object<input v-model="edit.object" class="a-input" maxlength="80"></label>
    <div class="a-row2">
      <label class="a-field">Subject class<select v-model="edit.subjectClass" class="a-select"><option value="">Match from relationship</option><option v-for="c in onto.classes" :key="c.id">{{ c.name }}</option></select></label>
      <label class="a-field">Object class<select v-model="edit.objectClass" class="a-select"><option value="">Match from relationship</option><option v-for="c in onto.classes" :key="c.id">{{ c.name }}</option></select></label>
    </div>
    <p v-if="edit.id" class="a-muted">Saving marks this relationship as corrected.</p>
    <template #footer>
      <button type="button" class="a-btn" @click="edit = null">Cancel</button>
      <button type="button" class="a-btn primary" :disabled="busy || !edit.subject.trim() || !edit.predicate.trim() || !edit.object.trim()" @click="save">Save</button>
    </template>
  </Modal>
</template>

<style scoped>
.nowrap { flex-wrap: nowrap; }
.rel { min-width: 170px; } .rel em { font-style: normal; color: var(--teal); font-weight: 800; } .rel small { display: block; color: var(--ink-soft); }
.nw { white-space: nowrap; }
.gbar { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; margin-bottom: 12px; }
</style>
