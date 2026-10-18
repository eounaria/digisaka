import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { createStub } from './server.js';
import { SAMPLE_USERS, issueToken } from './supabase.js';

const B = '/api/v1/scheduler';
const WEEK = '2026-W24';
const farmer = { Authorization: `Bearer ${issueToken(SAMPLE_USERS[0])}`, 'Content-Type': 'application/json' };
let server, base, t;

beforeEach(async () => {
  t = 1_000_000;
  server = createStub({ now: () => t, cycleMs: 3000 });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  base = `http://127.0.0.1:${server.address().port}`;
});
afterEach(() => server.close());

const call = async (method, path, body) => {
  const res = await fetch(base + path, { method, headers: farmer, body: body ? JSON.stringify(body) : undefined });
  return { status: res.status, body: await res.json() };
};
const scan = (line, name, extra = {}) => call('POST', `${B}/lines/${line}/weeks/${WEEK}/diagnoses`, { img_name: name, img: 'AAAA', ...extra });
const close = (line) => call('POST', `${B}/lines/${line}/weeks/${WEEK}/close`);
const verify = (line) => scan(line, 'leaf-healthy.jpg');

test('each image name gives its canned answer; unrecognised names are stage 2', async () => {
  assert.deepEqual((await scan('L04', 'a-healthy.jpg')).body, { qa_output_id: 'qa-1', outcome: 'healthy', stage: null });
  assert.equal((await scan('L04', 'not_leaf.jpg')).body.outcome, 'not_leaf');
  assert.equal((await scan('L04', 'referral.jpg')).body.outcome, 'referral');
  assert.equal((await scan('L04', 'rescan.jpg')).body.next_action, 're_scan');
  const stage2 = (await scan('L04', 'IMG_0042.jpg')).body;
  assert.equal(stage2.outcome, null);
  assert.equal(stage2.stage, 'Stage 2');
  assert.ok(stage2.symptom_checklist.length > 0);
});

test('an image the QA service cannot take answers 503 once, then goes through', async () => {
  const first = await scan('L04', 'unavailable.jpg');
  assert.equal(first.status, 503);
  assert.equal(first.body.error, 'qa_unavailable');
  assert.equal((await scan('L04', 'unavailable.jpg')).status, 201);
});

test('confirming symptoms finishes the scan; denying asks for a re-scan, and a re-scan keeps the same session', async () => {
  const q = (await scan('L04', 'a.jpg')).body.qa_output_id;
  const yes = await call('POST', `${B}/diagnoses/${q}/confirm-symptoms`, { confirmed: true });
  assert.deepEqual(yes.body, { qa_output_id: q, outcome: 'treatment_result', stage: 'Stage 2' });
  const q2 = (await scan('L04', 'b.jpg')).body.qa_output_id;
  assert.equal((await call('POST', `${B}/diagnoses/${q2}/confirm-symptoms`, { confirmed: false })).body.next_action, 're_scan');
  const again = await scan('L04', 'b2.jpg', { qa_output_id: q2 });
  assert.equal(again.body.qa_output_id, q2);
  assert.ok(again.body.symptom_checklist);
  assert.equal((await call('POST', `${B}/diagnoses/nope/confirm-symptoms`, { confirmed: true })).body.error, 'unknown_session');
  assert.equal((await scan('L04', 'c.jpg', { qa_output_id: 'nope' })).body.error, 'unknown_session');
});

test('scan validation: missing image and bad week', async () => {
  assert.equal((await call('POST', `${B}/lines/L04/weeks/${WEEK}/diagnoses`, { img_name: 'a.jpg' })).body.error, 'validation_error');
  assert.equal((await call('POST', `${B}/lines/L04/weeks/bad/diagnoses`, { img_name: 'a', img: 'A' })).body.error, 'invalid_week');
});

