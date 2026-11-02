<script setup>
import { computed, watch, onBeforeUnmount } from 'vue';
import { useLineHistoryStore } from '../stores/lineHistory.js';
import WeekCharts from './WeekCharts.vue';
import { diseaseCaption, rainfallCaption, verdictText } from '../helpers/evidence.js';
import { outcomeReasonText } from '../helpers/messages.js';

// The last three weekly values of a line, so the practitioner sees the trend while choosing what to scan.
const props = defineProps({ line: { type: String, default: '' }, week: { type: String, default: '' } });
const store = useLineHistoryStore();
const load = () => store.load(props.line, props.week);
watch(() => [props.line, props.week], load, { immediate: true });
onBeforeUnmount(() => store.load('', ''));

const latestValue = (key) => [...store.weeks].reverse().find((w) => w[key] != null) ?? null;
const yls = computed(() => latestValue('yls'));
const yli = computed(() => latestValue('yli'));
const disease = computed(() => store.evidence?.disease ?? null);
const rainfall = computed(() => store.evidence?.rainfall ?? null);
const progression = computed(() => disease.value ? diseaseCaption({ weeks: store.evidence.weeks ?? store.weeks, disease: disease.value }) : 'No completed assessment evidence is available.');
const rainfallContext = computed(() => rainfall.value ? rainfallCaption({ rainfall: rainfall.value }) : 'No completed assessment evidence is available.');
const risk = computed(() => rainfall.value ? verdictText(rainfall.value.favourable) : 'Not assessed');
const progressionLabel = computed(() => disease.value ? verdictText(disease.value.worsening) : 'Not assessed');
const latestCycle = computed(() => store.lineStatus?.latest_cycle ?? null);
const cycleResult = computed(() => {
  const c = latestCycle.value;
  if (!c) return 'No completed assessment is recorded.';
  const result = c.outcome === 'proposal' ? 'Treatment proposal' : c.outcome === 'continue_monitoring' ? 'Continue monitoring' : c.outcome === 'human_review_required' ? 'Human review required' : c.status;
  const reason = outcomeReasonText(c.outcome_reason);
  return reason ? `${result}: ${reason}` : result;
});
</script>

<template>
  <section v-if="store.phase !== 'idle'" class="history" aria-label="Recent weeks for this line">
    <h3>Line {{ store.lineId }} insights</h3>
    <p v-if="store.phase === 'loading'" class="hint">Loading…</p>
    <p v-else-if="store.phase === 'error'" class="err">{{ store.error }} <button class="mark" type="button" @click="load">Try again</button></p>
    <template v-if="store.phase === 'ready'">
      <p v-if="store.statusError" class="err" role="alert">Line status could not be loaded: {{ store.statusError }}</p>
      <div v-else class="insights">
        <div class="metrics">
          <article class="metric">
            <span>YLS</span><strong>{{ yls?.yls ?? '—' }}</strong>
            <small>{{ yls ? `${yls.week}, latest recorded` : 'No reading recorded' }}</small>
          </article>
          <article class="metric">
            <span>YLI</span><strong>{{ yli?.yli ?? '—' }}</strong>
            <small>{{ yli ? `${yli.week}, latest recorded` : 'No reading recorded' }}</small>
          </article>
          <article class="metric unavailable">
            <span>Functional leaves</span><strong>Not recorded</strong>
            <small>Leaf-count data is not available</small>
          </article>
          <article class="metric" :class="{ risk: rainfall?.favourable === true }">
            <span>Infection risk</span><strong>{{ risk }}</strong>
            <small>{{ rainfall ? rainfallContext : 'No completed assessment evidence' }}</small>
          </article>
          <article class="metric" :class="{ risk: disease?.worsening === true }">
            <span>Progression</span><strong>{{ progressionLabel }}</strong>
            <small>{{ progression }}</small>
          </article>
          <article class="metric">
            <span>Last treatment</span>
            <strong>{{ store.appliedProposal ? (store.treatment?.name ?? 'Recorded application') : 'None recorded' }}</strong>
            <small v-if="store.appliedProposal">{{ store.appliedProposal.appliedOn ? `Applied ${store.appliedProposal.appliedOn}` : `Proposal ${store.appliedProposal.week}` }}</small>
            <small v-else>No application recorded for this line</small>
          </article>
        </div>
        <p v-if="store.evidenceError" class="err" role="alert">Assessment evidence could not be loaded: {{ store.evidenceError }}</p>
        <p v-if="store.treatmentError" class="err" role="alert">Treatment details could not be loaded: {{ store.treatmentError }}</p>

        <div class="canopy">
          <div class="section-title"><h4>Canopy check</h4><span>Prototype · sample values</span></div>
          <div class="canopy-bar" role="img" aria-label="Prototype only: 9 functional leaves, critical level 8, target 10">
            <div class="canopy-fill"></div>
            <i class="canopy-tick critical"></i>
            <i class="canopy-tick target"></i>
          </div>
          <div class="canopy-scale" aria-hidden="true">
            <span class="critical-label">8 critical</span>
            <span class="target-label">10 target</span>
          </div>
          <div class="canopy-summary"><b>9 leaves.</b><span>Below the target, above the critical level</span><strong>Watch</strong></div>
          <p class="prototype-note">Illustrative only—not measured for this line. Functional-leaf counts and thresholds are not yet provided by the scheduler.</p>
        </div>

        <div class="management">
          <h4>Why management may be needed</h4>
          <div class="reason">
            <b>Disease progression</b><p>{{ progression }}</p>
          </div>
          <div class="reason">
            <b>Rainfall context</b><p>{{ rainfallContext }}</p>
          </div>
          <div class="reason">
            <b>Latest scheduler result</b><p>{{ cycleResult }}</p>
          </div>
          <p class="disclaimer">These indicators are context, not a confirmed diagnosis. Verify findings with an agricultural specialist before treatment decisions.</p>
        </div>
      </div>
      <WeekCharts v-if="store.phase === 'ready'" :weeks="store.weeks" />
    </template>
  </section>
