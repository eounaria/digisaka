<script setup>
import { ref, watch, computed } from 'vue';
import { api } from '../api.js';
import { useUseCaseStore } from '../stores/useCase.js';
import Icon from '../components/Icon.vue';
import Modal from './Modal.vue';
import Pill from './Pill.vue';
import { qs, useLoader, bytes } from './util.js';

const SIZE = 24;
const uc = useUseCaseStore();
const folders = ref([]), totals = ref({ total: 0, unfiled: 0 });
const sel = ref('all');                       // 'all' | 'unfiled' | folder id
const q = ref(''), status = ref(''), sort = ref('newest'), page = ref(0);
const images = ref([]), total = ref(0), metrics = ref({ images: 0, labeled: 0, validationPct: 0 });
const note = ref(null), folderModal = ref(null), detail = ref(null), progress = ref(''), picker = ref(null);

const fl = useLoader(() => api.get(`/api/admin/datasets/folders?${qs({ useCase: uc.slug })}`));
const il = useLoader(() => api.get(`/api/admin/datasets/images?${qs({ useCase: uc.slug, folderId: sel.value === 'all' ? '' : sel.value, q: q.value.trim(), status: status.value, sort: sort.value, limit: SIZE, offset: page.value * SIZE })}`));
async function loadFolders() { const r = await fl.run(); if (r) { folders.value = r.folders; totals.value = r; } }
async function loadImages() { const r = await il.run(); if (r) { images.value = r.images; total.value = r.total; metrics.value = r.metrics; } }
const reload = () => Promise.all([loadFolders(), loadImages()]);

// Folders flattened depth-first, each with the image count of everything beneath it.
const tree = computed(() => {
  const kids = new Map();
  for (const f of folders.value) (kids.get(f.parentId) ?? kids.set(f.parentId, []).get(f.parentId)).push(f);
  const sum = (f) => f.count + (kids.get(f.id) ?? []).reduce((a, c) => a + sum(c), 0);
  const out = [];
  const walk = (parent, depth) => { for (const f of kids.get(parent) ?? []) { out.push({ ...f, depth, rolled: sum(f) }); walk(f.id, depth + 1); } };
  walk(null, 0);
  return out;
});
const current = computed(() => (typeof sel.value === 'number' ? tree.value.find((f) => f.id === sel.value) : null));
const heading = computed(() => (sel.value === 'all' ? uc.current.label : sel.value === 'unfiled' ? `${uc.current.label} / Unfiled` : current.value ? `${uc.current.label} / ${current.value.name}` : uc.current.label));
const indent = (f) => '\u00A0\u00A0\u00A0'.repeat(f.depth);

let t;
watch(q, () => { clearTimeout(t); t = setTimeout(() => { page.value = 0; loadImages(); }, 250); });
watch([sel, status, sort], () => { page.value = 0; loadImages(); });
watch(page, loadImages);
watch(() => uc.slug, () => { sel.value = 'all'; page.value = 0; reload(); }, { immediate: true });
const from = computed(() => (total.value ? page.value * SIZE + 1 : 0)), to = computed(() => Math.min((page.value + 1) * SIZE, total.value));
const error = computed(() => fl.error.value || il.error.value);

const say = (text, err = false) => { note.value = { text, err }; };
async function guard(fn) { try { await fn(); return true; } catch (e) { say(e.message, true); return false; } }
const url = (id) => `/api/admin/datasets/images/${id}/file`;

async function upload(e) {
  const files = [...e.target.files]; e.target.value = '';
  if (!files.length) return;
  let ok = 0; const failed = [];
  for (const [i, f] of files.entries()) {
    progress.value = `Uploading ${i + 1} of ${files.length}…`;
    try { await api.upload(`/api/admin/datasets/images?${qs({ useCase: uc.slug, folderId: typeof sel.value === 'number' ? sel.value : '', name: f.name })}`, f); ok++; }
    catch (err) { failed.push(`${f.name}: ${err.message}`); }
  }
  progress.value = '';
  say(`Uploaded ${ok} image${ok === 1 ? '' : 's'}${failed.length ? `. ${failed.length} failed — ${failed.slice(0, 2).join('; ')}` : '.'}`, !!failed.length && !ok);
  await reload();
}

const createFolder = async () => {
  const m = folderModal.value;
  const done = await guard(() => (m.id ? api.put(`/api/admin/datasets/folders/${m.id}`, { name: m.name }) : api.post('/api/admin/datasets/folders', { useCase: uc.slug, name: m.name, parentId: m.parentId })));
  if (done) { folderModal.value = null; note.value = null; await reload(); }
};
const deleteFolder = () => confirm(`Delete the folder “${current.value.name}”?`) && guard(async () => { await api.del(`/api/admin/datasets/folders/${current.value.id}`); sel.value = 'all'; note.value = null; await reload(); });

