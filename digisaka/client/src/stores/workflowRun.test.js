import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { setTokenProvider } from '../api.js';
import { useWorkflowRunStore, GATES } from './workflowRun.js';

const json = (status, body) => ({ status, ok: status < 400, json: async () => body });
const ID = '3fb2718a-406f-4c36-bfac-6dcae19c7b70';
const wf = (state, extra = {}) => json(200, { workflow_id: ID, state, failure: null, retrying: null, retry_available: false, ...extra });
let fetchMock;
const wait = vi.fn(async () => {});

beforeEach(() => {
  setActivePinia(createPinia());
  setTokenProvider(() => 'TOK');
  fetchMock = vi.fn();
  vi.stubGlobal('fetch', fetchMock);
  wait.mockClear();
});
afterEach(() => { vi.unstubAllGlobals(); setTokenProvider(() => null); });

describe('following a workflow', () => {
  it('polls while the workflow is working and stops at a review gate', async () => {
    fetchMock.mockResolvedValueOnce(wf('extracting')).mockResolvedValueOnce(wf('restoring_verifying')).mockResolvedValueOnce(wf('awaiting_extraction_review'));
    const s = useWorkflowRunStore();
    await s.follow(ID, wait);
    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect(wait).toHaveBeenCalledTimes(2);
    expect(s.workflow.state).toBe('awaiting_extraction_review');
    expect(s.phase).toBe('gate');
  });
  it('stops at a terminal state', async () => {
    fetchMock.mockResolvedValueOnce(wf('committing')).mockResolvedValueOnce(wf('completed'));
    const s = useWorkflowRunStore();
    await s.follow(ID, wait);
    expect(s.phase).toBe('done');
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });
  it('stops on failed and commit_failed and exposes the failure the API gives', async () => {
    fetchMock.mockResolvedValueOnce(wf('failed', { failure: { stage: 'extract', code: 'llm_timeout', message: 'The language model service timed out.', retryable: true, attempts: 3 } }));
    const s = useWorkflowRunStore();
    await s.follow(ID, wait);
    expect(s.phase).toBe('failed');
    expect(s.workflow.failure.message).toMatch(/timed out/);
  });
  it('shows an automatic retry in progress and keeps polling', async () => {
    fetchMock.mockResolvedValueOnce(wf('extracting', { retrying: { stage: 'extract', attempt: 1, max_attempts: 3 } })).mockResolvedValueOnce(wf('awaiting_extraction_review'));
    const s = useWorkflowRunStore();
    const seen = [];
    wait.mockImplementationOnce(async () => { seen.push(s.workflow.retrying?.attempt); });
    await s.follow(ID, wait);
    expect(seen).toEqual([1]);
  });
  it('tolerates two failed polls in a row and gives up on the third', async () => {
    fetchMock.mockRejectedValueOnce(new Error('net')).mockResolvedValueOnce(wf('extracting')).mockRejectedValue(new Error('net'));
    const s = useWorkflowRunStore();
    await s.follow(ID, wait);
    expect(s.phase).toBe('error');
    expect(s.error).toBeTruthy();
  });
  it('shows an unknown id as the API says and does not keep polling', async () => {
    fetchMock.mockResolvedValue(json(404, { error: { code: 'NOT_FOUND', message: 'Workflow not found', details: {} } }));
    const s = useWorkflowRunStore();
    await s.follow(ID, wait);
    expect(s.phase).toBe('error');
    expect(s.error).toBe('Workflow not found');
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
  it('stop() ends a running poll, and following another workflow replaces it', async () => {
    fetchMock.mockResolvedValue(wf('extracting'));
    const s = useWorkflowRunStore();
    let n = 0;
    await s.follow(ID, async () => { if (++n === 2) s.stop(); });
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });
  it('never calls a sign-in endpoint while waiting', async () => {
    fetchMock.mockResolvedValueOnce(wf('extracting')).mockResolvedValueOnce(wf('awaiting_final_approval'));
    await useWorkflowRunStore().follow(ID, wait);
    expect(fetchMock.mock.calls.every(([u]) => u.startsWith('/api/v1/knowledge-maintenance/'))).toBe(true);
    expect(GATES).toContain('awaiting_final_approval');
  });
});

describe('after a review', () => {
  it('stays at the gate while facts are still waiting', async () => {
    fetchMock.mockResolvedValueOnce(wf('awaiting_extraction_review')).mockResolvedValueOnce(wf('awaiting_extraction_review'));
    const s = useWorkflowRunStore();
    await s.follow(ID, wait);
    await s.recheck(ID, wait);
    expect(s.phase).toBe('gate');
    expect(wait).not.toHaveBeenCalled();
  });
  it('picks the polling back up once the last fact has moved the workflow on', async () => {
    fetchMock.mockResolvedValueOnce(wf('awaiting_extraction_review')).mockResolvedValueOnce(wf('canonicalizing')).mockResolvedValueOnce(wf('canonicalizing')).mockResolvedValueOnce(wf('awaiting_final_approval'));
    const s = useWorkflowRunStore();
    await s.follow(ID, wait);
    await s.recheck(ID, wait);
    expect(s.workflow.state).toBe('awaiting_final_approval');
    expect(s.phase).toBe('gate');
  });
});
