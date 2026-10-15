import { describe, it, expect } from 'vitest';
import { stateLabel, stateTone } from './workflowState.js';

describe('workflow state words', () => {
  it('names each state and marks the ones that need a person or went wrong', () => {
    expect(stateLabel('awaiting_extraction_review')).toBe('Waiting for extraction review');
    expect(stateTone('awaiting_final_approval')).toBe('warn');
    expect(stateTone('commit_failed')).toBe('bad');
    expect(stateTone('completed')).toBe('good');
  });
  it('shows an unknown state as recorded', () => {
    expect(stateLabel('something_new')).toBe('something_new');
    expect(stateTone('something_new')).toBe('neutral');
  });
});
