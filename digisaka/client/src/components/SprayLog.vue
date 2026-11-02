<script setup>
import { computed, watch, onBeforeUnmount } from 'vue';
import { useLineHistoryStore } from '../stores/lineHistory.js';
import { usePrototypeStore } from '../stores/prototype.js';
import { verdictText } from '../helpers/evidence.js';

const props = defineProps({
  line: { type: String, required: true },
  week: { type: String, required: true },
});

const store = useLineHistoryStore();
const prototypeStore = usePrototypeStore();
const load = () => store.load(props.line, props.week);
watch(() => [props.line, props.week], () => {
  load();
  prototypeStore.load(props.line, props.week);
}, { immediate: true });
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
const selectedWeek = computed(() => store.weeks.find((item) => item.week === props.week) ?? null);
const risk = computed(() => store.evidence?.week === props.week ? verdictText(store.evidence.rainfall?.favourable) : 'Not assessed');
</script>

<template>
  <div class="history-layout">
    <div class="history-main">
      <section class="card" aria-label="Spray history">
      <header>
        <div>
          <h2>Spray history</h2>
          <p>Recorded applications for Line {{ line }} up to {{ week }}.</p>
        </div>
        <span class="count">{{ applications.length }} recorded</span>
      </header>

      <p v-if="store.phase === 'loading'" class="hint" role="status">Loading application history…</p>
      <p v-else-if="store.phase === 'error'" class="hint error" role="alert">
        {{ store.error }} <button type="button" @click="load">Try again</button>
      </p>
      <p v-else-if="store.statusError" class="hint error" role="alert">Application history could not be loaded: {{ store.statusError }}</p>
      <p v-else-if="store.phase === 'ready' && !applications.length" class="empty">
        No treatment applications are recorded for this line and week range.
      </p>
      <ul v-else-if="store.phase === 'ready'" class="timeline">
        <li v-for="app in applications" :key="app.proposal_id">
          <span class="timeline-dot applied" aria-hidden="true"></span>
          <span class="date">{{ app.appliedOn }}</span>
          <span class="detail">
            <strong>{{ app.week }}</strong>
            <small>Recorded application · product details are not included in the spray log response</small>
          </span>
          <span class="badge">Applied</span>
        </li>
      </ul>

      <p v-if="prototypeStore.phase === 'loading'" class="hint" role="status">Loading prototype spray data…</p>
      <p v-else-if="prototypeStore.phase === 'error'" class="hint error" role="alert">Prototype spray data could not be loaded: {{ prototypeStore.error }}</p>
      <template v-else-if="prototypeStore.phase === 'ready'">
        <div class="sample-heading">
          <div><h3>Prototype spray history</h3><span>{{ prototypeStore.data.label }}</span></div>
          <span class="sample-badge">Sample only</span>
        </div>
        <ul class="timeline sample-timeline">
          <li v-for="(spray, index) in prototypeStore.data.spray_history" :key="`${spray.date}-${index}`">
            <span class="timeline-dot" :class="{ restricted: spray.status === 'Restricted' }" aria-hidden="true"></span>
            <span class="date">{{ spray.date }}</span>
            <span class="detail">
              <strong>{{ spray.name }}</strong>
              <small>{{ spray.mode }} · FRAC {{ spray.frac_code }}</small>
            </span>
            <span class="badge" :class="{ restricted: spray.status === 'Restricted' }">{{ spray.status }}</span>
          </li>
        </ul>
      </template>
      </section>

      <section class="card frac-card" :class="{ restricted: prototypeStore.data?.frac_history?.some((entry) => entry.status === 'Restricted') }" aria-label="FRAC history">
        <header>
          <div>
            <h2>{{ prototypeStore.data?.frac_history?.some((entry) => entry.status === 'Restricted') ? 'Restricted FRAC groups' : 'FRAC history' }}</h2>
            <p>Rotation context and sample season-use limits.</p>
          </div>
          <span v-if="prototypeStore.phase === 'ready'" class="sample-badge">Sample only</span>
        </header>
        <template v-if="prototypeStore.phase === 'ready'">
          <p class="sample-label">{{ prototypeStore.data.label }}</p>
          <div class="frac-history">
            <div v-for="entry in prototypeStore.data.frac_history" :key="entry.frac_code" class="frac-row">
              <span class="frac-code">FRAC {{ entry.frac_code }}</span>
              <div class="frac-row-detail">
                <strong>{{ entry.reason }}</strong>
                <small>{{ entry.uses }} / {{ entry.limit }} sample uses</small>
              </div>
              <span class="frac-status" :class="{ restricted: entry.status === 'Restricted' }">{{ entry.status }}</span>
            </div>
          </div>
          <p v-if="prototypeStore.data.frac_history.some((entry) => entry.status === 'Restricted')" class="frac-footnote">Restricted groups are excluded from eligible sample options.</p>
        </template>
        <p v-else class="rotation-note">
          FRAC codes and season-use limits are not provided by the scheduler, so rotation eligibility cannot be assessed here.
        </p>
      </section>
      </div>

      <aside class="card line-summary" aria-label="Selected line summary">
        <p class="eyebrow">Line {{ line }} · {{ week }}</p>
        <div class="summary-row"><span>Infection risk</span><strong>{{ risk }}</strong></div>
        <div class="summary-row"><span>YLS / YLI</span><strong>{{ selectedWeek ? `${selectedWeek.yls ?? '—'} / ${selectedWeek.yli ?? '—'}` : '— / —' }}</strong></div>
        <div class="summary-row"><span>Functional leaves</span><strong>Not recorded</strong></div>
        <div class="summary-row"><span>Last treatment</span><strong>{{ store.appliedProposal ? (store.treatment?.name ?? 'Recorded application') : 'None recorded' }}</strong></div>
        <section v-if="prototypeStore.phase === 'ready'" class="action-card" aria-label="Prototype recommended action">
          <header><h2>Recommended action</h2><span class="sample-badge">Sample</span></header>
          <div class="action-chips">
            <span class="action-chip preventive" :class="{ active: prototypeStore.data.recommended_action.preventive }">{{ prototypeStore.data.recommended_action.preventive ? '✓ ' : '' }}Preventive</span>
            <span class="action-chip mechanical" :class="{ active: prototypeStore.data.recommended_action.mechanical }">{{ prototypeStore.data.recommended_action.mechanical ? '✓ ' : '' }}Mechanical</span>
            <span class="action-chip treatment" :class="{ active: prototypeStore.data.recommended_action.treatment }">{{ prototypeStore.data.recommended_action.treatment ? '✓ ' : '' }}Treatment</span>
            <span class="action-chip monitor" :class="{ active: prototypeStore.data.recommended_action.monitor }">{{ prototypeStore.data.recommended_action.monitor ? '✓ ' : '' }}Monitor</span>
            <span class="action-chip provisional">{{ prototypeStore.data.recommended_action.provisional_label }}</span>
          </div>
          <p>{{ prototypeStore.data.recommended_action.summary }}</p>
          <small>Sample action · not validated guidance.</small>
        </section>
        <p class="summary-note">This information is context for review, not a confirmed diagnosis or treatment recommendation.</p>
      </aside>
    </div>
