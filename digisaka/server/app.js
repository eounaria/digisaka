import express from 'express';
import cookieParser from 'cookie-parser';
import helmet from 'helmet';
import path from 'node:path';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import { authRouter, requireAuth } from './auth.js';
import { dashboardRouter } from './routes/dashboard.js';
import { bulksRouter } from './routes/bulks.js';
import { meRouter } from './routes/me.js';
import { schedulesRouter } from './routes/schedules.js';
import { notificationsRouter } from './routes/notifications.js';
import { adminRouter } from './routes/admin.js';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const legacyDir = path.join(root, 'legacy');
const distDir = path.join(root, 'client', 'dist');

export function createApp() {
  const app = express();
  // The legacy screens use inline handlers, so CSP is relaxed there; tighten before production.
  app.use(helmet({ contentSecurityPolicy: false }));
  app.use(express.json({ limit: '2mb' }));
  app.use(cookieParser());

  app.get('/api/health', (_req, res) => res.json({ ok: true }));
  app.use('/api/auth', authRouter);
  app.use('/api/dashboard', requireAuth, dashboardRouter);
  app.use('/api/bulks', requireAuth, bulksRouter);
  app.use('/api/me', requireAuth, meRouter);
  app.use('/api/schedules', requireAuth, schedulesRouter);
  app.use('/api/notifications', requireAuth, notificationsRouter);
  app.use('/api/admin', requireAuth, adminRouter);
  app.use('/api', (_req, res) => res.status(404).json({ error: 'Not found.' }));

  // Screens not yet ported to Vue still run from the original prototype code.
  app.use('/legacy', express.static(legacyDir));

  if (fs.existsSync(distDir)) {
    app.use(express.static(distDir));
    app.get(/^\/(?!api\/|legacy\/).*/, (_req, res) => res.sendFile(path.join(distDir, 'index.html')));
  }
  app.use((err, _req, res, _next) => {
    if (err.status && err.status < 500) return res.status(err.status).json({ error: err.message });
    if (err.type === 'entity.too.large') return res.status(413).json({ error: 'That file is too large.' });
    console.error(err); res.status(500).json({ error: 'Something went wrong on our side. Try again.' }); });
  return app;
}
