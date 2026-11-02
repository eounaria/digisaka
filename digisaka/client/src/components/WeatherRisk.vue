<script setup>
import { computed, onBeforeUnmount, watch } from 'vue';
import { useLineHistoryStore } from '../stores/lineHistory.js';
import { diseaseCaption, rainfallCaption } from '../helpers/evidence.js';
import WeekCharts from './WeekCharts.vue';

const props = defineProps({
  line: { type: String, default: '' },
  week: { type: String, default: '' },
  refreshKey: { type: String, default: '' },
});

const store = useLineHistoryStore();
const load = () => store.load(props.line, props.week);
watch(() => [props.line, props.week], load, { immediate: true });
watch(() => props.refreshKey, (phase) => {
  if (['proposal', 'monitoring', 'review'].includes(phase)) load();
});
onBeforeUnmount(() => store.load('', ''));

const selectedWeek = computed(() => store.weeks.find((week) => week.week === props.week) ?? null);
const evidence = computed(() => (store.evidence?.week === props.week ? store.evidence : null));
const rainfall = computed(() => evidence.value?.rainfall ?? null);
const risk = computed(() => {
  if (rainfall.value?.favourable === true) return 'Favourable';
  if (rainfall.value?.favourable === false) return 'Not favourable';
  return 'Not assessed';
});
const rainContext = computed(() => rainfall.value
  ? rainfallCaption({ rainfall: rainfall.value })
  : 'No completed weather assessment is available for this scan week.');
const diseaseContext = computed(() => evidence.value
  ? diseaseCaption({ weeks: evidence.value.weeks ?? store.weeks, disease: evidence.value.disease })
  : 'Disease and weather evidence will be available after the scheduler assesses this week.');
</script>

<template>
  <section class="weather-layout" aria-label="Weather and risk">
    <div class="main-column">
      <div class="notice">
        Weather information is limited to recorded weekly rainfall and completed assessment evidence.
        Forecast, humidity, and leaf-wetness data are not currently provided by the scheduler.
      </div>

      <p v-if="store.phase === 'loading'" class="hint" role="status">Loading weather and line data…</p>
      <p v-else-if="store.phase === 'error'" class="error" role="alert">
        {{ store.error }} <button type="button" @click="load">Try again</button>
      </p>
      <template v-else-if="store.phase === 'ready'">
        <p v-if="store.statusError" class="error" role="alert">Line status could not be loaded: {{ store.statusError }}</p>
        <div class="metrics">
          <article class="metric">
            <span>Recorded rainfall</span>
            <strong>{{ selectedWeek?.rainfall_mm == null ? '—' : `${selectedWeek.rainfall_mm} mm` }}</strong>
            <small>{{ selectedWeek ? `${week} · weekly total` : 'No rainfall value recorded for this week' }}</small>
          </article>
          <article class="metric unavailable">
            <span>Humidity</span><strong>Unavailable</strong>
            <small>Not supplied by the scheduler</small>
          </article>
          <article class="metric unavailable">
            <span>Leaf wetness</span><strong>Unavailable</strong>
            <small>Not supplied by the scheduler</small>
          </article>
        </div>

        <div class="insights">
          <article class="card risk-card">
            <div class="card-heading">
              <h2>Weather risk signal</h2>
              <span class="badge" :class="{ known: rainfall }">{{ rainfall ? 'Assessment evidence' : 'Not assessed' }}</span>
            </div>
            <strong class="risk-value" :class="{ favourable: rainfall?.favourable === true, unfavourable: rainfall?.favourable === false }">{{ risk }}</strong>
            <p>{{ rainContext }}</p>
            <p class="fine">This indicates whether recorded rainfall favours disease spread; it is not a forecast or probability of infection.</p>
          </article>

          <article class="card">
            <h2>What is driving the assessment</h2>
            <p>{{ diseaseContext }}</p>
            <p>{{ rainContext }}</p>
          </article>
        </div>

        <p v-if="store.evidenceError" class="error" role="alert">Assessment evidence could not be loaded: {{ store.evidenceError }}</p>
        <WeekCharts v-if="store.weeks.length && !evidence" :weeks="store.weeks" />
        <p v-else class="hint">No weekly history is available to chart for this line.</p>
      </template>
    </div>

    <aside class="card line-summary" aria-label="Selected line summary">
      <p class="eyebrow">Selected scan</p>
      <h2>Line {{ line }} · {{ week }}</h2>
      <div class="summary-row"><span>YLS</span><b>{{ selectedWeek?.yls ?? '—' }}</b></div>
      <div class="summary-row"><span>YLI</span><b>{{ selectedWeek?.yli ?? '—' }}</b></div>
      <div class="summary-row"><span>Infection risk</span><b>{{ risk }}</b></div>
      <div class="summary-row">
        <span>Last treatment</span>
        <b>{{ store.appliedProposal ? (store.treatment?.name ?? 'Recorded application') : 'None recorded' }}</b>
      </div>
      <div class="summary-row"><span>Functional leaves</span><b>Not recorded</b></div>
      <p class="fine">Risk is not assessed when completed weather evidence is unavailable.</p>
      <p class="disclaimer">This information is context for review, not a confirmed diagnosis or treatment recommendation.</p>
    </aside>
  </section>
