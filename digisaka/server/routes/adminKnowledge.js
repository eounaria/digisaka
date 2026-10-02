import { Router } from 'express';
import { db } from '../db.js';
import { audit } from '../audit.js';
import { extractTriples } from '../extract.js';
import { bad, notFound, HttpError } from '../http.js';

export const knowledgeRouter = Router();

// ---------- helpers ----------
const pageOf = (req, max = 100, dflt = 25) => ({
  limit: Math.min(Math.max(Number(req.query.limit) || dflt, 1), max),
  offset: Math.max(Number(req.query.offset) || 0, 0),
});
const like = (q) => `%${String(q || '').trim().replace(/[\\%_]/g, '\\$&')}%`;
const text = (v, label, max = 80) => {
  const s = String(v ?? '').replace(/\s+/g, ' ').trim();
  if (!s) throw bad(`${label} is required.`);
  if (s.length > max) throw bad(`${label} must be ${max} characters or fewer.`);
  return s;
};

/** Every admin screen is scoped to one use case. */
export function scopeOf(req) {
  const slug = String(req.query.useCase ?? req.body?.useCase ?? '');
  if (!db.prepare('SELECT 1 FROM use_cases WHERE slug = ?').get(slug)) throw bad('Choose a valid use case.');
  return slug;
}

const colorOf = (uc, name) => name && db.prepare('SELECT color FROM ontology_classes WHERE use_case = ? AND name = ?').get(uc, name)?.color;
const relationsOf = (uc) => db.prepare(`SELECT r.label, a.name AS fromName, b.name AS toName FROM ontology_relations r
  JOIN ontology_classes a ON a.id = r.from_class JOIN ontology_classes b ON b.id = r.to_class WHERE r.use_case = ?`).all(uc);
const tripleText = (t) => `${t.subject} ${t.predicate} ${t.object}`;

/** A document's status follows what has happened to its relationships. */
export function refreshDocument(id) {
  if (!id) return;
  const d = db.prepare('SELECT extracted_at FROM documents WHERE id = ?').get(id);
  if (!d) return;
  const live = db.prepare("SELECT stage, confidence FROM triples WHERE document_id = ? AND stage != 'rejected'").all(id);
  let status = 'Queued';
  if (d.extracted_at) {
    if (!live.length) status = 'Needs review';
    else if (live.every((t) => t.stage === 'confirmed')) status = 'Confirmed';
    else if (live.some((t) => t.stage === 'extracted' && t.confidence < 0.8)) status = 'Needs review';
    else status = 'Extracted';
  }
  db.prepare("UPDATE documents SET status = ?, updated_at = datetime('now') WHERE id = ?").run(status, id);
}

// ---------- documents ----------
const DOC_LIST = `SELECT d.id, d.title, d.doc_type AS docType, d.source, d.file_name AS fileName, d.size_bytes AS sizeBytes, d.status,
  d.extracted_at AS extractedAt, d.created_at AS createdAt, d.updated_at AS updatedAt,
  (SELECT COUNT(*) FROM triples t WHERE t.document_id = d.id AND t.stage != 'rejected') AS relationships,
  (SELECT COUNT(*) FROM (SELECT subject AS n FROM triples WHERE document_id = d.id AND stage != 'rejected'
                         UNION SELECT object FROM triples WHERE document_id = d.id AND stage != 'rejected')) AS entities,
  (SELECT ROUND(AVG(confidence), 3) FROM triples t WHERE t.document_id = d.id AND t.stage != 'rejected') AS confidence
  FROM documents d`;

