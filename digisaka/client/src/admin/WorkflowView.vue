<script setup>
import { computed, onMounted, onBeforeUnmount, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useWorkflowRunStore } from '../stores/workflowRun.js';
import { useWorkflowsStore } from '../stores/workflows.js';
import { useAuthStore } from '../stores/auth.js';
import Pill from './Pill.vue';
import { fmtDateTime } from './util.js';
import { stateLabel, stateTone } from './workflowState.js';

const route = useRoute(), router = useRouter(), store = useWorkflowRunStore();
const list = useWorkflowsStore(), auth = useAuthStore();
const id = computed(() => String(route.params.id));
const wf = computed(() => store.workflow);
onMounted(() => { list.load(auth.email); store.follow(id.value); });
watch(() => wf.value?.state, (state) => { if (state) list.setState(id.value, state); });
watch(id, () => store.follow(id.value));
onBeforeUnmount(() => store.stop());

// The path of a maintenance workflow, in order. The state the workflow is in is the current step.
const PATH = ['document_submitted', 'extracting', 'restoring_verifying', 'awaiting_extraction_review', 'canonicalizing', 'validating', 'correcting_revalidating', 'awaiting_final_approval', 'committing', 'completed'];
const at = computed(() => PATH.indexOf(wf.value?.state));
const stepClass = (i) => (at.value < 0 ? '' : i < at.value ? 'past' : i === at.value ? 'now' : '');
const utc = (s) => (s ? fmtDateTime(s.replace('T', ' ').replace(/(\.\d+)?(Z|\+00:00)$/, '')) : '—');
</script>

<template>
  <header class="a-head">
    <h1>Workflow</h1>
    <p><small class="id">{{ id }}</small></p>
  </header>
  <div class="a-toolbar"><button type="button" class="a-btn" @click="router.push('/admin/extractions')">&larr; All workflows</button></div>

  <p v-if="store.phase === 'error'" class="a-note err" role="alert">{{ store.error }}</p>
  <p v-else-if="store.phase === 'loading'" class="a-muted">Loading…</p>

  <div v-if="wf" class="a-card box">
    <div class="state">
      <Pill :tone="stateTone(wf.state)">{{ stateLabel(wf.state) }}</Pill>
      <span v-if="store.phase === 'working'" class="a-muted">Updating every 15 seconds.</span>
      <span v-else-if="store.phase === 'gate'" class="a-muted">It moves on once a reviewer acts.</span>
    </div>

    <p v-if="wf.retrying" class="a-note" role="status">
      Trying again after a problem{{ wf.retrying.stage ? ` in ${wf.retrying.stage}` : '' }}: attempt {{ wf.retrying.attempt }} of {{ wf.retrying.max_attempts }}.
    </p>
    <p v-if="wf.failure" class="a-note err" role="alert">
      {{ wf.failure.message }}
      <small class="a-muted">({{ wf.failure.code }}{{ wf.failure.attempts ? `, ${wf.failure.attempts} attempts` : '' }})</small>
    </p>
    <p v-else-if="store.phase === 'failed'" class="a-note err" role="alert">The workflow failed. Contact an administrator.</p>

    <ol v-if="at >= 0" class="path" aria-label="Progress">
      <li v-for="(s, i) in PATH" :key="s" :class="stepClass(i)" :aria-current="i === at ? 'step' : undefined">{{ stateLabel(s) }}</li>
    </ol>

    <dl class="facts">
      <dt>Created</dt><dd>{{ utc(wf.created_at) }}</dd>
      <dt>Updated</dt><dd>{{ utc(wf.updated_at) }}</dd>
      <dt v-if="wf.completed_at">Finished</dt><dd v-if="wf.completed_at">{{ utc(wf.completed_at) }}</dd>
      <dt>Ontology</dt><dd>{{ wf.ontology_version_pinned ?? '—' }}</dd>
      <dt>Run graph</dt><dd class="id">{{ wf.named_graph_uri }}</dd>
    </dl>

    <div class="a-actions">
      <button type="button" class="a-btn" disabled title="Not available yet: the service has no retry endpoint">Retry</button>
      <button type="button" class="a-btn" disabled title="Not available yet: the service has no cancel endpoint">Cancel workflow</button>
      <small class="a-muted">Retry and cancel are not available yet.</small>
    </div>
  </div>
</template>

<style scoped>
.box { padding: 20px; display: grid; gap: 16px; }
.state { display: flex; align-items: center; gap: 12px; }
.id { font-family: ui-monospace, monospace; overflow-wrap: anywhere; }
.path { display: grid; gap: 6px; margin: 0; padding: 0; list-style: none; }
.path li { padding: 6px 12px; border-radius: 10px; color: var(--ink-soft); background: var(--bg); }
.path li.past { color: var(--forest); background: var(--tint); }
.path li.now { font-weight: 800; color: #fff; background: var(--forest); }
.facts { display: grid; grid-template-columns: max-content 1fr; gap: 6px 16px; margin: 0; }
.facts dt { font-weight: 800; color: var(--forest); } .facts dd { margin: 0; }
</style>
