process.env.DB_PATH = ':memory:';
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';

const { createApp } = await import('./app.js');
const { TECHNICAL_USER_ROLES } = await import('./supabaseAuth.js');
const { db } = await import('./db.js');
let server, base, token = 'tech-token';
const PEOPLE = {
  'tech-token': { email: 'adm@x.co', name: 'Ada Min', roles: ['administrator'] },
  'practitioner-token': { email: 'prac@x.co', name: 'Pra Ctitioner', roles: ['practitioner'] },
  'down-token': null,
};
const verifyToken = async (t) => {
  if (!(t in PEOPLE)) throw Object.assign(new Error('bad'), { status: 401 });
  if (PEOPLE[t] === null) throw Object.assign(new Error('down'), { status: 503 });
  return PEOPLE[t];
};
const UC = 'black-sigatoka';

before(() => new Promise((r) => { server = createApp({ verifyToken }).listen(0, () => { base = `http://localhost:${server.address().port}`; r(); }); }));
after(() => server.close());

const call = async (method, url, body, headers = {}) => {
  const isBuf = Buffer.isBuffer(body);
  const res = await fetch(base + url, { method, headers: { ...(body && !isBuf ? { 'Content-Type': 'application/json' } : {}), ...(token ? { Authorization: `Bearer ${token}` } : {}), ...headers }, body: body && (isBuf ? body : JSON.stringify(body)) });
  const ct = res.headers.get('content-type') || '';
  return { status: res.status, data: ct.includes('json') ? await res.json() : null, type: ct };
};
const A = (path) => `${path}${path.includes('?') ? '&' : '?'}useCase=${UC}`;

test('only Technical Users reach the admin API', async () => {
  token = null;
  assert.equal((await call('GET', A('/api/admin/audit'))).status, 401);
  token = 'garbage';
  assert.equal((await call('GET', A('/api/admin/audit'))).status, 401);
  token = 'down-token';
  assert.equal((await call('GET', A('/api/admin/audit'))).status, 503);
  token = 'practitioner-token';
  assert.equal((await call('GET', A('/api/admin/audit'))).status, 403);
  assert.equal((await call('GET', A('/api/admin/datasets/folders'))).status, 403);
  assert.equal(db.prepare("SELECT 1 FROM users WHERE email = 'prac@x.co'").get(), undefined);
  for (const role of TECHNICAL_USER_ROLES) {
    PEOPLE['role-token'] = { email: `${role}@x.co`, name: role, roles: [role] };
    token = 'role-token';
    assert.equal((await call('GET', '/api/admin/use-cases')).status, 200);
  }
  token = 'tech-token';
  assert.equal((await call('GET', '/api/admin/audit')).status, 400);                 // use case is required
  assert.equal((await call('GET', '/api/admin/audit?useCase=nope')).status, 400);
});

test('first request records the Technical User once', async () => {
  token = 'tech-token';
  await call('GET', '/api/admin/use-cases'); await call('GET', '/api/admin/use-cases');
  const rows = db.prepare("SELECT name, role FROM users WHERE email = 'adm@x.co'").all();
  assert.deepEqual(rows, [{ name: 'Ada Min', role: 'admin' }]);
});

test('use cases are served by the admin API', async () => {
  const r = await call('GET', '/api/admin/use-cases');
  assert.equal(r.data.useCases.length, 3);
});

