import { describe, it, expect } from 'vitest';
import { proxyTargets } from './vite.proxy.js';

const LOCAL = { scheduler: 'http://127.0.0.1:8001', km: 'http://127.0.0.1:8000', api: 'http://localhost:3000' };

describe('proxyTargets', () => {
  it('keeps the local targets when nothing is set', () => {
    expect(proxyTargets({})).toEqual(LOCAL);
  });

  it('takes the targets from the environment', () => {
    expect(proxyTargets({ SCHEDULER_URL: 'http://host.docker.internal:8001', KM_URL: 'http://host.docker.internal:8000', API_URL: 'http://api:3000' })).toEqual({
      scheduler: 'http://host.docker.internal:8001',
      km: 'http://host.docker.internal:8000',
      api: 'http://api:3000',
    });
  });

  it('treats empty values as unset', () => {
    expect(proxyTargets({ SCHEDULER_URL: '', KM_URL: '', API_URL: '' })).toEqual(LOCAL);
  });
});
