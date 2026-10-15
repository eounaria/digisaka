process.env.DB_PATH = ':memory:';
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';

const { createApp } = await import('./app.js');
let server, base;

before(() => new Promise((r) => { server = createApp({ verifyToken: async () => { throw new Error('should not be called'); } }).listen(0, () => { base = `http://localhost:${server.address().port}`; r(); }); }));
after(() => server.close());

const get = (url, init) => fetch(base + url, init);

test('health stays open', async () => assert.equal((await get('/api/health')).status, 200));

test('the old shell endpoints are gone', async () => {
  for (const [method, url] of [['POST', '/api/auth/login'], ['POST', '/api/auth/register'], ['GET', '/api/dashboard'], ['GET', '/api/bulks'],
    ['GET', '/api/me/use-cases'], ['GET', '/api/schedules'], ['GET', '/api/notifications']])
    assert.equal((await get(url, { method })).status, 404, url);
});

test('the legacy prototype is not served', async () => {
  const [legacy, other] = await Promise.all([get('/legacy/index.html'), get('/no-such-page')]);   // both fall to the SPA shell or 404
  assert.equal(legacy.status, other.status);
  assert.equal(await legacy.text(), await other.text());
});

test('the admin API needs a bearer token', async () => assert.equal((await get('/api/admin/use-cases')).status, 401));