knowledgeRouter.get('/documents', (req, res) => {
  const uc = scopeOf(req), { limit, offset } = pageOf(req, 200, 100);
  const q = like(req.query.q), status = req.query.status ? String(req.query.status) : null;
  const where = `d.use_case = @uc AND (@q = '%%' OR d.title LIKE @q ESCAPE '\\' OR d.source LIKE @q ESCAPE '\\' OR d.doc_type LIKE @q ESCAPE '\\') AND (@status IS NULL OR d.status = @status)`;
  const args = { uc, q, status };
  const total = db.prepare(`SELECT COUNT(*) n FROM documents d WHERE ${where}`).get(args).n;
  const documents = db.prepare(`${DOC_LIST} WHERE ${where} ORDER BY d.updated_at DESC, d.id DESC LIMIT @limit OFFSET @offset`).all({ ...args, limit, offset });
  const counts = { Queued: 0, Extracted: 0, 'Needs review': 0, Confirmed: 0 };
  for (const r of db.prepare('SELECT status, COUNT(*) n FROM documents WHERE use_case = ? GROUP BY status').all(uc)) counts[r.status] = r.n;
  res.json({ total, documents, counts });
});

function runExtraction(doc, actor) {
  const rels = relationsOf(doc.use_case);
  const known = new Set(db.prepare("SELECT subject n FROM triples WHERE use_case = ? AND stage != 'rejected' UNION SELECT object FROM triples WHERE use_case = ? AND stage != 'rejected'")
    .all(doc.use_case, doc.use_case).map((r) => r.n.toLowerCase()));
  const found = extractTriples(doc.content, rels, known);
  const exists = db.prepare('SELECT 1 FROM triples WHERE use_case = ? AND lower(subject) = ? AND lower(predicate) = ? AND lower(object) = ?');
  const ins = db.prepare(`INSERT INTO triples (use_case, document_id, subject, subject_class, predicate, object, object_class, confidence) VALUES (?,?,?,?,?,?,?,?)`);
  let added = 0;
  db.transaction(() => {
    for (const t of found) {
      if (exists.get(doc.use_case, t.subject.toLowerCase(), t.predicate.toLowerCase(), t.object.toLowerCase())) continue;
      ins.run(doc.use_case, doc.id, t.subject, t.subjectClass, t.predicate, t.object, t.objectClass, t.confidence);
      added++;
    }
    db.prepare("UPDATE documents SET extracted_at = datetime('now') WHERE id = ?").run(doc.id);
  })();
  refreshDocument(doc.id);
  audit(actor, { useCase: doc.use_case, action: 'EXTRACT', objectType: 'Document', objectId: doc.id, objectLabel: doc.title, previous: 'Queued', newValue: `${added} relationships`,
    documentId: doc.id, detail: { found: found.length, added, alreadyKnown: found.length - added } });
  return { found: found.length, added };
}

knowledgeRouter.post('/documents', (req, res) => {
  const uc = scopeOf(req), b = req.body ?? {};
  const content = String(b.content ?? '');
  if (!content.trim()) throw bad('The document has no readable text. Upload a .txt, .md, .csv or .json file.');
  const title = text(b.title || String(b.fileName ?? '').replace(/\.[^.]+$/, ''), 'Title', 120);
  const id = db.prepare(`INSERT INTO documents (use_case, title, doc_type, source, file_name, size_bytes, content, uploaded_by) VALUES (?,?,?,?,?,?,?,?)`)
    .run(uc, title, text(b.docType || 'Field notes', 'Type', 40), text(b.source || 'Upload portal', 'Source', 60), b.fileName ? String(b.fileName).slice(0, 200) : null,
      Buffer.byteLength(content), content, req.user.id).lastInsertRowid;
  audit(req.user, { useCase: uc, action: 'UPLOAD', objectType: 'Document', objectId: id, objectLabel: title, previous: '—', newValue: 'Queued', documentId: id });
  const doc = db.prepare('SELECT * FROM documents WHERE id = ?').get(id);
  const extraction = b.extract ? runExtraction(doc, req.user) : null;
  res.status(201).json({ document: db.prepare(`${DOC_LIST} WHERE d.id = ?`).get(id), extraction });
});

const docOr404 = (id) => db.prepare('SELECT * FROM documents WHERE id = ?').get(Number(id)) ?? (() => { throw notFound('That document'); })();

