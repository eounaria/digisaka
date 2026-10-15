import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createSupabaseVerifier } from './supabaseAuth.js';

const URL_ = 'https://proj.example.test';
const user = (over = {}) => ({ id: 'u1', email: 'tech@x.co', app_metadata: { roles: ['administrator'] }, user_metadata: { full_name: 'Tess Nical' }, ...over });
const reply = (status, body) => async (url, init) => { reply.calls.push({ url, init }); return new Response(JSON.stringify(body), { status }); };
reply.calls = [];
const verifier = (fetch) => createSupabaseVerifier({ fetch, url: URL_, anonKey: 'anon' });

test('a valid token yields the email, display name and known roles', async () => {
  reply.calls.length = 0;
  const who = await verifier(reply(200, user({ app_metadata: { roles: ['domain_expert', 'practitioner', 'wizard'] } })))('tok');
  assert.deepEqual(who, { email: 'tech@x.co', name: 'Tess Nical', roles: ['domain_expert', 'practitioner'] });
  assert.equal(reply.calls[0].url, `${URL_}/auth/v1/user`);
  assert.equal(reply.calls[0].init.headers.Authorization, 'Bearer tok');
  assert.equal(reply.calls[0].init.headers.apikey, 'anon');
});

test('the name falls back to the email, and the legacy single role is not honoured', async () => {
  const who = await verifier(reply(200, user({ user_metadata: {}, app_metadata: { role: 'administrator' } })))('tok');
  assert.deepEqual(who, { email: 'tech@x.co', name: 'tech@x.co', roles: [] });
});

test('a token Supabase rejects is a 401', async () => {
  await assert.rejects(verifier(reply(401, { msg: 'bad jwt' }))('tok'), { status: 401 });
  await assert.rejects(verifier(reply(403, {}))('tok'), { status: 401 });
});

test('an outage fails closed with 503', async () => {
  await assert.rejects(verifier(reply(500, {}))('tok'), { status: 503 });
  await assert.rejects(verifier(async () => { throw new Error('ECONNREFUSED'); })('tok'), { status: 503 });
});

test('missing Supabase settings fail closed with 503', async () => {
  await assert.rejects(createSupabaseVerifier({ fetch: reply(200, user()), url: '', anonKey: '' })('tok'), { status: 503 });
});
