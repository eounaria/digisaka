<script setup>
import { computed, watch, onBeforeUnmount } from 'vue';
import { useEvidenceStore } from '../stores/evidence.js';
import { diseaseCaption, rainfallCaption, verdictText, missingWeeks, linePath, niceMax } from '../helpers/evidence.js';

// What the rules looked at: weekly YLS/YLI and rainfall for one cycle, drawn as plain SVG.
const props = defineProps({ cycleId: { type: String, default: '' } });
const store = useEvidenceStore();
const load = () => (props.cycleId ? store.load(props.cycleId) : store.reset());
watch(() => props.cycleId, load, { immediate: true });
onBeforeUnmount(() => store.reset());

const W = 320, H = 150, L = 34, R = 10, T = 10, B = 28;
const ev = computed(() => (store.phase === 'ready' ? store.evidence : null));
const weeks = computed(() => ev.value?.weeks ?? []);
const label = (w) => `W${w.slice(-2)}`;
const x = (i) => (weeks.value.length < 2 ? (L + W - R) / 2 : L + (i * (W - L - R)) / (weeks.value.length - 1));

// Disease chart: the axis runs so that the worsening direction is always down.
const lowerIsWorse = computed(() => ev.value?.disease.worsening_direction !== 'higher');
const diseaseValues = computed(() => weeks.value.flatMap((w) => [w.yls, w.yli]).filter((v) => v != null));
const lo = computed(() => Math.min(...diseaseValues.value, 0));
const hi = computed(() => Math.max(...diseaseValues.value, 1));
const yD = (v) => {
  const t = (v - lo.value) / (hi.value - lo.value || 1);
  return T + (lowerIsWorse.value ? 1 - t : t) * (H - T - B);
};
const series = (key) => weeks.value.map((w, i) => (w[key] == null ? null : { x: x(i), y: yD(w[key]) }));
const ylsPts = computed(() => series('yls'));
const yliPts = computed(() => series('yli'));
const compared = computed(() => new Set(ev.value?.disease.compared_weeks ?? []));
const ticks = computed(() => [lo.value, Math.round((lo.value + hi.value) / 2), hi.value]);

// Rainfall chart.
const rainTop = computed(() => niceMax(Math.max(0, ...weeks.value.map((w) => w.rainfall_mm ?? 0), ev.value?.rainfall.min_total_mm ?? 0)));
const yR = (v) => T + (1 - v / rainTop.value) * (H - T - B);
const barW = computed(() => Math.min(24, ((W - L - R) / Math.max(weeks.value.length, 1)) * 0.6));
const group = (w) => (ev.value.rainfall.recent_weeks.includes(w) ? 'recent' : ev.value.rainfall.previous_weeks.includes(w) ? 'previous' : 'other');
const minLine = computed(() => ev.value?.rainfall.min_total_mm > 0 ? ev.value.rainfall.min_total_mm / Math.max(ev.value.rainfall.window_weeks, 1) : 0);

const missing = computed(() => missingWeeks(weeks.value));
const missingText = computed(() => {
  const parts = [['YLS', 'yls'], ['YLI', 'yli'], ['Rainfall', 'rainfall_mm']].filter(([, k]) => missing.value[k].length).map(([n, k]) => `${n}: ${missing.value[k].join(', ')}`);
  return parts.length ? `Missing weeks — ${parts.join('; ')}.` : '';
});
const dCap = computed(() => (ev.value ? diseaseCaption(ev.value) : ''));
const rCap = computed(() => (ev.value ? rainfallCaption(ev.value) : ''));
const cell = (v) => (v == null ? '—' : v);
</script>

