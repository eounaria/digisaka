import { describe, it, expect } from 'vitest';
import { todayIso, toIso, fromIso } from './today.js';
import { isoWeekOf } from './week.js';

describe('today', () => {
  it('is a day in 2026-W24, where the stub data ends', () => {
    expect(isoWeekOf(new Date(todayIso() + 'T12:00:00'))).toBe('2026-W24');
  });
  it('round-trips ISO dates without shifting the day', () => {
    expect(toIso(fromIso('2026-06-08'))).toBe('2026-06-08');
  });
});
