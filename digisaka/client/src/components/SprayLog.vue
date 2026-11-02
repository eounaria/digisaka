<script setup>
import { computed, watch, onBeforeUnmount } from 'vue';
import { useLineHistoryStore } from '../stores/lineHistory.js';

const props = defineProps({
  line: { type: String, required: true },
  week: { type: String, required: true },
});

const store = useLineHistoryStore();
const load = () => store.load(props.line, props.week);
watch(() => [props.line, props.week], load, { immediate: true });
onBeforeUnmount(() => store.load('', ''));

const applications = computed(() => {
  const status = store.lineStatus;
  if (!status) return [];
  const appliedOn = new Map((status.applications ?? []).map((app) => [app.proposal_id, app.applied_on]));
  return (status.proposals ?? [])
    .filter((proposal) => proposal.week <= props.week && appliedOn.has(proposal.proposal_id))
    .map((proposal) => ({ ...proposal, appliedOn: appliedOn.get(proposal.proposal_id) }))
    .sort((a, b) => b.appliedOn.localeCompare(a.appliedOn));
});
</script>

<template>
  <section class="card" aria-label="Spray history">
    <header>
      <div>
        <h2>Spray history</h2>
        <p>Recorded applications for Line {{ line }} up to {{ week }}.</p>
      </div>
      <span class="count">{{ applications.length }} recorded</span>
    </header>

    <p v-if="store.phase === 'loading'" class="hint" role="status">Loading application history…</p>
    <p v-else-if="store.phase === 'error'" class="error" role="alert">
      {{ store.error }} <button type="button" @click="load">Try again</button>
    </p>
    <p v-else-if="store.statusError" class="error" role="alert">Application history could not be loaded: {{ store.statusError }}</p>
    <p v-else-if="store.phase === 'ready' && !applications.length" class="empty">
      No treatment applications are recorded for this line and week range.
    </p>
    <ul v-else-if="store.phase === 'ready'" class="records">
      <li v-for="app in applications" :key="app.proposal_id">
        <span class="date">{{ app.appliedOn }}</span>
        <span class="detail">
          <strong>{{ app.week }}</strong>
          <small>Recorded application · product details are not included in the spray log response</small>
        </span>
        <span class="badge">Applied</span>
      </li>
    </ul>

    <div class="rotation-note">
      <strong>FRAC rotation</strong>
      <span>FRAC codes and season-use limits are not provided by the scheduler, so rotation eligibility cannot be assessed here.</span>
    </div>
  </section>
</template>

<style scoped>
.card { padding: 18px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); box-shadow: var(--shadow); }
header { display: flex; justify-content: space-between; align-items: start; gap: 12px; }
h2 { margin: 0 0 5px; color: var(--forest); font: 800 17px var(--font-display); }
header p, .hint, .empty { color: var(--ink-soft); font-size: .88rem; }
.count, .badge { flex: none; padding: 5px 10px; border-radius: 999px; background: var(--tint); color: var(--forest); font-size: .75rem; font-weight: 700; }
.records { list-style: none; margin: 14px 0; padding: 0; border-top: 1px solid var(--line); }
.records li { display: flex; align-items: center; gap: 14px; padding: 13px 0; border-bottom: 1px solid var(--line); }
.date { min-width: 100px; color: var(--ink-soft); font-size: .85rem; }
.detail { min-width: 0; flex: 1; display: grid; gap: 3px; }
.detail small { color: var(--ink-soft); font-size: .78rem; }
.rotation-note { display: grid; gap: 4px; padding: 12px; border-radius: 10px; background: var(--beige); font-size: .82rem; line-height: 1.45; }
.rotation-note span { color: var(--ink-soft); }
.error { color: var(--danger); }
.error button { margin-left: 8px; }
@media (max-width: 540px) {
  header { flex-direction: column; }
  .records li { flex-wrap: wrap; }
}
</style>
