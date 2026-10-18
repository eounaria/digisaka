// The stub backend: one HTTP server standing in for Supabase, the scheduler and Knowledge Maintenance,
// routed by path. Routes are { method, path, handle({ query, body, headers, params }) } where handle
// returns { status, body }. See `match` for path forms.
import http from 'node:http';
import { supabaseRoutes } from './supabase.js';
import { createSeedStore } from './seed.js';
import { schedulerRoutes } from './scheduler.js';
import { createKmStore, kmRoutes } from './km.js';

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

// The request body as received (`raw`, for multipart) and as JSON when it parses (`body`).
async function readBody(req) {
  const chunks = [];
  for await (const c of req) chunks.push(c);
  const raw = Buffer.concat(chunks);
  if (!raw.length) return { raw };
  try { return { raw, body: JSON.parse(raw.toString()) }; } catch { return { raw }; }
}

// The browser signs in against the stub directly (another origin from the page), so every answer allows it.
const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
};

export function createStub({ routes, onReset = [], now = Date.now, cycleMs, stepMs } = {}) {
  const store = createSeedStore();
  const km = createKmStore();
  routes ??= [...supabaseRoutes, ...schedulerRoutes(store, { now, cycleMs }), ...kmRoutes(km, { now, stepMs })];
  onReset = [store.reset, km.reset, ...onReset];
  const all = [
    { method: 'GET', path: '/__stub/health', handle: () => ({ status: 200, body: { ok: true } }) },
    { method: 'POST', path: '/__stub/reset', handle: () => { onReset.forEach((fn) => fn()); return { status: 200, body: { ok: true } }; } },
    ...routes,
  ];
  return http.createServer(async (req, res) => {
    if (req.method === 'OPTIONS') { res.writeHead(204, CORS); res.end(); return; }
    const url = new URL(req.url, 'http://stub');
    let route, params;
    for (const r of all) { params = match(r, req.method, url.pathname); if (params) { route = r; break; } }
    let out;
    try {
      const { raw, body } = await readBody(req);
      out = route ? await route.handle({ query: url.searchParams, body, raw, headers: req.headers, params }) : notFound(url.pathname);
    } catch (e) {
      out = { status: 500, body: { error: 'stub_error', detail: String(e?.message || e) } };
    }
    res.writeHead(out.status, { 'Content-Type': 'application/json', ...CORS });
    res.end(JSON.stringify(out.body));
  });
}