test('closing before a verified scan is week_not_verified; a scan awaiting confirmation does not count', async () => {
  assert.equal((await close('L04')).body.error, 'week_not_verified');
  await scan('L04', 'a.jpg');
  assert.equal((await close('L04')).status, 409);
});

test('L04 closes to a running cycle that becomes a proposal visible in the line status', async () => {
  await verify('L04');
  const started = await close('L04');
  assert.equal(started.status, 202);
  assert.equal(started.body.status, 'running');
  const id = started.body.cycle_id;
  t += 2999;
  assert.equal((await call('GET', `${B}/cycles/${id}`)).body.status, 'running');
  t += 1;
  assert.deepEqual(await call('GET', `${B}/cycles/${id}`).then((r) => [r.body.status, r.body.outcome]), ['done', 'proposal']);
  const status = (await call('GET', `${B}/lines/L04`)).body;
  assert.equal(status.proposals.at(-1).cycle_id, id);
  assert.equal(status.latest_cycle.week, WEEK);
  assert.equal(status.leaves_scanned, 10);
});

test('L01 ends in monitoring and L05 in human review', async () => {
  await verify('L01'); await verify('L05');
  const l1 = (await close('L01')).body.cycle_id;
  const l5 = (await close('L05')).body;
  t += 3000;
  assert.equal((await call('GET', `${B}/cycles/${l1}`)).body.outcome, 'continue_monitoring');
  assert.equal(l5.cycle_id, 'c-L05-24'); // L05 already has a W24 cycle in the seed
  assert.equal(l5.outcome, 'human_review_required');
});

test('L06 fails, retry succeeds, and a cycle that is not failed cannot be retried', async () => {
  await verify('L06');
  const id = (await close('L06')).body.cycle_id;
  assert.equal((await call('POST', `${B}/cycles/${id}/retry`)).body.error, 'cycle_not_failed');
  t += 3000;
  const failed = (await call('GET', `${B}/cycles/${id}`)).body;
  assert.equal(failed.status, 'failed');
  assert.ok(failed.failure_reason);
  const retry = await call('POST', `${B}/cycles/${id}/retry`);
  assert.equal(retry.status, 202);
  assert.equal(retry.body.status, 'running');
  t += 3000;
  assert.deepEqual(await call('GET', `${B}/cycles/${id}`).then((r) => [r.body.status, r.body.outcome]), ['done', 'continue_monitoring']);
  assert.equal((await call('POST', `${B}/cycles/c-L02-23/retry`)).body.error, 'cycle_not_failed');
  assert.equal((await call('POST', `${B}/cycles/nope/retry`)).body.error, 'unknown_cycle');
});

test('only one running cycle per line', async () => {
  await verify('L06');
  const id = (await close('L06')).body.cycle_id;
  t += 3000; // failed
  await call('POST', `${B}/cycles/${id}/retry`);
  assert.equal((await call('POST', `${B}/cycles/${id}/retry`)).body.error, 'cycle_not_failed');
  // Another week on the same line cannot open while this one runs.
  await call('POST', `${B}/lines/L06/weeks/2026-W25/diagnoses`, { img_name: 'healthy.jpg', img: 'A' });
  const other = await call('POST', `${B}/lines/L06/weeks/2026-W25/close`);
  assert.equal(other.status, 409);
  assert.equal(other.body.error, 'cycle_slot_taken');
});

test('state survives until reset, which restores the seed', async () => {
  await verify('L04');
  const id = (await close('L04')).body.cycle_id;
  t += 3000;
  assert.equal((await call('GET', `${B}/cycles/${id}`)).body.status, 'done');
  await fetch(`${base}/__stub/reset`, { method: 'POST' });
  assert.equal((await call('GET', `${B}/cycles/${id}`)).body.error, 'unknown_cycle');
  assert.equal((await call('GET', `${B}/lines/L04`)).body.proposals.length, 0);
  assert.equal((await close('L04')).body.error, 'week_not_verified');
});
