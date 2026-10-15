import crypto from 'node:crypto';
import bcrypt from 'bcryptjs';
import fs from 'node:fs';
import { db } from './db.js';

const upsert = db.prepare(`INSERT OR IGNORE INTO users (email, name, first_name, middle_name, last_name, contact, password_hash, role, location)
                           VALUES (?,?,?,?,?,?,?,?,?)`);

// The farmers shown in the admin Users screen demo (no usable password until invited)
const sample = JSON.parse(fs.readFileSync(new URL('./sample-farmers.json', import.meta.url), 'utf8'));
for (const f of sample)
  upsert.run(f.email, [f.first, f.middle, f.last].filter(Boolean).join(' '), f.first, f.middle, f.last, f.contact, bcrypt.hashSync(crypto.randomUUID(), 4), 'farmer', null);

console.log('Seeded sample farmers. No logins are created; sign in with a Supabase Technical User.');
