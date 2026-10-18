import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createStub } from './server.js';
import { SAMPLE_USERS, issueToken, userForToken } from './supabase.js';

let server, base, resets = 0;
before(async () => {
  server = createStub({ onReset: [() => { resets += 1; }] });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => server.close());

const signIn = (email, password) => fetch(`${base}/auth/v1/token?grant_type=password`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password }) });
const claims = (token) => JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString());

test('each sample user gets a token carrying sub, email and roles', async () => {
  for (const u of SAMPLE_USERS) {
    const res = await signIn(u.email, 'anything');
    assert.equal(res.status, 200);
    const c = claims((await res.json()).access_token);
    assert.equal(c.sub, u.id);
    assert.equal(c.email, u.email);
    assert.deepEqual(c.app_metadata.roles, u.roles);
  }
});

test('an unknown email, the password "wrong" and a missing password are the same invalid-credentials answer', async () => {
  for (const [email, pw] of [['nobody@x.test', 'pw'], [SAMPLE_USERS[0].email, 'wrong'], [SAMPLE_USERS[0].email, '']]) {
    const res = await signIn(email, pw);
    assert.equal(res.status, 400);
    assert.deepEqual(await res.json(), { code: 400, error_code: 'invalid_credentials', msg: 'Invalid login credentials' });
  }
});

test('/auth/v1/user answers for a stub token in the shape supabaseAuth.js reads', async () => {
  const admin = SAMPLE_USERS[1];
  const res = await fetch(`${base}/auth/v1/user`, { headers: { Authorization: `Bearer ${issueToken(admin)}` } });
  assert.equal(res.status, 200);
  const u = await res.json();
  assert.equal(u.email, admin.email);
  assert.deepEqual(u.app_metadata.roles, ['administrator']);
});

test('/auth/v1/user is 401 for a missing, garbage, forged or expired token', async () => {
  const forged = issueToken(SAMPLE_USERS[0]).replace(/.$/, (c) => (c === 'A' ? 'B' : 'A'));
  const expired = issueToken(SAMPLE_USERS[0], Date.now() - 2 * 3600 * 1000);
  for (const headers of [{}, { Authorization: 'Bearer garbage' }, { Authorization: `Bearer ${forged}` }, { Authorization: `Bearer ${expired}` }]) {
    assert.equal((await fetch(`${base}/auth/v1/user`, { headers })).status, 401);
  }
  assert.equal(userForToken(issueToken(SAMPLE_USERS[0])).email, SAMPLE_USERS[0].email);
});

test('health and reset exist, and reset runs the registered hooks', async () => {
  assert.deepEqual(await (await fetch(`${base}/__stub/health`)).json(), { ok: true });
  assert.equal((await fetch(`${base}/__stub/reset`, { method: 'POST' })).status, 200);
  assert.equal(resets, 1);
});

test('an unmatched path is a 404 in the scheduler error shape', async () => {
  const res = await fetch(`${base}/nothing/here`);
  assert.equal(res.status, 404);
  const body = await res.json();
  assert.equal(body.error, 'not_found');
  assert.equal(typeof body.detail, 'string');
});
