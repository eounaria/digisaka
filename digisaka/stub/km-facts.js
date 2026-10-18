// The facts a stub Knowledge Maintenance workflow extracts: about 30, built the same for every workflow.
// The mix is chosen so each block the fact review shows (ontology check, correction, resolution, match
// and conflict warnings, a colleague's claim, a stale accepted fact) appears on some fact. The ontology check,
// correction, resolution and warnings are only served from final approval on (see factView in km.js).
export const COLLEAGUE = '00000000-0000-4000-8000-0000000000c1';

const SUBJECTS = ['Late blight', 'Phytophthora infestans', 'Metalaxyl', 'Potato leaf', 'Copper fungicide'];
const PREDICATES = ['causes', 'treated_by', 'affects', 'spreads_in'];
const OBJECTS = ['Potato leaf', 'Humid weather', 'Foliar spray', 'Tuber rot', 'Seed potato', 'Cool nights'];
const triple = (i, shift = 0) => ({ subject: SUBJECTS[i % 5], predicate: PREDICATES[(i + shift) % 4], object: OBJECTS[(i + shift) % 6] });
const iri = (label) => `https://digisaka.test/kg/${label.toLowerCase().replace(/\s+/g, '-')}`;
const end = (label, status, type) => ({ label, iri: iri(label), status, type });

// pending 0-19, unresolved 20-23, accepted 24-29 (28 and 29 are flagged again at final review).
export function stubFacts(claimExpires) {
  return Array.from({ length: 30 }, (_, i) => {
    const t = triple(i);
    const disposition = i < 20 ? 'pending' : i < 24 ? 'unresolved' : 'accepted';
    const gate3 = [{ status: 'passed', violations: [] }, { status: 'violations', violations: [{ message: `${t.predicate} does not allow ${t.object} as its object.` }] }, { status: 'passed', violations: [] }, null][i % 4];
    const mend = i % 5 === 0
      ? { altered: true, iterations: [{ iteration: 1, before: triple(i, 1), after: t }] }
      : i % 10 === 3 ? { altered: false, iterations: [{ iteration: 1, before: t, after: null }] } : null;
    return {
      id: `fact-${String(i + 1).padStart(2, '0')}`,
      disposition,
      stale: i >= 28,
      lock_version: i % 3,
      claimed_by: i === 1 ? COLLEAGUE : null,
      claimed_at: i === 1 ? new Date(Date.parse(claimExpires) - 15 * 60000).toISOString() : null,
      claim_expires_at: i === 1 ? claimExpires : null,
      extracted_triple: t,
      source_excerpt: `…${t.subject.toLowerCase()} ${t.predicate.replace(/_/g, ' ')} ${t.object.toLowerCase()}, as described in section ${i + 1}…`,
      graphjudge_result: i % 7 === 6 ? 'unsupported' : 'supported',
      restoration_status: { subject_restored: i % 2 === 0, relation_restored: false, object_restored: i % 3 === 0 },
      gate3,
      mend,
      entity_resolution: i % 2 === 0 ? { subject: end(t.subject, 'matched', 'Disease'), object: end(t.object, i % 4 === 0 ? 'new_entity' : 'matched', 'Concept') } : null,
      entity_match_warnings: i % 6 === 2 ? [{ message: `${t.object} could also be the existing entity "${t.object} (cultivar)".` }] : [],
      entity_conflict_warnings: i % 7 === 3 ? [{ message: `The graph already says ${t.subject} ${PREDICATES[(i + 1) % 4].replace(/_/g, ' ')} ${OBJECTS[(i + 2) % 6]}.` }] : [],
    };
  });
}