</template>

<style scoped>
.history-layout { display: grid; grid-template-columns: minmax(0, 1fr) minmax(280px, 340px); gap: 20px; align-items: start; }
.history-main { display: grid; gap: 16px; min-width: 0; }
.card { min-width: 0; padding: 18px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); box-shadow: var(--shadow); }
header { display: flex; justify-content: space-between; align-items: start; gap: 12px; }
h2 { margin: 0 0 5px; color: var(--forest); font: 800 17px var(--font-display); }
header p, .hint, .empty { color: var(--ink-soft); font-size: .88rem; line-height: 1.5; }
.line-summary { position: sticky; top: 16px; }
.eyebrow { margin-bottom: 10px; color: var(--ink-soft); font-size: .76rem; font-weight: 800; letter-spacing: .04em; text-transform: uppercase; }
.summary-row { display: flex; justify-content: space-between; gap: 12px; padding: 10px 0; border-top: 1px solid var(--line); font-size: .86rem; }
.summary-row span { color: var(--ink-soft); }
.summary-row strong { text-align: right; }
.summary-note { margin-top: 12px; padding-top: 10px; border-top: 1px solid var(--line); color: var(--ink-soft); font-size: .76rem; line-height: 1.45; }
.count, .badge { flex: none; padding: 5px 10px; border-radius: 999px; background: var(--tint); color: var(--forest); font-size: .75rem; font-weight: 700; }
.timeline { position: relative; list-style: none; margin: 14px 0 0 8px; padding: 0 0 0 20px; border-left: 2px dotted #aab8af; }
.timeline li { position: relative; display: flex; align-items: center; gap: 12px; min-height: 48px; padding: 8px 0; border-bottom: 1px solid var(--line); }
.timeline li:last-child { border-bottom: 0; }
.timeline-dot { position: absolute; left: -27px; top: 50%; width: 12px; height: 12px; transform: translateY(-50%); border: 2px solid #fff; border-radius: 50%; background: var(--forest); box-shadow: 0 0 0 1px var(--forest); }
.timeline-dot.restricted { background: var(--danger); box-shadow: 0 0 0 1px var(--danger); }
.date { min-width: 82px; color: var(--ink-soft); font-size: .82rem; }
.detail { min-width: 0; flex: 1; display: grid; gap: 3px; }
.detail small { color: var(--ink-soft); font-size: .78rem; line-height: 1.4; }
.empty { margin-top: 16px; }
.sample-heading { display: flex; justify-content: space-between; align-items: start; gap: 12px; margin-top: 20px; padding-top: 16px; border-top: 1px solid var(--line); }
.sample-heading h3 { margin: 0 0 5px; color: var(--forest); font-size: .95rem; }
.sample-heading > div > span, .sample-label { color: var(--ink-soft); font-size: .76rem; line-height: 1.45; }
.sample-badge { flex: none; padding: 5px 10px; border-radius: 999px; background: #e5e7eb; color: #374151; font-size: .72rem; font-weight: 800; }
.sample-timeline { margin-top: 10px; }
.badge.restricted { background: var(--warn-tint); color: var(--warn); }
.frac-card.restricted { border: 1.5px solid #d6455a; box-shadow: none; }
.frac-card.restricted header h2 { color: var(--ink); }
.frac-history { display: grid; gap: 2px; margin-top: 12px; }
.frac-row { display: grid; grid-template-columns: auto minmax(0, 1fr) auto; align-items: center; gap: 10px; padding: 9px 0; }
.frac-code { flex: none; padding: 4px 9px; border-radius: 999px; background: #e5e7eb; color: #374151; font-size: .72rem; font-weight: 800; white-space: nowrap; }
.frac-row-detail { display: grid; min-width: 0; gap: 2px; }
.frac-row-detail strong { color: var(--ink); font-size: .79rem; font-weight: 600; line-height: 1.4; }
.frac-row-detail small { color: var(--ink-soft); font-size: .72rem; }
.frac-status { flex: none; padding: 3px 9px; border-radius: 999px; background: #dff3e4; color: #0b5a1f; font-size: .68rem; font-weight: 800; white-space: nowrap; }
.frac-status.restricted { background: #fbdada; color: #9b1c1c; }
.frac-footnote { margin-top: 5px; color: var(--ink-soft); font-size: .74rem; line-height: 1.4; }
.action-card { display: grid; gap: 12px; margin-top: 10px; padding-top: 14px; border-top: 1px solid var(--line); }
.action-card header { align-items: center; }
.action-card header h2 { margin: 0; }
.action-card > p { font-size: .85rem; line-height: 1.45; }
.action-card > small { color: var(--ink-soft); font-size: .75rem; }
.action-chips { display: flex; flex-wrap: wrap; gap: 6px; }
.action-chip { padding: 4px 8px; border-radius: 999px; background: #f0f2f0; color: var(--ink-soft); font-size: .7rem; font-weight: 800; }
.action-chip.preventive.active { background: #dcefff; color: #0b4f8a; }
.action-chip.mechanical.active { background: #e3f4e6; color: #0b5a1f; }
.action-chip.treatment.active { background: var(--warn-tint); color: var(--warn); }
.action-chip.monitor.active { background: var(--tint); color: var(--forest); }
.action-chip.provisional { background: var(--beige); }
.rotation-note { margin-top: 14px; padding: 12px; border-radius: 10px; background: var(--beige); color: var(--ink-soft); font-size: .84rem; line-height: 1.5; }
.error { color: var(--danger); }
.error button { margin-left: 8px; }
@media (max-width: 760px) {
  .history-layout { grid-template-columns: minmax(0, 1fr); }
  .line-summary { position: static; }
}
@media (max-width: 540px) {
  header { flex-direction: column; }
  .timeline li { flex-wrap: wrap; }
  .date { min-width: 72px; }
}
</style>
