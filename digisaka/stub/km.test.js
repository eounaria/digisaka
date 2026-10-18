import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { createStub } from './server.js';
import { SAMPLE_USERS, issueToken } from './supabase.js';
import { pathOf } from './km.js';

const B = '/api/v1/knowledge-maintenance/workflows';
const STEP = 3000;
const headers = (u) => ({ Authorization: `Bearer ${issueToken(u)}`, 'Content-Type': 'application/json' });
const admin = headers(SAMPLE_USERS[1]);
let server, base, t;

beforeEach(async () => {
  t = 1_000_000;
  server = createStub({ now: () => t, stepMs: STEP });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  base = `http://127.0.0.1:${server.address().port}`;
});
afterEach(() => server.close());

const call = async (method, path, body, h = admin) => {
  const res = await fetch(base + B + path, { method, headers: h, body: body ? JSON.stringify(body) : undefined });
  return { status: res.status, body: await res.json() };
};
const submit = async (title) => (await call('POST', '', { document: { title, content: 'Late blight spreads in humid weather.' } })).body.workflow_id;
const state = async (id) => (await call('GET', `/${id}`)).body.state;
const tick = (n = 1) => { t += STEP * n; };
const facts = async (id, q = '') => (await call('GET', `/${id}/facts?limit=500${q}`)).body;
// Walks a happy workflow to extraction review and decides every pending fact.
async function toFinal(id) {
  tick(3);
  for (const f of (await facts(id, '&disposition=pending')).facts) await call('POST', `/${id}/facts/${f.id}/claim`) && await call('POST', `/${id}/facts/${f.id}/review`, { lock_version: f.lock_version, review_stage: 'extraction_review', decision: 'accept' });
  tick(3);
}

test('the title picks the path', () => {
  assert.deepEqual(pathOf('Potato notes'), { commitFail: false, fail: false, slow: false });
  assert.deepEqual(pathOf('A FAIL case'), { commitFail: false, fail: true, slow: false });
  assert.deepEqual(pathOf('commit-fail run'), { commitFail: true, fail: false, slow: false });
  assert.equal(pathOf('slow one').slow, true);
});

test('submitting JSON creates a workflow that advances on the timer and stops at the first gate', async () => {
  const id = await submit('Potato notes');
  const w = (await call('GET', `/${id}`)).body;
  assert.equal(w.state, 'document_submitted');
  assert.equal(w.completed_at, null);
  assert.equal(w.failure, null);
  tick(); assert.equal(await state(id), 'extracting');
  tick(); assert.equal(await state(id), 'restoring_verifying');
  tick(); assert.equal(await state(id), 'awaiting_extraction_review');
  tick(50); assert.equal(await state(id), 'awaiting_extraction_review');
});

test('a multipart file submission works and takes the title from the form or the filename', async () => {
  const form = new FormData();
  form.set('title', 'fail upload');
  form.set('file', new Blob(['Some text'], { type: 'text/plain' }), 'notes.txt');
  const res = await fetch(base + B, { method: 'POST', headers: { Authorization: admin.Authorization }, body: form });
  assert.equal(res.status, 202);
  const id = (await res.json()).workflow_id;
  tick(3); assert.equal(await state(id), 'failed');
  const bare = new FormData();
  bare.set('file', new Blob(['x']), 'slow-notes.txt');
  const id2 = (await (await fetch(base + B, { method: 'POST', headers: { Authorization: admin.Authorization }, body: bare })).json()).workflow_id;
  tick(3); assert.equal(await state(id2), 'document_submitted', 'slow comes from the filename');
});

test('bad submissions, unknown ids and the wrong caller get the nested error shape', async () => {
  assert.equal((await call('POST', '', { document: { title: '', content: 'x' } })).body.error.code, 'VALIDATION_ERROR');
  assert.deepEqual((await call('GET', '/nope')).body.error, { code: 'NOT_FOUND', message: 'Workflow not found', details: {} });
  assert.equal((await call('GET', '/nope', undefined, {})).status, 401);
  assert.equal((await call('GET', '/nope', undefined, headers(SAMPLE_USERS[0]))).status, 403);
});

test('a fail title retries then ends in failed with a cause', async () => {
  const id = await submit('fail please');
  tick(); assert.equal((await call('GET', `/${id}`)).body.retrying.max_attempts, 3);
  tick();
  const w = (await call('GET', `/${id}`)).body;
  assert.equal(w.state, 'failed');
  assert.equal(w.retrying, null);
  assert.equal(w.failure.code, 'EXTRACTION_FAILED');
  assert.equal(w.retry_available, false);
  assert.equal((await facts(id)).total, 0);
});

test('slow stretches every state', async () => {
  const id = await submit('slow doc');
  tick(9); assert.equal(await state(id), 'document_submitted');
  tick(1); assert.equal(await state(id), 'extracting');
});

