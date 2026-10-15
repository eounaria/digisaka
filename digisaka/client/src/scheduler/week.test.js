import { describe, it, expect } from 'vitest';
import { isoWeekOf, previousWeek, nextWeek, isValidWeek } from './week.js';

describe('isoWeekOf', () => {
  it('formats a mid-year date', () => {
    expect(isoWeekOf(new Date(2026, 5, 10))).toBe('2026-W24');
  });
  it('puts early January days of the previous ISO year in its last week', () => {
    expect(isoWeekOf(new Date(2021, 0, 1))).toBe('2020-W53');
  });
  it('puts late December days of the next ISO year in its first week', () => {
    expect(isoWeekOf(new Date(2024, 11, 30))).toBe('2025-W01');
  });
});

describe('previousWeek and nextWeek', () => {
  it('step within a year', () => {
    expect(previousWeek('2026-W24')).toBe('2026-W23');
    expect(nextWeek('2026-W24')).toBe('2026-W25');
  });
  it('cross a 52-week year boundary', () => {
    expect(nextWeek('2026-W52')).toBe('2026-W53');
    expect(previousWeek('2026-W01')).toBe('2025-W52');
  });
  it('cross a 53-week year boundary', () => {
    expect(nextWeek('2020-W53')).toBe('2021-W01');
    expect(previousWeek('2021-W01')).toBe('2020-W53');
  });
});

describe('isValidWeek', () => {
  it('accepts real weeks', () => {
    expect(isValidWeek('2026-W24')).toBe(true);
    expect(isValidWeek('2020-W53')).toBe(true);
  });
  it('rejects malformed values and non-existent weeks', () => {
    for (const v of ['2026-24', '2026-W5', '2026-W00', '2026-W54', '2025-W53', '', null, undefined]) {
      expect(isValidWeek(v)).toBe(false);
    }
  });
});
