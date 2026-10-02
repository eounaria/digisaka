<script setup>
import { ref } from 'vue';
import { api } from '../api.js';
import Modal from './Modal.vue';

const props = defineProps({ useCase: String });
const emit = defineEmits(['close', 'done']);
const TYPES = ['Field notes', 'Survey', 'Report', 'Data table', 'Other'];
const MAX = 1.5 * 1024 * 1024;   // the API accepts 2 MB of JSON
const file = ref(null), title = ref(''), docType = ref(TYPES[0]), source = ref('Upload portal'), extract = ref(true), busy = ref(false), error = ref('');

function pick(e) {
  const f = e.target.files[0];
  error.value = '';
  if (!f) return;
  if (f.size > MAX) { error.value = 'That file is over 1.5 MB. Split it into smaller documents.'; e.target.value = ''; return; }
  file.value = f;
  if (!title.value) title.value = f.name.replace(/\.[^.]+$/, '');
}
async function submit() {
  busy.value = true; error.value = '';
  try {
    const content = await file.value.text();
    emit('done', await api.post('/api/admin/documents', { useCase: props.useCase, title: title.value, docType: docType.value, source: source.value, fileName: file.value.name, content, extract: extract.value }));
  } catch (e) { error.value = e.message; busy.value = false; }
}
</script>

<template>
  <Modal title="Upload document" @close="emit('close')">
    <label class="a-field">Text file
      <input type="file" class="a-input file" accept=".txt,.md,.csv,.json,text/plain,text/csv,application/json" @change="pick">
      <small class="a-muted">Plain text, Markdown, CSV (subject, predicate, object columns) or JSON triples.</small>
    </label>
    <label class="a-field">Title<input v-model="title" class="a-input" maxlength="120"></label>
    <div class="a-row2">
      <label class="a-field">Type<select v-model="docType" class="a-select"><option v-for="t in TYPES" :key="t">{{ t }}</option></select></label>
      <label class="a-field">Source<input v-model="source" class="a-input" maxlength="60"></label>
    </div>
    <label class="check"><input v-model="extract" type="checkbox"> Extract relationships now</label>
    <p v-if="error" class="a-note err" role="alert">{{ error }}</p>
    <template #footer>
      <button type="button" class="a-btn" @click="emit('close')">Cancel</button>
      <button type="button" class="a-btn primary" :disabled="!file || !title.trim() || busy" @click="submit">{{ busy ? 'Uploading…' : 'Upload' }}</button>
    </template>
  </Modal>
</template>

<style scoped>
.file { height: auto; padding: 9px 12px; } .check { display: flex; gap: 10px; align-items: center; font-weight: 800; color: var(--forest); }
</style>
