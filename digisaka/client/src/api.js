// Scheduler errors are {error: code, detail: text}; the admin API sends {error: text}.
// The Knowledge Maintenance API nests it: {error: {code, message, details}}.
const failure = (data, status, fallback) => {
  const e = data.error;
  if (e && typeof e === 'object') return Object.assign(new Error(e.message || fallback), { status, code: e.code });
  return Object.assign(new Error(data.detail || e || fallback), { status, code: e });
};

let onUnauthorized = () => {};
let getToken = () => null;
export const setUnauthorizedHandler = (fn) => { onUnauthorized = fn; };
export const setTokenProvider = (fn) => { getToken = fn; };

const authHeader = () => { const t = getToken(); return t ? { Authorization: `Bearer ${t}` } : {}; };

async function request(method, url, body) {
  const res = await fetch(url, { method, headers: { ...authHeader(), ...(body ? { 'Content-Type': 'application/json' } : {}) }, body: body ? JSON.stringify(body) : undefined });
  const data = await res.json().catch(() => ({}));
  if (res.status === 401) onUnauthorized();
  if (!res.ok) throw failure(data, res.status, 'Request failed');
  return data;
}
// Send a file as the raw request body (used for image uploads).
async function upload(url, file) {
  const res = await fetch(url, { method: 'POST', headers: { ...authHeader(), 'Content-Type': file.type || 'application/octet-stream' }, body: file });
  const data = await res.json().catch(() => ({}));
  if (res.status === 401) onUnauthorized();
  if (!res.ok) throw failure(data, res.status, 'Upload failed');
  return data;
}
// Send a multipart form (the browser sets the boundary, so no Content-Type here).
async function postForm(url, form) {
  const res = await fetch(url, { method: 'POST', headers: authHeader(), body: form });
  const data = await res.json().catch(() => ({}));
  if (res.status === 401) onUnauthorized();
  if (!res.ok) throw failure(data, res.status, 'Request failed');
  return data;
}
export const api = { get: (u) => request('GET', u), post: (u, b) => request('POST', u, b || {}), put: (u, b) => request('PUT', u, b), del: (u) => request('DELETE', u), upload, postForm };
