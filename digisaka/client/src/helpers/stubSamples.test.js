import { describe, it, expect } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { SAMPLE_SCENARIOS, sampleFile, defaultSamples, addDefaultSamples } from './stubSamples.js';
import { useScanStore } from '../stores/scan.js';

// The stub's own rule (stub/scheduler.js scenarioOf), restated so a rename on either side fails here.
const scenarioOf = (name) => ['healthy', 'not_leaf', 'referral', 'rescan', 'unavailable'].find((s) => name.toLowerCase().includes(s)) ?? 'stage2';

describe('stub sample leaves', () => {
  it('names each sample after the scenario the stub reads from it', () => {
    for (const s of Object.keys(SAMPLE_SCENARIOS)) expect(scenarioOf(sampleFile(s).name)).toBe(s);
  });

  it('carries a non-empty PNG payload', async () => {
    const f = sampleFile('healthy');
    expect(f.type).toBe('image/png');
    expect(f.size).toBeGreaterThan(0);
  });

  it('rejects an unknown scenario', () => {
    expect(() => sampleFile('nope')).toThrow();
  });

  it('gives two stage 2 leaves and one healthy leaf by default, with distinct names', () => {
    const names = defaultSamples().map((f) => f.name);
    expect(names.map(scenarioOf)).toEqual(['stage2', 'stage2', 'healthy']);
    expect(new Set(names).size).toBe(3);
  });
});

describe('addDefaultSamples', () => {
  const store = () => { setActivePinia(createPinia()); return useScanStore(); };

  it('fills an empty queue when enabled', () => {
    const s = store(); s.select('L04', '2026-W24');
    addDefaultSamples(s, true);
    expect(s.leaves).toHaveLength(3);
  });

  it('does nothing when disabled', () => {
    const s = store(); s.select('L04', '2026-W24');
    addDefaultSamples(s, false);
    expect(s.leaves).toHaveLength(0);
  });

  it('never overwrites a queue that has leaves, and waits for a line', () => {
    const s = store();
    addDefaultSamples(s, true);
    expect(s.leaves).toHaveLength(0);
    s.select('L04', '2026-W24');
    s.addFiles([sampleFile('healthy')]);
    addDefaultSamples(s, true);
    expect(s.leaves).toHaveLength(1);
  });

  it('refills after a line or week change clears the queue', () => {
    const s = store(); s.select('L04', '2026-W24');
    addDefaultSamples(s, true);
    s.select('L04', '2026-W23');
    expect(s.leaves).toHaveLength(0);
    addDefaultSamples(s, true);
    expect(s.leaves).toHaveLength(3);
  });
});
