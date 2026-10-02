let onUnauthorized = () => {};
export const setUnauthorizedHandler = (fn) => { onUnauthorized = fn; };

async function request(method, url, body) {
  const res = await fetch(url, { method, headers: body ? { 'Content-Type': 'application/json' } : undefined, body: body ? JSON.stringify(body) : undefined, credentials: 'same-origin' });
  const data = await res.json().catch(() => ({}));
  if (res.status === 401 && !url.startsWith('/api/auth/')) onUnauthorized();
  if (!res.ok) throw Object.assign(new Error(data.error || 'Request failed'), { status: res.status });
  return data;
}
// Send a file as the raw request body (used for image uploads).
async function upload(url, file) {
  const res = await fetch(url, { method: 'POST', headers: { 'Content-Type': file.type || 'application/octet-stream' }, body: file, credentials: 'same-origin' });
  const data = await res.json().catch(() => ({}));
  if (res.status === 401) onUnauthorized();
  if (!res.ok) throw Object.assign(new Error(data.error || 'Upload failed'), { status: res.status });
  return data;
}
export const api = { get: (u) => request('GET', u), post: (u, b) => request('POST', u, b || {}), put: (u, b) => request('PUT', u, b), del: (u) => request('DELETE', u), upload };
