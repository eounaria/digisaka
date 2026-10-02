CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY,
  email         TEXT NOT NULL UNIQUE COLLATE NOCASE,
  name          TEXT NOT NULL,
  first_name    TEXT,
  middle_name   TEXT,
  last_name     TEXT,
  contact       TEXT,
  password_hash TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'farmer' CHECK (role IN ('farmer','admin')),
  location      TEXT,
  use_case      TEXT NOT NULL DEFAULT 'black-sigatoka',
  created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS use_cases (
  slug TEXT PRIMARY KEY, label TEXT NOT NULL, icon TEXT, crop TEXT, disease TEXT
);

-- One bulk = a named assessment session for one plant, holding many leaf assessments.
CREATE TABLE IF NOT EXISTS bulks (
  id            INTEGER PRIMARY KEY,
  user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bulk_code     TEXT NOT NULL,
  plant         TEXT NOT NULL,
  assessed_date TEXT NOT NULL,
  status        TEXT NOT NULL DEFAULT 'Assessment Complete',
  created_at    TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE (user_id, bulk_code)
);

-- Stage 0 = healthy, 1-4 = suspected stage. valid = 0 means Unvalidated (stage is NULL).
CREATE TABLE IF NOT EXISTS leaves (
  id                 INTEGER PRIMARY KEY,
  bulk_id            INTEGER NOT NULL REFERENCES bulks(id) ON DELETE CASCADE,
  leaf_no            INTEGER NOT NULL,
  valid              INTEGER NOT NULL CHECK (valid IN (0,1)),
  stage              INTEGER CHECK (stage IS NULL OR stage BETWEEN 0 AND 4),
  status             TEXT,
  confidence         TEXT,
  recommended_action TEXT,
  treatment_eligible INTEGER NOT NULL DEFAULT 0,
  UNIQUE (bulk_id, leaf_no)
);

-- Leaves of the same stage share one treatment window; schedule holds the confirmed calendar steps.
CREATE TABLE IF NOT EXISTS treatment_groups (
  id           INTEGER PRIMARY KEY,
  bulk_id      INTEGER NOT NULL REFERENCES bulks(id) ON DELETE CASCADE,
  stage        INTEGER NOT NULL CHECK (stage BETWEEN 1 AND 4),
  leaf_nums    TEXT NOT NULL DEFAULT '[]',
  window_text  TEXT,
  schedule     TEXT,
  confirmed_at TEXT,
  UNIQUE (bulk_id, stage)
);

CREATE TABLE IF NOT EXISTS notifications (
  id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL, body TEXT, read INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_bulks_user ON bulks(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_leaves_bulk ON leaves(bulk_id);

-- ===== Admin knowledge console =====
-- Source files for the extraction pipeline. `content` holds the extracted text of a text-based upload.
CREATE TABLE IF NOT EXISTS documents (
  id           INTEGER PRIMARY KEY,
  use_case     TEXT NOT NULL REFERENCES use_cases(slug),
  title        TEXT NOT NULL,
  doc_type     TEXT NOT NULL DEFAULT 'Field notes',
  source       TEXT NOT NULL DEFAULT 'Upload portal',
  file_name    TEXT,
  size_bytes   INTEGER NOT NULL DEFAULT 0,
  content      TEXT NOT NULL DEFAULT '',
  status       TEXT NOT NULL DEFAULT 'Queued' CHECK (status IN ('Queued','Extracted','Needs review','Confirmed')),
  extracted_at TEXT,
  uploaded_by  INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_at   TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

-- One relationship (subject - predicate - object). stage: extracted -> corrected -> confirmed, or rejected.
-- Confirmed triples make up the knowledge graph; extracted + corrected ones make up the temporary graph.
CREATE TABLE IF NOT EXISTS triples (
  id            INTEGER PRIMARY KEY,
  use_case      TEXT NOT NULL REFERENCES use_cases(slug),
  document_id   INTEGER REFERENCES documents(id) ON DELETE CASCADE,
  subject       TEXT NOT NULL,
  subject_class TEXT,
  predicate     TEXT NOT NULL,
  object        TEXT NOT NULL,
  object_class  TEXT,
  confidence    REAL,
  stage         TEXT NOT NULL DEFAULT 'extracted' CHECK (stage IN ('extracted','corrected','confirmed','rejected')),
  reviewer_id   INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_at    TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS ontology_classes (
  id INTEGER PRIMARY KEY, use_case TEXT NOT NULL REFERENCES use_cases(slug),
  name TEXT NOT NULL COLLATE NOCASE, color TEXT NOT NULL DEFAULT '#3948d1', description TEXT,
  UNIQUE (use_case, name)
);
CREATE TABLE IF NOT EXISTS ontology_relations (
  id INTEGER PRIMARY KEY, use_case TEXT NOT NULL REFERENCES use_cases(slug),
  from_class INTEGER NOT NULL REFERENCES ontology_classes(id) ON DELETE CASCADE,
  to_class   INTEGER NOT NULL REFERENCES ontology_classes(id) ON DELETE CASCADE,
  label TEXT NOT NULL COLLATE NOCASE,
  UNIQUE (from_class, to_class, label)
);

-- parent_id NULL = top level of the use case.
CREATE TABLE IF NOT EXISTS dataset_folders (
  id INTEGER PRIMARY KEY, use_case TEXT NOT NULL REFERENCES use_cases(slug),
  parent_id INTEGER REFERENCES dataset_folders(id) ON DELETE CASCADE,
  name TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS dataset_images (
  id INTEGER PRIMARY KEY, use_case TEXT NOT NULL REFERENCES use_cases(slug),
  folder_id INTEGER REFERENCES dataset_folders(id) ON DELETE SET NULL,
  name TEXT NOT NULL, stored_name TEXT NOT NULL, mime TEXT NOT NULL, size_bytes INTEGER NOT NULL,
  label TEXT, status TEXT NOT NULL DEFAULT 'Needs review' CHECK (status IN ('Needs review','Validated')),
  uploaded_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Every admin change. document_id links an entry to a source document so Tracing can follow its history.
CREATE TABLE IF NOT EXISTS audit_log (
  id INTEGER PRIMARY KEY, use_case TEXT, actor_id INTEGER REFERENCES users(id) ON DELETE SET NULL, actor_name TEXT NOT NULL,
  action TEXT NOT NULL, object_type TEXT NOT NULL, object_id INTEGER, object_label TEXT,
  previous TEXT, new_value TEXT, status TEXT NOT NULL DEFAULT 'OK', document_id INTEGER, detail TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_docs_uc ON documents(use_case, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_triples_uc ON triples(use_case, stage);
CREATE INDEX IF NOT EXISTS idx_triples_doc ON triples(document_id);
CREATE INDEX IF NOT EXISTS idx_images_folder ON dataset_images(use_case, folder_id);
CREATE INDEX IF NOT EXISTS idx_audit_uc ON audit_log(use_case, id DESC);
CREATE INDEX IF NOT EXISTS idx_audit_doc ON audit_log(document_id);