knowledgeRouter.get('/documents/:id', (req, res) => {
  const d = docOr404(req.params.id);
  const triples = db.prepare('SELECT id, subject, predicate, object, confidence, stage FROM triples WHERE document_id = ? ORDER BY id').all(d.id);
  res.json({ document: { ...db.prepare(`${DOC_LIST} WHERE d.id = ?`).get(d.id), content: d.content }, triples });
});

knowledgeRouter.put('/documents/:id', (req, res) => {
  const d = docOr404(req.params.id), b = req.body ?? {};
  const next = { title: text(b.title ?? d.title, 'Title', 120), docType: text(b.docType ?? d.doc_type, 'Type', 40), source: text(b.source ?? d.source, 'Source', 60) };
  db.prepare("UPDATE documents SET title = ?, doc_type = ?, source = ?, updated_at = datetime('now') WHERE id = ?").run(next.title, next.docType, next.source, d.id);
  audit(req.user, { useCase: d.use_case, action: 'UPDATE', objectType: 'Document', objectId: d.id, objectLabel: next.title,
    previous: `${d.title} / ${d.doc_type} / ${d.source}`, newValue: `${next.title} / ${next.docType} / ${next.source}`, documentId: d.id });
  res.json({ document: db.prepare(`${DOC_LIST} WHERE d.id = ?`).get(d.id) });
});

knowledgeRouter.delete('/documents/:id', (req, res) => {
  const d = docOr404(req.params.id);
  const n = db.prepare('SELECT COUNT(*) n FROM triples WHERE document_id = ?').get(d.id).n;
  db.prepare('DELETE FROM documents WHERE id = ?').run(d.id);
  audit(req.user, { useCase: d.use_case, action: 'DELETE', objectType: 'Document', objectId: d.id, objectLabel: d.title, previous: `${n} relationships`, newValue: 'Deleted' });
  res.json({ ok: true });
});

knowledgeRouter.post('/documents/:id/extract', (req, res) => {
  const d = docOr404(req.params.id);
  const r = runExtraction(d, req.user);
  res.json({ ...r, document: db.prepare(`${DOC_LIST} WHERE d.id = ?`).get(d.id) });
});

// Tracing: what happened to one document, newest first, plus the pipeline steps it has been through.
knowledgeRouter.get('/documents/:id/trace', (req, res) => {
  const d = docOr404(req.params.id);
  const doc = db.prepare(`${DOC_LIST} WHERE d.id = ?`).get(d.id);
  const stages = Object.fromEntries(db.prepare("SELECT stage, COUNT(*) n FROM triples WHERE document_id = ? GROUP BY stage").all(d.id).map((r) => [r.stage, r.n]));
  const live = (stages.extracted ?? 0) + (stages.corrected ?? 0) + (stages.confirmed ?? 0);
  const firstOf = (action) => db.prepare('SELECT created_at t FROM audit_log WHERE document_id = ? AND action = ? ORDER BY id LIMIT 1').get(d.id, action)?.t ?? null;
  const awaiting = stages.extracted ?? 0;
  const lineage = [
    { title: 'Source document', time: d.created_at, detail: `${d.doc_type} / ${d.title}`, state: 'done' },
    { title: 'Extraction', time: d.extracted_at, state: d.extracted_at ? 'done' : 'pending',
      detail: d.extracted_at ? `${doc.entities} entities, ${doc.relationships} relationships` : 'Waiting to be extracted' },
    { title: 'Correction', time: firstOf('CORRECT'), state: d.extracted_at && live && !awaiting ? 'done' : 'pending',
      detail: !d.extracted_at ? 'After extraction' : !live ? 'Nothing to review' : awaiting ? `${awaiting} relationship${awaiting === 1 ? '' : 's'} not reviewed yet` : 'All relationships reviewed' },
    { title: 'Knowledge graph', time: firstOf('CONFIRM'), state: live && (stages.confirmed ?? 0) === live ? 'done' : 'pending',
      detail: live ? `${stages.confirmed ?? 0} of ${live} confirmed` : 'No relationships to confirm' },
  ];
  const events = db.prepare('SELECT id, actor_name actor, action, object_type objectType, object_label objectLabel, previous, new_value newValue, status, detail, created_at createdAt FROM audit_log WHERE document_id = ? ORDER BY id DESC LIMIT 100').all(d.id)
    .map((e) => ({ ...e, detail: e.detail ? JSON.parse(e.detail) : null }));
  res.json({ document: doc, lineage, events });
});

