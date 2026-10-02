import crypto from 'node:crypto';
import bcrypt from 'bcryptjs';
import fs from 'node:fs';
import { db } from './db.js';

const pw = bcrypt.hashSync('digisaka123', 10);
const upsert = db.prepare(`INSERT OR IGNORE INTO users (email, name, first_name, middle_name, last_name, contact, password_hash, role, location)
                           VALUES (?,?,?,?,?,?,?,?,?)`);

upsert.run('juan@digisaka.test', 'Juan Dela Cruz', 'Juan', 'Dela', 'Cruz', null, pw, 'farmer', 'Sitio Malabo, Balayan, Batangas');
upsert.run('admin@digisaka.test', 'Jamie Santos', 'Jamie', '', 'Santos', null, pw, 'admin', null);

// The farmers shown in the admin Users screen demo (no usable password until invited)
const sample = JSON.parse(fs.readFileSync(new URL('./sample-farmers.json', import.meta.url), 'utf8'));
for (const f of sample)
  upsert.run(f.email, [f.first, f.middle, f.last].filter(Boolean).join(' '), f.first, f.middle, f.last, f.contact, bcrypt.hashSync(crypto.randomUUID(), 4), 'farmer', null);

console.log('Seeded. Demo logins (password digisaka123): juan@digisaka.test (farmer), admin@digisaka.test (admin)');

// Demo knowledge for the admin console: one source document per use case, run through the same extractor admins use.
{
  const { extractTriples } = await import('./extract.js');
  const { audit } = await import('./audit.js');
  const { refreshDocument } = await import('./routes/adminKnowledge.js');
  const admin = db.prepare("SELECT id, name FROM users WHERE email = 'admin@digisaka.test'").get();
  const DOCS = {
    'black-sigatoka': ['Field notes BS-102', [
      'Banana | affected by | Black Sigatoka', 'Black Sigatoka is caused by Pseudocercospora fijiensis.', 'Black Sigatoka shows leaf streaks.',
      'Leaf streaks indicates early stage.', 'Early stage is influenced by high humidity.', 'Black Sigatoka is managed with a fungicide plan.',
      'A fungicide plan protects Banana.', 'Black Sigatoka is observed in Davao.']],
    rice: ['Rice survey 14', [
      'Rice | affected by | Rice blast', 'Rice blast is caused by Magnaporthe oryzae.', 'Rice blast shows leaf lesions.',
      'Rice blast is managed with field treatment.', 'Rice blast is observed in Nueva Ecija.']],
    corn: ['Corn farm log', [
      'Corn | affected by | Corn rust', 'Corn rust is caused by Puccinia sorghi.', 'Corn rust shows rust spots.', 'Corn rust is observed in Bukidnon.']],
  };
  for (const { slug } of db.prepare('SELECT slug FROM use_cases').all()) {
    if (db.prepare('SELECT 1 FROM documents WHERE use_case = ?').get(slug) || !DOCS[slug]) continue;
    const [title, lines] = DOCS[slug];
    const content = lines.join('\n');
    const rels = db.prepare(`SELECT r.label, a.name fromName, b.name toName FROM ontology_relations r JOIN ontology_classes a ON a.id = r.from_class
                             JOIN ontology_classes b ON b.id = r.to_class WHERE r.use_case = ?`).all(slug);
    const docId = db.prepare("INSERT INTO documents (use_case, title, doc_type, source, file_name, size_bytes, content, extracted_at, uploaded_by) VALUES (?,?,?,?,?,?,?,datetime('now'),?)")
      .run(slug, title, 'Field notes', 'Upload portal', title.toLowerCase().replace(/\W+/g, '-') + '.txt', Buffer.byteLength(content), content, admin?.id).lastInsertRowid;
    const ins = db.prepare('INSERT INTO triples (use_case, document_id, subject, subject_class, predicate, object, object_class, confidence, stage, reviewer_id) VALUES (?,?,?,?,?,?,?,?,?,?)');
    extractTriples(content, rels).forEach((t, i) => {
      const stage = i < 4 ? 'confirmed' : i < 5 ? 'corrected' : 'extracted';   // leave some work in every stage
      ins.run(slug, docId, t.subject, t.subjectClass, t.predicate, t.object, t.objectClass, t.confidence, stage, stage === 'extracted' ? null : admin?.id);
    });
    const live = db.prepare("SELECT COUNT(*) n FROM triples WHERE document_id = ?").get(docId).n;
    refreshDocument(docId);
    audit(admin, { useCase: slug, action: 'EXTRACT', objectType: 'Document', objectId: docId, objectLabel: title, previous: 'Queued', newValue: `${live} relationships`, documentId: docId });
  }
}
