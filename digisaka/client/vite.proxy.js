// Dev proxy targets. Defaults suit a run outside Docker; compose overrides them.
export const proxyTargets = (env) => ({
  scheduler: env.SCHEDULER_URL || 'http://127.0.0.1:8001',
  api: env.API_URL || 'http://localhost:3000',
});