// ---------- relationships (triples) ----------
const TRIPLE_COLS = `t.id, t.subject, t.subject_class AS subjectClass, t.predicate, t.object, t.object_class AS objectClass, t.confidence, t.stage,
  t.document_id AS documentId, d.title AS documentTitle, d.doc_type AS documentType, u.name AS reviewer, t.updated_at AS updatedAt`;
const TRIPLE_FROM = 'FROM triples t LEFT JOIN documents d ON d.id = t.document_id LEFT JOIN users u ON u.id = t.reviewer_id';

knowledgeRouter.get('/triples', (req, res) => {
  const uc = scopeOf(req), { limit, offset } = pageOf(req);
  const stage = ['extracted', 'corrected', 'confirmed', 'rejected'].includes(req.query.stage) ? req.query.stage : null;
  const where = `t.use_case = @uc AND (@stage IS NULL OR t.stage = @stage) AND (@q = '%%' OR t.subject LIKE @q ESCAPE '\\' OR t.object LIKE @q ESCAPE '\\' OR t.predicate LIKE @q ESCAPE '\\')`;
  const args = { uc, stage, q: like(req.query.q) };
  const total = db.prepare(`SELECT COUNT(*) n FROM triples t WHERE ${where}`).get(args).n;
  const triples = db.prepare(`SELECT ${TRIPLE_COLS} ${TRIPLE_FROM} WHERE ${where} ORDER BY t.updated_at DESC, t.id DESC LIMIT @limit OFFSET @offset`).all({ ...args, limit, offset });
  res.json({ total, triples, counts: pipelineCounts(uc) });
});

function pipelineCounts(uc) {
  const c = { extracted: 0, corrected: 0, confirmed: 0, rejected: 0 };
  for (const r of db.prepare('SELECT stage, COUNT(*) n FROM triples WHERE use_case = ? GROUP BY stage').all(uc)) c[r.stage] = r.n;
  return {
    ...c,
    queued: db.prepare("SELECT COUNT(*) n FROM documents WHERE use_case = ? AND extracted_at IS NULL").get(uc).n,
    pendingTrace: db.prepare("SELECT COUNT(*) n FROM triples WHERE use_case = ? AND document_id IS NULL AND stage != 'rejected'").get(uc).n,
  };
}

function tripleFields(b, uc) {
  const s = text(b.subject, 'Subject'), p = text(b.predicate, 'Relationship', 40), o = text(b.object, 'Object');
  const rel = relationsOf(uc).find((r) => r.label.toLowerCase() === p.toLowerCase());
  return { s, p: rel?.label ?? p, o, sc: b.subjectClass || rel?.fromName || null, oc: b.objectClass || rel?.toName || null };
}

knowledgeRouter.post('/triples', (req, res) => {
  const uc = scopeOf(req), f = tripleFields(req.body ?? {}, uc);
  const id = db.prepare(`INSERT INTO triples (use_case, subject, subject_class, predicate, object, object_class, confidence, stage, reviewer_id) VALUES (?,?,?,?,?,?,1,'corrected',?)`)
    .run(uc, f.s, f.sc, f.p, f.o, f.oc, req.user.id).lastInsertRowid;
  audit(req.user, { useCase: uc, action: 'CREATE', objectType: 'Relationship', objectId: id, objectLabel: tripleText({ subject: f.s, predicate: f.p, object: f.o }), previous: '—', newValue: 'Corrected' });
  res.status(201).json({ triple: db.prepare(`SELECT ${TRIPLE_COLS} ${TRIPLE_FROM} WHERE t.id = ?`).get(id) });
});

