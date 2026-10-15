<script setup>
import { ref, onMounted } from 'vue';
import { useAuthStore } from '../stores/auth.js';
import { useWorkflowsStore } from '../stores/workflows.js';
import Icon from '../components/Icon.vue';
import Pill from './Pill.vue';
import SubmitDocModal from './SubmitDocModal.vue';
import { fmtDateTime } from './util.js';
import { stateLabel, stateTone } from './workflowState.js';

const auth = useAuthStore(), store = useWorkflowsStore();
const submitting = ref(false), openId = ref(''), note = ref('');
onMounted(() => store.load(auth.email));

const onSubmitted = (w) => { submitting.value = false; note.value = `Submitted “${w.title}”. Its workflow id is ${w.id}.`; };
async function openById() {
  if (!openId.value.trim()) return;
  note.value = '';
  if (await store.open(openId.value)) openId.value = '';
}
</script>

<template>
  <header class="a-head"><h1>Document Extractions</h1><p>Submit a source document to the Knowledge Maintenance workflow and follow it to the knowledge graph.</p></header>

  <div class="a-toolbar">
    <form class="open" @submit.prevent="openById">
      <label class="a-search"><Icon name="search" :size="16" /><input v-model="openId" type="search" placeholder="Open a workflow by id" aria-label="Workflow id"></label>
      <button type="submit" class="a-btn" :disabled="!openId.trim() || store.busy">Open</button>
    </form>
    <button type="button" class="a-btn primary" @click="submitting = true"><Icon name="upload" :size="16" />Submit document</button>
  </div>
  <p v-if="store.error && !submitting" class="a-note err" role="alert">{{ store.error }}</p>
  <p v-if="note" class="a-note" role="status">{{ note }}</p>

  <div class="a-card">
    <div class="a-scroll">
      <table class="a-table a-sticky">
        <thead><tr><th>Document</th><th>Workflow id</th><th>State</th><th>Created</th><th>Actions</th></tr></thead>
        <tbody>
          <tr v-for="w in store.items" :key="w.id">
            <td class="doc"><b>{{ w.title }}</b></td>
            <td><small class="a-muted id">{{ w.id }}</small></td>
            <td><Pill :tone="stateTone(w.state)">{{ stateLabel(w.state) }}</Pill></td>
            <td class="nw">{{ fmtDateTime(w.createdAt.replace('T', ' ').replace(/(\.\d+)?Z$/, '')) }}</td>
            <td><div class="a-actions nowrap"><button type="button" class="a-mini warn" @click="store.forget(w.id)">Forget</button></div></td>
          </tr>
        </tbody>
      </table>
      <p v-if="!store.items.length" class="a-empty">No workflows from this browser yet. Submit a document, or open one by its id.</p>
    </div>
  </div>

  <SubmitDocModal v-if="submitting" @close="submitting = false" @done="onSubmitted" />
</template>

<style scoped>
.nowrap { flex-wrap: nowrap; }
.nw { white-space: nowrap; }
.doc { min-width: 180px; overflow-wrap: anywhere; }
.id { font-family: ui-monospace, monospace; }
.open { display: flex; gap: 8px; align-items: center; }
</style>
