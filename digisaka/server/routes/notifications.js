import { Router } from 'express';
import { db } from '../db.js';

export const notificationsRouter = Router();

notificationsRouter.get('/', (req, res) => {
  const rows = db.prepare('SELECT id, title, body, read, created_at FROM notifications WHERE user_id = ? ORDER BY id DESC LIMIT 50').all(req.user.id);
  res.json({
    unread: rows.filter((n) => !n.read).length,
    notifications: rows.map((n) => ({ id: n.id, title: n.title, body: n.body, read: !!n.read, createdAt: n.created_at.replace(' ', 'T') + 'Z' })),
  });
});

notificationsRouter.post('/read-all', (req, res) => {
  db.prepare('UPDATE notifications SET read = 1 WHERE user_id = ? AND read = 0').run(req.user.id);
  res.json({ ok: true });
});