<template>
  <section v-if="store.phase === 'loading' || store.phase === 'error' || ev" class="evidence" aria-label="Evidence">
    <h3>What the system looked at</h3>
    <p v-if="store.phase === 'loading'" class="hint">Loading the evidence…</p>
    <p v-else-if="store.phase === 'error'" class="err">{{ store.error }} <button class="mark" type="button" @click="load">Try again</button></p>
    <template v-else-if="ev && weeks.length">
      <div class="chips">
        <span class="chip" :class="String(ev.disease.worsening)">Disease getting worse: {{ verdictText(ev.disease.worsening) }}</span>
        <span class="chip" :class="String(ev.rainfall.favourable)">Rainfall favours spread: {{ verdictText(ev.rainfall.favourable) }}</span>
      </div>

      <figure>
        <figcaption>Leaf-spot stage (YLS) by week <small>— {{ lowerIsWorse ? 'lower = disease on a younger leaf' : 'higher = disease on a younger leaf' }}, so worsening goes down</small></figcaption>
        <svg :viewBox="`0 0 ${W} ${H}`" role="img" :aria-label="dCap">
          <g class="axis">
            <template v-for="t in ticks" :key="t"><line :x1="L" :x2="W - R" :y1="yD(t)" :y2="yD(t)" /><text :x="L - 6" :y="yD(t) + 3" text-anchor="end">{{ t }}</text></template>
            <text v-for="(w, i) in weeks" :key="w.week" :x="x(i)" :y="H - 10" text-anchor="middle">{{ label(w.week) }}</text>
          </g>
          <path class="yli" :d="linePath(yliPts)" />
          <path class="yls" :d="linePath(ylsPts)" />
          <template v-for="(p, i) in ylsPts" :key="weeks[i].week">
            <circle v-if="p" :cx="p.x" :cy="p.y" :r="compared.has(weeks[i].week) ? 5 : 3" :class="['dot', { hi: compared.has(weeks[i].week) }]" />
          </template>
        </svg>
        <p class="cap">{{ dCap }} <span class="soft">YLI (lighter line) is shown for context and is not part of the decision.</span></p>
      </figure>

      <figure>
        <figcaption>Rainfall by week (mm)</figcaption>
        <svg :viewBox="`0 0 ${W} ${H}`" role="img" :aria-label="rCap">
          <g class="axis">
            <template v-for="t in [0, rainTop / 2, rainTop]" :key="t"><line :x1="L" :x2="W - R" :y1="yR(t)" :y2="yR(t)" /><text :x="L - 6" :y="yR(t) + 3" text-anchor="end">{{ t }}</text></template>
            <text v-for="(w, i) in weeks" :key="w.week" :x="x(i)" :y="H - 10" text-anchor="middle">{{ label(w.week) }}</text>
          </g>
          <template v-for="(w, i) in weeks" :key="w.week">
            <rect v-if="w.rainfall_mm != null" :class="['bar', group(w.week)]" :x="x(i) - barW / 2" :y="yR(w.rainfall_mm)" :width="barW" :height="yR(0) - yR(w.rainfall_mm)" />
          </template>
          <line v-if="minLine" class="min" :x1="L" :x2="W - R" :y1="yR(minLine)" :y2="yR(minLine)" />
        </svg>
        <p class="legend"><i class="sw recent"></i>Last {{ ev.rainfall.window_weeks }} weeks <i class="sw previous"></i>Weeks before <span v-if="minLine"><i class="sw minsw"></i>Minimum per week</span></p>
        <p class="cap">{{ rCap }}</p>
      </figure>

      <p v-if="missingText" class="cap soft">{{ missingText }}</p>
      <details>
        <summary>Show the numbers</summary>
        <table>
          <thead><tr><th>Week</th><th>YLS</th><th>YLI</th><th>Rain (mm)</th></tr></thead>
          <tbody><tr v-for="w in weeks" :key="w.week"><td>{{ w.week }}</td><td>{{ cell(w.yls) }}</td><td>{{ cell(w.yli) }}</td><td>{{ cell(w.rainfall_mm) }}</td></tr></tbody>
        </table>
      </details>
    </template>
  </section>
</template>

<style scoped>
.evidence { background: var(--card); border: 1px solid var(--line); border-radius: var(--radius-md); padding: 16px; margin-top: 14px; box-shadow: var(--shadow); }
h3 { margin: 0 0 10px; font-size: 1rem; }
.chips { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 10px; }
.chip { font-size: .85rem; padding: 4px 10px; border-radius: 999px; background: var(--tint); color: var(--forest-deep); }
.chip.true { background: var(--warn-tint); color: var(--warn); }
.chip.not_computable { background: var(--beige); color: var(--ink-soft); }
figure { margin: 12px 0 0; }
figcaption { font-weight: 600; font-size: .9rem; }
figcaption small { font-weight: 400; color: var(--ink-soft); }
svg { width: 100%; height: auto; display: block; margin-top: 6px; }
.axis line { stroke: var(--line); }
.axis text { fill: var(--ink-soft); font-size: 9px; }
path { fill: none; stroke-linejoin: round; stroke-linecap: round; }
.yls { stroke: var(--forest); stroke-width: 2.5; }
.yli { stroke: var(--leaf-soft); stroke-width: 2; }
.dot { fill: var(--forest); }
.dot.hi { fill: var(--warn); stroke: var(--card); stroke-width: 1.5; }
.bar.recent { fill: var(--teal); }
.bar.previous { fill: var(--leaf-soft); }
.bar.other { fill: var(--line); }
.min { stroke: var(--danger); stroke-dasharray: 4 3; }
.cap { margin: 6px 0 0; font-size: .9rem; }
.soft, .hint { color: var(--ink-soft); }
.legend { font-size: .8rem; color: var(--ink-soft); margin: 4px 0 0; }
.sw { display: inline-block; width: 10px; height: 10px; border-radius: 2px; margin: 0 4px 0 8px; vertical-align: baseline; }
.sw:first-child { margin-left: 0; }
.sw.recent { background: var(--teal); }
.sw.previous { background: var(--leaf-soft); }
.sw.minsw { background: var(--danger); }
details { margin-top: 10px; font-size: .85rem; }
table { border-collapse: collapse; margin-top: 6px; }
th, td { padding: 3px 12px 3px 0; text-align: left; }
.err { color: var(--danger); }
</style>
