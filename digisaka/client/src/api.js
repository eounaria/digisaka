let onUnauthorized = () => {};
let getToken = () => null;
export const setUnauthorizedHandler = (fn) => { onUnauthorized = fn; };
export const setTokenProvider = (fn) => { getToken = fn; };

const authHeader = () => { const t = getToken(); return t ? { Authorization: `Bearer ${t}` } : {}; };

async function request(method, url, body) {
  const res = await fetch(url, { method, headers: { ...authHeader(), ...(body ? { 'Content-Type': 'application/json' } : {}) }, body: body ? JSON.stringify(body) : undefined });
  const data = await res.json().catch(() => ({}));
  if (res.status === 401) onUnauthorized();
  if (!res.ok) throw Object.assign(new Error(data.error || 'Request failed'), { status: res.status });
  return data;
}
// Send a file as the raw request body (used for image uploads).
async function upload(url, file) {
  const res = await fetch(url, { method: 'POST', headers: { ...authHeader(), 'Content-Type': file.type || 'application/octet-stream' }, body: file });
  const data = await res.json().catch(() => ({}));
  if (res.status === 401) onUnauthorized();
  if (!res.ok) throw Object.assign(new Error(data.error || 'Upload failed'), { status: res.status });
  return data;
}
export const api = { get: (u) => request('GET', u), post: (u, b) => request('POST', u, b || {}), put: (u, b) => request('PUT', u, b), del: (u) => request('DELETE', u), upload };
