import crypto from 'node:crypto';
import { db } from './db.js';
import { TECHNICAL_USER_ROLES } from './supabaseAuth.js';

// Bearer-token gate for the admin API. Only Technical Users get through; each is recorded in `users` on first request
// so uploaded-by, reviewer and audit-actor references keep working.
export function requireTechnicalUser(verifyToken) {
  return async (req, res, next) => {
    const token = /^Bearer (.+)$/i.exec(req.headers.authorization || '')?.[1];
    if (!token) return res.status(401).json({ error: 'Sign in to continue.' });
    try {
      const who = await verifyToken(token);
      if (!who.roles?.some((r) => TECHNICAL_USER_ROLES.includes(r))) return res.status(403).json({ error: 'You do not have access to this area.' });
      let user = db.prepare('SELECT * FROM users WHERE email = ?').get(who.email);
      if (!user) {
        const id = db.prepare("INSERT INTO users (email, name, password_hash, role) VALUES (?,?,?, 'admin')")
          .run(who.email, who.name || who.email, crypto.randomBytes(32).toString('hex')).lastInsertRowid;
        user = db.prepare('SELECT * FROM users WHERE id = ?').get(id);
      }
      req.user = user;
      next();
    } catch (err) {
      const status = err.status === 401 ? 401 : 503;
      res.status(status).json({ error: status === 401 ? 'Sign in to continue.' : 'Sign-in could not be checked.' });
    }
  };
}
