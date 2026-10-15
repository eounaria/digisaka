import { describe, it, expect, vi } from 'vitest';
import { createCycleFlow, POLL_LIMIT } from './cycleFlow.js';
import { SchedulerError } from './client.js';

const cycle = (over = {}) => ({ cycle_id: 'c1', line_id: 'L04', week: '2026-W24', status: 'done', outcome: 'proposal', outcome_reason: null, failure_reason: null, ...over });
const proposal = (over = {}) => ({
  proposal_id: 'p1', treatment: { id: 't', name: 'Mancozeb' }, window: { start: '2026-06-15', end: '2026-06-17' },
  reason: 'r', constraints: ['c'], next_assessment: '2026-06-22', decision: null, ...over,
});
function setup(clientOver = {}) {
  const client = {
    getCycle: vi.fn(async () => cycle()),
    getProposal: vi.fn(async () => proposal()),
    retryCycle: vi.fn(async () => cycle({ status: 'running', outcome: null })),
    decide: vi.fn(async () => ({})),
    recordApplication: vi.fn(async () => ({ applied_on: '2026-06-16' })),
    getLine: vi.fn(async () => ({ applications: [] })),
    ...clientOver,
  };
  const wait = vi.fn(async () => {});
  const flow = createCycleFlow({ client, cycleId: 'c1', wait });
  return { client, flow, wait };
}

describe('createCycleFlow.start', () => {
  it('shows an undecided proposal when the cycle is done', async () => {
    const { flow } = setup();
    await flow.start();
    expect(flow.state.phase).toBe('proposal');
    expect(flow.state.proposal.treatment.name).toBe('Mancozeb');
  });

  it('polls while running, waits between polls, then reads the proposal', async () => {
    const { client, flow, wait } = setup();
    client.getCycle.mockResolvedValueOnce(cycle({ status: 'running', outcome: null }))
      .mockResolvedValueOnce(cycle({ status: 'running', outcome: null }));
    await flow.start();
    expect(client.getCycle).toHaveBeenCalledTimes(3);
    expect(wait).toHaveBeenCalledTimes(2);
    expect(flow.state.phase).toBe('proposal');
  });

  it('stops polling when stop() is called', async () => {
    const { client, flow, wait } = setup();
    client.getCycle.mockResolvedValue(cycle({ status: 'running', outcome: null }));
    wait.mockImplementation(async () => { flow.stop(); });
    await flow.start();
    expect(client.getCycle).toHaveBeenCalledTimes(1);
    expect(flow.state.phase).toBe('running');
  });

  it('times out after the poll limit', async () => {
    const { client, flow } = setup();
    client.getCycle.mockResolvedValue(cycle({ status: 'running', outcome: null }));
    await flow.start();
    expect(client.getCycle).toHaveBeenCalledTimes(POLL_LIMIT);
    expect(flow.state.phase).toBe('timeout');
  });

  it('shows Human Review Required without a proposal', async () => {
    const { client, flow } = setup();
    client.getCycle.mockResolvedValue(cycle({ outcome: 'human_review_required', outcome_reason: 'no_option' }));
    await flow.start();
    expect(flow.state.phase).toBe('review');
    expect(client.getProposal).not.toHaveBeenCalled();
    expect(flow.state.proposal).toBeNull();
  });

  it('treats a missing proposal as review', async () => {
    const { client, flow } = setup();
    client.getProposal.mockRejectedValue(new SchedulerError(404, 'unknown_proposal', 'x'));
    await flow.start();
    expect(flow.state.phase).toBe('review');
  });

  it('a failed cycle offers a retry that polls the new cycle', async () => {
    const { client, flow } = setup();
    client.getCycle.mockResolvedValueOnce(cycle({ status: 'failed', outcome: null, failure_reason: 'llm' }));
    await flow.start();
    expect(flow.state.phase).toBe('failed');
    client.retryCycle.mockResolvedValue(cycle({ cycle_id: 'c2', status: 'running', outcome: null }));
    client.getCycle.mockResolvedValue(cycle({ cycle_id: 'c2' }));
    await flow.retry();
    expect(client.retryCycle).toHaveBeenCalledWith('c1');
    expect(client.getCycle).toHaveBeenLastCalledWith('c2');
    expect(flow.state.phase).toBe('proposal');
  });

  it('restores an approved proposal and its recorded application', async () => {
    const { client, flow } = setup();
    client.getProposal.mockResolvedValue(proposal({ decision: { decision: 'approved' } }));
    client.getLine.mockResolvedValue({ applications: [{ proposal_id: 'p1', applied_on: '2026-06-16' }, { proposal_id: 'other', applied_on: '2026-01-01' }] });
    await flow.start();
    expect(flow.state).toMatchObject({ phase: 'applied', appliedOn: '2026-06-16' });
  });

  it('shows a readable error when polling fails', async () => {
    const { client, flow } = setup();
    client.getCycle.mockRejectedValue(new SchedulerError(404, 'unknown_cycle', 'secret'));
    await flow.start();
    expect(flow.state.phase).toBe('error');
    expect(flow.state.error).toMatch(/cycle/i);
    expect(flow.state.error).not.toMatch(/secret/);
  });
});

