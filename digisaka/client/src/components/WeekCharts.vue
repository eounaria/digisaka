<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import { diseaseCaption, rainfallCaption, missingWeeks, linePath, niceMax } from '../helpers/evidence.js';

// Weekly YLS/YLI and rainfall as plain SVG. With `disease` and `rainfall` (a cycle's evidence) the compared
// weeks are highlighted and captioned; without them it is a plain look at recent weeks.
const props = defineProps({ weeks: { type: Array, required: true }, disease: { type: Object, default: null }, rainfall: { type: Object, default: null } });

const W = 320, H = 150, L = 34, R = 10, T = 10, B = 28, RAIN_L = 46;
const hoveredPoint = ref(null);
const diseaseTooltipText = ref(null), rainfallTooltipText = ref(null);
const tooltipWidth = ref(0);
const weeks = computed(() => props.weeks);
const label = (w) => `W${w.slice(-2)}`;
const x = (i) => (weeks.value.length < 2 ? (L + W - R) / 2 : L + (i * (W - L - R)) / (weeks.value.length - 1));
const pointDetails = (chart, w, seriesName, value, pointX, pointY) => ({
  chart, key: `${chart}-${w.week}-${seriesName}`, week: w.week, seriesName, value, x: pointX, y: pointY,
});
const activePoint = computed(() => hoveredPoint.value);
const hoverPoint = (...args) => { hoveredPoint.value = pointDetails(...args); };
const clearHover = (chart, key) => {
  if (hoveredPoint.value?.chart === chart && (!key || hoveredPoint.value.key === key)) hoveredPoint.value = null;
};
const clearChartHover = (chart) => clearHover(chart);
const tooltipX = computed(() => {
  const half = tooltipWidth.value / 2;
  return Math.max(half + 4, Math.min(W - half - 4, activePoint.value?.x ?? 0));
});
const tooltipY = computed(() => Math.max(20, (activePoint.value?.y ?? 0) - 13));
const pointText = computed(() => activePoint.value
  ? `${activePoint.value.week} · ${activePoint.value.seriesName}: ${activePoint.value.value}${activePoint.value.chart === 'rainfall' ? ' mm' : ''}`
  : '');
watch(pointText, async (text) => {
  await nextTick();
  const element = activePoint.value?.chart === 'rainfall' ? rainfallTooltipText.value : diseaseTooltipText.value;
  tooltipWidth.value = text && element
    ? element.getComputedTextLength() + 12
    : 0;
});

// Disease chart: the axis runs so that the worsening direction is always down.
const lowerIsWorse = computed(() => props.disease?.worsening_direction !== 'higher');
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
const compared = computed(() => new Set(props.disease?.compared_weeks ?? []));
const ticks = computed(() => [lo.value, Math.round((lo.value + hi.value) / 2), hi.value]);

// Rainfall chart.
const rainTop = computed(() => niceMax(Math.max(0, ...weeks.value.map((w) => w.rainfall_mm ?? 0), props.rainfall?.min_total_mm ?? 0)));
const rainX = (i) => (weeks.value.length < 2 ? (RAIN_L + W - R) / 2 : RAIN_L + (i * (W - RAIN_L - R)) / (weeks.value.length - 1));
const yR = (v) => T + (1 - v / rainTop.value) * (H - T - B);
const barW = computed(() => Math.min(24, ((W - RAIN_L - R) / Math.max(weeks.value.length, 1)) * 0.6));
const group = (w) => (!props.rainfall || props.rainfall.recent_weeks.includes(w) ? 'recent' : props.rainfall.previous_weeks.includes(w) ? 'previous' : 'other');
const minLine = computed(() => (props.rainfall?.min_total_mm > 0 ? props.rainfall.min_total_mm / Math.max(props.rainfall.window_weeks, 1) : 0));