const tripleOr404 = (id) => db.prepare('SELECT * FROM triples WHERE id = ?').get(Number(id)) ?? (() => { throw notFound('That relationship'); })();
const tripleOut = (id) => db.prepare(`SELECT ${TRIPLE_COLS} ${TRIPLE_FROM} WHERE t.id = ?`).get(id);

knowledgeRouter.put('/triples/:id', (req, res) => {
  const t = tripleOr404(req.params.id), f = tripleFields(req.body ?? {}, t.use_case);
  if (t.stage === 'rejected') throw new HttpError(409, 'Restore this relationship before editing it.');
  db.prepare("UPDATE triples SET subject = ?, subject_class = ?, predicate = ?, object = ?, object_class = ?, stage = 'corrected', reviewer_id = ?, updated_at = datetime('now') WHERE id = ?")
    .run(f.s, f.sc, f.p, f.o, f.oc, req.user.id, t.id);
  refreshDocument(t.document_id);
  audit(req.user, { useCase: t.use_case, action: 'CORRECT', objectType: 'Relationship', objectId: t.id, objectLabel: tripleText({ subject: f.s, predicate: f.p, object: f.o }),
    previous: tripleText(t), newValue: tripleText({ subject: f.s, predicate: f.p, object: f.o }), documentId: t.document_id });
  res.json({ triple: tripleOut(t.id) });
});

const MOVES = {
  confirm: { from: ['extracted', 'corrected'], to: 'confirmed', verb: 'CONFIRM' },
  reject: { from: ['extracted', 'corrected'], to: 'rejected', verb: 'REJECT' },
  restore: { from: ['rejected'], to: 'corrected', verb: 'RESTORE' },
  unconfirm: { from: ['confirmed'], to: 'corrected', verb: 'UNCONFIRM' },
};

knowledgeRouter.post('/triples/confirm-pending', (req, res) => {
  const uc = scopeOf(req);
  const rows = db.prepare("SELECT id, document_id FROM triples WHERE use_case = ? AND stage IN ('extracted','corrected')").all(uc);
  if (!rows.length) throw new HttpError(409, 'There is nothing waiting for confirmation.');
  db.transaction(() => db.prepare("UPDATE triples SET stage = 'confirmed', reviewer_id = ?, updated_at = datetime('now') WHERE use_case = ? AND stage IN ('extracted','corrected')").run(req.user.id, uc))();
  [...new Set(rows.map((r) => r.document_id))].forEach(refreshDocument);
  audit(req.user, { useCase: uc, action: 'CONFIRM', objectType: 'Knowledge Graph', objectLabel: `${rows.length} relationships`, previous: 'Unconfirmed', newValue: 'Confirmed' });
  res.json({ confirmed: rows.length });
});

knowledgeRouter.post('/triples/:id/:action', (req, res) => {
  const move = MOVES[req.params.action];
  if (!move) throw notFound('That action');
  const t = tripleOr404(req.params.id);
  if (!move.from.includes(t.stage)) throw new HttpError(409, `A ${t.stage} relationship can't be ${req.params.action}ed.`);
  db.prepare("UPDATE triples SET stage = ?, reviewer_id = ?, updated_at = datetime('now') WHERE id = ?").run(move.to, req.user.id, t.id);
  refreshDocument(t.document_id);
  audit(req.user, { useCase: t.use_case, action: move.verb, objectType: 'Relationship', objectId: t.id, objectLabel: tripleText(t), previous: t.stage, newValue: move.to, documentId: t.document_id });
  res.json({ triple: tripleOut(t.id) });
});