test('facts page and filter, and show every block somewhere', async () => {
  const id = await submit('Potato notes'); tick(3);
  const all = await facts(id);
  assert.equal(all.total, 30);
  const page = (await call('GET', `/${id}/facts?limit=10&offset=25`)).body;
  assert.deepEqual([page.facts.length, page.total, page.limit, page.offset], [5, 30, 10, 25]);
  for (const d of ['pending', 'accepted', 'rejected', 'unresolved']) assert.equal((await facts(id, `&disposition=${d}`)).facts.every((f) => f.disposition === d), true);
  assert.ok((await facts(id, '&disposition=unresolved')).total > 0);
  const f = all.facts;
  assert.ok(f.some((x) => x.gate3?.status === 'passed') && f.some((x) => x.gate3?.violations.length));
  assert.ok(f.some((x) => x.mend?.altered) && f.some((x) => x.mend && !x.mend.altered));
  assert.ok(f.some((x) => x.entity_resolution) && f.some((x) => x.entity_match_warnings.length) && f.some((x) => x.entity_conflict_warnings.length));
  assert.equal((await call('GET', `/${id}/facts?disposition=bogus`)).status, 422);
  assert.equal((await facts(await submit('early'))).total, 0, 'no facts before extraction finishes');
});

test('claim, takeover of a colleague, release, and a stale review', async () => {
  const id = await submit('Potato notes'); tick(3);
  const colleague = (await facts(id)).facts.find((f) => f.claimed_by);
  const blocked = await call('POST', `/${id}/facts/${colleague.id}/review`, { lock_version: colleague.lock_version, review_stage: 'extraction_review', decision: 'accept' });
  assert.equal(blocked.status, 409, 'a colleague holds it');
  const taken = (await call('POST', `/${id}/facts/${colleague.id}/claim`)).body;
  assert.equal(taken.previous_holder, colleague.claimed_by);
  assert.equal(taken.claimed_by, SAMPLE_USERS[1].id);
  assert.equal((await call('POST', `/${id}/facts/fact-05/claim`)).body.previous_holder, undefined);
  assert.equal((await call('POST', `/${id}/facts/fact-05/release`)).body.claimed_by, null);
  const f = (await facts(id)).facts.find((x) => x.id === 'fact-03');
  const ok = await call('POST', `/${id}/facts/fact-03/review`, { lock_version: f.lock_version, review_stage: 'extraction_review', decision: 'reject' });
  assert.deepEqual([ok.status, ok.body.disposition, ok.body.lock_version], [200, 'rejected', f.lock_version + 1]);
  const stale = await call('POST', `/${id}/facts/fact-03/review`, { lock_version: f.lock_version, review_stage: 'extraction_review', decision: 'accept' });
  assert.equal(stale.status, 409);
  assert.equal((await call('POST', `/${id}/facts/fact-04/review`, { lock_version: 0, review_stage: 'final_review', decision: 'accept' })).status, 422);
});

test('deciding the last pending fact moves on to final approval, which only approve passes', async () => {
  const id = await submit('Potato notes');
  assert.equal((await call('POST', `/${id}/approve`)).status, 409);
  await toFinal(id);
  assert.equal(await state(id), 'awaiting_final_approval');
  const stale = (await facts(id, '&disposition=accepted')).facts.filter((f) => f.requires_action);
  assert.equal(stale.length, 2);
  await call('POST', `/${id}/facts/${stale[0].id}/review`, { lock_version: stale[0].lock_version, review_stage: 'final_review', decision: 'reject' });
  assert.equal((await facts(id, '&disposition=accepted')).facts.filter((f) => f.requires_action).length, 1);
  assert.equal((await call('POST', `/${id}/approve`)).status, 202);
  assert.equal(await state(id), 'committing');
  tick(); const done = (await call('GET', `/${id}`)).body;
  assert.equal(done.state, 'completed');
  assert.ok(done.completed_at);
  assert.equal((await call('POST', `/${id}/approve`)).status, 409);
  assert.deepEqual([(await facts(id, '&disposition=rejected')).total, (await facts(id, '&disposition=unresolved')).total], [1, 4]);
});

test('commit-fail ends in commit_failed once, and approve retries to success', async () => {
  const id = await submit('commit-fail batch');
  await toFinal(id);
  await call('POST', `/${id}/approve`);
  tick();
  const failed = (await call('GET', `/${id}`)).body;
  assert.deepEqual([failed.state, failed.retry_available, failed.failure.code], ['commit_failed', true, 'COMMIT_FAILED']);
  assert.equal((await call('POST', `/${id}/approve`)).status, 202);
  assert.equal((await call('GET', `/${id}`)).body.failure, null);
  tick(); assert.equal(await state(id), 'completed');
});

test('reset forgets workflows', async () => {
  const id = await submit('Potato notes');
  await fetch(`${base}/__stub/reset`, { method: 'POST' });
  assert.equal((await call('GET', `/${id}`)).status, 404);
});
