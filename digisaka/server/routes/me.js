import { Router } from 'express';
import { db } from '../db.js';

export const meRouter = Router();

meRouter.get('/use-cases', (_req, res) => res.json({ useCases: db.prepare('SELECT * FROM use_cases ORDER BY rowid').all() }));

meRouter.put('/preferences', (req, res) => {
  const { useCase } = req.body ?? {};
  if (!db.prepare('SELECT 1 FROM use_cases WHERE slug = ?').get(useCase)) return res.status(400).json({ error: 'Unknown use case.' });
  db.prepare('UPDATE users SET use_case = ? WHERE id = ?').run(useCase, req.user.id);
  res.json({ ok: true, useCase });
});
