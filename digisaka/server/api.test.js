process.env.DB_PATH = ':memory:';
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';

const { createApp } = await import('./app.js');
let server, base, cookie = '';

before(() => new Promise((r) => { server = createApp().listen(0, () => { base = `http://localhost:${server.address().port}`; r(); }); }));
after(() => server.close());

const call = async (method, url, body) => {
  const res = await fetch(base + url, { method, headers: { 'Content-Type': 'application/json', cookie }, body: body && JSON.stringify(body) });
  const set = res.headers.get('set-cookie'); if (set) cookie = set.split(';')[0];
  return { status: res.status, data: await res.json() };
};

test('requires sign-in', async () => assert.equal((await call('GET', '/api/dashboard')).status, 401));

test('register, save a bulk, read dashboard', async () => {
  const reg = await call('POST', '/api/auth/register', { email: 'a@b.co', name: 'Ana Reyes', password: 'longenough1' });
  assert.equal(reg.status, 201); assert.equal(reg.data.user.initials, 'AR');

  const leaves = [{ valid: true, stage: 0 }, { valid: true, stage: 2 }, { valid: false }];
  const put = await call('PUT', '/api/bulks/BA-001', { plant: 'Banana Plant #001', date: 'August 19, 2026', leaves });
  assert.equal(put.status, 200); assert.deepEqual(put.data.bulk.counts, { 1: 0, 2: 1, 3: 0, 4: 0 });

  const dash = await call('GET', '/api/dashboard');
  assert.deepEqual(dash.data, { leavesScanned: 3, bulksAssessed: 1, leavesNeedingTreatment: 1 });
});

test('use case preferences', async () => {
  assert.equal((await call('GET', '/api/me/use-cases')).data.useCases.length, 3);
  assert.equal((await call('PUT', '/api/me/preferences', { useCase: 'rice' })).status, 200);
  assert.equal((await call('GET', '/api/auth/me')).data.user.useCase, 'rice');
  assert.equal((await call('PUT', '/api/me/preferences', { useCase: 'nope' })).status, 400);
});

test('bad login rejected', async () => { cookie=''; assert.equal((await call('POST', '/api/auth/login', { email: 'a@b.co', password: 'wrong' })).status, 401); });

test('deleting a bulk removes its schedule and 404s the second time', async () => {
  await call('POST', '/api/auth/login', { email: 'a@b.co', password: 'longenough1' });
  const leaves = [{ valid: true, stage: 2, treatmentEligible: true }];
  await call('PUT', '/api/bulks/BA-DEL', { plant: 'Banana Plant #002', date: 'August 19, 2026', leaves });
  const groups = [{ stage: 2, leafNums: [1], window: 'x', schedule: [{ label: 'Treatment', day: 20, month: 'August', desc: 'd', status: 'Suggested' }] }];
  assert.equal((await call('PUT', '/api/schedules/BA-DEL', { groups })).status, 200);
  assert.equal((await call('DELETE', '/api/bulks/BA-DEL')).status, 200);
  const s = await call('GET', '/api/schedules');
  assert.ok(!s.data.schedules.some((x) => x.bulkId === 'BA-DEL'));
  assert.equal((await call('DELETE', '/api/bulks/BA-DEL')).status, 404);
});
