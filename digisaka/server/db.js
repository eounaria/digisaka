import Database from 'better-sqlite3';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { config } from './config.js';

const here = path.dirname(fileURLToPath(import.meta.url));
if (config.dbPath !== ':memory:') fs.mkdirSync(path.dirname(config.dbPath), { recursive: true });

export const db = new Database(config.dbPath);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');
db.exec(fs.readFileSync(path.join(here, 'schema.sql'), 'utf8'));

if (!db.prepare('SELECT 1 FROM use_cases').get()) {
  const ins = db.prepare('INSERT INTO use_cases VALUES (?,?,?,?,?)');
  ins.run('black-sigatoka', 'Black Sigatoka', '🍌', 'Banana', 'Black Sigatoka');
  ins.run('rice', 'Rice', '🌾', 'Rice', 'Rice Blast');
  ins.run('corn', 'Corn', '🌽', 'Corn', 'Northern Corn Leaf Blight');
}

// Every use case starts with the default ontology and image folders so the admin screens are usable straight away.
{
  const { DEFAULT_CLASSES, DEFAULT_RELATIONS, DEFAULT_FOLDERS } = await import('./ontology-defaults.js');
  const insClass = db.prepare('INSERT INTO ontology_classes (use_case, name, color, description) VALUES (?,?,?,?)');
  const insRel = db.prepare('INSERT INTO ontology_relations (use_case, from_class, to_class, label) VALUES (?,?,?,?)');
  const insFolder = db.prepare('INSERT INTO dataset_folders (use_case, name) VALUES (?,?)');
  for (const { slug } of db.prepare('SELECT slug FROM use_cases').all()) {
    db.transaction(() => {
      if (!db.prepare('SELECT 1 FROM ontology_classes WHERE use_case = ?').get(slug)) {
        const ids = new Map(DEFAULT_CLASSES.map(([name, color, desc]) => [name, insClass.run(slug, name, color, desc).lastInsertRowid]));
        DEFAULT_RELATIONS.forEach(([a, b, label]) => insRel.run(slug, ids.get(a), ids.get(b), label));
      }
      if (!db.prepare('SELECT 1 FROM dataset_folders WHERE use_case = ?').get(slug)) DEFAULT_FOLDERS.forEach((n) => insFolder.run(slug, n));
    })();
  }
}
