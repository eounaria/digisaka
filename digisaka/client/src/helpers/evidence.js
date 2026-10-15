// Plain-words captions and chart geometry for the evidence charts.
const WORD = { 1: 'one week', 2: 'two weeks', 3: 'three weeks' };
const weekWord = (n) => WORD[n] ?? `${n} weeks`;

export const verdictText = (v) => (v === true ? 'yes' : v === false ? 'no' : 'not enough data');

const valueOf = (weeks, week, key) => weeks.find((w) => w.week === week)?.[key];

export function diseaseCaption({ weeks, disease: d }) {
  if (d.worsening === 'not_computable' || !d.compared_weeks?.length) return 'Not enough scan history to compare YLS week to week.';
  const values = d.compared_weeks.map((w) => valueOf(weeks, w, 'yls'));
  const word = weekWord(d.consecutive_weeks);
  const verb = d.worsening_direction === 'lower' ? 'fell' : 'rose';
  return d.worsening
    ? `YLS ${verb} ${word} in a row (${values.join(' to ')}).`
    : `YLS did not ${d.worsening_direction === 'lower' ? 'fall' : 'rise'} ${word} in a row (${values.join(', ')}).`;
}

const mm = (n) => `${Number.isInteger(n) ? n : Math.round(n * 10) / 10} mm`;

export function rainfallCaption({ rainfall: r }) {
  if (r.favourable === 'not_computable' || r.recent_total_mm == null || r.previous_total_mm == null) return `Not enough rainfall data to compare the last ${r.window_weeks} weeks.`;
  const dir = r.recent_total_mm > r.previous_total_mm ? 'up from' : r.recent_total_mm < r.previous_total_mm ? 'down from' : 'the same as';
  return `Rain over the last ${r.window_weeks} weeks: ${mm(r.recent_total_mm)}, ${dir} ${mm(r.previous_total_mm)}.`;
}

export const missingWeeks = (weeks) => Object.fromEntries(['yls', 'yli', 'rainfall_mm'].map((k) => [k, weeks.filter((w) => w[k] == null).map((w) => w.week)]));

// SVG path through points; a null point breaks the line so a missing week stays a gap.
export function linePath(points) {
  let d = '', pen = false;
  for (const p of points) {
    if (!p) { pen = false; continue; }
    d += `${pen ? 'L' : 'M'}${p.x} ${p.y}`; pen = true;
  }
  return d;
}

// Smallest round number at or above v, for a chart axis top.
export function niceMax(v) {
  if (!(v > 0)) return 1;
  const pow = 10 ** Math.floor(Math.log10(v));
  for (const m of [1, 2, 4, 5, 8, 10]) if (m * pow >= v) return m * pow;
  return 10 * pow;
}

// Last three weeks, plus any earlier week the rules compared, so every caption can be checked against the chart.
export function visibleWeeks({ weeks, disease, rainfall }) {
  const used = new Set([...(disease.compared_weeks ?? []), ...(rainfall.recent_weeks ?? []), ...(rainfall.previous_weeks ?? [])]);
  return weeks.filter((w, i) => i >= weeks.length - 3 || used.has(w.week));
}
