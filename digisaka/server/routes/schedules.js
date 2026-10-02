import { Router } from 'express';
import { db } from '../db.js';

export const schedulesRouter = Router();

const STATUSES = ['Suggested', 'Confirmed', 'Applied', 'Unknown', 'Follow-up Required'];

const groupsOut = (bulkId) =>
  db.prepare('SELECT * FROM treatment_groups WHERE bulk_id = ? ORDER BY id').all(bulkId).map((g) => ({
    stage: g.stage, leafNums: JSON.parse(g.leaf_nums), window: g.window_text, schedule: JSON.parse(g.schedule || '[]'),
  }));

// Same shape the prototype keeps in `confirmedBulks`.
schedulesRouter.get('/', (req, res) => {
  const rows = db.prepare(`
    SELECT b.* FROM bulks b
    WHERE b.user_id = ? AND EXISTS (SELECT 1 FROM treatment_groups g WHERE g.bulk_id = b.id)
    ORDER BY (SELECT MIN(id) FROM treatment_groups g WHERE g.bulk_id = b.id)`).all(req.user.id);
  res.json({ schedules: rows.map((b, i) => ({ displayLabel: `Bulk ${i + 1}`, bulkId: b.bulk_code, plant: b.plant, groups: groupsOut(b.id) })) });
});

schedulesRouter.put('/:code', (req, res) => {
  const { groups } = req.body ?? {};
  const bulk = db.prepare('SELECT * FROM bulks WHERE user_id = ? AND bulk_code = ?').get(req.user.id, req.params.code);
  if (!bulk) return res.status(404).json({ error: 'Save the bulk assessment before scheduling treatment.' });
  const bad = !Array.isArray(groups) || !groups.length || groups.some((g) =>
    !(Number.isInteger(g.stage) && g.stage >= 1 && g.stage <= 4) || !Array.isArray(g.leafNums) ||
    !Array.isArray(g.schedule) || g.schedule.some((s) => !STATUSES.includes(s.status)));
  if (bad) return res.status(400).json({ error: 'Each treatment group needs a stage from 1 to 4, its leaves and a valid schedule.' });

  db.transaction(() => {
    const previous = new Map(db.prepare('SELECT stage, confirmed_at FROM treatment_groups WHERE bulk_id = ?').all(bulk.id).map((g) => [g.stage, g.confirmed_at]));
    db.prepare('DELETE FROM treatment_groups WHERE bulk_id = ?').run(bulk.id);
    const ins = db.prepare(`INSERT INTO treatment_groups (bulk_id, stage, leaf_nums, window_text, schedule, confirmed_at)
                            VALUES (?,?,?,?,?, COALESCE(?, datetime('now')))`);
    groups.forEach((g) => ins.run(bulk.id, g.stage, JSON.stringify(g.leafNums), g.window ?? null, JSON.stringify(g.schedule), previous.get(g.stage) ?? null));
    if (previous.size === 0) {
      const windows = groups.map((g) => g.window).filter(Boolean).join('; ');
      db.prepare('INSERT INTO notifications (user_id, title, body) VALUES (?,?,?)')
        .run(req.user.id, 'Treatment scheduled', `${bulk.plant} (${bulk.bulk_code}): ${windows}. Review the steps in Treatment Schedule.`);
    }
  })();
  res.json({ ok: true, groups: groupsOut(bulk.id) });
});
