<script setup>
import { onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { api } from '../api.js';
import PageHeader from '../components/PageHeader.vue';
import SkeletonList from '../components/SkeletonList.vue';

const router = useRouter();
const bulks = ref([]), scheduled = ref(new Set()), loading = ref(true), error = ref('');

async function load() {
  loading.value = true; error.value = '';
  try {
    const [b, s] = await Promise.all([api.get('/api/bulks?limit=50'), api.get('/api/schedules')]);
    bulks.value = b.bulks;
    scheduled.value = new Set(s.schedules.map((x) => x.bulkId));
  }
  catch (e) { error.value = e.message; }
  finally { loading.value = false; }
}
onMounted(load);

// Only bulks with a confirmed treatment schedule have stages to show.
const hasSchedule = (b) => scheduled.value.has(b.bulkId);
const confirming = ref(''), deleting = ref('');
async function removeBulk(b) {
  deleting.value = b.bulkId; error.value = '';
  try {
    await api.del(`/api/bulks/${encodeURIComponent(b.bulkId)}`);
    bulks.value = bulks.value.filter((x) => x.bulkId !== b.bulkId);
    confirming.value = '';
  } catch (e) { error.value = e.message; }
  finally { deleting.value = ''; }
}
const openBulk = (b) => { if (hasSchedule(b)) router.push(`/schedule/${encodeURIComponent(b.bulkId)}`); };
</script>

<template>
  <div class="page">
    <PageHeader title="Bulk Recent Scanned" subtitle="Recent bulk assessments grouped by plant, bulk ID, date, and Black Sigatoka stage." />
    <SkeletonList v-if="loading && !bulks.length" />
    <p v-else-if="error" class="error">{{ error }}</p>
    <p v-else-if="!loading && !bulks.length" class="empty">No bulk assessments have been completed yet. Run a bulk assessment to see it here.</p>
    <p v-if="error && bulks.length" class="error">{{ error }}</p>
    <div v-for="b in bulks" :key="b.bulkId" class="item">
    <button class="card" type="button" :disabled="!hasSchedule(b)" @click="openBulk(b)">
      <span class="thumb">📦</span>
      <span class="body">
        <span class="date">{{ b.date }}</span>
        <span class="name">{{ b.plant }}</span>
        <span class="line teal">{{ b.bulkId }}</span>
        <span class="line">{{ b.leafCount }} leaves scanned</span>
        <span class="line soft">Stage 1: {{ b.counts[1] }} | Stage 2: {{ b.counts[2] }} | Stage 3: {{ b.counts[3] }} | Stage 4: {{ b.counts[4] }}</span>
      </span>
      <span class="side"><span class="status">{{ b.status }}</span><span class="view" :class="{ none: !hasSchedule(b) }">{{ hasSchedule(b) ? 'View Bulk' : 'No schedule yet' }}</span></span>
    </button>
    <div v-if="confirming === b.bulkId" class="confirm" role="alertdialog">
      <span>Delete {{ b.bulkId }} and its treatment schedule? This can't be undone.</span>
      <button class="danger" type="button" :disabled="deleting === b.bulkId" @click="removeBulk(b)">{{ deleting === b.bulkId ? 'Deleting…' : 'Delete' }}</button>
      <button class="ghost" type="button" :disabled="deleting === b.bulkId" @click="confirming = ''">Cancel</button>
    </div>
    <button v-else class="trash" type="button" :aria-label="`Delete ${b.bulkId}`" title="Delete bulk" @click="confirming = b.bulkId">🗑</button>
    </div>
  </div>
</template>

<style scoped>
.error { color: var(--danger); font-weight: 700; }
.empty { padding: 30px; text-align: center; color: var(--ink-soft); border: 1.5px dashed var(--line); border-radius: var(--radius-md); background: var(--card); }
.item { position: relative; margin-bottom: 10px; }
.item .card { margin-bottom: 0; padding-right: 54px; }
.trash { position: absolute; top: 8px; right: 8px; width: 34px; height: 34px; border: 0; border-radius: 10px; background: none; font-size: 16px; opacity: .55; transition: opacity .15s, background .15s; }
.trash:hover { opacity: 1; background: var(--warn-tint); }
.confirm { display: flex; flex-wrap: wrap; align-items: center; gap: 10px; margin-top: 6px; padding: 12px 14px; border-radius: var(--radius-md); background: var(--warn-tint); font-size: 13.5px; font-weight: 700; color: #B4432A; }
.confirm span { flex: 1 1 220px; }
.confirm button { padding: 8px 14px; border-radius: 10px; font: 800 13px var(--font-display); }
.confirm .danger { border: 0; background: #D8352A; color: #fff; }
.confirm .ghost { border: 1px solid var(--line); background: var(--card); color: var(--ink); }
.card { display: flex; align-items: center; gap: 14px; width: 100%; padding: 16px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); box-shadow: var(--shadow); text-align: left; }
.card:hover:not(:disabled) { border-color: var(--leaf); }
.card:disabled { cursor: default; }
.view.none { color: var(--ink-soft); font-weight: 700; }
.thumb { display: grid; place-items: center; flex: none; width: 44px; height: 44px; border-radius: 12px; background: var(--tint); font-size: 20px; }
.body { flex: 1; min-width: 0; display: grid; gap: 1px; }
.date { font-size: 12.5px; color: var(--ink-soft); font-weight: 700; }
.name { font: 800 16px var(--font-display); }
.line { font-size: 13.5px; }
.line.teal { color: var(--teal); font-weight: 800; }
.line.soft { color: var(--ink-soft); }
.side { text-align: right; flex: none; }
.status { display: block; font-size: 11px; font-weight: 800; color: var(--ink-soft); }
.view { display: block; margin-top: 4px; font-weight: 800; font-size: 13px; color: var(--forest); }
</style>
