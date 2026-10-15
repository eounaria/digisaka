<script setup>
import { onMounted, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import PageHeader from '../components/PageHeader.vue';
import SkeletonList from '../components/SkeletonList.vue';
import { useLinesStore, proposalRows } from '../stores/lines.js';

const route = useRoute(), router = useRouter(), lines = useLinesStore();
const line = computed(() => lines.byId(String(route.params.lineId)));
const rows = computed(() => (line.value ? proposalRows(line.value) : []));
const STATUS = { proposed: 'Awaiting decision', approved: 'Approved', rejected: 'Rejected', applied: 'Applied' };
onMounted(() => { if (!lines.loaded) lines.load(); });
const open = (p) => router.push(`/treatment/${encodeURIComponent(String(route.params.lineId))}/${encodeURIComponent(p.week)}`);
</script>

<template>
  <div class="page">
    <PageHeader :title="`Line ${route.params.lineId}`" subtitle="One treatment proposal per week." />
    <SkeletonList v-if="lines.loading && !line" />
    <p v-else-if="lines.error" class="error">{{ lines.error }}</p>
    <p v-else-if="lines.loaded && !line" class="empty">This line's schedule couldn't be found.</p>
    <p v-else-if="line && !rows.length" class="empty">No proposals for this line yet.</p>
    <template v-else-if="line">
      <p class="hint">Choose a week to see its treatment.</p>
      <button v-for="p in rows" :key="p.proposal_id" class="card" type="button" @click="open(p)">
        <span class="thumb">🗓</span>
        <span class="body"><span class="name">{{ p.week }}</span><span class="sub">{{ p.window_start }} to {{ p.window_end }}</span></span>
        <span class="count">{{ p.appliedOn ? `Applied ${p.appliedOn}` : STATUS[p.status] ?? p.status }}</span>
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
