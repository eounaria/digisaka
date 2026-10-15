import { describe, it, expect, vi } from 'vitest';
import { createSchedulerClient, SchedulerError, messageFor } from './client.js';

function reply(status, body) {
  return { ok: status >= 200 && status < 300, status, json: async () => body };
}
function setup(response, opts = {}) {
  const fetch = vi.fn(async () => response);
  const onUnauthorized = vi.fn();
  const client = createSchedulerClient({ fetch, getToken: () => ('token' in opts ? opts.token : 'tok'), onUnauthorized });
  return { client, fetch, onUnauthorized };
}

describe('createSchedulerClient', () => {
  it('sends the bearer token and returns the JSON body', async () => {
    const { client, fetch } = setup(reply(200, [{ line_id: 'L01' }]));
    expect(await client.listLines()).toEqual([{ line_id: 'L01' }]);
    const [url, init] = fetch.mock.calls[0];
    expect(url).toBe('/api/v1/scheduler/lines');
    expect(init.method).toBe('GET');
    expect(init.headers.Authorization).toBe('Bearer tok');
  });

  it('posts JSON bodies to the documented routes', async () => {
    const { client, fetch } = setup(reply(200, {}));
    await client.confirmSymptoms('q1', true);
    await client.decide('p1', 'approved', 'ok');
    await client.recordApplication('p1', '2026-06-12');
    const calls = fetch.mock.calls.map(([u, i]) => [i.method, u, JSON.parse(i.body)]);
    expect(calls).toEqual([
      ['POST', '/api/v1/scheduler/diagnoses/q1/confirm-symptoms', { confirmed: true }],
      ['POST', '/api/v1/scheduler/proposals/p1/decision', { decision: 'approved', note: 'ok' }],
      ['POST', '/api/v1/scheduler/proposals/p1/application', { applied_on: '2026-06-12' }],
    ]);
  });

  it('builds line-week routes and the upload body', async () => {
    const { client, fetch } = setup(reply(201, {}));
    await client.upload('L04', '2026-W24', { img_name: 'a.jpg', img: 'AAAA' });
    await client.upload('L04', '2026-W24', { img_name: 'b.jpg', img: 'BBBB' }, 'q9');
    await client.getLineWeek('L04', '2026-W24');
    await client.closeWeek('L04', '2026-W24');
    expect(fetch.mock.calls[0][0]).toBe('/api/v1/scheduler/lines/L04/weeks/2026-W24/diagnoses');
    expect(JSON.parse(fetch.mock.calls[0][1].body)).toEqual({ img_name: 'a.jpg', img: 'AAAA' });
    expect(JSON.parse(fetch.mock.calls[1][1].body)).toEqual({ img_name: 'b.jpg', img: 'BBBB', qa_output_id: 'q9' });
    expect(fetch.mock.calls[2][0]).toBe('/api/v1/scheduler/lines/L04/weeks/2026-W24');
    expect(fetch.mock.calls[3][0]).toBe('/api/v1/scheduler/lines/L04/weeks/2026-W24/close');
  });

  it('reads cycles and proposals and retries failed cycles', async () => {
    const { client, fetch } = setup(reply(200, {}));
    await client.getCycle('c1');
    await client.getProposal('c1');
    await client.retryCycle('c1');
    expect(fetch.mock.calls.map(([u, i]) => [i.method, u])).toEqual([
      ['GET', '/api/v1/scheduler/cycles/c1'],
      ['GET', '/api/v1/scheduler/cycles/c1/proposal'],
      ['POST', '/api/v1/scheduler/cycles/c1/retry'],
    ]);
  });

  it('encodes path segments', async () => {
    const { client, fetch } = setup(reply(200, {}));
    await client.getLine('L/1');
    expect(fetch.mock.calls[0][0]).toBe('/api/v1/scheduler/lines/L%2F1');
  });

  it('throws SchedulerError with the documented code and detail', async () => {
    const { client } = setup(reply(409, { error: 'week_not_verified', detail: 'no finished session' }));
    const err = await client.closeWeek('L04', '2026-W24').catch((e) => e);
    expect(err).toBeInstanceOf(SchedulerError);
    expect(err).toMatchObject({ status: 409, code: 'week_not_verified', detail: 'no finished session' });
  });

  it('falls back to a generic code when the body is not JSON', async () => {
    const res = { ok: false, status: 502, json: async () => { throw new Error('bad'); } };
    const { client } = setup(res);
    const err = await client.listLines().catch((e) => e);
    expect(err).toMatchObject({ status: 502, code: 'http_502' });
  });

  it('calls onUnauthorized on a 401 and still throws', async () => {
    const { client, onUnauthorized } = setup(reply(401, { error: 'unauthenticated', detail: 'expired' }));
    await expect(client.listLines()).rejects.toMatchObject({ code: 'unauthenticated' });
    expect(onUnauthorized).toHaveBeenCalledOnce();
  });

  it('fails without a token before any request', async () => {
    const { client, fetch, onUnauthorized } = setup(reply(200, []), { token: null });
    await expect(client.listLines()).rejects.toMatchObject({ code: 'unauthenticated' });
    expect(fetch).not.toHaveBeenCalled();
    expect(onUnauthorized).toHaveBeenCalledOnce();
  });

  it('turns a network failure into a SchedulerError', async () => {
    const client = createSchedulerClient({ fetch: async () => { throw new TypeError('down'); }, getToken: () => 't', onUnauthorized() {} });
    await expect(client.listLines()).rejects.toMatchObject({ code: 'network_error', status: 0 });
  });
});

describe('messageFor', () => {
  it('gives readable text for documented codes and never the raw payload', () => {
    expect(messageFor(new SchedulerError(409, 'week_not_verified', 'x'))).toMatch(/symptom confirmation/i);
    expect(messageFor(new SchedulerError(502, 'qa_unavailable', 'x'))).toMatch(/QA/);
    expect(messageFor(new SchedulerError(422, 'invalid_week', 'x'))).toMatch(/week/i);
  });
  it('falls back to a generic message for unknown codes and plain errors', () => {
    expect(messageFor(new SchedulerError(500, 'weird', 'secret'))).not.toMatch(/secret/);
    expect(messageFor(new Error('boom'))).toBe('Something went wrong. Try again.');
  });
});
