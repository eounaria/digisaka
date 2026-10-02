import crypto from 'node:crypto';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';

const isProd = process.env.NODE_ENV === 'production';
let jwtSecret = process.env.JWT_SECRET;
if (!jwtSecret) {
  if (isProd) throw new Error('JWT_SECRET must be set in production');
  jwtSecret = crypto.randomBytes(32).toString('hex');
  console.warn('[config] JWT_SECRET not set; using a temporary one (sessions reset on restart)');
}

const dbPath = process.env.DB_PATH || 'data/digisaka.db';
// Uploaded dataset images live next to the database (a temp folder when the database is in memory, e.g. tests).
const uploadDir = process.env.UPLOAD_DIR || (dbPath === ':memory:' ? fs.mkdtempSync(path.join(os.tmpdir(), 'digisaka-')) : path.join(path.dirname(dbPath), 'uploads'));

export const config = { isProd, port: Number(process.env.PORT) || 3000, dbPath, uploadDir, jwtSecret, sessionDays: 7 };
