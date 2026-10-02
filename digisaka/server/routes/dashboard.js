import { Router } from 'express';
import { db } from '../db.js';

export const dashboardRouter = Router();

dashboardRouter.get('/', (req, res) => {
  const row = db.prepare(`
    SELECT (SELECT COUNT(*) FROM bulks WHERE user_id = @u) AS bulks,
           (SELECT COUNT(*) FROM leaves l JOIN bulks b ON b.id = l.bulk_id WHERE b.user_id = @u) AS leaves,
           (SELECT COUNT(*) FROM leaves l JOIN bulks b ON b.id = l.bulk_id WHERE b.user_id = @u AND l.valid = 1 AND l.stage BETWEEN 1 AND 4) AS needTreatment
  `).get({ u: req.user.id });
  res.json({ leavesScanned: row.leaves, bulksAssessed: row.bulks, leavesNeedingTreatment: row.needTreatment });
});
