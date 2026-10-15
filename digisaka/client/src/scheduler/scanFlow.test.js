import { describe, it, expect, vi } from 'vitest';
import { createScanFlow, phaseOf, sessionLabel } from './scanFlow.js';
import { SchedulerError } from './client.js';

const checklist = ['Dark streaks', 'Yellowing'];
function fakeClient(over = {}) {
  return {
    upload: vi.fn(async () => ({ qa_output_id: 'q1', outcome: null, stage: 'Fouré Stage 2', symptom_checklist: checklist })),
    confirmSymptoms: vi.fn(async () => ({ qa_output_id: 'q1', outcome: 'treatment_result', stage: 'Fouré Stage 2' })),
    getLineWeek: vi.fn(async () => ({ sessions: [{ qa_output_id: 'q1', outcome: 'treatment_result', stage: 'Fouré Stage 2', finished: true }] })),
    ...over,
  };
}
const img = { img_name: 'a.jpg', img: 'AAAA' };

describe('phaseOf', () => {
  it('maps QA answers to the next thing the user does', () => {
    expect(phaseOf({ outcome: null, symptom_checklist: checklist })).toBe('confirm');
    expect(phaseOf({ outcome: null, next_action: 're_scan' })).toBe('rescan');
    expect(phaseOf({ outcome: 'healthy' })).toBe('done');
    expect(phaseOf({ outcome: null })).toBe('waiting');
  });
});

describe('createScanFlow', () => {
  it('upload moves to confirm and keeps the checklist and session id', async () => {
    const client = fakeClient();
    const flow = createScanFlow({ client, line: 'L04', week: '2026-W24' });
    await flow.upload(img);
    expect(client.upload).toHaveBeenCalledWith('L04', '2026-W24', img, undefined);
    expect(flow.state).toMatchObject({ phase: 'confirm', qaOutputId: 'q1', stage: 'Fouré Stage 2', checklist, error: '', busy: false });
  });

  it('confirming yes finishes with the outcome and refreshes sessions', async () => {
    const client = fakeClient();
    const flow = createScanFlow({ client, line: 'L04', week: '2026-W24' });
    await flow.upload(img);
    await flow.confirm(true);
    expect(client.confirmSymptoms).toHaveBeenCalledWith('q1', true);
    expect(flow.state).toMatchObject({ phase: 'done', outcome: 'treatment_result' });
    expect(flow.state.sessions).toHaveLength(1);
  });

  it('refreshes sessions after a non-terminal upload', async () => {
    const client = fakeClient();
    const flow = createScanFlow({ client, line: 'L04', week: '2026-W24' });
    await flow.upload(img);
    expect(client.getLineWeek).toHaveBeenCalledOnce();
  });

  it('does not show a previous stage next to a new outcome', async () => {
    const client = fakeClient({ upload: vi.fn(async () => ({ qa_output_id: 'q1', outcome: null, next_action: 're_scan', stage: 'Fouré Stage 2' })) });
    client.upload.mockResolvedValueOnce({ qa_output_id: 'q1', outcome: null, next_action: 're_scan', stage: 'Fouré Stage 2' });
    const flow = createScanFlow({ client, line: 'L04', week: '2026-W24' });
    await flow.upload(img);
    client.upload.mockResolvedValueOnce({ qa_output_id: 'q1', outcome: 'healthy', stage: null });
    await flow.upload(img);
    expect(flow.state).toMatchObject({ outcome: 'healthy', stage: null });
  });

  it('a denial with re_scan asks for a new upload that reuses the session', async () => {
    const client = fakeClient({
      confirmSymptoms: vi.fn(async () => ({ qa_output_id: 'q1', outcome: null, next_action: 're_scan' })),
    });
    const flow = createScanFlow({ client, line: 'L04', week: '2026-W24' });
    await flow.upload(img);
    await flow.confirm(false);
    expect(flow.state.phase).toBe('rescan');
    await flow.upload(img);
    expect(client.upload).toHaveBeenLastCalledWith('L04', '2026-W24', img, 'q1');
  });

  it('a capped denial ends with the terminal outcome', async () => {
    const client = fakeClient({
      confirmSymptoms: vi.fn(async () => ({ qa_output_id: 'q1', outcome: 'referral', next_action: null })),
    });
    const flow = createScanFlow({ client, line: 'L04', week: '2026-W24' });
    await flow.upload(img);
    await flow.confirm(false);
    expect(flow.state).toMatchObject({ phase: 'done', outcome: 'referral' });
  });

  it('a terminal upload answer (healthy) skips confirmation', async () => {
    const client = fakeClient({ upload: vi.fn(async () => ({ qa_output_id: 'q2', outcome: 'healthy', stage: null })) });
    const flow = createScanFlow({ client, line: 'L04', week: '2026-W24' });
    await flow.upload(img);
    expect(flow.state).toMatchObject({ phase: 'done', outcome: 'healthy' });
  });

  it('shows a readable message on failure and stays where it was', async () => {
    const client = fakeClient({ upload: vi.fn(async () => { throw new SchedulerError(502, 'qa_unavailable', 'secret'); }) });
    const flow = createScanFlow({ client, line: 'L04', week: '2026-W24' });
    await flow.upload(img);
    expect(flow.state.error).toMatch(/QA/);
    expect(flow.state.error).not.toMatch(/secret/);
    expect(flow.state).toMatchObject({ phase: 'idle', busy: false });
  });

  it('a failed confirmation keeps the checklist so the user can retry', async () => {
    const client = fakeClient({ confirmSymptoms: vi.fn(async () => { throw new SchedulerError(502, 'qa_unavailable', 'x'); }) });
    const flow = createScanFlow({ client, line: 'L04', week: '2026-W24' });
    await flow.upload(img);
    await flow.confirm(true);
    expect(flow.state).toMatchObject({ phase: 'confirm', checklist });
    expect(flow.state.error).not.toBe('');
  });

  it('refresh loads sessions and reports a failure', async () => {
    const client = fakeClient();
    const flow = createScanFlow({ client, line: 'L04', week: '2026-W24' });
    await flow.refresh();
    expect(flow.state.sessions).toHaveLength(1);
    client.getLineWeek.mockRejectedValueOnce(new SchedulerError(422, 'invalid_week', 'x'));
    await flow.refresh();
    expect(flow.state.error).toMatch(/week/i);
  });

  it('ignores a second upload while one is in flight', async () => {
    let release;
    const client = fakeClient({ upload: vi.fn(() => new Promise((r) => { release = () => r({ qa_output_id: 'q1', outcome: 'healthy' }); })) });
    const flow = createScanFlow({ client, line: 'L04', week: '2026-W24' });
    const first = flow.upload(img);
    await flow.upload(img);
    release();
    await first;
    expect(client.upload).toHaveBeenCalledOnce();
  });
});

describe('sessionLabel', () => {
  it('describes finished and waiting sessions', () => {
    expect(sessionLabel({ finished: true, outcome: 'healthy', stage: null })).toBe('Healthy');
    expect(sessionLabel({ finished: true, outcome: 'treatment_result', stage: 'Fouré Stage 2' })).toBe('Treatment result (Fouré Stage 2)');
    expect(sessionLabel({ finished: false, outcome: null, stage: 'Fouré Stage 2' })).toBe('Waiting for confirmation (Fouré Stage 2)');
    expect(sessionLabel({ finished: true, outcome: 'referral', stage: null })).toBe('Referral');
    expect(sessionLabel({ finished: true, outcome: 'not_leaf', stage: null })).toBe('Not a leaf');
  });
});
