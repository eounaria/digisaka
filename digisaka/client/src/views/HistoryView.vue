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
const openBulk = (b) => { if (hasSchedule(b)) router.push(`/schedule/${encodeURIComponent(b.bulkId)}`); };
</script>

<template>
  <div class="page">
    <PageHeader title="Bulk Recent Scanned" subtitle="Recent bulk assessments grouped by plant, bulk ID, date, and Black Sigatoka stage." />
    <SkeletonList v-if="loading && !bulks.length" />
    <p v-else-if="error" class="error">{{ error }}</p>
    <p v-else-if="!loading && !bulks.length" class="empty">No bulk assessments have been completed yet. Run a bulk assessment to see it here.</p>
    <button v-for="b in bulks" :key="b.bulkId" class="card" type="button" :disabled="!hasSchedule(b)" @click="openBulk(b)">
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
  </div>
</template>

<style scoped>
.error { color: var(--danger); font-weight: 700; }
.empty { padding: 30px; text-align: center; color: var(--ink-soft); border: 1.5px dashed var(--line); border-radius: var(--radius-md); background: var(--card); }
.card { display: flex; align-items: center; gap: 14px; width: 100%; margin-bottom: 10px; padding: 16px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); box-shadow: var(--shadow); text-align: left; }
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
