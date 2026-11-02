import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { createStub } from './server.js';
import { SAMPLE_USERS, issueToken } from './supabase.js';

const B = '/api/v1/scheduler/prototype';
const farmerToken = issueToken(SAMPLE_USERS.find((user) => user.email === 'farmer@digisaka.test'));
const farmer = { Authorization: 'Bearer ' + farmerToken, 'Content-Type': 'application/json' };
let server, base;

beforeEach(async () => {
  server = createStub();
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  base = `http://127.0.0.1:${server.address().port}`;
});
afterEach(() => server.close());

const call = async (method, path, body, headers = farmer) => {
  const response = await fetch(`${base}${B}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: response.status, body: await response.json() };
};

test('prototype fixture returns labeled weather, spray and fungicide data', async () => {
  const result = await call('GET', '/lines/L04/weeks/2026-W24');
  assert.equal(result.status, 200);
  assert.equal(result.body.sample, true);
  assert.match(result.body.label, /Sample data for demo/);
  assert.equal(result.body.weather.rainfall_7d_mm, 42);
  assert.equal(result.body.weather.forecast.length, 5);
  assert.deepEqual(result.body.recommended_action, {
    preventive: true,
    mechanical: true,
    treatment: false,
    monitor: false,
    provisional_label: 'Provisional threshold',
    summary: 'Protect young leaves and remove heavily infected leaves. Reassess after this scan week.',
  });
  assert.equal(result.body.spray_history.length, 4);
  assert.equal(result.body.frac_history.length, 3);
  assert.equal(result.body.products.find((product) => product.id === 'opt-protectant').rate, 'Not provided');
  assert.equal(result.body.products.filter((product) => product.eligibility === 'Eligible in prototype data').length, 2);
  assert.equal(result.body.products.filter((product) => product.eligibility !== 'Eligible in prototype data').length, 3);
  assert.equal(result.body.products.find((product) => product.id === 'opt-tilt').eligibility, 'Excluded in prototype data');
  assert.equal(result.body.excluded.length, 3);
});

test('a selected prototype product updates only the stub proposal', async () => {
  const result = await call('POST', '/lines/L03/weeks/2026-W24/selection', { option_id: 'opt-chlorothalonil' });
  assert.equal(result.status, 200);
  assert.equal(result.body.selected_option_id, 'opt-chlorothalonil');
  assert.equal(result.body.sample, true);
  const proposal = await fetch(`${base}/api/v1/scheduler/cycles/c-L03-24/proposal`, { headers: farmer });
  const details = await proposal.json();
  assert.equal(details.treatment.name, 'Chlorothalonil 720 SC');
  assert.equal(details.treatment.frac_code, 'M05');
  assert.equal(details.decision, undefined);
});

test('prototype product selection validates the line, week, option and proposal', async () => {
  assert.equal((await call('GET', '/lines/L99/weeks/2026-W24')).body.error, 'unknown_line');
  assert.equal((await call('GET', '/lines/L04/weeks/2026-W54')).body.error, 'invalid_week');
  assert.equal((await call('POST', '/lines/L03/weeks/2026-W24/selection', { option_id: 'missing' })).body.error, 'invalid_option');
  const noProposal = await call('POST', '/lines/L04/weeks/2026-W24/selection', { option_id: 'opt-chlorothalonil' });
  assert.equal(noProposal.status, 409);
  assert.equal(noProposal.body.error, 'proposal_required');
});

test('reset restores the initial prototype selection', async () => {
  await call('POST', '/lines/L03/weeks/2026-W24/selection', { option_id: 'opt-chlorothalonil' });
  await fetch(`${base}/__stub/reset`, { method: 'POST' });
  const response = await call('GET', '/lines/L03/weeks/2026-W24');
  assert.equal(response.body.selected_option_id, 'opt-protectant');
});

test('prototype data requires the scheduler practitioner role', async () => {
  const adminUser = SAMPLE_USERS.find((user) => user.email === 'admin@digisaka.test');
  const adminHeaders = { Authorization: 'Bearer ' + issueToken(adminUser) };
  const forbidden = await call('GET', '/lines/L04/weeks/2026-W24', null, adminHeaders);
  assert.equal(forbidden.status, 403);
  assert.equal((await call('GET', '/lines/L04/weeks/2026-W24', null, {})).status, 401);
});
