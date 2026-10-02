import { Router } from 'express';
import crypto from 'node:crypto';
import bcrypt from 'bcryptjs';
import { db } from '../db.js';
import { requireRole } from '../auth.js';
import { parseCsv } from '../csv.js';
import { audit } from '../audit.js';
import { knowledgeRouter } from './adminKnowledge.js';
import { datasetsRouter } from './adminDatasets.js';

export const adminRouter = Router();
adminRouter.use(requireRole('admin'));
adminRouter.use(knowledgeRouter);
adminRouter.use(datasetsRouter);

const userOut = (u) => ({
  id: u.id, lastName: u.last_name || '', firstName: u.first_name || '', middleName: u.middle_name || '',
  email: u.email, contact: u.contact || '', location: u.location || '', createdAt: u.created_at,
});

// Farmer accounts, searchable and paginated.
adminRouter.get('/users', (req, res) => {
  const limit = Math.min(Math.max(Number(req.query.limit) || 25, 1), 100);
  const offset = Math.max(Number(req.query.offset) || 0, 0);
  const q = String(req.query.q || '').trim();
  const like = `%${q.replace(/[\\%_]/g, '\\$&')}%`;
  const where = `role = 'farmer' AND (@q = '' OR first_name LIKE @like ESCAPE '\\' OR last_name LIKE @like ESCAPE '\\'
                 OR middle_name LIKE @like ESCAPE '\\' OR email LIKE @like ESCAPE '\\' OR contact LIKE @like ESCAPE '\\')`;
  const total = db.prepare(`SELECT COUNT(*) AS n FROM users WHERE ${where}`).get({ q, like }).n;
  const rows = db.prepare(`SELECT * FROM users WHERE ${where} ORDER BY last_name COLLATE NOCASE, first_name COLLATE NOCASE LIMIT @limit OFFSET @offset`)
    .all({ q, like, limit, offset });
  res.json({ total, limit, offset, users: rows.map(userOut) });
});

// Master list import. Accounts are created without a usable password; farmers get access through an invite flow.
const HEADERS = { 'last name': 'last', lastname: 'last', 'first name': 'first', firstname: 'first', 'middle name': 'middle',
  middlename: 'middle', email: 'email', contact: 'contact', 'contact number': 'contact' };

adminRouter.post('/users/import', (req, res) => {
  const rows = parseCsv(String(req.body?.csv ?? ''));
  if (rows.length < 2) return res.status(400).json({ error: 'The file needs a header row and at least one farmer.' });
  if (rows.length > 5001) return res.status(400).json({ error: 'Import up to 5,000 farmers at a time.' });

  const cols = rows[0].map((h) => HEADERS[h.trim().toLowerCase()]);
  if (!cols.includes('email') || !cols.includes('first') || !cols.includes('last'))
    return res.status(400).json({ error: 'Header row must include Last Name, First Name and Email.' });

  const exists = db.prepare('SELECT 1 FROM users WHERE email = ?');
  const ins = db.prepare(`INSERT INTO users (email, name, first_name, middle_name, last_name, contact, password_hash, role)
                          VALUES (?,?,?,?,?,?,?, 'farmer')`);
  let created = 0; const skipped = [];
  db.transaction(() => {
    rows.slice(1).forEach((r, i) => {
      const v = {}; cols.forEach((k, j) => { if (k) v[k] = (r[j] ?? '').trim(); });
      const line = i + 2;
      if (!/^\S+@\S+\.\S+$/.test(v.email || '')) return skipped.push({ line, reason: 'Invalid email' });
      if (!v.first || !v.last) return skipped.push({ line, email: v.email, reason: 'Missing name' });
      if (exists.get(v.email)) return skipped.push({ line, email: v.email, reason: 'Already registered' });
      const name = [v.first, v.middle, v.last].filter(Boolean).join(' ');
      ins.run(v.email, name, v.first, v.middle || '', v.last, v.contact || null, bcrypt.hashSync(crypto.randomBytes(24).toString('hex'), 4));
      created++;
    });
  })();
  audit(req.user, { action: 'IMPORT', objectType: 'Farmer list', objectLabel: `${created} farmers`, previous: '—', newValue: `${created} created, ${skipped.length} skipped` });
  res.json({ created, skipped });
});
