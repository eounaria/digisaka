<script setup>
import { ref, watch, computed } from 'vue';
import { api } from '../api.js';
import { useUseCaseStore } from '../stores/useCase.js';
import GraphCanvas from './GraphCanvas.vue';
import Modal from './Modal.vue';
import { qs, useLoader } from './util.js';

const uc = useUseCaseStore();
const onto = ref({ classes: [], relations: [] }), status = ref(null);
const { loading, error, run } = useLoader(() => api.get(`/api/admin/ontology?${qs({ useCase: uc.slug })}`));
async function load() { const r = await run(); if (r) onto.value = r; }
watch(() => uc.slug, load, { immediate: true });

const nodes = computed(() => onto.value.classes.map((c) => ({ id: c.id, label: c.name, color: c.color })));
const edges = computed(() => onto.value.relations.map((r) => ({ from: r.fromId, to: r.toId, label: r.label })));

const edit = ref(null);   // { id?, name, color, description }
const rel = ref({ fromId: '', label: '', toId: '' });
const flash = (text, err = false) => { status.value = { text, err }; };
async function attempt(fn, done) {
  try { await fn(); status.value = null; if (done) flash(done); await load(); return true; }
  catch (e) { flash(e.message, true); return false; }
}
const saveClass = async () => {
  const c = edit.value, body = { useCase: uc.slug, name: c.name, color: c.color, description: c.description };
  if (await attempt(() => (c.id ? api.put(`/api/admin/ontology/classes/${c.id}`, body) : api.post('/api/admin/ontology/classes', body)))) edit.value = null;
};
const delClass = (c) => confirm(`Delete the class "${c.name}" and its links?`) && attempt(() => api.del(`/api/admin/ontology/classes/${c.id}`));
const addRel = async () => {
  if (await attempt(() => api.post('/api/admin/ontology/relations', { useCase: uc.slug, ...rel.value }))) rel.value = { fromId: '', label: '', toId: '' };
};
const delRel = (r) => attempt(() => api.del(`/api/admin/ontology/relations/${r.id}`));
</script>

<template>
  <header class="a-head"><h1>Ontologies</h1><p>The classes and relationship types that extraction uses for {{ uc.current.label }}.</p></header>
  <p v-if="error" class="a-note err" role="alert">{{ error }}</p>
  <p v-if="status" class="a-note" :class="{ err: status.err }" role="status">{{ status.text }}</p>

  <div class="layout">
    <div>
      <GraphCanvas v-if="onto.classes.length" :nodes="nodes" :edges="edges" label-edges :label="`${uc.current.label} ontology`" />
      <p v-else-if="!loading" class="a-card a-empty">No classes yet. Add one to start building the ontology.</p>
    </div>

    <aside>
      <section class="a-card a-pad">
        <div class="top"><h3>Classes <small>{{ onto.classes.length }}</small></h3><button type="button" class="a-mini solid" @click="edit = { name: '', color: '#3948d1', description: '' }">Add class</button></div>
        <ul>
          <li v-for="c in onto.classes" :key="c.id">
            <i class="dot" :style="{ background: c.color }"></i>
            <div><b>{{ c.name }}</b><small>{{ c.usage }} relationship{{ c.usage === 1 ? '' : 's' }}<template v-if="c.description"> · {{ c.description }}</template></small></div>
            <button type="button" class="a-mini" @click="edit = { ...c }">Edit</button>
            <button type="button" class="a-mini warn" :aria-label="`Delete ${c.name}`" @click="delClass(c)">Delete</button>
          </li>
        </ul>
      </section>

      <section class="a-card a-pad">
        <h3>Relationship types <small>{{ onto.relations.length }}</small></h3>
        <ul>
          <li v-for="r in onto.relations" :key="r.id">
            <div><b>{{ r.fromName }} <em>{{ r.label }}</em> {{ r.toName }}</b></div>
            <button type="button" class="a-mini warn" :aria-label="`Delete ${r.fromName} ${r.label} ${r.toName}`" @click="delRel(r)">Delete</button>
          </li>
        </ul>
        <div v-if="onto.classes.length > 1" class="add">
          <select v-model="rel.fromId" class="a-select" aria-label="From class"><option value="" disabled>From…</option><option v-for="c in onto.classes" :key="c.id" :value="c.id">{{ c.name }}</option></select>
          <input v-model="rel.label" class="a-input" placeholder="relationship" maxlength="40" aria-label="Relationship name">
          <select v-model="rel.toId" class="a-select" aria-label="To class"><option value="" disabled>To…</option><option v-for="c in onto.classes" :key="c.id" :value="c.id">{{ c.name }}</option></select>
          <button type="button" class="a-btn primary" :disabled="!rel.fromId || !rel.toId || !rel.label.trim()" @click="addRel">Add relationship type</button>
        </div>
      </section>
    </aside>
  </div>

  <Modal v-if="edit" :title="edit.id ? 'Edit class' : 'Add class'" width="440px" @close="edit = null">
    <label class="a-field">Name<input v-model="edit.name" class="a-input" maxlength="40" required></label>
    <label class="a-field">Colour<input v-model="edit.color" type="color" class="a-input color"></label>
    <label class="a-field">Description<textarea v-model="edit.description" class="a-textarea" maxlength="200"></textarea></label>
    <p v-if="status?.err" class="a-note err" role="alert">{{ status.text }}</p>
    <template #footer><button type="button" class="a-btn" @click="edit = null">Cancel</button><button type="button" class="a-btn primary" :disabled="!edit.name.trim()" @click="saveClass">Save</button></template>
  </Modal>
</template>

<style scoped>
.layout { display: grid; grid-template-columns: 1fr 380px; gap: 18px; align-items: start; }
aside { display: grid; gap: 16px; }
.top { display: flex; justify-content: space-between; align-items: center; }
h3 { font: 800 17px var(--font-display); color: var(--forest); } h3 small { margin-left: 6px; color: var(--ink-soft); font-size: 14px; }
ul { margin-top: 10px; }
li { display: flex; align-items: center; gap: 10px; padding: 9px 0; border-top: 1px solid var(--line); }
li:first-child { border-top: 0; } li div { flex: 1; min-width: 0; display: grid; } li small { color: var(--ink-soft); } em { font-style: normal; color: var(--teal); }
.dot { width: 14px; height: 14px; border-radius: 50%; flex: none; }
.add { display: grid; gap: 8px; margin-top: 14px; padding-top: 14px; border-top: 1px solid var(--line); }
.color { padding: 4px; width: 80px; }
@media (max-width: 1100px) { .layout { grid-template-columns: 1fr; } }
</style>
