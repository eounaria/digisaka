<script setup>
import { onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { api } from '../api.js';
import PageHeader from '../components/PageHeader.vue';
import SkeletonList from '../components/SkeletonList.vue';

const router = useRouter();
const schedules = ref([]), loading = ref(true), error = ref('');

onMounted(async () => {
  try { schedules.value = (await api.get('/api/schedules')).schedules; }
  catch (e) { error.value = e.message; }
  finally { loading.value = false; }
});
</script>

<template>
  <div class="page">
    <PageHeader title="Scheduled Treatments" subtitle="Grouped by bulk assessment — tap a bulk to see its stages." />
    <SkeletonList v-if="loading && !schedules.length" />
    <p v-else-if="error" class="error">{{ error }}</p>
    <p v-else-if="!loading && !schedules.length" class="empty">No treatments have been scheduled yet. Scan and confirm a bulk treatment schedule to see it here.</p>
    <button v-for="(s, i) in schedules" :key="s.bulkId" class="card" type="button" @click="router.push(`/schedule/${s.bulkId}`)">
      <span class="thumb">📦</span>
      <span class="body"><span class="name">{{ s.displayLabel }}</span><span class="sub">{{ s.plant }} · {{ s.bulkId }}</span></span>
      <span class="count">{{ s.groups.length }} {{ s.groups.length === 1 ? 'scheduled stage' : 'scheduled stages' }}</span>
      <span class="chev">›</span>
    </button>
  </div>
</template>

<style scoped>
.error { color: var(--danger); font-weight: 700; }
.empty { padding: 30px; text-align: center; color: var(--ink-soft); border: 1.5px dashed var(--line); border-radius: var(--radius-md); background: var(--card); }
.card { display: flex; align-items: center; gap: 14px; width: 100%; margin-bottom: 10px; padding: 16px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); box-shadow: var(--shadow); text-align: left; }
.card:hover { border-color: var(--leaf); }
.thumb { display: grid; place-items: center; flex: none; width: 44px; height: 44px; border-radius: 12px; background: var(--tint); font-size: 20px; }
.body { flex: 1; min-width: 0; display: grid; gap: 2px; }
.name { font: 800 16px var(--font-display); }
.sub { font-size: 13.5px; color: var(--ink-soft); }
.count { flex: none; font-size: 13px; font-weight: 800; color: var(--teal); }
.chev { flex: none; font-size: 20px; color: var(--ink-soft); }
</style>
