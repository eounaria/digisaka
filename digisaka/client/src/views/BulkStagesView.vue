<script setup>
import { onMounted, ref, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { api } from '../api.js';
import PageHeader from '../components/PageHeader.vue';
import SkeletonList from '../components/SkeletonList.vue';

const route = useRoute(), router = useRouter();
const schedules = ref([]), loading = ref(true), error = ref('');

const bulk = computed(() => schedules.value.find((s) => s.bulkId === route.params.bulkId));
const STAGE_EMOJI = { 1: '🟡', 2: '🟠', 3: '🔴', 4: '🟣' };

onMounted(async () => {
  try { schedules.value = (await api.get('/api/schedules')).schedules; }
  catch (e) { error.value = e.message; }
  finally { loading.value = false; }
});

const openStage = (stage) => router.push(`/schedule/${encodeURIComponent(route.params.bulkId)}/${stage}`);
</script>

<template>
  <div class="page">
    <PageHeader :title="bulk ? bulk.displayLabel : 'Bulk'" :subtitle="bulk ? `${bulk.plant} · ${bulk.bulkId}` : ''" />
    <SkeletonList v-if="loading && !bulk" />
    <p v-else-if="error" class="error">{{ error }}</p>
    <p v-else-if="!loading && !bulk" class="empty">This bulk's schedule couldn't be found.</p>
    <template v-else-if="bulk">
      <p class="hint">Each stage below has its own treatment schedule.</p>
      <button v-for="g in bulk.groups" :key="g.stage" class="card" type="button" @click="openStage(g.stage)">
        <span class="thumb">{{ STAGE_EMOJI[g.stage] || '🟡' }}</span>
        <span class="body"><span class="name">Stage {{ g.stage }}</span><span class="sub">Treatment schedule available</span></span>
        <span class="chev">›</span>
      </button>
    </template>
  </div>
</template>

<style scoped>
.error { color: var(--danger); font-weight: 700; }
.empty, .hint { color: var(--ink-soft); }
.empty { padding: 30px; text-align: center; border: 1.5px dashed var(--line); border-radius: var(--radius-md); background: var(--card); }
.hint { margin-bottom: 14px; }
.card { display: flex; align-items: center; gap: 14px; width: 100%; margin-bottom: 10px; padding: 16px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); box-shadow: var(--shadow); text-align: left; }
.card:hover { border-color: var(--leaf); }
.thumb { display: grid; place-items: center; flex: none; width: 44px; height: 44px; border-radius: 12px; background: var(--tint); font-size: 20px; }
.body { flex: 1; min-width: 0; display: grid; gap: 2px; }
.name { font: 800 16px var(--font-display); }
.sub { font-size: 13.5px; color: var(--ink-soft); }
.chev { flex: none; font-size: 20px; color: var(--ink-soft); }
</style>
