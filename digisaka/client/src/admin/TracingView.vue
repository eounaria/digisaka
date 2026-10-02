<script setup>
import { ref, watch, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { api } from '../api.js';
import { useUseCaseStore } from '../stores/useCase.js';
import Pill from './Pill.vue';
import { qs, useLoader, fmtTime, fmtDateTime, ACTION, DOC_TONE } from './util.js';

const uc = useUseCaseStore(), route = useRoute(), router = useRouter();
const docs = ref([]), trace = ref(null), docId = ref(route.query.doc ? Number(route.query.doc) : null);
const list = useLoader(() => api.get(`/api/admin/documents?${qs({ useCase: uc.slug, limit: 200 })}`));
const one = useLoader((id) => api.get(`/api/admin/documents/${id}/trace`));

async function loadDocs() {
  const r = await list.run();
  if (!r) return;
  docs.value = r.documents;
  if (!docs.value.some((d) => d.id === docId.value)) docId.value = docs.value[0]?.id ?? null;   // a document from another use case no longer applies
  loadTrace();
}
async function loadTrace() {
  if (!docId.value) { trace.value = null; return; }
  const r = await one.run(docId.value);
  if (r) trace.value = r;
}
watch(() => uc.slug, loadDocs, { immediate: true });
watch(docId, (id) => { router.replace({ query: id ? { doc: id } : {} }); loadTrace(); });

const doc = computed(() => trace.value?.document);
const describe = (e) => [e.objectLabel, e.previous && e.newValue ? `${e.previous} → ${e.newValue}` : null, `by ${e.actor}`].filter(Boolean).join(' · ');
const error = computed(() => list.error.value || one.error.value);
</script>

<template>
  <header class="a-head"><h1>Tracing</h1><p>Follow one source document from upload to the knowledge graph.</p></header>
  <p v-if="error" class="a-note err" role="alert">{{ error }}</p>

  <div v-if="docs.length" class="a-toolbar">
    <label class="pick">Document
      <select v-model="docId" class="a-select"><option v-for="d in docs" :key="d.id" :value="d.id">{{ d.title }}</option></select>
    </label>
    <Pill v-if="doc" :tone="DOC_TONE[doc.status]">{{ doc.status }}</Pill>
    <span v-if="doc" class="a-muted">Trace ID TR-{{ String(doc.id).padStart(4, '0') }} · {{ doc.docType }} · {{ doc.source }}</span>
  </div>
  <p v-else-if="!list.loading.value" class="a-card a-empty">No documents yet for {{ uc.current.label }}. Upload one in Document Extractions.</p>

  <div v-if="trace" class="shell">
    <section class="a-card a-pad">
      <h3>Activity</h3>
      <ol v-if="trace.events.length">
        <li v-for="e in trace.events" :key="e.id">
          <time :datetime="e.createdAt" :title="fmtDateTime(e.createdAt)">{{ fmtTime(e.createdAt) }}</time>
          <div><b>{{ ACTION[e.action] ?? e.action }}</b> {{ e.objectType.toLowerCase() }}<small>{{ describe(e) }}</small></div>
        </li>
      </ol>
      <p v-else class="a-muted">No recorded activity for this document yet.</p>
    </section>

    <section class="a-card a-pad">
      <h3>Trace status</h3>
      <ol class="steps">
        <li v-for="(s, i) in trace.lineage" :key="s.title">
          <span class="num" :class="{ pending: s.state === 'pending' }">{{ i + 1 }}</span>
          <div><b>{{ s.title }}</b><small v-if="s.time">{{ fmtDateTime(s.time) }}</small><small>{{ s.detail }}</small>
            <Pill :tone="s.state === 'done' ? 'good' : 'warn'">{{ s.state === 'done' ? 'Completed' : 'Pending' }}</Pill></div>
        </li>
      </ol>
    </section>
  </div>
</template>

<style scoped>
.pick { display: flex; align-items: center; gap: 10px; font-weight: 800; color: var(--ink-soft); } .pick select { min-width: 240px; color: var(--ink); }
.shell { display: grid; grid-template-columns: 1.5fr 1fr; gap: 18px; align-items: start; }
h3 { font: 800 17px var(--font-display); color: var(--forest); margin-bottom: 8px; }
ol { list-style: none; }
li { display: grid; grid-template-columns: 64px 1fr; gap: 12px; padding: 12px 0; border-top: 1px solid var(--line); }
li:first-child { border-top: 0; }
time { font-weight: 800; color: var(--forest); } li div { display: grid; min-width: 0; } small { color: var(--ink-soft); overflow-wrap: anywhere; }
.steps li { grid-template-columns: 34px 1fr; } .steps li div { gap: 2px; justify-items: start; }
.num { display: grid; place-items: center; width: 30px; height: 30px; border-radius: 50%; background: var(--forest); color: #fff; font-weight: 800; }
.num.pending { background: var(--banana); color: #5B4300; }
@media (max-width: 900px) { .shell { grid-template-columns: 1fr; } }
</style>
