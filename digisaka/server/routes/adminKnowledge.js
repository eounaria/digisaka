import { Router } from 'express';
import { db } from '../db.js';
import { audit } from '../audit.js';
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

function pipelineCounts(uc) {
  const c = { extracted: 0, corrected: 0, confirmed: 0, rejected: 0 };
  for (const r of db.prepare('SELECT stage, COUNT(*) n FROM triples WHERE use_case = ? GROUP BY stage').all(uc)) c[r.stage] = r.n;
  return {
    ...c,
    queued: db.prepare("SELECT COUNT(*) n FROM documents WHERE use_case = ? AND extracted_at IS NULL").get(uc).n,
    pendingTrace: db.prepare("SELECT COUNT(*) n FROM triples WHERE use_case = ? AND document_id IS NULL AND stage != 'rejected'").get(uc).n,
  };
}

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