// ---------- graph ----------
const MAX_EDGES = 150;
knowledgeRouter.get('/graph', (req, res) => {
  const uc = scopeOf(req);
  const stages = req.query.scope === 'pending' ? ['extracted', 'corrected'] : ['confirmed'];
  const rows = db.prepare(`SELECT subject, subject_class sc, predicate, object, object_class oc FROM triples WHERE use_case = ? AND stage IN (${stages.map(() => '?').join(',')}) ORDER BY updated_at DESC, id DESC`).all(uc, ...stages);
  const classes = new Map(db.prepare('SELECT name, color FROM ontology_classes WHERE use_case = ?').all(uc).map((c) => [c.name.toLowerCase(), c]));
  const nodes = new Map(), edges = [];
  const touch = (name, cls) => {
    const k = name.toLowerCase();
    const n = nodes.get(k) ?? { id: k, label: name, caption: cls ?? '', color: null, degree: 0 };
    if (!n.caption && cls) n.caption = cls;
    n.degree++; nodes.set(k, n); return k;
  };
  const used = rows.slice(0, MAX_EDGES);
  for (const r of used) edges.push({ from: touch(r.subject, r.sc), to: touch(r.object, r.oc), label: r.predicate });
  const all = new Set(); const dist = new Map();
  for (const r of rows) for (const [n, c] of [[r.subject, r.sc], [r.object, r.oc]]) {
    const k = n.toLowerCase(); if (all.has(k)) continue; all.add(k);
    const cls = c || 'Unclassified'; dist.set(cls, (dist.get(cls) ?? 0) + 1);
  }
  for (const n of nodes.values()) n.color = classes.get(n.caption.toLowerCase())?.color ?? '#5b6475';
  res.json({
    nodes: [...nodes.values()], edges, truncated: rows.length > MAX_EDGES,
    stats: { entities: all.size, relationships: rows.length },
    classes: [...dist].sort((a, b) => b[1] - a[1]).map(([name, count]) => ({ name, count, pct: Math.round((count / all.size) * 100), color: classes.get(name.toLowerCase())?.color ?? '#5b6475' })),
  });
});

// ---------- ontology ----------
const HEX = /^#[0-9a-f]{6}$/i;
knowledgeRouter.get('/ontology', (req, res) => {
  const uc = scopeOf(req);
  const classes = db.prepare(`SELECT c.id, c.name, c.color, c.description,
    (SELECT COUNT(*) FROM triples t WHERE t.use_case = c.use_case AND t.stage != 'rejected' AND (t.subject_class = c.name OR t.object_class = c.name)) AS usage
    FROM ontology_classes c WHERE c.use_case = ? ORDER BY c.id`).all(uc);
  const relations = db.prepare(`SELECT r.id, r.label, r.from_class AS fromId, r.to_class AS toId, a.name AS fromName, b.name AS toName
    FROM ontology_relations r JOIN ontology_classes a ON a.id = r.from_class JOIN ontology_classes b ON b.id = r.to_class WHERE r.use_case = ? ORDER BY r.id`).all(uc);
  res.json({ classes, relations });
});

const classOr404 = (id) => db.prepare('SELECT * FROM ontology_classes WHERE id = ?').get(Number(id)) ?? (() => { throw notFound('That class'); })();
const classFields = (b) => {
  const color = String(b.color ?? '#3948d1');
  if (!HEX.test(color)) throw bad('Pick a valid colour.');
  return { name: text(b.name, 'Class name', 40), color, description: String(b.description ?? '').trim().slice(0, 200) || null };
};
const dupe = (e) => (String(e.message).includes('UNIQUE') ? new HttpError(409, 'That already exists in this ontology.') : e);

knowledgeRouter.post('/ontology/classes', (req, res) => {
  const uc = scopeOf(req), f = classFields(req.body ?? {});
  try {
    const id = db.prepare('INSERT INTO ontology_classes (use_case, name, color, description) VALUES (?,?,?,?)').run(uc, f.name, f.color, f.description).lastInsertRowid;
    audit(req.user, { useCase: uc, action: 'CREATE', objectType: 'Ontology class', objectId: id, objectLabel: f.name, previous: '—', newValue: 'Created' });
    res.status(201).json({ id });
  } catch (e) { throw dupe(e); }
});

