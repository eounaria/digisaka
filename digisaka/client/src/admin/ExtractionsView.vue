<script setup>
import { ref, watch, computed } from 'vue';
import { useRouter } from 'vue-router';
import { api } from '../api.js';
import { useUseCaseStore } from '../stores/useCase.js';
import Icon from '../components/Icon.vue';
import Modal from './Modal.vue';
import Pill from './Pill.vue';
import SkeletonRows from './SkeletonRows.vue';
import UploadDocModal from './UploadDocModal.vue';
import { qs, useLoader, fmtDate, bytes, confidence, DOC_TONE, STAGE } from './util.js';

const SIZE = 25, STATUSES = ['Queued', 'Needs review', 'Extracted', 'Confirmed'];
const uc = useUseCaseStore(), router = useRouter();
const q = ref(''), status = ref(''), page = ref(0), docs = ref([]), total = ref(0), counts = ref({});
const note = ref(null), uploading = ref(false), viewing = ref(null), editing = ref(null), busyId = ref(0);
const { loading, error, run } = useLoader(() => api.get(`/api/admin/documents?${qs({ useCase: uc.slug, q: q.value.trim(), status: status.value, limit: SIZE, offset: page.value * SIZE })}`));
async function load() { const r = await run(); if (r) { docs.value = r.documents; total.value = r.total; counts.value = r.counts; } }
let t;
watch(q, () => { clearTimeout(t); t = setTimeout(() => { page.value = 0; load(); }, 250); });
watch([status, () => uc.slug], () => { page.value = 0; load(); }, { immediate: true });
watch(page, load);
const from = computed(() => (total.value ? page.value * SIZE + 1 : 0)), to = computed(() => Math.min((page.value + 1) * SIZE, total.value));
const allCount = computed(() => Object.values(counts.value).reduce((a, b) => a + b, 0));

const say = (text, err = false) => { note.value = { text, err }; };
async function guard(fn) { try { await fn(); } catch (e) { say(e.message, true); } }

const onUploaded = (r) => {
  uploading.value = false;
  const x = r.extraction;
  say(!x ? `Uploaded “${r.document.title}”. It is queued for extraction.`
    : !x.found ? `Uploaded “${r.document.title}”, but no relationships were found. Check that the text uses the ontology’s relationship wording.`
    : x.added ? `Uploaded “${r.document.title}” and found ${x.added} new relationship${x.added === 1 ? '' : 's'}${x.found > x.added ? ` (${x.found - x.added} already known)` : ''}.`
    : `Uploaded “${r.document.title}”. All ${x.found} relationships in it were already known.`);
  load();
};
const extract = (d) => guard(async () => {
  busyId.value = d.id;
  const r = await api.post(`/api/admin/documents/${d.id}/extract`);
  say(r.added ? `Added ${r.added} new relationship${r.added === 1 ? '' : 's'} from “${d.title}”.` : r.found ? `Everything in “${d.title}” was already known.` : `No relationships found in “${d.title}”. Check that the text uses the ontology’s relationship wording.`);
  await load();
}).finally(() => { busyId.value = 0; });
const remove = (d) => confirm(`Delete “${d.title}” and its ${d.relationships} relationship${d.relationships === 1 ? '' : 's'}?`) && guard(async () => { await api.del(`/api/admin/documents/${d.id}`); say(`Deleted “${d.title}”.`); await load(); });
const view = (d) => guard(async () => { viewing.value = await api.get(`/api/admin/documents/${d.id}`); });
const saveEdit = () => guard(async () => { const e = editing.value; await api.put(`/api/admin/documents/${e.id}`, { title: e.title, docType: e.docType, source: e.source }); editing.value = null; say('Saved.'); await load(); });
</script>

