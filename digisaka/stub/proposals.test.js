import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { createStub } from './server.js';
import { SAMPLE_USERS, issueToken } from './supabase.js';

const B = '/api/v1/scheduler';
const farmer = { Authorization: `Bearer ${issueToken(SAMPLE_USERS[0])}`, 'Content-Type': 'application/json' };
let server, base;
beforeEach(async () => {
  server = createStub();
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  base = `http://127.0.0.1:${server.address().port}`;
});
afterEach(() => server.close());

const call = async (method, path, body) => {
  const res = await fetch(base + B + path, { method, headers: farmer, body: body ? JSON.stringify(body) : undefined });
  return { status: res.status, body: await res.json() };
};
const decide = (id, decision, note) => call('POST', `/proposals/${id}/decision`, { decision, ...(note ? { note } : {}) });
const apply = (id, applied_on = '2026-06-16') => call('POST', `/proposals/${id}/application`, { applied_on });
const statusOf = async (line, id) => (await call('GET', `/lines/${line}`)).body.proposals.find((p) => p.proposal_id === id).status;

test('a proposal carries treatment, window, reason, constraints and next assessment', async () => {
  const p = (await call('GET', '/cycles/c-L03-24/proposal')).body;
  assert.deepEqual(p.window, { start: '2026-06-10', end: '2026-06-12' });
  assert.equal(p.treatment.name, 'Protectant fungicide spray');
  assert.equal(p.next_assessment, '2026-W25');
  assert.deepEqual(p.constraints, []);
  assert.equal(p.decision, undefined);
  assert.equal((await call('GET', '/cycles/nope/proposal')).body.error, 'unknown_proposal');
});

test('the seed: L02 reads as approved and applied, L05 explains why a person must decide', async () => {
  assert.equal(await statusOf('L02', 'p-L02-23'), 'applied');
  assert.equal((await call('GET', '/cycles/c-L02-23/proposal')).body.decision.decision, 'approved');
  const review = (await call('GET', '/cycles/c-L05-24/proposal')).body;
  assert.ok(review.constraints.length > 0);
});

test('approve with a note, then apply: the line status follows', async () => {
  const r = await decide('p-L03-24', 'approved', '  Spray at dawn  ');
  assert.deepEqual(r.body, { proposal_id: 'p-L03-24', decision: 'approved', note: 'Spray at dawn' });
  assert.deepEqual((await call('GET', '/cycles/c-L03-24/proposal')).body.decision, { decision: 'approved', note: 'Spray at dawn' });
  assert.equal(await statusOf('L03', 'p-L03-24'), 'approved');
  const applied = await apply('p-L03-24');
  assert.equal(applied.status, 201);
  assert.equal(await statusOf('L03', 'p-L03-24'), 'applied');
  assert.deepEqual((await call('GET', '/lines/L03')).body.applications, [{ proposal_id: 'p-L03-24', applied_on: '2026-06-16' }]);
});

test('rejecting is final and cannot be applied', async () => {
  await decide('p-L03-24', 'rejected');
  assert.equal(await statusOf('L03', 'p-L03-24'), 'rejected');
  assert.equal((await apply('p-L03-24')).body.error, 'proposal_not_approved');
});

test('the three 409s', async () => {
  assert.equal((await apply('p-L03-24')).body.error, 'proposal_not_approved');
  await decide('p-L03-24', 'approved');
  const again = await decide('p-L03-24', 'rejected');
  assert.equal(again.status, 409);
  assert.equal(again.body.error, 'proposal_already_decided');
  await apply('p-L03-24');
  const twice = await apply('p-L03-24');
  assert.equal(twice.status, 409);
  assert.equal(twice.body.error, 'application_already_recorded');
  assert.equal((await apply('p-L02-23')).body.error, 'application_already_recorded');
});

test('bad input and unknown ids', async () => {
  assert.equal((await decide('p-L03-24', 'maybe')).body.error, 'validation_error');
  await decide('p-L03-24', 'approved');
  assert.equal((await apply('p-L03-24', '16/06/2026')).body.error, 'validation_error');
  assert.equal((await decide('nope', 'approved')).body.error, 'unknown_proposal');
  assert.equal((await apply('nope')).status, 404);
});

test('a proposal made by closing a week can be read and decided', async () => {
  let t = 0;
  server.close();
  server = createStub({ now: () => t, cycleMs: 100 });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  base = `http://127.0.0.1:${server.address().port}`;
  await call('POST', '/lines/L04/weeks/2026-W24/diagnoses', { img_name: 'healthy.jpg', img: 'A' });
  await call('POST', '/lines/L04/weeks/2026-W24/close');
  t += 100;
  const p = (await call('GET', '/cycles/c-L04-24/proposal')).body;
  assert.equal(p.proposal_id, 'p-L04-24');
  assert.equal(p.next_assessment, '2026-W25');
  assert.equal((await decide(p.proposal_id, 'approved')).status, 200);
});
