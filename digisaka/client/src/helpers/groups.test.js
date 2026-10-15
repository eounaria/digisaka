import { describe, it, expect } from 'vitest';
import { groupLeaves } from './groups.js';

const leaf = (id, outcome, stage = null) => ({ id, outcome, stage });

describe('groupLeaves', () => {
  it('groups treatment leaves by stage label and lists healthy and unvalidated apart', () => {
    const g = groupLeaves([leaf(1, 'treatment_result', 'Stage 3'), leaf(2, 'healthy'), leaf(3, 'treatment_result', 'Stage 2'), leaf(4, 'treatment_result', 'Stage 3'), leaf(5, 'not_leaf'), leaf(6, 'referral')]);
    expect(g.stages.map((s) => [s.label, s.leaves.map((l) => l.id)])).toEqual([['Stage 2', [3]], ['Stage 3', [1, 4]]]);
    expect(g.healthy.map((l) => l.id)).toEqual([2]);
    expect(g.unvalidated.map((l) => l.id)).toEqual([5, 6]);
  });
  it('keeps a treatment leaf with no stage label visible', () => {
    expect(groupLeaves([leaf(1, 'treatment_result')]).stages[0].label).toBe('Stage not given');
  });
});