describe('robustness', () => {
  it('survives one transient poll failure', async () => {
    const { client, flow } = setup();
    client.getCycle.mockRejectedValueOnce(new SchedulerError(0, 'network_error', 'x'));
    await flow.start();
    expect(flow.state.phase).toBe('proposal');
  });

  it('gives up after three failures in a row and can start again', async () => {
    const { client, flow } = setup();
    client.getCycle.mockRejectedValue(new SchedulerError(503, 'auth_unavailable', 'x'));
    await flow.start();
    expect(flow.state.phase).toBe('error');
    expect(client.getCycle).toHaveBeenCalledTimes(3);
    client.getCycle.mockResolvedValue(cycle());
    await flow.start();
    expect(flow.state.phase).toBe('proposal');
  });

  it('does not restart polling when stop() happens during retry', async () => {
    const { client, flow } = setup();
    client.getCycle.mockResolvedValueOnce(cycle({ status: 'failed', outcome: null }));
    await flow.start();
    client.retryCycle.mockImplementation(async () => { flow.stop(); return cycle({ cycle_id: 'c2', status: 'running' }); });
    client.getCycle.mockClear();
    await flow.retry();
    expect(client.getCycle).not.toHaveBeenCalled();
  });

  it('stays on approved when the application lookup fails', async () => {
    const { client, flow } = setup();
    client.getProposal.mockResolvedValue(proposal({ decision: { decision: 'approved' } }));
    client.getLine.mockRejectedValue(new SchedulerError(500, 'internal_error', 'x'));
    await flow.start();
    expect(flow.state.phase).toBe('approved');
  });
});

describe('decision and application', () => {
  it('approve moves to the approved phase', async () => {
    const { client, flow } = setup();
    await flow.start();
    client.getProposal.mockResolvedValue(proposal({ decision: { decision: 'approved' } }));
    await flow.decide('approved', 'ok');
    expect(client.decide).toHaveBeenCalledWith('p1', 'approved', 'ok');
    expect(flow.state.phase).toBe('approved');
  });

  it('reject moves to the rejected phase', async () => {
    const { client, flow } = setup();
    await flow.start();
    client.getProposal.mockResolvedValue(proposal({ decision: { decision: 'rejected' } }));
    await flow.decide('rejected');
    expect(flow.state.phase).toBe('rejected');
  });

  it('records the application date after approval', async () => {
    const { client, flow } = setup();
    client.getProposal.mockResolvedValue(proposal({ decision: { decision: 'approved' } }));
    await flow.start();
    expect(flow.state.phase).toBe('approved');
    await flow.apply('2026-06-16');
    expect(client.recordApplication).toHaveBeenCalledWith('p1', '2026-06-16');
    expect(flow.state).toMatchObject({ phase: 'applied', appliedOn: '2026-06-16' });
  });

  it('rejects a malformed application date without calling the API', async () => {
    const { client, flow } = setup();
    client.getProposal.mockResolvedValue(proposal({ decision: { decision: 'approved' } }));
    await flow.start();
    await flow.apply('16/06/2026');
    expect(client.recordApplication).not.toHaveBeenCalled();
    expect(flow.state.error).toMatch(/date/i);
  });

  it('re-syncs with the real state when the proposal was already decided', async () => {
    const { client, flow } = setup();
    await flow.start();
    client.decide.mockRejectedValue(new SchedulerError(409, 'proposal_already_decided', 'x'));
    client.getProposal.mockResolvedValue(proposal({ decision: { decision: 'approved' } }));
    await flow.decide('rejected');
    expect(flow.state.phase).toBe('approved');
    expect(flow.state.error).toMatch(/already decided/i);
    expect(flow.state.busy).toBe(false);
  });

  it('re-syncs when the application was already recorded', async () => {
    const { client, flow } = setup();
    client.getProposal.mockResolvedValue(proposal({ decision: { decision: 'approved' } }));
    await flow.start();
    client.recordApplication.mockRejectedValue(new SchedulerError(409, 'application_already_recorded', 'x'));
    client.getLine.mockResolvedValue({ applications: [{ proposal_id: 'p1', applied_on: '2026-06-15' }] });
    await flow.apply('2026-06-16');
    expect(flow.state).toMatchObject({ phase: 'applied', appliedOn: '2026-06-15' });
  });
});
