// Drives the real workflows, workflow-run and fact-review stores against the in-process stub,
// moving its fake clock instead of waiting out the polling interval.
import { describe, it, expect } from 'vitest';
import { useStub, CYCLE_MS } from './harness.js';
import { useWorkflowsStore } from '../stores/workflows.js';
import { useWorkflowRunStore } from '../stores/workflowRun.js';
import { useFactReviewStore } from '../stores/factReview.js';
import { useAuthStore } from '../stores/auth.js';

const ctx = useStub({ email: 'admin@digisaka.test' });
const wait = async () => { ctx.clock.t += CYCLE_MS; };
const GATE1 = 'extraction_review', GATE2 = 'final_review';

async function open(title) {
  const list = useWorkflowsStore();
  list.load('admin@digisaka.test');
  const w = await list.submitText(title, 'Late blight spreads in humid weather.');
  const run = useWorkflowRunStore();
  await run.follow(w.id, wait);
  return { list, run, id: w.id, facts: useFactReviewStore() };
}
async function decideAll(facts, run, id, stage, from) {
  await facts.load(id, { disposition: from, offset: 0 });
  for (const f of [...facts.facts]) {
    expect(await facts.claim(f.id)).toBe(true);
    expect(await facts.review(f.id, 'accept', stage)).toBe(true);
  }
  if (facts.total > facts.facts.length) await decideAll(facts, run, id, stage, from);
}

describe('Knowledge Maintenance stores against the stub', () => {
  it('submits text, follows it to extraction review and lists it', async () => {
    const { list, run, id } = await open('Potato notes');
    expect(run).toMatchObject({ phase: 'gate' });
    expect(run.workflow.state).toBe('awaiting_extraction_review');
    expect(list.items[0]).toMatchObject({ id, title: 'Potato notes' });
    expect(await list.open(id)).toMatchObject({ id });
    expect(await list.open('00000000-0000-4000-8000-000000000999')).toBeNull();
    expect(list.error).toBe('Workflow not found');
  });

  it('submits a file and opens it by id', async () => {
    const list = useWorkflowsStore();
    list.load('admin@digisaka.test');
    const w = await list.submitFile(new File(['Some text'], 'notes.txt', { type: 'text/plain' }), 'Uploaded notes');
    expect(w).toMatchObject({ title: 'Uploaded notes', state: 'document_submitted' });
    expect(await list.open(w.id)).toMatchObject({ id: w.id });
  });

  it('reviews facts, reaches final approval, approves and completes with counts', async () => {
    const { run, id, facts } = await open('Potato notes');
    await facts.load(id, { disposition: 'pending' });
    expect(facts.total).toBe(20);
    // A colleague holds one fact: claiming takes it over, a stale version is a 409 and reloads.
    const held = facts.facts.find((f) => f.claimed_by);
    expect(await facts.claim(held.id)).toBe(true);
    expect(facts.notice).toContain('took over');
    const f = facts.facts[0];
    facts._patch(f.id, { lock_version: 99 });
    expect(await facts.review(f.id, 'accept', GATE1)).toBe(false);
    expect(facts.error).toBe('The fact changed since it was read; reload and retry');
    expect(facts.facts.find((x) => x.id === f.id).lock_version).not.toBe(99);
    await decideAll(facts, run, id, GATE1, 'pending');
    await run.recheck(id, wait);
    expect(run.workflow.state).toBe('awaiting_final_approval');
    expect(await facts.countChanged(id)).toBe(2);
    expect(await run.approve(id, wait)).toBe(true);
    expect(run).toMatchObject({ phase: 'done' });
    expect(await facts.summarize(id)).toEqual({ accepted: 26, rejected: 0, unresolved: 4 });
    expect(await run.approve(id, wait)).toBe(false);
    expect(run.approveError).toMatch(/completed/);
  });

  it('shows the failure for a fail title', async () => {
    const { run } = await open('fail on purpose');
    expect(run.phase).toBe('failed');
    expect(run.workflow.failure.code).toBe('EXTRACTION_FAILED');
  });

  it('retries a failed commit with approve', async () => {
    const { run, id, facts } = await open('commit-fail batch');
    await decideAll(facts, run, id, GATE1, 'pending');
    await run.recheck(id, wait);
    await run.approve(id, wait);
    expect(run).toMatchObject({ phase: 'failed' });
    expect(run.workflow).toMatchObject({ state: 'commit_failed', retry_available: true });
    await run.approve(id, wait);
    expect(run).toMatchObject({ phase: 'done' });
    expect(run.workflow.state).toBe('completed');
  });

  it('shows the later-stage blocks only from final approval on', async () => {
    const { id, run, facts } = await open('Potato notes');
    const read = async () => {
      const token = useAuthStore().token;
      const page = async (offset) => (await (await fetch(`/api/v1/knowledge-maintenance/workflows/${id}/facts?limit=25&offset=${offset}`, { headers: { Authorization: `Bearer ${token}` } })).json()).facts;
      return [...await page(0), ...await page(25)];
    };
    const early = await read();
    expect(early.some((f) => f.gate3 || f.mend || f.entity_resolution || f.entity_match_warnings.length || f.entity_conflict_warnings.length)).toBe(false);
    await decideAll(facts, run, id, GATE1, 'pending');
    await run.recheck(id, wait);
    expect(run.workflow.state).toBe('awaiting_final_approval');
    const all = await read();
    for (const key of ['gate3', 'mend', 'entity_resolution']) expect(all.some((f) => f[key])).toBe(true);
    expect(all.some((f) => f.entity_match_warnings.length)).toBe(true);
    expect(all.some((f) => f.entity_conflict_warnings.length)).toBe(true);
  });
});
