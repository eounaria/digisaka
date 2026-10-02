window.api = (() => {
  async function request(method, url, body) {
    const res = await fetch(url, { method, headers: body ? { 'Content-Type': 'application/json' } : undefined, body: body ? JSON.stringify(body) : undefined, credentials: 'same-origin' });
    const data = await res.json().catch(() => ({}));
    if (res.status === 401 && !url.startsWith('/api/auth/')) { location.href = '/login'; throw new Error('Signed out'); }
    if (!res.ok) throw Object.assign(new Error(data.error || 'Request failed'), { status: res.status });
    return data;
  }
  return { get: (u) => request('GET', u), post: (u, b) => request('POST', u, b || {}), put: (u, b) => request('PUT', u, b) };
})();