<template>
  <header class="a-head"><h1>Document Extractions</h1><p>Source documents for {{ uc.current.label }} and the relationships extracted from them.</p></header>

  <div class="a-toolbar">
    <label class="a-search"><Icon name="search" :size="16" /><input v-model="q" type="search" placeholder="Search title, type or source" aria-label="Search documents"></label>
    <button type="button" class="a-btn primary" @click="uploading = true"><Icon name="upload" :size="16" />Upload document</button>
  </div>
  <div class="a-tabs" role="tablist" aria-label="Filter by status">
    <button type="button" role="tab" :aria-selected="status === ''" @click="status = ''">All {{ allCount }}</button>
    <button v-for="s in STATUSES" :key="s" type="button" role="tab" :aria-selected="status === s" @click="status = s">{{ s }} {{ counts[s] ?? 0 }}</button>
  </div>
  <p v-if="error" class="a-note err" role="alert">{{ error }}</p>
  <p v-if="note" class="a-note" :class="{ err: note.err }" role="status">{{ note.text }}</p>

  <div class="a-card">
    <div class="a-scroll">
      <table class="a-table a-sticky">
        <thead><tr><th>Document</th><th>Type / source</th><th>Status</th><th>Entities / links</th><th>Confidence</th><th>Actions</th></tr></thead>
        <tbody>
          <SkeletonRows v-if="loading && !docs.length" :cols="6" />
          <tr v-for="d in docs" :key="d.id">
            <td class="doc"><b>{{ d.title }}</b><br><small class="a-muted">{{ d.fileName ?? 'No file' }} · {{ bytes(d.sizeBytes) }} · {{ fmtDate(d.updatedAt) }}</small></td>
            <td class="nw">{{ d.docType }}<br><small class="a-muted">{{ d.source }}</small></td>
            <td><Pill :tone="DOC_TONE[d.status]">{{ d.status }}</Pill></td>
            <td class="nw">{{ d.entities }} <span class="a-muted">/</span> {{ d.relationships }}</td>
            <td><span class="a-chip">{{ confidence(d.confidence) }}</span></td>
            <td><div class="a-actions nowrap">
              <button type="button" class="a-mini" @click="view(d)">View</button>
              <button type="button" class="a-mini" :disabled="busyId === d.id" @click="extract(d)">{{ d.extractedAt ? 'Re-run' : 'Extract' }}</button>
              <button type="button" class="a-mini" @click="editing = { id: d.id, title: d.title, docType: d.docType, source: d.source }">Edit</button>
              <button type="button" class="a-mini warn" @click="remove(d)">Delete</button>
            </div></td>
          </tr>
        </tbody>
      </table>
      <p v-if="!loading && !docs.length" class="a-empty">{{ q || status ? 'No documents match your filters.' : 'No documents yet. Upload one to start extracting.' }}</p>
    </div>
    <footer class="a-foot">
      <span>{{ total ? `Showing ${from}–${to} of ${total}` : '' }}</span>
      <span class="a-pager"><button type="button" class="a-mini" :disabled="page === 0" @click="page--">Previous</button><button type="button" class="a-mini" :disabled="to >= total" @click="page++">Next</button></span>
    </footer>
  </div>

  <UploadDocModal v-if="uploading" :use-case="uc.slug" @close="uploading = false" @done="onUploaded" />

  <Modal v-if="viewing" :title="viewing.document.title" width="720px" @close="viewing = null">
    <p class="a-muted">{{ viewing.document.docType }} · {{ viewing.document.source }} · {{ bytes(viewing.document.sizeBytes) }}</p>
    <h3>Extracted relationships</h3>
    <ul v-if="viewing.triples.length" class="tr">
      <li v-for="t in viewing.triples" :key="t.id"><span>{{ t.subject }} <em>{{ t.predicate }}</em> {{ t.object }}</span><Pill :tone="STAGE[t.stage][1]">{{ STAGE[t.stage][0] }}</Pill></li>
    </ul>
    <p v-else class="a-muted">{{ viewing.document.extractedAt ? 'Nothing was extracted. The text may not use the ontology’s relationship wording.' : 'Not extracted yet.' }}</p>
    <h3>Text</h3>
    <pre>{{ viewing.document.content.slice(0, 4000) }}{{ viewing.document.content.length > 4000 ? '\n…' : '' }}</pre>
    <template #footer>
      <button type="button" class="a-btn" @click="router.push({ path: '/admin/tracing', query: { doc: viewing.document.id } })">Open trace</button>
      <button type="button" class="a-btn primary" @click="viewing = null">Close</button>
    </template>
  </Modal>

  <Modal v-if="editing" title="Edit metadata" width="440px" @close="editing = null">
    <label class="a-field">Title<input v-model="editing.title" class="a-input" maxlength="120"></label>
    <div class="a-row2">
      <label class="a-field">Type<input v-model="editing.docType" class="a-input" maxlength="40"></label>
      <label class="a-field">Source<input v-model="editing.source" class="a-input" maxlength="60"></label>
    </div>
    <template #footer><button type="button" class="a-btn" @click="editing = null">Cancel</button><button type="button" class="a-btn primary" :disabled="!editing.title.trim()" @click="saveEdit">Save</button></template>
  </Modal>
</template>

<style scoped>
.nowrap { flex-wrap: nowrap; }
.doc { min-width: 180px; max-width: 200px; overflow-wrap: anywhere; }
.nw { white-space: nowrap; }
h3 { margin: 18px 0 8px; font: 800 16px var(--font-display); color: var(--forest); }
.tr li { display: flex; justify-content: space-between; align-items: center; gap: 12px; padding: 8px 0; border-top: 1px solid var(--line); } .tr li:first-child { border-top: 0; } em { font-style: normal; color: var(--teal); font-weight: 800; }
pre { max-height: 220px; overflow: auto; padding: 12px; border-radius: 12px; background: var(--bg); white-space: pre-wrap; overflow-wrap: anywhere; font: 13px/1.5 ui-monospace, monospace; }
</style>
