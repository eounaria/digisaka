<script setup>
import { ref, watch, computed } from 'vue';
import { api } from '../api.js';
import { useUseCaseStore } from '../stores/useCase.js';
import Icon from '../components/Icon.vue';
import Modal from './Modal.vue';
import Pill from './Pill.vue';
import SkeletonRows from './SkeletonRows.vue';
import { qs, useLoader, fmtDateTime, ACTION } from './util.js';

const SIZE = 25;
const uc = useUseCaseStore();
const q = ref(''), action = ref(''), page = ref(0), rows = ref([]), total = ref(0), actions = ref([]), open = ref(null);
const { loading, error, run } = useLoader(() => api.get(`/api/admin/audit?${qs({ useCase: uc.slug, q: q.value.trim(), action: action.value, limit: SIZE, offset: page.value * SIZE })}`));
async function load() { const r = await run(); if (r) { rows.value = r.entries; total.value = r.total; actions.value = r.actions; } }
let t;
watch(q, () => { clearTimeout(t); t = setTimeout(() => { page.value = 0; load(); }, 250); });
watch([action, () => uc.slug], () => { page.value = 0; load(); }, { immediate: true });
watch(page, load);
const from = computed(() => (total.value ? page.value * SIZE + 1 : 0));
const to = computed(() => Math.min((page.value + 1) * SIZE, total.value));
const tone = (s) => (s === 'OK' ? 'good' : s === 'Failed' ? 'bad' : 'neutral');
const detailRows = (d) => Object.entries(d ?? {}).map(([k, v]) => [k.replace(/([A-Z])/g, ' $1').toLowerCase(), typeof v === 'object' ? JSON.stringify(v) : String(v)]);
</script>

<template>
  <header class="a-head"><h1>History</h1><p>Audit log of every change made in the admin console.</p></header>
  <div class="a-toolbar">
    <label class="a-search"><Icon name="search" :size="16" /><input v-model="q" type="search" placeholder="Search actor or object" aria-label="Search history"></label>
    <select v-model="action" class="a-select" aria-label="Filter by action"><option value="">All actions</option><option v-for="a in actions" :key="a" :value="a">{{ ACTION[a] ?? a }}</option></select>
    <button type="button" class="a-btn" @click="load"><Icon name="refresh" :size="16" />Refresh</button>
  </div>
  <p v-if="error" class="a-note err" role="alert">{{ error }}</p>

  <div class="a-card">
    <div class="a-scroll">
      <table class="a-table">
        <thead><tr><th>Timestamp</th><th>User / Actor</th><th>Action</th><th>Object type</th><th>Object</th><th>Previous</th><th>New</th><th>Status</th><th>Details</th></tr></thead>
        <tbody>
          <SkeletonRows v-if="loading && !rows.length" :cols="9" />
          <tr v-for="e in rows" :key="e.id">
            <td class="nw">{{ fmtDateTime(e.createdAt) }}</td><td>{{ e.actor }}</td><td><b>{{ e.action }}</b></td><td>{{ e.objectType }}</td>
            <td class="obj">{{ e.objectLabel ?? '—' }}</td><td class="obj">{{ e.previous ?? '—' }}</td><td class="obj">{{ e.newValue ?? '—' }}</td>
            <td><Pill :tone="tone(e.status)">{{ e.status }}</Pill></td>
            <td><button type="button" class="a-mini" @click="open = e">View</button></td>
          </tr>
        </tbody>
      </table>
      <p v-if="!loading && !rows.length" class="a-empty">{{ q || action ? 'Nothing matches your filters.' : 'No activity has been recorded yet.' }}</p>
    </div>
    <footer class="a-foot">
      <span>{{ total ? `Showing ${from}–${to} of ${total}` : '' }}</span>
      <span class="a-pager"><button type="button" class="a-mini" :disabled="page === 0" @click="page--">Previous</button><button type="button" class="a-mini" :disabled="to >= total" @click="page++">Next</button></span>
    </footer>
  </div>

  <Modal v-if="open" :title="`${ACTION[open.action] ?? open.action} · ${open.objectType}`" @close="open = null">
    <dl>
      <dt>When</dt><dd>{{ fmtDateTime(open.createdAt) }}</dd>
      <dt>Who</dt><dd>{{ open.actor }}</dd>
      <dt>Object</dt><dd>{{ open.objectLabel ?? '—' }}</dd>
      <dt>Previous</dt><dd>{{ open.previous ?? '—' }}</dd>
      <dt>New</dt><dd>{{ open.newValue ?? '—' }}</dd>
      <template v-for="[k, v] in detailRows(open.detail)" :key="k"><dt>{{ k }}</dt><dd>{{ v }}</dd></template>
    </dl>
  </Modal>
</template>

<style scoped>
.nw { white-space: nowrap; } .obj { max-width: 220px; overflow-wrap: anywhere; }
dl { display: grid; grid-template-columns: 110px 1fr; gap: 10px 14px; } dt { font-weight: 800; color: var(--ink-soft); text-transform: capitalize; } dd { margin: 0; overflow-wrap: anywhere; }
</style>