const open = (im) => { detail.value = { ...im, folderId: im.folderId ?? '' }; note.value = null; };
const saveImage = async () => {
  const d = detail.value;
  const done = await guard(() => api.put(`/api/admin/datasets/images/${d.id}`, { name: d.name, label: d.label ?? '', status: d.status, folderId: d.folderId === '' ? null : d.folderId }));
  if (done) { detail.value = null; await reload(); }
};
const removeImage = () => confirm(`Delete “${detail.value.name}”? This cannot be undone.`) && guard(async () => { await api.del(`/api/admin/datasets/images/${detail.value.id}`); detail.value = null; await reload(); });
</script>

<template>
  <header class="a-head"><h1>Datasets &amp; Images</h1><p>Training images for {{ uc.current.label }}, organised in folders.</p></header>
  <p v-if="error" class="a-note err" role="alert">{{ error }}</p>

  <div class="layout">
    <nav class="a-card tree" aria-label="Folders">
      <h2>Folders</h2>
      <button type="button" class="node" :class="{ on: sel === 'all' }" @click="sel = 'all'"><span>All images</span><span class="n">{{ totals.total }}</span></button>
      <button type="button" class="node" :class="{ on: sel === 'unfiled' }" @click="sel = 'unfiled'"><span>Unfiled</span><span class="n">{{ totals.unfiled }}</span></button>
      <button v-for="f in tree" :key="f.id" type="button" class="node" :class="{ on: sel === f.id }" :style="{ paddingLeft: 14 + f.depth * 16 + 'px' }" @click="sel = f.id">
        <span><Icon name="folder" :size="15" /> {{ f.name }}</span><span class="n">{{ f.rolled }}</span>
      </button>
    </nav>

    <section class="a-card main">
      <div class="top">
        <h3>{{ heading }}</h3>
        <div class="a-actions">
          <template v-if="current">
            <button type="button" class="a-btn" @click="folderModal = { id: current.id, name: current.name }">Rename</button>
            <button type="button" class="a-btn danger" @click="deleteFolder">Delete folder</button>
          </template>
          <button type="button" class="a-btn" @click="folderModal = { name: '', parentId: current?.id ?? null }">Create folder</button>
          <button type="button" class="a-btn primary" :disabled="!!progress" @click="picker.click()"><Icon name="upload" :size="16" />{{ progress || 'Upload' }}</button>
          <input ref="picker" type="file" accept="image/png,image/jpeg,image/webp,image/gif" multiple hidden @change="upload">
        </div>
      </div>
      <p v-if="note" class="a-note" :class="{ err: note.err }" role="status">{{ note.text }}</p>

      <div class="a-toolbar">
        <label class="a-search"><Icon name="search" :size="16" /><input v-model="q" type="search" placeholder="Search images or labels" aria-label="Search images"></label>
        <select v-model="status" class="a-select" aria-label="Filter by status"><option value="">All statuses</option><option>Validated</option><option>Needs review</option></select>
        <select v-model="sort" class="a-select" aria-label="Sort"><option value="newest">Newest first</option><option value="oldest">Oldest first</option><option value="name">Name</option></select>
      </div>

      <div class="a-stats">
        <div class="a-stat"><b>{{ metrics.images }}</b><span>Images</span></div>
        <div class="a-stat"><b>{{ metrics.labeled }}</b><span>Labeled</span></div>
        <div class="a-stat"><b>{{ metrics.validationPct }}%</b><span>Validated</span></div>
        <div class="a-stat"><b>{{ folders.length }}</b><span>Folders</span></div>
      </div>

      <div v-if="images.length" class="grid">
        <article v-for="im in images" :key="im.id" class="asset">
          <button type="button" class="thumb" :aria-label="`Open ${im.name}`" @click="open(im)"><img :src="url(im.id)" :alt="im.name" loading="lazy"></button>
          <b class="nm" :title="im.name">{{ im.name }}</b>
          <small>{{ im.label ?? 'No label' }} · <Pill :tone="im.status === 'Validated' ? 'good' : 'warn'">{{ im.status }}</Pill></small>
        </article>
      </div>
      <div v-else-if="il.loading.value" class="grid" aria-hidden="true"><div v-for="i in 8" :key="i" class="asset"><span class="skel" style="aspect-ratio: 4 / 3"></span><span class="skel" style="height: 13px; width: 70%"></span></div></div>
      <p v-else class="a-empty">{{ q || status ? 'No images match your filters.' : 'No images here yet. Upload PNG, JPEG, WebP or GIF files.' }}</p>

      <footer v-if="total > SIZE" class="a-foot">
        <span>Showing {{ from }}–{{ to }} of {{ total }}</span>
        <span class="a-pager"><button type="button" class="a-mini" :disabled="page === 0" @click="page--">Previous</button><button type="button" class="a-mini" :disabled="to >= total" @click="page++">Next</button></span>
      </footer>
    </section>
  </div>

  <Modal v-if="folderModal" :title="folderModal.id ? 'Rename folder' : current && folderModal.parentId ? `New folder in ${current.name}` : 'New folder'" width="420px" @close="folderModal = null">
    <label class="a-field">Folder name<input v-model="folderModal.name" class="a-input" maxlength="60" @keydown.enter="createFolder"></label>
    <p v-if="note?.err" class="a-note err" role="alert">{{ note.text }}</p>
    <template #footer><button type="button" class="a-btn" @click="folderModal = null">Cancel</button><button type="button" class="a-btn primary" :disabled="!folderModal.name.trim()" @click="createFolder">Save</button></template>
  </Modal>

  <Modal v-if="detail" :title="detail.name" width="640px" @close="detail = null">
    <img class="big" :src="url(detail.id)" :alt="detail.name">
    <div class="a-row2">
      <label class="a-field">Name<input v-model="detail.name" class="a-input" maxlength="100"></label>
      <label class="a-field">Label<input v-model="detail.label" class="a-input" maxlength="60" placeholder="e.g. Early Stage"></label>
      <label class="a-field">Folder<select v-model="detail.folderId" class="a-select"><option value="">Unfiled</option><option v-for="f in tree" :key="f.id" :value="f.id">{{ indent(f) }}{{ f.name }}</option></select></label>
      <label class="a-field">Status<select v-model="detail.status" class="a-select"><option>Needs review</option><option>Validated</option></select></label>
    </div>
    <p class="a-muted">{{ bytes(detail.sizeBytes) }} · {{ detail.mime }}. Moving an image to another folder re-labels it with that folder’s name.</p>
    <p v-if="note?.err" class="a-note err" role="alert">{{ note.text }}</p>
    <template #footer>
      <button type="button" class="a-btn danger" @click="removeImage">Delete</button><span class="a-grow"></span>
      <button type="button" class="a-btn" @click="detail = null">Cancel</button><button type="button" class="a-btn primary" :disabled="!detail.name.trim()" @click="saveImage">Save</button>
    </template>
  </Modal>
