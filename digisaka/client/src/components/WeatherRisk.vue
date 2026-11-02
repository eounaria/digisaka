<script setup>
import { computed, onBeforeUnmount, watch } from 'vue';
import { useLineHistoryStore } from '../stores/lineHistory.js';
import { usePrototypeStore } from '../stores/prototype.js';
import { diseaseCaption, rainfallCaption } from '../helpers/evidence.js';

const props = defineProps({
  line: { type: String, default: '' },
  week: { type: String, default: '' },
  refreshKey: { type: String, default: '' },
});

const store = useLineHistoryStore();
const prototypeStore = usePrototypeStore();
const load = () => store.load(props.line, props.week);
watch(() => [props.line, props.week], () => {
  load();
  prototypeStore.load(props.line, props.week);
}, { immediate: true });
watch(() => props.refreshKey, (phase) => {
  if (['proposal', 'monitoring', 'review'].includes(phase)) load();
});
onBeforeUnmount(() => store.load('', ''));

const selectedWeek = computed(() => store.weeks.find((week) => week.week === props.week) ?? null);
const evidence = computed(() => (store.evidence?.week === props.week ? store.evidence : null));
const rainfall = computed(() => evidence.value?.rainfall ?? null);
const prototype = computed(() => (prototypeStore.phase === 'ready' ? prototypeStore.data : null));
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
      <div v-if="prototype" class="notice sample-notice">{{ prototype.label }}</div>
      <p v-else-if="prototypeStore.phase === 'loading'" class="hint" role="status">Loading prototype weather data…</p>
      <p v-else-if="prototypeStore.phase === 'error'" class="error" role="alert">Prototype weather data could not be loaded: {{ prototypeStore.error }}</p>
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
          <article v-if="prototype" class="metric sample-metric">
            <span>Rainfall · sample</span>
            <strong>{{ prototype.weather.rainfall_7d_mm }} mm</strong>
            <small>Past 7 days · illustrative value</small>
          </article>
          <article v-else class="metric">
            <span>Recorded rainfall</span>
            <strong>{{ selectedWeek?.rainfall_mm == null ? '—' : `${selectedWeek.rainfall_mm} mm` }}</strong>
            <small>{{ selectedWeek ? `${week} · weekly total` : 'No rainfall value recorded for this week' }}</small>
          </article>
          <article v-if="prototype" class="metric sample-metric">
            <span>Humidity · sample</span>
            <strong>{{ prototype.weather.humidity_average_pct }}%</strong>
            <small>Average · illustrative value</small>
          </article>
          <article v-if="prototype" class="metric sample-metric">
            <span>Leaf wetness · sample</span>
            <strong>{{ prototype.weather.leaf_wetness_hours_daily }} hours</strong>
            <small>Per day · illustrative value</small>
          </article>
          <article v-if="!prototype" class="metric unavailable">
            <span>Humidity</span><strong>Unavailable</strong>
            <small>Not supplied by the scheduler</small>
          </article>
          <article v-if="!prototype" class="metric unavailable">
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
            <div class="recorded-rainfall">
              <span>Recorded rainfall · {{ week }}</span>
              <strong>{{ selectedWeek?.rainfall_mm == null ? '—' : `${selectedWeek.rainfall_mm} mm` }}</strong>
            </div>
            <p class="fine">This indicates whether recorded rainfall favours disease spread; it is not a forecast or probability of infection.</p>
            <template v-if="prototype">
              <div class="sample-risk"><span>Prototype infection risk</span><strong>{{ prototype.weather.infection_risk }}</strong></div>
              <div class="forecast">
                <div v-for="day in prototype.weather.forecast" :key="day.day">
                  <span>{{ day.day }}</span><strong>{{ day.rainfall_mm }} mm</strong>
                </div>
              </div>
              <p class="fine">Sample forecast: rain on {{ prototype.weather.forecast_rain_days }} of the next 5 days. Not a live forecast.</p>
            </template>
          </article>

          <article class="card">
            <h2>What is driving the assessment</h2>
            <p>{{ diseaseContext }}</p>
            <p>{{ rainContext }}</p>
          </article>
        </div>

        <p v-if="store.evidenceError" class="error" role="alert">Assessment evidence could not be loaded: {{ store.evidenceError }}</p>
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
      <div v-if="prototype" class="action-summary">
        <h3>Recommended action</h3>
        <div class="action-chips">
          <span class="action-chip preventive" :class="{ active: prototype.recommended_action.preventive }">{{ prototype.recommended_action.preventive ? '✓ ' : '' }}Preventive</span>
          <span class="action-chip mechanical" :class="{ active: prototype.recommended_action.mechanical }">{{ prototype.recommended_action.mechanical ? '✓ ' : '' }}Mechanical</span>
          <span class="action-chip treatment" :class="{ active: prototype.recommended_action.treatment }">{{ prototype.recommended_action.treatment ? '✓ ' : '' }}Treatment</span>
          <span class="action-chip monitor" :class="{ active: prototype.recommended_action.monitor }">{{ prototype.recommended_action.monitor ? '✓ ' : '' }}Monitor</span>
          <span class="action-chip provisional">{{ prototype.recommended_action.provisional_label }}</span>
        </div>
        <p>{{ prototype.recommended_action.summary }}</p>
        <small>Sample action · not a treatment recommendation</small>
      </div>
      <p class="fine">Risk is not assessed when completed weather evidence is unavailable.</p>
      <p class="disclaimer">This information is context for review, not a confirmed diagnosis or treatment recommendation.</p>
    </aside>
  </section>
