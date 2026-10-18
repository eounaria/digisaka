// Drives the real scan and cycle stores against the in-process stub, polling on its fake clock.
import { describe, it, expect, vi } from 'vitest';
import { useStub, CYCLE_MS } from './harness.js';
import { useScanStore } from '../stores/scan.js';
import { useCycleStore } from '../stores/cycle.js';
import { useLinesStore } from '../stores/lines.js';

vi.mock('../helpers/image.js', () => ({ fileToPayload: async (f) => ({ img_name: f.name, img: 'AAAA' }) }));

const ctx = useStub();
const file = (n) => ({ name: `${n}.jpg` });
// Each poll wait moves the stub's clock past the cycle's run time.
const wait = async () => { ctx.clock.t += CYCLE_MS; };

async function scanned(line, ...names) {
  const s = useScanStore();
  s.select(line, '2026-W24');
  s.addFiles(names.map(file));
  await s.assess();
  return s;
}

describe('scan store against the stub', () => {
  it('reaches every outcome the Scan screen renders', async () => {
    const s = await scanned('L04', 'a-healthy', 'b-not_leaf', 'c-referral', 'd-rescan', 'e-stage2', 'f-unavailable');
    expect(s.leaves.map((l) => l.phase)).toEqual(['done', 'done', 'done', 'rescan', 'confirm', 'failed']);
    expect(s.leaves[5].error).toBe('The QA service is unavailable. Try again shortly.');
    await s.assess(); // retry the failed one
    expect(s.leaves[5].phase).toBe('confirm');
    await s.confirm(s.leaves[4].id, true);
    expect(s.leaves[4]).toMatchObject({ phase: 'done', outcome: 'treatment_result' });
    await s.confirm(s.leaves[5].id, false);
    expect(s.leaves[5].phase).toBe('rescan');
    await s.rescan(s.leaves[5].id, file('g-stage2'));
    expect(s.leaves[5].phase).toBe('confirm');
  });
});

describe('cycle store against the stub', () => {
  it('refuses to close a week with no verified scan', async () => {
    const c = useCycleStore();
    await c.close('L04', '2026-W24', wait);
    expect(c.phase).toBe('idle');
    expect(c.error).toBe('Finish at least one scan, including its symptom confirmation, before closing the week.');
  });

  it.each([
    ['L04', 'proposal'],
    ['L01', 'monitoring'],
  ])('closing %s ends in %s', async (line, phase) => {
    await scanned(line, 'a-healthy');
    const c = useCycleStore();
    await c.close(line, '2026-W24', wait);
    expect(c.phase).toBe(phase);
  });

  it('shows human review for L05', async () => {
    await scanned('L05', 'a-healthy');
    const c = useCycleStore();
    await c.close('L05', '2026-W24', wait);
    expect(c.phase).toBe('review');
  });

  it('L06 fails and the retry succeeds', async () => {
    await scanned('L06', 'a-healthy');
    const c = useCycleStore();
    await c.close('L06', '2026-W24', wait);
    expect(c.phase).toBe('failed');
    expect(c.cycle.failure_reason).toBeTruthy();
    await c.retry(wait);
    expect(c.phase).toBe('monitoring');
  });

  it('a finished proposal appears in the line status', async () => {
    await scanned('L04', 'a-healthy');
    await useCycleStore().close('L04', '2026-W24', wait);
    const lines = useLinesStore();
    await lines.load();
    expect(lines.byId('L04').proposals.map((p) => p.week)).toEqual(['2026-W24']);
  });
});
