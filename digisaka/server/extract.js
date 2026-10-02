import { parseCsv } from './csv.js';

/*
 * Rule-based relationship extraction. It reads three kinds of text:
 *   1. structured triples: JSON arrays, CSV with subject/predicate/object columns, or lines like "A | predicate | B" / "A -> predicate -> B"
 *   2. plain sentences that use one of the ontology's relation labels, e.g. "Black Sigatoka is caused by Pseudocercospora fijiensis."
 * Anything else is ignored. To use a language model instead, replace extractTriples() and keep its return shape.
 */
const tidy = (s) => String(s ?? '').replace(/\s+/g, ' ').replace(/^[\s"'*•\-–]+|[\s"'.;:,]+$/g, '').replace(/^(the|a|an)\s+/i, '').trim();
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const ok = (s) => s.length >= 2 && s.length <= 80;

/**
 * @param text       document text
 * @param relations  [{ label, fromName, toName }] from the ontology
 * @param known      Set of lower-cased entity names already in the knowledge graph (raises confidence)
 * @returns [{ subject, subjectClass, predicate, object, objectClass, confidence }]
 */
export function extractTriples(text, relations, known = new Set()) {
  const byLabel = new Map(relations.map((r) => [r.label.toLowerCase(), r]));
  const out = new Map();
  const add = (s, p, o, confidence) => {
    s = tidy(s); p = tidy(p); o = tidy(o);
    if (!ok(s) || !ok(o) || !p || p.length > 40) return;
    const rel = byLabel.get(p.toLowerCase());
    const key = `${s}|${p}|${o}`.toLowerCase();
    if (!out.has(key)) out.set(key, { subject: s, subjectClass: rel?.fromName ?? null, predicate: rel ? rel.label : p, object: o, objectClass: rel?.toName ?? null, confidence });
  };

  const body = String(text ?? '').trim();
  if (!body) return [];

  // JSON
  if (/^[[{]/.test(body)) {
    try {
      const data = JSON.parse(body);
      for (const t of Array.isArray(data) ? data : data.triples ?? []) {
        const c = Number(t.confidence);
        add(t.subject, t.predicate, t.object, c > 0 && c <= 1 ? c : 0.95);
      }
      return [...out.values()];
    } catch { /* not JSON, fall through to text */ }
  }

  // CSV with a header
  const first = body.split(/\r?\n/, 1)[0].toLowerCase();
  if (first.includes(',') && /subject/.test(first) && /predicate|relation/.test(first) && /object/.test(first)) {
    const [head, ...rows] = parseCsv(body);
    const col = (re) => head.findIndex((h) => re.test(h.trim().toLowerCase()));
    const [s, p, o, c] = [col(/^subject$/), col(/^(predicate|relation|relationship)$/), col(/^object$/), col(/^confidence$/)];
    if (s >= 0 && p >= 0 && o >= 0) {
      for (const r of rows) { const cf = Number(r[c]); add(r[s], r[p], r[o], cf > 0 && cf <= 1 ? cf : 0.95); }
      return [...out.values()];
    }
  }

  // Delimited lines and plain sentences
  const labels = [...byLabel.keys()].sort((a, b) => b.length - a.length);
  const patterns = labels.map((l) => [l, new RegExp(`^(.{2,80}?)\\s+(?:is\\s+|are\\s+|was\\s+|were\\s+)?${esc(l)}\\s+(.{2,80})$`, 'i')]);
  for (const line of body.split(/\r?\n/)) {
    const parts = line.split(/\s*(?:\||->|→)\s*/);
    if (parts.length === 3) { add(parts[0], parts[1], parts[2], 0.95); continue; }
    for (const sentence of line.split(/(?<=[.!?])\s+/)) {
      const s = sentence.trim().replace(/[.!?]+$/, '');
      for (const [label, re] of patterns) {
        const m = re.exec(s);
        if (!m) continue;
        const hits = [m[1], m[2]].filter((x) => known.has(tidy(x).toLowerCase())).length;
        add(m[1], label, m[2], Math.round(Math.min(0.9, 0.76 + hits * 0.07) * 100) / 100);
        break;
      }
    }
  }
  return [...out.values()];
}