const missing = computed(() => missingWeeks(weeks.value));
const missingText = computed(() => {
  const parts = [['YLS', 'yls'], ['YLI', 'yli'], ['Rainfall', 'rainfall_mm']].filter(([, k]) => missing.value[k].length).map(([n, k]) => `${n}: ${missing.value[k].join(', ')}`);
  return parts.length ? `Missing weeks — ${parts.join('; ')}.` : '';
});
const dCap = computed(() => (props.disease ? diseaseCaption({ weeks: weeks.value, disease: props.disease }) : ''));
const rCap = computed(() => (props.rainfall ? rainfallCaption({ rainfall: props.rainfall }) : ''));
const dLabel = computed(() => dCap.value || 'YLS and YLI by week');
const rLabel = computed(() => rCap.value || 'Rainfall by week');
const cell = (v) => (v == null ? '—' : v);</script>

<template>
  <div>
  <figure>
    <figcaption>Leaf-spot stage (YLS) by week <small>— {{ lowerIsWorse ? 'lower = disease on a younger leaf' : 'higher = disease on a younger leaf' }}, so worsening goes down</small></figcaption>
    <svg :viewBox="`0 0 ${W} ${H}`" role="group" :aria-label="dLabel" @pointerleave="clearChartHover('disease')">
      <g class="axis">
        <template v-for="t in ticks" :key="t"><line :x1="L" :x2="W - R" :y1="yD(t)" :y2="yD(t)" /><text :x="L - 6" :y="yD(t) + 3" text-anchor="end">{{ t }}</text></template>
        <text v-for="(w, i) in weeks" :key="w.week" :x="x(i)" :y="H - 10" text-anchor="middle">{{ label(w.week) }}</text>
      </g>
      <path class="yli" :d="linePath(yliPts)" />
      <path class="yls" :d="linePath(ylsPts)" />
      <template v-for="(w, i) in weeks" :key="w.week">
        <circle v-if="ylsPts[i]" :cx="ylsPts[i].x" :cy="ylsPts[i].y" :r="compared.has(w.week) ? 5 : 3" :class="['dot', 'yls-dot', { hi: compared.has(w.week) }]"
                @pointerenter="hoverPoint('disease', w, 'YLS', w.yls, ylsPts[i].x, ylsPts[i].y)"
                @pointerleave="clearHover('disease', `disease-${w.week}-YLS`)">
          <title>{{ w.week }} · YLS: {{ w.yls }}</title>
        </circle>
        <circle v-if="yliPts[i]" :cx="yliPts[i].x" :cy="yliPts[i].y" r="3" class="dot yli-dot"
                @pointerenter="hoverPoint('disease', w, 'YLI', w.yli, yliPts[i].x, yliPts[i].y)"
                @pointerleave="clearHover('disease', `disease-${w.week}-YLI`)">
          <title>{{ w.week }} · YLI: {{ w.yli }}</title>
        </circle>
      </template>
      <g v-if="activePoint?.chart === 'disease'" class="tooltip" aria-hidden="true">
        <rect :x="tooltipX - tooltipWidth / 2" :y="tooltipY - 9" :width="tooltipWidth" height="18" rx="4" />
        <text ref="diseaseTooltipText" :x="tooltipX" :y="tooltipY + 2.5">{{ pointText }}</text>
      </g>
    </svg>
    <p class="sr-only" aria-live="polite">{{ activePoint?.chart === 'disease' ? pointText : '' }}</p>
    <p v-if="dCap" class="cap">{{ dCap }} <span class="soft">YLI (lighter line) is shown for context and is not part of the decision.</span></p>
    <p v-else class="cap soft">YLI (lighter line) is shown for context.</p>
  </figure>

  <figure>
    <figcaption>Rainfall by week (mm)</figcaption>
    <svg :viewBox="`0 0 ${W} ${H}`" role="group" :aria-label="rLabel" @pointerleave="clearChartHover('rainfall')">
      <g class="axis">
        <template v-for="t in [0, rainTop / 2, rainTop]" :key="t"><line :x1="RAIN_L" :x2="W - R" :y1="yR(t)" :y2="yR(t)" /><text :x="L - 6" :y="yR(t) + 3" text-anchor="end">{{ t }}</text></template>
        <text v-for="(w, i) in weeks" :key="w.week" :x="rainX(i)" :y="H - 10" text-anchor="middle">{{ label(w.week) }}</text>
      </g>
      <template v-for="(w, i) in weeks" :key="w.week">
        <rect v-if="w.rainfall_mm != null" :class="['bar', group(w.week)]" :x="rainX(i) - barW / 2" :y="yR(w.rainfall_mm)" :width="barW" :height="yR(0) - yR(w.rainfall_mm)"
              @pointerenter="hoverPoint('rainfall', w, 'Rainfall', w.rainfall_mm, rainX(i), yR(w.rainfall_mm))"
              @pointerleave="clearHover('rainfall', `rainfall-${w.week}-Rainfall`)">
          <title>{{ w.week }} · Rainfall: {{ w.rainfall_mm }} mm</title>
        </rect>
      </template>
      <line v-if="minLine" class="min" :x1="RAIN_L" :x2="W - R" :y1="yR(minLine)" :y2="yR(minLine)" />
      <g v-if="activePoint?.chart === 'rainfall'" class="tooltip" aria-hidden="true">
        <rect :x="tooltipX - tooltipWidth / 2" :y="tooltipY - 9" :width="tooltipWidth" height="18" rx="4" />
        <text ref="rainfallTooltipText" :x="tooltipX" :y="tooltipY + 2.5">{{ pointText }}</text>
      </g>
    </svg>
    <p class="sr-only" aria-live="polite">{{ activePoint?.chart === 'rainfall' ? pointText : '' }}</p>
    <p v-if="rainfall" class="legend"><i class="sw recent"></i>Last {{ rainfall.window_weeks }} weeks <i class="sw previous"></i>Weeks before <span v-if="minLine"><i class="sw minsw"></i>Minimum per week</span></p>
    <p v-if="rCap" class="cap">{{ rCap }}</p>
  </figure>

  <p v-if="missingText" class="cap soft">{{ missingText }}</p>
  <details>
    <summary>Show the numbers</summary>
    <table>
      <thead><tr><th>Week</th><th>YLS</th><th>YLI</th><th>Rain (mm)</th></tr></thead>
      <tbody><tr v-for="w in weeks" :key="w.week"><td>{{ w.week }}</td><td>{{ cell(w.yls) }}</td><td>{{ cell(w.yli) }}</td><td>{{ cell(w.rainfall_mm) }}</td></tr></tbody>
    </table>
  </details>
  </div>
