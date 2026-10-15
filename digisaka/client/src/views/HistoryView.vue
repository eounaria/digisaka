<script setup>
import { onMounted } from 'vue';
import { useRouter } from 'vue-router';
import PageHeader from '../components/PageHeader.vue';
import SkeletonList from '../components/SkeletonList.vue';
import { useLinesStore, proposalRows } from '../stores/lines.js';

const router = useRouter(), lines = useLinesStore();
onMounted(() => lines.load());
const STATUS = { proposed: 'Awaiting decision', approved: 'Approved', rejected: 'Rejected', applied: 'Applied' };
const cycleText = (l) => (l.human_review_required ? 'Human review required' : l.latest_cycle ? `Last cycle ${l.latest_cycle.week}: ${l.latest_cycle.status}` : 'No cycles yet');
const open = (l, p) => router.push(`/treatment/${encodeURIComponent(l.line_id)}/${encodeURIComponent(p.week)}`);
</script>

<template>
  <div class="page">
    <PageHeader title="Diagnosis History" subtitle="Each line's recent weeks, treatment proposals and recorded applications." />
    <SkeletonList v-if="lines.loading && !lines.statuses.length" />
    <p v-else-if="lines.error" class="error">{{ lines.error }}</p>
    <p v-else-if="lines.loaded && !lines.statuses.length" class="empty">No lines are available.</p>
    <div v-for="l in lines.statuses" :key="l.line_id" class="item">
      <div class="card static">
        <span class="thumb">🌱</span>
        <span class="body">
          <span class="name">Line {{ l.line_id }}</span>
          <span class="line soft">{{ cycleText(l) }}</span>
          <span v-if="l.error" class="error">{{ l.error }}</span>
        </span>
        <button class="trash" type="button" disabled aria-label="Delete (not available yet)" title="Not available yet">🗑</button>
      </div>
      <ul v-if="l.proposals.length" class="weeks">
        <li v-for="p in proposalRows(l)" :key="p.proposal_id">
          <button type="button" @click="open(l, p)">
            <b>{{ p.week }}</b><span>{{ STATUS[p.status] ?? p.status }}</span>
            <span class="soft">{{ p.window_start }} to {{ p.window_end }}</span>
            <span v-if="p.appliedOn" class="teal">Applied {{ p.appliedOn }}</span>
          </button>
        </li>
      </ul>
      <p v-else-if="!l.error" class="soft none">No proposals yet.</p>
    </div>
  </div>
</template>

<style scoped>
.error { color: var(--danger); font-weight: 700; }
.empty { padding: 30px; text-align: center; color: var(--ink-soft); border: 1.5px dashed var(--line); border-radius: var(--radius-md); background: var(--card); }
.item { margin-bottom: 14px; }
.card { display: flex; align-items: center; gap: 14px; width: 100%; padding: 16px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); box-shadow: var(--shadow); }
.thumb { display: grid; place-items: center; flex: none; width: 44px; height: 44px; border-radius: 12px; background: var(--tint); font-size: 20px; }
.body { flex: 1; min-width: 0; display: grid; gap: 1px; }
.name { font: 800 16px var(--font-display); }
.soft { color: var(--ink-soft); font-size: 13.5px; }
.teal { color: var(--teal); font-weight: 800; }
.trash { width: 34px; height: 34px; border: 0; border-radius: 10px; background: none; font-size: 16px; opacity: .3; cursor: not-allowed; }
.weeks { display: grid; gap: 6px; margin: 8px 0 0 24px; list-style: none; }
.weeks button { display: flex; flex-wrap: wrap; gap: 6px 14px; width: 100%; padding: 10px 14px; border: 1px solid var(--line); border-radius: var(--radius-sm); background: var(--card); text-align: left; }
.weeks button:hover { border-color: var(--leaf); }
.none { margin: 6px 0 0 24px; }
</style>
