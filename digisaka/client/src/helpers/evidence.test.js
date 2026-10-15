import { describe, it, expect } from 'vitest';
import { diseaseCaption, rainfallCaption, verdictText, missingWeeks, linePath, niceMax } from './evidence.js';

const weeks = [
  { week: '2026-W22', yls: 7, yli: 4, rainfall_mm: 10 },
  { week: '2026-W23', yls: 6, yli: null, rainfall_mm: 30 },
  { week: '2026-W24', yls: 5, yli: 3, rainfall_mm: null },
];
const ev = (over = {}) => ({
  weeks,
  disease: { worsening_direction: 'lower', consecutive_weeks: 2, compared_weeks: ['2026-W22', '2026-W23', '2026-W24'], worsening: true },
  rainfall: { window_weeks: 2, min_total_mm: 0, recent_weeks: ['2026-W23', '2026-W24'], previous_weeks: ['2026-W21', '2026-W22'], recent_total_mm: 84, previous_total_mm: 52, favourable: true },
  ...over,
});

describe('diseaseCaption', () => {
  it('describes a fall over the compared weeks', () => {
    expect(diseaseCaption(ev())).toBe('YLS fell two weeks in a row (7 to 6 to 5).');
  });
  it('says it was not falling when the disease is not worsening', () => {
    expect(diseaseCaption(ev({ disease: { ...ev().disease, worsening: false } }))).toBe('YLS did not fall two weeks in a row (7, 6, 5).');
  });
  it('says there is not enough data when not computable', () => {
    expect(diseaseCaption(ev({ disease: { ...ev().disease, worsening: 'not_computable', compared_weeks: [] } }))).toBe('Not enough scan history to compare YLS week to week.');
  });
});

describe('rainfallCaption', () => {
  it('compares the recent and previous totals', () => {
    expect(rainfallCaption(ev())).toBe('Rain over the last 2 weeks: 84 mm, up from 52 mm.');
  });
  it('says down when it fell', () => {
    expect(rainfallCaption(ev({ rainfall: { ...ev().rainfall, recent_total_mm: 20 } }))).toBe('Rain over the last 2 weeks: 20 mm, down from 52 mm.');
  });
  it('says not enough data when not computable', () => {
    expect(rainfallCaption(ev({ rainfall: { ...ev().rainfall, favourable: 'not_computable', recent_total_mm: null, previous_total_mm: null } }))).toBe('Not enough rainfall data to compare the last 2 weeks.');
  });
});

describe('verdictText', () => {
  it('maps the three states', () => {
    expect(verdictText(true)).toBe('yes');
    expect(verdictText(false)).toBe('no');
    expect(verdictText('not_computable')).toBe('not enough data');
  });
});

describe('missingWeeks', () => {
  it('lists weeks missing a yls, yli or rainfall value', () => {
    expect(missingWeeks(weeks)).toEqual({ yls: [], yli: ['2026-W23'], rainfall_mm: ['2026-W24'] });
  });
});

describe('linePath', () => {
  it('breaks the line at a null instead of filling it', () => {
    expect(linePath([{ x: 0, y: 1 }, { x: 10, y: 2 }, null, { x: 30, y: 4 }])).toBe('M0 1L10 2M30 4');
  });
  it('is empty when there are no points', () => { expect(linePath([null, null])).toBe(''); });
});

describe('niceMax', () => {
  it('rounds up to a round number', () => {
    expect(niceMax(84)).toBe(100);
    expect(niceMax(7)).toBe(8);
    expect(niceMax(0)).toBe(1);
  });
});
