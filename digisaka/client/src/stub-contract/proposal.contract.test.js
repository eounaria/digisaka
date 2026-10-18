// Drives the real proposal store against the in-process stub, including the 409 recovery path.
import { describe, it, expect } from 'vitest';
import { useStub } from './harness.js';
import { useAuthStore } from '../stores/auth.js';
import { useProposalStore } from '../stores/proposal.js';
import { useLinesStore, proposalRows } from '../stores/lines.js';

useStub();
const WEEK = '2026-W24';

describe('proposal store against the stub', () => {
  it('shows L02 as applied and L05 as human review with its constraints', async () => {
    const s = useProposalStore();
    await s.load('L02', '2026-W23');
    expect(s).toMatchObject({ phase: 'ready', status: 'applied', appliedOn: '2026-06-04' });
    await s.load('L05', WEEK);
    expect(s.humanReview).toBe(true);
    expect(s.proposal.constraints.length).toBeGreaterThan(0);
  });

  it('approves L03 with a note, then records the application', async () => {
    const s = useProposalStore();
    await s.load('L03', WEEK);
    expect(s.status).toBe('proposed');
    await s.decide('approved', ' Spray at dawn ');
    expect(s).toMatchObject({ status: 'approved', error: '' });
    expect(s.proposal.decision.note).toBe('Spray at dawn');
    await s.apply('2026-06-11');
    expect(s).toMatchObject({ status: 'applied', appliedOn: '2026-06-11' });
    const lines = useLinesStore();
    await lines.load();
    expect(proposalRows(lines.byId('L03'))[0]).toMatchObject({ status: 'applied', appliedOn: '2026-06-11' });
  });

  it('rejecting L03 is shown as rejected', async () => {
    const s = useProposalStore();
    await s.load('L03', WEEK);
    await s.decide('rejected');
    expect(s.status).toBe('rejected');
  });

  it('recovers when another tab decided first: message shown, real state reloaded', async () => {
    const a = useProposalStore();
    await a.load('L03', WEEK);
    await fetch('/api/v1/scheduler/proposals/p-L03-24/decision', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${useAuthStore().token}` }, body: JSON.stringify({ decision: 'rejected' }) });
    await a.decide('approved');
    expect(a.error).toBe('This proposal was already decided.');
    expect(a.status).toBe('rejected');
  });

  it('refuses an application before approval and a repeat application', async () => {
    const s = useProposalStore();
    await s.load('L03', WEEK);
    await s.apply('2026-06-11');
    expect(s.error).toBe('Approve the proposal before recording its application.');
    await s.load('L02', '2026-W23');
    await s.apply('2026-06-12');
    expect(s.error).toBe('The application was already recorded.');
    expect(s.status).toBe('applied');
  });
});