knowledgeRouter.put('/ontology/classes/:id', (req, res) => {
  const c = classOr404(req.params.id), f = classFields({ ...c, ...req.body });
  try {
    db.transaction(() => {
      db.prepare('UPDATE ontology_classes SET name = ?, color = ?, description = ? WHERE id = ?').run(f.name, f.color, f.description, c.id);
      if (f.name !== c.name) {   // triples keep the class by name
        db.prepare('UPDATE triples SET subject_class = ? WHERE use_case = ? AND subject_class = ?').run(f.name, c.use_case, c.name);
        db.prepare('UPDATE triples SET object_class = ? WHERE use_case = ? AND object_class = ?').run(f.name, c.use_case, c.name);
      }
    })();
  } catch (e) { throw dupe(e); }
  audit(req.user, { useCase: c.use_case, action: 'UPDATE', objectType: 'Ontology class', objectId: c.id, objectLabel: f.name, previous: c.name, newValue: f.name });
  res.json({ ok: true });
});

knowledgeRouter.delete('/ontology/classes/:id', (req, res) => {
  const c = classOr404(req.params.id);
  const used = db.prepare("SELECT COUNT(*) n FROM triples WHERE use_case = ? AND stage != 'rejected' AND (subject_class = ? OR object_class = ?)").get(c.use_case, c.name, c.name).n;
  if (used) throw new HttpError(409, `${used} relationship${used === 1 ? ' uses' : 's use'} this class. Reclassify them first.`);
  db.prepare('DELETE FROM ontology_classes WHERE id = ?').run(c.id);   // its links go with it
  audit(req.user, { useCase: c.use_case, action: 'DELETE', objectType: 'Ontology class', objectId: c.id, objectLabel: c.name, previous: c.name, newValue: 'Deleted' });
  res.json({ ok: true });
});

knowledgeRouter.post('/ontology/relations', (req, res) => {
  const uc = scopeOf(req), b = req.body ?? {}, label = text(b.label, 'Relationship name', 40);
  const from = classOr404(b.fromId), to = classOr404(b.toId);
  if (from.use_case !== uc || to.use_case !== uc) throw bad('Both classes must belong to this use case.');
  try {
    const id = db.prepare('INSERT INTO ontology_relations (use_case, from_class, to_class, label) VALUES (?,?,?,?)').run(uc, from.id, to.id, label).lastInsertRowid;
    audit(req.user, { useCase: uc, action: 'CREATE', objectType: 'Ontology relation', objectId: id, objectLabel: `${from.name} ${label} ${to.name}`, previous: '—', newValue: 'Created' });
    res.status(201).json({ id });
  } catch (e) { throw dupe(e); }
});

knowledgeRouter.delete('/ontology/relations/:id', (req, res) => {
  const r = db.prepare(`SELECT r.*, a.name AS an, b.name AS bn FROM ontology_relations r JOIN ontology_classes a ON a.id = r.from_class JOIN ontology_classes b ON b.id = r.to_class WHERE r.id = ?`).get(Number(req.params.id));
  if (!r) throw notFound('That relationship type');
  db.prepare('DELETE FROM ontology_relations WHERE id = ?').run(r.id);
  audit(req.user, { useCase: r.use_case, action: 'DELETE', objectType: 'Ontology relation', objectId: r.id, objectLabel: `${r.an} ${r.label} ${r.bn}`, previous: r.label, newValue: 'Deleted' });
  res.json({ ok: true });
});

