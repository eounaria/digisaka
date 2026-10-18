// The stub backend: one HTTP server standing in for Supabase, the scheduler and Knowledge Maintenance,
// routed by path. Routes are { method, path, handle({ query, body, headers, params }) } where handle
// returns { status, body }. A path ending in /* matches any suffix.
import http from 'node:http';
import { supabaseRoutes } from './supabase.js';

const notFound = (path) => ({ status: 404, body: { error: 'not_found', detail: `No stub route for ${path}` } });

const matches = (route, method, path) => route.method === method && (route.path.endsWith('/*') ? path.startsWith(route.path.slice(0, -1)) : route.path === path);

async function readJson(req) {
  const chunks = [];
  for await (const c of req) chunks.push(c);
  const text = Buffer.concat(chunks).toString();
  if (!text) return undefined;
  try { return JSON.parse(text); } catch { return undefined; }
}

export function createStub({ routes = [...supabaseRoutes], onReset = [] } = {}) {
  const all = [
    { method: 'GET', path: '/__stub/health', handle: () => ({ status: 200, body: { ok: true } }) },
    { method: 'POST', path: '/__stub/reset', handle: () => { onReset.forEach((fn) => fn()); return { status: 200, body: { ok: true } }; } },
    ...routes,
  ];
  return http.createServer(async (req, res) => {
    const url = new URL(req.url, 'http://stub');
    const route = all.find((r) => matches(r, req.method, url.pathname));
    let out;
    try {
      out = route ? await route.handle({ query: url.searchParams, body: await readJson(req), headers: req.headers }) : notFound(url.pathname);
    } catch (e) {
      out = { status: 500, body: { error: 'stub_error', detail: String(e?.message || e) } };
    }
    res.writeHead(out.status, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(out.body));
  });
}
