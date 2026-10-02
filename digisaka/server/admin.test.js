process.env.DB_PATH = ':memory:';
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import bcrypt from 'bcryptjs';

const { createApp } = await import('./app.js');
const { db } = await import('./db.js');
let server, base, cookie = '';
const UC = 'black-sigatoka';

before(() => new Promise((r) => { server = createApp().listen(0, () => { base = `http://localhost:${server.address().port}`; r(); }); }));
after(() => server.close());

const call = async (method, url, body, headers = {}) => {
  const isBuf = Buffer.isBuffer(body);
  const res = await fetch(base + url, { method, headers: { ...(body && !isBuf ? { 'Content-Type': 'application/json' } : {}), cookie, ...headers }, body: body && (isBuf ? body : JSON.stringify(body)) });
  const set = res.headers.get('set-cookie'); if (set) cookie = set.split(';')[0];
  const ct = res.headers.get('content-type') || '';
  return { status: res.status, data: ct.includes('json') ? await res.json() : null, type: ct };
};
const A = (path) => `${path}${path.includes('?') ? '&' : '?'}useCase=${UC}`;

test('farmers cannot reach the admin API', async () => {
  db.prepare("INSERT INTO users (email, name, password_hash, role) VALUES ('f@x.co','Farm Er',?, 'farmer'), ('adm@x.co','Ada Min',?, 'admin')").run(bcrypt.hashSync('longenough1', 4), bcrypt.hashSync('longenough1', 4));
  await call('POST', '/api/auth/login', { email: 'f@x.co', password: 'longenough1' });
  assert.equal((await call('GET', A('/api/admin/documents'))).status, 403);
  assert.equal((await call('GET', A('/api/admin/datasets/folders'))).status, 403);
  await call('POST', '/api/auth/login', { email: 'adm@x.co', password: 'longenough1' });
  assert.equal((await call('GET', '/api/admin/documents')).status, 400);                 // use case is required
  assert.equal((await call('GET', '/api/admin/documents?useCase=nope')).status, 400);
});

let docId;
test('upload a document, extract relationships, follow it through the pipeline', async () => {
  const content = 'Black Sigatoka is caused by Pseudocercospora fijiensis.\nBlack Sigatoka shows leaf streaks.\nBanana | affected by | Black Sigatoka\nThis line says nothing useful.';
  const up = await call('POST', '/api/admin/documents', { useCase: UC, title: 'Field notes BS-102', fileName: 'bs102.txt', content, extract: true });
  assert.equal(up.status, 201);
  docId = up.data.document.id;
  assert.equal(up.data.extraction.added, 3);
  assert.equal(up.data.document.relationships, 3);
  assert.equal(up.data.document.status, 'Needs review');
  assert.equal((await call('GET', A('/api/admin/documents'))).data.counts['Needs review'], 1);    // sentence matches sit under 0.8 confidence

  assert.equal((await call('POST', '/api/admin/documents', { useCase: UC, title: 'Empty', content: '   ' })).status, 400);
  assert.equal((await call('POST', `/api/admin/documents/${docId}/extract`)).data.added, 0);   // already known: nothing duplicated

  const list = (await call('GET', A('/api/admin/triples?stage=extracted'))).data;
  assert.equal(list.total, 3);
  assert.equal(list.counts.extracted, 3);
  const [first, second, third] = list.triples;

  assert.equal((await call('POST', `/api/admin/triples/${first.id}/confirm`)).data.triple.stage, 'confirmed');
  assert.equal((await call('POST', `/api/admin/triples/${first.id}/confirm`)).status, 409);          // already confirmed
  const fixed = await call('PUT', `/api/admin/triples/${second.id}`, { subject: second.subject, predicate: second.predicate, object: 'leaf lesions' });
  assert.equal(fixed.data.triple.stage, 'corrected');
  assert.equal((await call('POST', `/api/admin/triples/${third.id}/reject`)).data.triple.stage, 'rejected');
  assert.equal((await call('PUT', `/api/admin/triples/${third.id}`, { subject: 'a b', predicate: 'shows', object: 'c d' })).status, 409);
  assert.equal((await call('POST', `/api/admin/triples/${third.id}/restore`)).data.triple.stage, 'corrected');

  const all = (await call('POST', '/api/admin/triples/confirm-pending', { useCase: UC })).data;
  assert.equal(all.confirmed, 2);
  const doc = (await call('GET', `/api/admin/documents/${docId}`)).data.document;
  assert.equal(doc.status, 'Confirmed');
});

test('knowledge graph reflects confirmed relationships', async () => {
  const g = (await call('GET', A('/api/admin/graph'))).data;
  assert.equal(g.stats.relationships, 3);
  assert.ok(g.nodes.find((n) => n.label === 'Pseudocercospora fijiensis'));
  assert.equal(g.edges.length, 3);
  assert.equal((await call('GET', A('/api/admin/graph?scope=pending'))).data.stats.relationships, 0);
});

test('manually added relationships are corrected, untraced, and validated', async () => {
  assert.equal((await call('POST', '/api/admin/triples', { useCase: UC, subject: 'Banana', predicate: 'protects', object: ' ' })).status, 400);
  const m = await call('POST', '/api/admin/triples', { useCase: UC, subject: 'Fungicide', predicate: 'Protects', object: 'Banana' });
  assert.equal(m.status, 201);
  assert.equal(m.data.triple.stage, 'corrected');
  assert.equal(m.data.triple.predicate, 'protects');          // matched to the ontology's label
  assert.equal(m.data.triple.subjectClass, 'Treatment');      // and its classes filled in
  assert.equal((await call('GET', A('/api/admin/triples'))).data.counts.pendingTrace, 1);
  await call('POST', `/api/admin/triples/${m.data.triple.id}/reject`);
});

test('trace follows a document through each step', async () => {
  const t = (await call('GET', `/api/admin/documents/${docId}/trace`)).data;
  assert.deepEqual(t.lineage.map((s) => s.state), ['done', 'done', 'done', 'done']);
  assert.ok(t.events.length >= 6);
  assert.equal(t.events.at(-1).action, 'UPLOAD');
  const audit = (await call('GET', A('/api/admin/audit?action=CONFIRM'))).data;
  assert.ok(audit.total >= 2 && audit.entries.every((e) => e.action === 'CONFIRM'));
});

test('ontology: rename carries through, in-use class cannot be deleted', async () => {
  const o = (await call('GET', A('/api/admin/ontology'))).data;
  assert.equal(o.classes.length, 9);
  const disease = o.classes.find((c) => c.name === 'Disease');
  assert.ok(disease.usage >= 3);
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

  const file = await fetch(`${base}/api/admin/datasets/images/${id}/file`, { headers: { cookie } });
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
  assert.equal(ov.kpis.documents, 1);
  assert.equal(ov.kpis.relationships, 3);
  assert.equal(ov.kpis.awaitingExtraction, 0);
  assert.equal(ov.scope.classes, 9);
  assert.ok(ov.activity.length > 0);
});