</template>

<style scoped>
.weather-layout { display: grid; grid-template-columns: minmax(0, 1fr) minmax(250px, 320px); gap: 20px; align-items: start; }
.main-column { min-width: 0; display: grid; gap: 14px; }
.notice { padding: 12px 16px; border-radius: 12px; background: var(--warn-tint); color: var(--warn); font-size: .9rem; line-height: 1.5; }
.metrics { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; }
.metric, .card { min-width: 0; padding: 16px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); box-shadow: var(--shadow); }
.metric { display: grid; align-content: start; gap: 5px; }
.metric > span, .eyebrow { color: var(--ink-soft); font-size: .76rem; font-weight: 700; letter-spacing: .04em; text-transform: uppercase; }
.metric strong { color: var(--forest); font-size: 1.5rem; }
.metric small, .fine, .disclaimer { color: var(--ink-soft); font-size: .78rem; line-height: 1.45; }
.metric.unavailable strong { color: var(--ink-soft); font-size: 1rem; }
.insights { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
.card h2 { margin: 0; color: var(--forest); font: 700 1rem var(--font-display); }
.card p { font-size: .9rem; line-height: 1.5; }
.card-heading { display: flex; justify-content: space-between; align-items: center; gap: 10px; }
.badge { flex: none; padding: 4px 10px; border-radius: 999px; background: var(--beige); color: var(--ink-soft); font-size: .72rem; font-weight: 700; }
.badge.known { background: var(--tint); color: var(--forest); }
.risk-value { display: block; margin: 10px 0; color: var(--ink-soft); font-size: 2rem; }
.risk-value.favourable { color: var(--warn); }
.risk-value.unfavourable { color: var(--forest); }
.risk-card p { margin: 8px 0; }
.line-summary { position: sticky; top: 16px; }
.eyebrow { margin: 0 0 6px; }
.line-summary h2 { margin-bottom: 12px; }
.summary-row { display: flex; justify-content: space-between; gap: 12px; padding: 10px 0; border-top: 1px solid var(--line); font-size: .9rem; }
.summary-row span { color: var(--ink-soft); }
.summary-row b { text-align: right; }
.disclaimer { margin: 12px 0 0; padding-top: 10px; border-top: 1px solid var(--line); }
.hint { color: var(--ink-soft); }
.error { color: var(--danger); }
.error button { margin-left: 8px; }
@media (max-width: 800px) {
  .weather-layout { grid-template-columns: minmax(0, 1fr); }
  .line-summary { position: static; }
}
@media (max-width: 580px) {
  .metrics, .insights { grid-template-columns: minmax(0, 1fr); }
}
</style>