</template>

<style scoped>
.history { margin-top: 12px; }
h3 { margin: 0 0 10px; font-size: 1rem; }
svg { max-width: 420px; }
.hint { color: var(--ink-soft); font-size: .8rem; margin: 6px 0 0; }
.err { color: var(--danger); }
.insights { display: grid; gap: 14px; }
.metrics { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px; }
.metric { min-width: 0; display: grid; align-content: start; gap: 2px; padding: 10px; border-radius: 12px; background: #f0f3f0; }
.metric > span { color: var(--ink-soft); font-size: .72rem; }
.metric strong { color: var(--ink); font-size: 1rem; line-height: 1.3; overflow-wrap: anywhere; }
.metric small { color: var(--ink-soft); font-size: .68rem; line-height: 1.35; }
.metric.risk { background: #fdebc8; }
.metric.risk strong, .metric.risk small { color: #6b4000; }
.metric.unavailable strong { font-size: .82rem; }
.canopy, .management { padding-top: 12px; border-top: 1px solid var(--line); }
.section-title { display: flex; justify-content: space-between; align-items: center; gap: 8px; margin-bottom: 5px; }
h4 { font-size: .9rem; }
.section-title span { padding: 3px 8px; border-radius: 999px; background: #e5e7eb; color: #4b5563; font-size: .68rem; font-weight: 700; }
.canopy p, .reason p, .disclaimer { color: var(--ink-soft); font-size: .76rem; line-height: 1.45; }
.canopy-bar { position: relative; height: 14px; margin: 12px 0 0; border-radius: 999px; background: #e5e7eb; }
.canopy-fill { width: 75%; height: 100%; border-radius: inherit; background: #8a6508; }
.canopy-tick { position: absolute; top: -4px; height: 22px; border-left: 2px solid; }
.canopy-tick.critical { left: 66.67%; border-color: var(--danger); }
.canopy-tick.target { left: 83.33%; border-color: var(--forest); }
.canopy-scale { position: relative; height: 20px; color: var(--ink-soft); font-size: .65rem; font-weight: 700; }
.canopy-scale span { position: absolute; top: 2px; white-space: nowrap; }
.critical-label { left: 66.67%; color: var(--danger); transform: translateX(-50%); }
.target-label { left: 83.33%; color: var(--forest); transform: translateX(-50%); }
.canopy-summary { display: flex; flex-wrap: wrap; align-items: baseline; gap: 6px 12px; font-size: .74rem; }
.canopy-summary strong { margin-left: auto; color: #7a4a00; }
.prototype-note { margin-top: 5px; }
.management h4 { margin-bottom: 6px; }
.reason { display: flex; justify-content: space-between; gap: 10px; padding: 7px 0; border-top: 1px solid var(--line); }
.reason:first-of-type { border-top: 0; }
.reason b { flex: 0 0 38%; font-size: .74rem; }
.reason p { margin: 0; }
.disclaimer { margin-top: 8px; padding: 9px 10px; border-radius: 10px; background: #f1f1f1; }
@media (max-width: 680px) {
  .metrics { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
</style>