test('ontology: rename carries through, in-use class cannot be deleted', async () => {
  const o = (await call('GET', A('/api/admin/ontology'))).data;
  assert.equal(o.classes.length, 9);
  const disease = o.classes.find((c) => c.name === 'Disease');
  db.prepare("INSERT INTO triples (use_case, subject, subject_class, predicate, object, object_class, confidence, stage) VALUES (?,?,?,?,?,?,1,'confirmed')").run(UC, 'Black Sigatoka', 'Disease', 'shows', 'leaf streaks', 'Symptom');
  assert.ok((await call('GET', A('/api/admin/ontology'))).data.classes.find((c) => c.name === 'Disease').usage >= 1);
  assert.equal((await call('DELETE', `/api/admin/ontology/classes/${disease.id}`)).status, 409);
  assert.equal((await call('PUT', `/api/admin/ontology/classes/${disease.id}`, { name: 'Disease', color: 'red' })).status, 400);
  assert.equal((await call('POST', '/api/admin/ontology/classes', { useCase: UC, name: 'disease', color: '#112233' })).status, 409);   // names are unique, case-insensitively
  const fresh = (await call('POST', '/api/admin/ontology/classes', { useCase: UC, name: 'Vector', color: '#112233' })).data.id;
  const rel = await call('POST', '/api/admin/ontology/relations', { useCase: UC, fromId: fresh, toId: disease.id, label: 'spreads' });
  assert.equal(rel.status, 201);
  assert.equal((await call('DELETE', `/api/admin/ontology/classes/${fresh}`)).status, 200);   // takes its links with it
  assert.equal((await call('GET', A('/api/admin/ontology'))).data.relations.length, 9);
});

test('dataset folders and image upload', async () => {
  const f = (await call('GET', A('/api/admin/datasets/folders'))).data;
  assert.equal(f.folders.length, 4);
  const healthy = f.folders.find((x) => x.name === 'Healthy'), early = f.folders.find((x) => x.name === 'Early Stage');
  assert.equal((await call('POST', '/api/admin/datasets/folders', { useCase: UC, name: 'healthy' })).status, 409);
  const sub = (await call('POST', '/api/admin/datasets/folders', { useCase: UC, name: 'Plot 4', parentId: healthy.id })).data.id;

  const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', 'base64');
  const up = await call('POST', `${A('/api/admin/datasets/images')}&folderId=${sub}&name=leaf-01.png`, png, { 'Content-Type': 'image/png' });
  assert.equal(up.status, 201);
  assert.equal(up.data.image.label, 'Plot 4');
  const id = up.data.image.id;

  const fake = await call('POST', `${A('/api/admin/datasets/images')}&name=evil.png`, Buffer.from('<svg onload=alert(1)>'), { 'Content-Type': 'image/png' });
  assert.equal(fake.status, 400);   // bytes are checked, not the header

  const file = await fetch(`${base}/api/admin/datasets/images/${id}/file`, { headers: { Authorization: `Bearer ${token}` } });
  assert.equal(file.headers.get('content-type'), 'image/png');
  assert.equal((await file.arrayBuffer()).byteLength, png.length);

  // a parent folder includes what is nested inside it
  const inHealthy = (await call('GET', A(`/api/admin/datasets/images?folderId=${healthy.id}`))).data;
  assert.equal(inHealthy.total, 1);
  assert.equal((await call('GET', A(`/api/admin/datasets/images?folderId=${early.id}`))).data.total, 0);

  assert.equal((await call('DELETE', `/api/admin/datasets/folders/${healthy.id}`)).status, 409);   // not empty
  const mv = await call('PUT', `/api/admin/datasets/images/${id}`, { folderId: early.id });
  assert.equal(mv.data.image.label, 'Early Stage');
  const ok = await call('PUT', `/api/admin/datasets/images/${id}`, { status: 'Validated' });
  assert.equal(ok.data.image.status, 'Validated');
  assert.equal((await call('GET', A('/api/admin/datasets/images?status=Validated'))).data.metrics.validationPct, 100);
  assert.equal((await call('PUT', `/api/admin/datasets/images/${id}`, { status: 'Maybe' })).status, 400);

  assert.equal((await call('DELETE', `/api/admin/datasets/images/${id}`)).status, 200);
  assert.equal((await call('DELETE', `/api/admin/datasets/folders/${sub}`)).status, 200);
  const ov = (await call('GET', A('/api/admin/overview'))).data;
  assert.equal(ov.scope.classes, 9);
  assert.ok(ov.activity.length > 0);
});
