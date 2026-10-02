import { Router, raw } from 'express';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { db } from '../db.js';
import { config } from '../config.js';
import { audit } from '../audit.js';
import { bad, notFound, HttpError } from '../http.js';
import { scopeOf } from './adminKnowledge.js';

export const datasetsRouter = Router();
fs.mkdirSync(config.uploadDir, { recursive: true });

const IMAGE_TYPES = { 'image/png': 'png', 'image/jpeg': 'jpg', 'image/webp': 'webp', 'image/gif': 'gif' };
// Trust the bytes, not the Content-Type header.
function sniff(b) {
  if (b.length > 12 && b.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return 'image/png';
  if (b.length > 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return 'image/jpeg';
  if (b.length > 12 && b.toString('ascii', 0, 4) === 'RIFF' && b.toString('ascii', 8, 12) === 'WEBP') return 'image/webp';
  if (b.length > 6 && /^GIF8[79]a$/.test(b.toString('ascii', 0, 6))) return 'image/gif';
  return null;
}
const name = (v, label, max = 60) => {
  const s = String(v ?? '').replace(/\s+/g, ' ').trim();
  if (!s) throw bad(`${label} is required.`);
  if (s.length > max) throw bad(`${label} must be ${max} characters or fewer.`);
  return s;
};
const folderOr404 = (id) => db.prepare('SELECT * FROM dataset_folders WHERE id = ?').get(Number(id)) ?? (() => { throw notFound('That folder'); })();
const sameUseCase = (folderId, uc) => {
  if (folderId == null || folderId === '') return null;
  const f = folderOr404(folderId);
  if (f.use_case !== uc) throw bad('That folder belongs to a different use case.');
  return f;
};
const siblingTaken = (uc, parentId, n, exceptId = 0) =>
  db.prepare('SELECT 1 FROM dataset_folders WHERE use_case = ? AND parent_id IS ? AND lower(name) = lower(?) AND id != ?').get(uc, parentId, n, exceptId);

// ---------- folders ----------
datasetsRouter.get('/datasets/folders', (req, res) => {
  const uc = scopeOf(req);
  const folders = db.prepare(`SELECT f.id, f.parent_id AS parentId, f.name, (SELECT COUNT(*) FROM dataset_images i WHERE i.folder_id = f.id) AS count
                              FROM dataset_folders f WHERE f.use_case = ? ORDER BY f.id`).all(uc);
  const total = db.prepare('SELECT COUNT(*) n FROM dataset_images WHERE use_case = ?').get(uc).n;
  res.json({ folders, total, unfiled: db.prepare('SELECT COUNT(*) n FROM dataset_images WHERE use_case = ? AND folder_id IS NULL').get(uc).n });
});

datasetsRouter.post('/datasets/folders', (req, res) => {
  const uc = scopeOf(req), n = name(req.body?.name, 'Folder name');
  const parent = sameUseCase(req.body?.parentId, uc);
  if (siblingTaken(uc, parent?.id ?? null, n)) throw new HttpError(409, 'A folder with that name already exists here.');
  const id = db.prepare('INSERT INTO dataset_folders (use_case, parent_id, name) VALUES (?,?,?)').run(uc, parent?.id ?? null, n).lastInsertRowid;
  audit(req.user, { useCase: uc, action: 'CREATE', objectType: 'Folder', objectId: id, objectLabel: n, previous: '—', newValue: parent ? `In ${parent.name}` : 'Top level' });
  res.status(201).json({ id });
});

datasetsRouter.put('/datasets/folders/:id', (req, res) => {
  const f = folderOr404(req.params.id), n = name(req.body?.name, 'Folder name');
  if (siblingTaken(f.use_case, f.parent_id, n, f.id)) throw new HttpError(409, 'A folder with that name already exists here.');
  db.prepare('UPDATE dataset_folders SET name = ? WHERE id = ?').run(n, f.id);
  audit(req.user, { useCase: f.use_case, action: 'UPDATE', objectType: 'Folder', objectId: f.id, objectLabel: n, previous: f.name, newValue: n });
  res.json({ ok: true });
});

datasetsRouter.delete('/datasets/folders/:id', (req, res) => {
  const f = folderOr404(req.params.id);
  if (db.prepare('SELECT 1 FROM dataset_images WHERE folder_id = ?').get(f.id) || db.prepare('SELECT 1 FROM dataset_folders WHERE parent_id = ?').get(f.id))
    throw new HttpError(409, 'Move or delete what is inside this folder first.');
  db.prepare('DELETE FROM dataset_folders WHERE id = ?').run(f.id);
  audit(req.user, { useCase: f.use_case, action: 'DELETE', objectType: 'Folder', objectId: f.id, objectLabel: f.name, previous: f.name, newValue: 'Deleted' });
  res.json({ ok: true });
});

// ---------- images ----------
const IMG = `SELECT i.id, i.name, i.mime, i.size_bytes AS sizeBytes, i.label, i.status, i.folder_id AS folderId, f.name AS folderName, i.created_at AS createdAt
             FROM dataset_images i LEFT JOIN dataset_folders f ON f.id = i.folder_id`;
const SORTS = { newest: 'i.id DESC', oldest: 'i.id ASC', name: 'i.name COLLATE NOCASE ASC' };

datasetsRouter.get('/datasets/images', (req, res) => {
  const uc = scopeOf(req);
  const limit = Math.min(Math.max(Number(req.query.limit) || 24, 1), 100), offset = Math.max(Number(req.query.offset) || 0, 0);
  const fid = req.query.folderId === 'unfiled' ? 'unfiled' : req.query.folderId ? Number(req.query.folderId) : null;
  const status = ['Validated', 'Needs review'].includes(req.query.status) ? req.query.status : null;
  const q = `%${String(req.query.q || '').trim().replace(/[\\%_]/g, '\\$&')}%`;
  // A folder includes everything nested beneath it.
  const scope = fid === 'unfiled' ? 'i.folder_id IS NULL' : fid
    ? `i.folder_id IN (WITH RECURSIVE t(id) AS (SELECT id FROM dataset_folders WHERE id = @fid UNION ALL SELECT f.id FROM dataset_folders f JOIN t ON f.parent_id = t.id) SELECT id FROM t)` : '1';
  const args = { uc, fid: typeof fid === 'number' ? fid : null, q, status };
  const where = `i.use_case = @uc AND ${scope} AND (@q = '%%' OR i.name LIKE @q ESCAPE '\\' OR i.label LIKE @q ESCAPE '\\') AND (@status IS NULL OR i.status = @status)`;
  const m = db.prepare(`SELECT COUNT(*) AS total, COALESCE(SUM(label IS NOT NULL AND label != ''), 0) AS labeled, COALESCE(SUM(status = 'Validated'), 0) AS validated
                        FROM dataset_images i WHERE i.use_case = @uc AND ${scope}`).get({ uc, fid: args.fid });
  const total = db.prepare(`SELECT COUNT(*) n FROM dataset_images i WHERE ${where}`).get(args).n;
  const images = db.prepare(`${IMG} WHERE ${where} ORDER BY ${SORTS[req.query.sort] ?? SORTS.newest} LIMIT @limit OFFSET @offset`).all({ ...args, limit, offset });
  res.json({ total, images, metrics: { images: m.total, labeled: m.labeled, validationPct: m.total ? Math.round((m.validated / m.total) * 100) : 0 } });
});

datasetsRouter.post('/datasets/images', raw({ type: Object.keys(IMAGE_TYPES), limit: '8mb' }), (req, res) => {
  const uc = scopeOf(req);
  if (!Buffer.isBuffer(req.body) || !req.body.length) throw bad('Choose a PNG, JPEG, WebP or GIF image (up to 8 MB).');
  const mime = sniff(req.body);
  if (!mime) throw bad('That file is not a supported image. Use PNG, JPEG, WebP or GIF.');
  const folder = sameUseCase(req.query.folderId, uc);
  const label = String(req.query.label ?? '').trim().slice(0, 60) || folder?.name || null;
  const stored = `${crypto.randomUUID()}.${IMAGE_TYPES[mime]}`;
  fs.writeFileSync(path.join(config.uploadDir, stored), req.body);
  const n = name(String(req.query.name || 'Untitled image').replace(/\.[^.]+$/, ''), 'Image name', 100);
  const id = db.prepare('INSERT INTO dataset_images (use_case, folder_id, name, stored_name, mime, size_bytes, label, uploaded_by) VALUES (?,?,?,?,?,?,?,?)')
    .run(uc, folder?.id ?? null, n, stored, mime, req.body.length, label, req.user.id).lastInsertRowid;
  audit(req.user, { useCase: uc, action: 'UPLOAD', objectType: 'Image', objectId: id, objectLabel: n, previous: '—', newValue: folder?.name ?? 'Unfiled' });
  res.status(201).json({ image: db.prepare(`${IMG} WHERE i.id = ?`).get(id) });
});

const imageOr404 = (id) => db.prepare('SELECT * FROM dataset_images WHERE id = ?').get(Number(id)) ?? (() => { throw notFound('That image'); })();

datasetsRouter.put('/datasets/images/:id', (req, res) => {
  const im = imageOr404(req.params.id), b = req.body ?? {};
  const n = b.name === undefined ? im.name : name(b.name, 'Image name', 100);
  const status = b.status === undefined ? im.status : b.status;
  if (!['Validated', 'Needs review'].includes(status)) throw bad('Status must be Validated or Needs review.');
  const moved = b.folderId !== undefined && (b.folderId ?? null) !== im.folder_id;
  const folder = moved ? sameUseCase(b.folderId, im.use_case) : null;
  const folderId = moved ? folder?.id ?? null : im.folder_id;
  // Moving to a folder re-labels the image with the folder's name unless a label is given.
  const label = b.label !== undefined ? String(b.label).trim().slice(0, 60) || null : moved ? folder?.name ?? null : im.label;
  db.prepare('UPDATE dataset_images SET name = ?, status = ?, folder_id = ?, label = ? WHERE id = ?').run(n, status, folderId, label, im.id);
  if (moved) audit(req.user, { useCase: im.use_case, action: 'MOVE', objectType: 'Image', objectId: im.id, objectLabel: n, previous: im.label ?? 'Unfiled', newValue: label ?? 'Unfiled' });
  else audit(req.user, { useCase: im.use_case, action: 'UPDATE', objectType: 'Image', objectId: im.id, objectLabel: n,
    previous: `${im.name} / ${im.status} / ${im.label ?? 'No label'}`, newValue: `${n} / ${status} / ${label ?? 'No label'}` });
  res.json({ image: db.prepare(`${IMG} WHERE i.id = ?`).get(im.id) });
});

datasetsRouter.delete('/datasets/images/:id', (req, res) => {
  const im = imageOr404(req.params.id);
  db.prepare('DELETE FROM dataset_images WHERE id = ?').run(im.id);
  fs.rm(path.join(config.uploadDir, im.stored_name), { force: true }, () => {});
  audit(req.user, { useCase: im.use_case, action: 'DELETE', objectType: 'Image', objectId: im.id, objectLabel: im.name, previous: im.label ?? 'Unfiled', newValue: 'Deleted' });
  res.json({ ok: true });
});

datasetsRouter.get('/datasets/images/:id/file', (req, res) => {
  const im = imageOr404(req.params.id);
  res.set('Cache-Control', 'private, max-age=3600').type(im.mime).sendFile(path.resolve(config.uploadDir, im.stored_name), (err) => {
    if (err && !res.headersSent) res.status(404).json({ error: 'That image file is missing.' });
  });
});
