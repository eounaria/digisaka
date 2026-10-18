// The stub backend: one HTTP server standing in for Supabase, the scheduler and Knowledge Maintenance,
// routed by path. Routes are { method, path, handle({ query, body, headers, params }) } where handle
// returns { status, body }. See `match` for path forms.
import http from 'node:http';
import { supabaseRoutes } from './supabase.js';
import { createSeedStore } from './seed.js';
import { schedulerRoutes } from './scheduler.js';

const notFound = (path) => ({ status: 404, body: { error: 'not_found', detail: `No stub route for ${path}` } });

// A route path is exact, ends in /* to take any suffix, or has :name segments that become params.
function match(route, method, path) {
  if (route.method !== method) return null;
  if (route.path.endsWith('/*')) return path.startsWith(route.path.slice(0, -1)) ? {} : null;
  const want = route.path.split('/'), have = path.split('/');
  if (want.length !== have.length) return null;
  const params = {};
  for (let i = 0; i < want.length; i += 1) {
    if (want[i].startsWith(':')) { try { params[want[i].slice(1)] = decodeURIComponent(have[i]); } catch { return null; } }
    else if (want[i] !== have[i]) return null;
  }
  return params;
}

async function readJson(req) {
  const chunks = [];
  for await (const c of req) chunks.push(c);
  const text = Buffer.concat(chunks).toString();
  if (!text) return undefined;
  try { return JSON.parse(text); } catch { return undefined; }
}

export function createStub({ routes, onReset = [], now = Date.now, cycleMs } = {}) {
  const store = createSeedStore();
  routes ??= [...supabaseRoutes, ...schedulerRoutes(store, { now, cycleMs })];
  onReset = [store.reset, ...onReset];
  const all = [
    { method: 'GET', path: '/__stub/health', handle: () => ({ status: 200, body: { ok: true } }) },
    { method: 'POST', path: '/__stub/reset', handle: () => { onReset.forEach((fn) => fn()); return { status: 200, body: { ok: true } }; } },
    ...routes,
  ];
  return http.createServer(async (req, res) => {
    const url = new URL(req.url, 'http://stub');
    let route, params;
    for (const r of all) { params = match(r, req.method, url.pathname); if (params) { route = r; break; } }
    let out;
    try {
      out = route ? await route.handle({ query: url.searchParams, body: await readJson(req), headers: req.headers, params }) : notFound(url.pathname);
    } catch (e) {
      out = { status: 500, body: { error: 'stub_error', detail: String(e?.message || e) } };
    }
    res.writeHead(out.status, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(out.body));
  });
}