</template>

<style scoped>
.layout { display: grid; grid-template-columns: 260px 1fr; gap: 18px; align-items: start; }
.tree { padding: 14px 10px; } .tree h2 { padding: 0 8px 8px; font: 800 13px var(--font-display); letter-spacing: .08em; text-transform: uppercase; color: var(--ink-soft); }
.node { display: flex; justify-content: space-between; align-items: center; gap: 8px; width: 100%; padding: 9px 14px; border: 0; border-radius: 12px; background: none; text-align: left; font-weight: 700; }
.node:hover { background: var(--tint); } .node.on { background: var(--forest); color: #fff; }
.node span:first-child { display: inline-flex; align-items: center; gap: 7px; min-width: 0; overflow-wrap: anywhere; }
.n { padding: 1px 9px; border-radius: 999px; background: rgba(8, 120, 63, .1); font-size: 13px; font-weight: 800; } .node.on .n { background: rgba(255, 255, 255, .22); }
.main { padding: 20px; overflow: visible; }
.top { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; margin-bottom: 14px; }
h3 { font: 800 19px var(--font-display); color: var(--forest); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(170px, 1fr)); gap: 14px; }
.asset { display: grid; gap: 4px; padding: 10px; border: 1px solid var(--line); border-radius: var(--radius-md); background: #fff; }
.thumb { display: block; padding: 0; border: 0; border-radius: 12px; overflow: hidden; background: var(--bg); aspect-ratio: 4 / 3; }
.thumb img { display: block; width: 100%; height: 100%; object-fit: cover; }
.nm { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; } .asset small { color: var(--ink-soft); }
.big { display: block; max-width: 100%; max-height: 320px; margin: 0 auto 16px; border-radius: 12px; }
@media (max-width: 900px) { .layout { grid-template-columns: 1fr; } }
</style>
