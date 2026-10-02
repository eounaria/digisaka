import { db } from './db.js';

const ins = db.prepare(`INSERT INTO audit_log (use_case, actor_id, actor_name, action, object_type, object_id, object_label, previous, new_value, status, document_id, detail)
                        VALUES (@useCase,@actorId,@actorName,@action,@objectType,@objectId,@objectLabel,@previous,@newValue,@status,@documentId,@detail)`);

/** Record an admin action. `actor` is req.user, or null for the system. */
export function audit(actor, e) {
  ins.run({
    useCase: e.useCase ?? null, actorId: actor?.id ?? null, actorName: actor?.name ?? 'System', action: e.action,
    objectType: e.objectType, objectId: e.objectId ?? null, objectLabel: e.objectLabel ?? null,
    previous: e.previous ?? null, newValue: e.newValue ?? null, status: e.status ?? 'OK', documentId: e.documentId ?? null,
    detail: e.detail ? JSON.stringify(e.detail) : null,
  });
}
