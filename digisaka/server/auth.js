import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import rateLimit from 'express-rate-limit';
import { db } from './db.js';
import { config } from './config.js';

const COOKIE = 'ds_session';
const cookieOpts = { httpOnly: true, sameSite: 'lax', secure: config.isProd, maxAge: config.sessionDays * 86400_000 };

export const publicUser = (u) => ({
  id: u.id, email: u.email, name: u.name, role: u.role, location: u.location, useCase: u.use_case,
  initials: u.name.split(/\s+/).map((w) => w[0]).slice(0, 2).join('').toUpperCase(),
});

export function requireAuth(req, res, next) {
  try {
    const { sub } = jwt.verify(req.cookies[COOKIE] || '', config.jwtSecret);
    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(sub);
    if (!user) throw new Error('unknown user');
    req.user = user;
    next();
  } catch { res.status(401).json({ error: 'Sign in to continue.' }); }
}

export const requireRole = (role) => (req, res, next) =>
  req.user.role === role ? next() : res.status(403).json({ error: 'You do not have access to this area.' });

const demoEmails = new Set(['juan@digisaka.test', 'admin@digisaka.test']);
const loginLimiter = rateLimit({
  windowMs: 15 * 60_000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => !config.isProd && demoEmails.has(req.body?.email),
  message: { error: 'Too many attempts. Try again in a few minutes.' },
});

export const authRouter = Router();

authRouter.post('/register', loginLimiter, (req, res) => {
  const { email, name, password, location } = req.body ?? {};
  if (!/^\S+@\S+\.\S+$/.test(email || '')) return res.status(400).json({ error: 'Enter a valid email address.' });
  if (!name?.trim()) return res.status(400).json({ error: 'Enter your name.' });
  if ((password || '').length < 8) return res.status(400).json({ error: 'Use a password with at least 8 characters.' });
  if (db.prepare('SELECT 1 FROM users WHERE email = ?').get(email)) return res.status(409).json({ error: 'An account with this email already exists.' });

  const parts = name.trim().split(/\s+/);
  const info = db.prepare('INSERT INTO users (email, name, first_name, middle_name, last_name, password_hash, location) VALUES (?,?,?,?,?,?,?)')
    .run(email, name.trim(), parts[0], parts.length > 2 ? parts.slice(1, -1).join(' ') : '', parts.length > 1 ? parts.at(-1) : '',
      bcrypt.hashSync(password, 10), location?.trim() || null);
  startSession(res, info.lastInsertRowid);
  res.status(201).json({ user: publicUser(db.prepare('SELECT * FROM users WHERE id = ?').get(info.lastInsertRowid)) });
});

authRouter.post('/login', loginLimiter, (req, res) => {
  const { email, password } = req.body ?? {};
  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email || '');
  if (!user || !bcrypt.compareSync(password || '', user.password_hash)) return res.status(401).json({ error: 'Email or password is incorrect.' });
  startSession(res, user.id);
  res.json({ user: publicUser(user) });
});

authRouter.post('/logout', (_req, res) => { res.clearCookie(COOKIE, cookieOpts); res.json({ ok: true }); });
authRouter.get('/me', requireAuth, (req, res) => res.json({ user: publicUser(req.user) }));

function startSession(res, userId) {
  const token = jwt.sign({ sub: userId }, config.jwtSecret, { expiresIn: `${config.sessionDays}d` });
  res.cookie(COOKIE, token, cookieOpts);
}
