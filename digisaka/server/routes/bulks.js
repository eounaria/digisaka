import { Router } from 'express';
import { db } from '../db.js';

export const bulksRouter = Router();

const leafOut = (l) => ({ id: l.leaf_no, valid: !!l.valid, stage: l.stage, status: l.status, confidence: l.confidence, recommendedAction: l.recommended_action, treatmentEligible: !!l.treatment_eligible });

function bulkOut(b) {
  const leaves = db.prepare('SELECT * FROM leaves WHERE bulk_id = ? ORDER BY leaf_no').all(b.id).map(leafOut);
  const counts = { 1: 0, 2: 0, 3: 0, 4: 0 };
  leaves.forEach((l) => { if (l.valid && counts[l.stage] !== undefined) counts[l.stage]++; });
  return { bulkId: b.bulk_code, plant: b.plant, date: b.assessed_date, leafCount: leaves.length, counts, status: b.status, leaves };
}

bulksRouter.get('/', (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 8, 50);
  const rows = db.prepare('SELECT * FROM bulks WHERE user_id = ? ORDER BY created_at DESC, id DESC LIMIT ?').all(req.user.id, limit);
  res.json({ bulks: rows.map(bulkOut) });
});

bulksRouter.put('/:code', (req, res) => {
  const { plant, date, status, leaves } = req.body ?? {};
  if (!plant || !date || !Array.isArray(leaves) || !leaves.length) return res.status(400).json({ error: 'A bulk needs a plant, a date and at least one leaf.' });
  if (leaves.some((l) => l.valid && !(Number.isInteger(l.stage) && l.stage >= 0 && l.stage <= 4))) return res.status(400).json({ error: 'Validated leaves need a stage from 0 to 4.' });

  const save = db.transaction(() => {
    db.prepare(`INSERT INTO bulks (user_id, bulk_code, plant, assessed_date, status) VALUES (?,?,?,?,?)
                ON CONFLICT (user_id, bulk_code) DO UPDATE SET plant=excluded.plant, assessed_date=excluded.assessed_date, status=excluded.status`)
      .run(req.user.id, req.params.code, plant, date, status || 'Assessment Complete');
    const bulk = db.prepare('SELECT * FROM bulks WHERE user_id = ? AND bulk_code = ?').get(req.user.id, req.params.code);
    db.prepare('DELETE FROM leaves WHERE bulk_id = ?').run(bulk.id);
    const ins = db.prepare('INSERT INTO leaves (bulk_id, leaf_no, valid, stage, status, confidence, recommended_action, treatment_eligible) VALUES (?,?,?,?,?,?,?,?)');
    leaves.forEach((l, i) => ins.run(bulk.id, i + 1, l.valid ? 1 : 0, l.valid ? l.stage : null, l.status ?? null, l.confidence ?? null, l.recommendedAction ?? null, l.treatmentEligible ? 1 : 0));
    return bulk;
  });
  res.json({ bulk: bulkOut(save()) });
});
