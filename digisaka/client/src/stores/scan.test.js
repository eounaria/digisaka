import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { setTokenProvider } from '../api.js';
import { useScanStore, phaseOf, MAX_LEAVES } from './scan.js';

vi.mock('../helpers/image.js', () => ({ fileToPayload: async (f) => ({ img_name: f.name, img: 'AAAA' }) }));

const checklist = ['Dark streaks', 'Yellowing'];
const file = (n) => ({ name: `${n}.jpg` });
const json = (status, body) => ({ status, ok: status < 400, json: async () => body });
let fetchMock;

beforeEach(() => {
  setActivePinia(createPinia());
  setTokenProvider(() => 'TOK');
  fetchMock = vi.fn();
  vi.stubGlobal('fetch', fetchMock);
});
afterEach(() => { vi.unstubAllGlobals(); setTokenProvider(() => null); });

const ready = (...names) => { const s = useScanStore(); s.select('L04', '2026-W24'); s.addFiles(names.map(file)); return s; };
const bodyOf = (i) => JSON.parse(fetchMock.mock.calls[i][1].body);

describe('phaseOf', () => {
  it('maps QA answers to the next thing the user does', () => {
    expect(phaseOf({ outcome: null, symptom_checklist: checklist })).toBe('confirm');
    expect(phaseOf({ outcome: null, next_action: 're_scan' })).toBe('rescan');
    expect(phaseOf({ outcome: 'healthy' })).toBe('done');
    expect(phaseOf({ outcome: null })).toBe('waiting');
  });
});

describe('adding leaves', () => {
  it('refuses a ninth leaf with a message', () => {
    const s = ready(...Array.from({ length: MAX_LEAVES }, (_, i) => i));
    s.addFiles([file('extra')]);
    expect(s.leaves).toHaveLength(MAX_LEAVES);
    expect(s.notice).toMatch(/up to 8/);
  });
  it('removes one and clears all', () => {
    const s = ready('a', 'b');
    s.remove(s.leaves[0].id);
    expect(s.leaves).toHaveLength(1);
    s.clear();
    expect(s.leaves).toHaveLength(0);
  });
  it('starts a fresh set when the line or week changes', () => {
    const s = ready('a');
    s.select('L04', '2026-W25');
    expect(s.leaves).toHaveLength(0);
  });
});

describe('assess', () => {
  it('uploads each leaf in order to the line-week and applies the answer', async () => {
    fetchMock
      .mockResolvedValueOnce(json(201, { qa_output_id: 'q1', outcome: null, stage: 'Stage 2', symptom_checklist: checklist }))
      .mockResolvedValueOnce(json(201, { qa_output_id: 'q2', outcome: 'healthy' }));
    const s = ready('a', 'b');
    await s.assess();
    expect(fetchMock.mock.calls.map((c) => c[0])).toEqual(Array(2).fill('/api/v1/scheduler/lines/L04/weeks/2026-W24/diagnoses'));
    expect(bodyOf(0)).toEqual({ img_name: 'a.jpg', img: 'AAAA' });
    expect(bodyOf(1).img_name).toBe('b.jpg');
    expect(s.leaves[0]).toMatchObject({ phase: 'confirm', qaOutputId: 'q1', stage: 'Stage 2', checklist });
    expect(s.leaves[1]).toMatchObject({ phase: 'done', outcome: 'healthy' });
    expect(s.assessing).toBe(false);
  });
  it('does nothing with an invalid week and says why', async () => {
    const s = ready('a');
    s.select('L04', 'nope');
    s.addFiles([file('a')]);
    await s.assess();
    expect(fetchMock).not.toHaveBeenCalled();
    expect(s.notice).toMatch(/not a valid week/);
  });
  it('marks a failed leaf, carries on with the rest, and retries only the failed one next time', async () => {
    fetchMock
      .mockResolvedValueOnce(json(503, { error: 'qa_unavailable', detail: 'down' }))
      .mockResolvedValueOnce(json(201, { qa_output_id: 'q2', outcome: 'not_leaf' }))
      .mockResolvedValueOnce(json(201, { qa_output_id: 'q1', outcome: 'healthy' }));
    const s = ready('a', 'b');
    await s.assess();
    expect(s.leaves[0]).toMatchObject({ phase: 'failed', error: expect.stringMatching(/QA service is unavailable/) });
    expect(s.leaves[1].phase).toBe('done');
    await s.assess();
    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect(s.leaves[0]).toMatchObject({ phase: 'done', error: '' });
  });
});

describe('confirm and re-scan', () => {
  const toConfirm = async () => {
    fetchMock.mockResolvedValueOnce(json(201, { qa_output_id: 'q1', outcome: null, stage: 'Stage 2', symptom_checklist: checklist }));
    const s = ready('a');
    await s.assess();
    return s;
  };
  it('yes finishes the leaf with the outcome', async () => {
    const s = await toConfirm();
    fetchMock.mockResolvedValueOnce(json(200, { qa_output_id: 'q1', outcome: 'treatment_result', stage: 'Stage 2' }));
    await s.confirm(s.leaves[0].id, true);
    expect(fetchMock.mock.calls[1][0]).toBe('/api/v1/scheduler/diagnoses/q1/confirm-symptoms');
    expect(bodyOf(1)).toEqual({ confirmed: true });
    expect(s.leaves[0]).toMatchObject({ phase: 'done', outcome: 'treatment_result' });
  });
  it('no with re_scan offers a new image that reuses the session', async () => {
    const s = await toConfirm();
    fetchMock.mockResolvedValueOnce(json(200, { qa_output_id: 'q1', outcome: null, next_action: 're_scan' }));
    await s.confirm(s.leaves[0].id, false);
    expect(s.leaves[0].phase).toBe('rescan');
    fetchMock.mockResolvedValueOnce(json(201, { qa_output_id: 'q1', outcome: null, symptom_checklist: checklist }));
    await s.rescan(s.leaves[0].id, file('again'));
    expect(bodyOf(2)).toEqual({ img_name: 'again.jpg', img: 'AAAA', qa_output_id: 'q1' });
    expect(s.leaves[0].phase).toBe('confirm');
  });
  it('shows a referral when the retry cap is reached', async () => {
    const s = await toConfirm();
    fetchMock.mockResolvedValueOnce(json(200, { qa_output_id: 'q1', outcome: 'referral', stage: null }));
    await s.confirm(s.leaves[0].id, false);
    expect(s.leaves[0]).toMatchObject({ phase: 'done', outcome: 'referral' });
  });
  it('keeps the checklist open and shows an error when confirming fails', async () => {
    const s = await toConfirm();
    fetchMock.mockResolvedValueOnce(json(404, { error: 'unknown_session', detail: 'x' }));
    await s.confirm(s.leaves[0].id, true);
    expect(s.leaves[0]).toMatchObject({ phase: 'confirm', error: expect.stringMatching(/does not belong/) });
  });
  it('a failed re-scan upload stays in re-scan', async () => {
    const s = await toConfirm();
    fetchMock.mockResolvedValueOnce(json(200, { qa_output_id: 'q1', outcome: null, next_action: 're_scan' }));
    await s.confirm(s.leaves[0].id, false);
    fetchMock.mockResolvedValueOnce(json(422, { error: 'validation_error', detail: 'bad' }));
    await s.rescan(s.leaves[0].id, file('again'));
    expect(s.leaves[0].phase).toBe('rescan');
  });
});