</template>

<style scoped>
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
.dot { cursor: crosshair; }
.yli-dot { fill: var(--leaf-soft); stroke: var(--forest-deep); stroke-width: .75; }
.dot.hi { fill: var(--warn); stroke: var(--card); stroke-width: 1.5; }
.bar.recent { fill: var(--teal); }
.bar.previous { fill: var(--leaf-soft); }
.bar.other { fill: var(--line); }
.bar { cursor: crosshair; }
.tooltip rect { fill: var(--ink); }
.tooltip text { fill: #fff; font-size: 7px; text-anchor: middle; }
.sr-only { position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0, 0, 0, 0); white-space: nowrap; border: 0; }
.min { stroke: var(--danger); stroke-dasharray: 4 3; }
.cap { margin: 6px 0 0; font-size: .9rem; }
.soft { color: var(--ink-soft); }
.legend { font-size: .8rem; color: var(--ink-soft); margin: 4px 0 0; }
.sw { display: inline-block; width: 10px; height: 10px; border-radius: 2px; margin: 0 4px 0 8px; vertical-align: baseline; }
.sw:first-child { margin-left: 0; }
.sw.recent { background: var(--teal); }
.sw.previous { background: var(--leaf-soft); }
.sw.minsw { background: var(--danger); }
details { margin-top: 10px; font-size: .85rem; }
table { border-collapse: collapse; margin-top: 6px; }
th, td { padding: 3px 12px 3px 0; text-align: left; }
</style>