// ---------- overview ----------
knowledgeRouter.get('/overview', (req, res) => {
  const uc = scopeOf(req), c = pipelineCounts(uc);
  const live = c.extracted + c.corrected + c.confirmed;
  const one = (sql, ...a) => db.prepare(sql).get(...a).n;
  const docs = one('SELECT COUNT(*) n FROM documents WHERE use_case = ?', uc);
  const imgs = one('SELECT COUNT(*) n FROM dataset_images WHERE use_case = ?', uc);
  const labeled = one("SELECT COUNT(*) n FROM dataset_images WHERE use_case = ? AND label IS NOT NULL AND label != ''", uc);
  const validated = one("SELECT COUNT(*) n FROM dataset_images WHERE use_case = ? AND status = 'Validated'", uc);
  const entities = one("SELECT COUNT(*) n FROM (SELECT lower(subject) FROM triples WHERE use_case = ? AND stage = 'confirmed' UNION SELECT lower(object) FROM triples WHERE use_case = ? AND stage = 'confirmed')", uc, uc);
  const avgConf = db.prepare("SELECT AVG(confidence) a FROM triples WHERE use_case = ? AND stage = 'confirmed'").get(uc).a;
  const tracedConfirmed = one("SELECT COUNT(*) n FROM triples WHERE use_case = ? AND stage = 'confirmed' AND document_id IS NOT NULL", uc);
  const pct = (a, b) => (b ? Math.round((a / b) * 100) : 0);
  res.json({
    kpis: { entities, relationships: c.confirmed, avgConfidence: avgConf == null ? null : Math.round(avgConf * 1000) / 10, documents: docs, awaitingExtraction: c.queued, images: imgs, imagesLabeledPct: pct(labeled, imgs) },
    pipeline: [
      { name: 'Extraction', pct: pct(docs - c.queued, docs), note: `${docs - c.queued} of ${docs} documents` },
      { name: 'Correction', pct: pct(c.corrected + c.confirmed, live), note: `${c.corrected + c.confirmed} of ${live} reviewed` },
      { name: 'Confirmation', pct: pct(c.confirmed, live), note: `${c.confirmed} of ${live} confirmed` },
      { name: 'Traceability', pct: pct(tracedConfirmed, c.confirmed), note: `${tracedConfirmed} of ${c.confirmed} traced to a document` },
      { name: 'Image validation', pct: pct(validated, imgs), note: `${validated} of ${imgs} images` },
    ],
    scope: { classes: one('SELECT COUNT(*) n FROM ontology_classes WHERE use_case = ?', uc), relations: one('SELECT COUNT(*) n FROM ontology_relations WHERE use_case = ?', uc), pendingReview: c.extracted + c.corrected },
    activity: db.prepare('SELECT id, actor_name actor, action, object_type objectType, object_label objectLabel, created_at createdAt FROM audit_log WHERE use_case = ? ORDER BY id DESC LIMIT 5').all(uc),
  });
});

// ---------- audit log ----------
knowledgeRouter.get('/audit', (req, res) => {
  const uc = scopeOf(req), { limit, offset } = pageOf(req, 100, 25);
  const action = req.query.action ? String(req.query.action) : null;
  const where = `(use_case = @uc OR use_case IS NULL) AND (@action IS NULL OR action = @action) AND (@q = '%%' OR actor_name LIKE @q ESCAPE '\\' OR object_label LIKE @q ESCAPE '\\' OR object_type LIKE @q ESCAPE '\\')`;
  const args = { uc, action, q: like(req.query.q) };
  const total = db.prepare(`SELECT COUNT(*) n FROM audit_log WHERE ${where}`).get(args).n;
  const rows = db.prepare(`SELECT id, actor_name actor, action, object_type objectType, object_label objectLabel, previous, new_value newValue, status, detail, created_at createdAt
    FROM audit_log WHERE ${where} ORDER BY id DESC LIMIT @limit OFFSET @offset`).all({ ...args, limit, offset });
  res.json({ total, entries: rows.map((e) => ({ ...e, detail: e.detail ? JSON.parse(e.detail) : null })),
    actions: db.prepare('SELECT DISTINCT action FROM audit_log ORDER BY action').all().map((r) => r.action) });
});