</template>

<style scoped>
.weather-layout { display: grid; grid-template-columns: minmax(0, 1fr) minmax(250px, 320px); gap: 20px; align-items: start; }
.main-column { min-width: 0; display: grid; gap: 14px; }
.notice { padding: 12px 16px; border-radius: 12px; background: var(--warn-tint); color: var(--warn); font-size: .9rem; line-height: 1.5; }
.sample-notice { background: #e5e7eb; color: #374151; font-weight: 700; }
.metrics { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; }
.metric, .card { min-width: 0; padding: 16px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); box-shadow: var(--shadow); }
.metric { display: grid; align-content: start; gap: 5px; }
.metric > span, .eyebrow { color: var(--ink-soft); font-size: .76rem; font-weight: 700; letter-spacing: .04em; text-transform: uppercase; }
.metric strong { color: var(--forest); font-size: 1.5rem; }
.metric small, .fine, .disclaimer { color: var(--ink-soft); font-size: .78rem; line-height: 1.45; }
.metric.unavailable strong { color: var(--ink-soft); font-size: 1rem; }
.sample-metric { border-color: #e3c36f; }
.sample-risk { display: flex; justify-content: space-between; gap: 12px; margin-top: 12px; padding: 10px 12px; border-radius: 10px; background: var(--warn-tint); color: var(--warn); }
.forecast { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 5px; margin-top: 10px; text-align: center; }
.forecast > div { display: grid; gap: 3px; padding: 8px 2px; border-radius: 8px; background: var(--tint); font-size: .76rem; }
.forecast span { color: var(--ink-soft); }
.insights { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
.insights > .card:not(.risk-card) { display: grid; align-content: start; gap: 10px; }
.card h2 { margin: 0; color: var(--forest); font: 700 1rem var(--font-display); }
.card p { font-size: .9rem; line-height: 1.5; }
.card-heading { display: flex; justify-content: space-between; align-items: center; gap: 10px; }
.badge { flex: none; padding: 4px 10px; border-radius: 999px; background: var(--beige); color: var(--ink-soft); font-size: .72rem; font-weight: 700; }
.badge.known { background: var(--tint); color: var(--forest); }
.risk-value { display: block; margin: 10px 0; color: var(--ink-soft); font-size: 2rem; }
.risk-value.favourable { color: var(--warn); }
.risk-value.unfavourable { color: var(--forest); }
.risk-card p { margin: 8px 0; }
.recorded-rainfall { display: flex; justify-content: space-between; align-items: center; gap: 12px; padding: 9px 0; border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); color: var(--ink-soft); font-size: .82rem; }
.recorded-rainfall strong { color: var(--ink); font-size: .9rem; }
.line-summary { position: sticky; top: 16px; }
.eyebrow { margin: 0 0 6px; }
.line-summary h2 { margin-bottom: 12px; }
.summary-row { display: flex; justify-content: space-between; gap: 12px; padding: 10px 0; border-top: 1px solid var(--line); font-size: .9rem; }
.summary-row span { color: var(--ink-soft); }
.summary-row b { text-align: right; }
.action-summary { display: grid; gap: 9px; margin-top: 8px; padding-top: 14px; border-top: 1px solid var(--line); }
.action-summary h3 { margin: 0; color: var(--forest); font: 700 .9rem var(--font-display); }
.action-summary p { font-size: .86rem; line-height: 1.45; }
.action-summary small { color: var(--ink-soft); font-size: .74rem; }
.action-chips { display: flex; flex-wrap: wrap; gap: 6px; }
.action-chip { padding: 4px 9px; border-radius: 999px; font-size: .72rem; font-weight: 800; }
.action-chip.preventive.active { background: #dcefff; color: #0b4f8a; }
.action-chip.mechanical.active { background: #e3f4e6; color: #0b5a1f; }
.action-chip.treatment.active { background: var(--warn-tint); color: var(--warn); }
.action-chip.monitor.active { background: var(--tint); color: var(--forest); }
.action-chip.provisional { background: var(--beige); color: var(--ink-soft); }
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
