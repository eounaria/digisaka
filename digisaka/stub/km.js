// Stand-in for the Knowledge Maintenance API under /api/v1/knowledge-maintenance: document workflows and
// their fact review. A workflow moves through timed states on a lazy clock (settled on the next read) and
// stops at the two review gates. The document title picks the path (see `pathOf`). Errors are the
// service's nested {error: {code, message, details}}.
import crypto from 'node:crypto';
import { userForToken } from './supabase.js';
import { stubFacts } from './km-facts.js';

const BASE = '/api/v1/knowledge-maintenance/workflows';
const TECHNICAL = ['administrator', 'domain_expert', 'plant_pathologist'];

// Sample TTL ontology for stub - matches the Digisaka Black Sigatoka domain
const SAMPLE_TTL = `
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix ds: <https://digisaka.org/ontology#> .
@prefix skos: <http://www.w3.org/2004/02/skos/core#> .

ds:BlackSigatoka rdf:type owl:Class ;
    rdfs:label "Black Sigatoka" ;
    rdfs:comment "Fungal disease caused by Pseudocercospora fijiensis affecting banana plants" ;
    skos:prefLabel "Black Sigatoka"@en .

ds:BananaPlant rdf:type owl:Class ;
    rdfs:label "Banana Plant" ;
    rdfs:comment "Musa species cultivated for fruit production" ;
    skos:prefLabel "Banana Plant"@en .

ds:Leaf rdf:type owl:Class ;
    rdfs:label "Leaf" ;
    rdfs:comment "Individual leaf of a banana plant" ;
    skos:prefLabel "Leaf"@en .

ds:LeafStage rdf:type owl:Class ;
    rdfs:label "Leaf Stage" ;
    rdfs:comment "Developmental stage of a leaf affecting disease susceptibility" ;
    skos:prefLabel "Leaf Stage"@en .

ds:Treatment rdf:type owl:Class ;
    rdfs:label "Treatment" ;
    rdfs:comment "Fungicide or cultural treatment applied to manage disease" ;
    skos:prefLabel "Treatment"@en .

ds:Fungicide rdf:type owl:Class ;
    rdfs:label "Fungicide" ;
    rdfs:subClassOf ds:Treatment ;
    skos:prefLabel "Fungicide"@en .

ds:CulturalPractice rdf:type owl:Class ;
    rdfs:label "Cultural Practice" ;
    rdfs:subClassOf ds:Treatment ;
    skos:prefLabel "Cultural Practice"@en .

ds:hasStage rdf:type owl:ObjectProperty ;
    rdfs:domain ds:Leaf ;
    rdfs:range ds:LeafStage ;
    rdfs:label "has stage" .

ds:hasDisease rdf:type owl:ObjectProperty ;
    rdfs:domain ds:Leaf ;
    rdfs:range ds:BlackSigatoka ;
    rdfs:label "has disease" .

ds:treatedWith rdf:type owl:ObjectProperty ;
    rdfs:domain ds:Leaf ;
    rdfs:range ds:Treatment ;
    rdfs:label "treated with" .

ds:hasSeverity rdf:type owl:DatatypeProperty ;
    rdfs:domain ds:BlackSigatoka ;
    rdfs:range xsd:integer ;
    rdfs:label "has severity" .

ds:hasIncubationDays rdf:type owl:DatatypeProperty ;
    rdfs:domain ds:BlackSigatoka ;
    rdfs:range xsd:integer ;
    rdfs:label "has incubation days" .

ds:YoungLeaf rdf:type ds:LeafStage ;
    rdfs:label "Young Leaf" ;
    skos:prefLabel "Young Leaf"@en .

ds:MatureLeaf rdf:type ds:LeafStage ;
    rdfs:label "Mature Leaf" ;
    skos:prefLabel "Mature Leaf"@en .

ds:OldLeaf rdf:type ds:LeafStage ;
    rdfs:label "Old Leaf" ;
    skos:prefLabel "Old Leaf"@en .

ds:Mancozeb rdf:type ds:Fungicide ;
    rdfs:label "Mancozeb" ;
    skos:prefLabel "Mancozeb"@en .

ds:Propiconazole rdf:type ds:Fungicide ;
    rdfs:label "Propiconazole" ;
    skos:prefLabel "Propiconazole"@en .

ds:LeafRemoval rdf:type ds:CulturalPractice ;
    rdfs:label "Leaf Removal" ;
    skos:prefLabel "Leaf Removal"@en .

ds:FieldSanitation rdf:type ds:CulturalPractice ;
    rdfs:label "Field Sanitation" ;
    skos:prefLabel "Field Sanitation"@en .
`;
const CLAIM_MS = 15 * 60000;
const DISPOSITIONS = ['pending', 'accepted', 'rejected', 'unresolved'];
const GATE_STAGE = { awaiting_extraction_review: 'extraction_review', awaiting_final_approval: 'final_review' };
const DECIDABLE = { extraction_review: 'pending', final_review: 'accepted' };
// Timed states and where each goes next. `committing` and `extracting` are settled by `leave`.
const NEXT = {
  document_submitted: 'extracting', extracting: 'restoring_verifying', restoring_verifying: 'awaiting_extraction_review',
  canonicalizing: 'validating', validating: 'correcting_revalidating', correcting_revalidating: 'awaiting_final_approval', committing: 'completed',
};

const err = (status, code, message) => ({ status, body: { error: { code, message, details: {} } } });
const ok = (body, status = 200, headers = {}) => ({ status, body, headers });

// A title containing `commit-fail` fails its first commit; `fail` fails extraction; `slow` stretches every state.
export function pathOf(title) {
  const t = String(title).toLowerCase();
  return { commitFail: t.includes('commit-fail'), fail: !t.includes('commit-fail') && t.includes('fail'), slow: t.includes('slow') };
}

export const createKmStore = () => {
  const store = { workflows: new Map(), nextId: 1, reset() { store.workflows = new Map(); store.nextId = 1; } };
  return store;
};

// The first part of a multipart body with the given field name: { value, filename }.
function multipartField(raw, contentType, name) {
  const boundary = /boundary=("?)([^";]+)\1/.exec(contentType || '')?.[2];
  if (!boundary) return null;
  for (const part of raw.toString('utf8').split(`--${boundary}`)) {
    const cut = part.indexOf('\r\n\r\n');
    if (cut < 0) continue;
    const head = part.slice(0, cut);
    if (!new RegExp(`[; ]name="${name}"`).test(head)) continue;
    return { value: part.slice(cut + 4).replace(/\r\n$/, ''), filename: /filename="([^"]*)"/.exec(head)?.[1] };
  }
  return null;
}

// Ontology check, correction, entity resolution and their warnings come from the stages after extraction
// review (canonicalizing, validating, correcting), so the first review sees none of them.
const laterStages = () => ({ gate3: null, mend: null, entity_resolution: null, entity_match_warnings: [], entity_conflict_warnings: [] });

export function kmRoutes(store, { now = Date.now, stepMs = 4000 } = {}) {
  const iso = (ms) => new Date(ms).toISOString();

  const enter = (w, state, at) => {
    w.state = state; w.enteredAt = at; w.updatedAt = at;
    w.retrying = state === 'extracting' && w.path.fail ? { stage: 'extraction', attempt: 2, max_attempts: 3 } : null;
    if (state === 'awaiting_extraction_review') w.factsReady = true;
    if (state === 'completed') w.completedAt = at;
    if (state !== 'commit_failed' && state !== 'failed') w.failure = null;
  };
  // What a timed state turns into when its time is up (extraction can fail, the first commit can fail).
  const leave = (w, at) => {
    if (w.state === 'extracting' && w.path.fail) {
      enter(w, 'failed', at);
      w.failure = { code: 'EXTRACTION_FAILED', message: 'The extraction model did not return a usable answer for this document.', attempts: 3 };
      w.retryAvailable = false;
    } else if (w.state === 'committing' && w.path.commitFail && !w.commitFailedOnce) {
      w.commitFailedOnce = true;
      enter(w, 'commit_failed', at);
      w.failure = { code: 'COMMIT_FAILED', message: 'The knowledge graph did not accept the commit. Retry it.', attempts: 1 };
      w.retryAvailable = true;
    } else enter(w, NEXT[w.state], at);
  };
  const settle = (w) => {
    for (;;) {
      if (!NEXT[w.state]) return w;
      const due = w.enteredAt + (w.path.slow ? stepMs * 10 : stepMs);
      if (now() < due) return w;
      leave(w, due);
    }
  };

  const view = (w) => ({
    workflow_id: w.id, workflow_type: 'document_extraction', state: w.state, failure: w.failure, retrying: w.retrying,
    retry_available: w.state === 'commit_failed' && w.retryAvailable,
    created_at: iso(w.createdAt), updated_at: iso(w.updatedAt), completed_at: w.completedAt ? iso(w.completedAt) : null,
    named_graph_uri: `https://digisaka.test/kg/run/${w.id}`, ontology_version_pinned: '1.4.0',
  });
  const factView = (w, f) => {
    const { stale, ...rest } = f;
    const live = !f.claim_expires_at || Date.parse(f.claim_expires_at) > now();
    const held = f.claimed_by && live;
    return {
      ...rest,
      ...(w.state === 'awaiting_extraction_review' ? laterStages() : {}),
      claimed_by: held ? f.claimed_by : null, claimed_at: held ? f.claimed_at : null, claim_expires_at: held ? f.claim_expires_at : null,
      requires_action: f.disposition === 'pending' || (w.state === 'awaiting_final_approval' && stale && f.disposition === 'accepted'),
    };
  };

  // Resolves the workflow and caller for the routes under /workflows/:id; `handle` gets (req, w, user).
  const withWorkflow = (handle) => (req) => {
    const user = userForToken((req.headers.authorization || '').replace(/^Bearer\s+/i, ''));
    if (!user) return err(401, 'UNAUTHENTICATED', 'Sign in to continue.');
    if (!user.roles.some((r) => TECHNICAL.includes(r))) return err(403, 'FORBIDDEN', 'This account is not a Technical User.');
    if (!req.params?.id) return handle(req, null, user);
    const w = store.workflows.get(req.params.id);
    if (!w) return err(404, 'NOT_FOUND', 'Workflow not found');
    return handle(req, settle(w), user);
  };
  const factOf = (w, id) => w.facts.find((f) => f.id === id);
  const noFact = () => err(404, 'NOT_FOUND', 'Fact not found');
  // Extraction review ends when no fact is waiting for a decision.
  const afterReview = (w) => { if (w.state === 'awaiting_extraction_review' && !w.facts.some((f) => f.disposition === 'pending')) enter(w, 'canonicalizing', now()); };

  return [
    {
      method: 'POST', path: BASE,
      handle: withWorkflow(({ body, raw, headers }) => {
        let title, content;
        if (/multipart\/form-data/i.test(headers['content-type'] || '')) {
          const file = multipartField(raw, headers['content-type'], 'file');
          if (!file) return err(422, 'VALIDATION_ERROR', 'A file is required');
          title = multipartField(raw, headers['content-type'], 'title')?.value?.trim() || file.filename || 'Uploaded document';
          content = file.value;
        } else {
          ({ title, content } = body?.document ?? {});
          if (typeof title !== 'string' || !title.trim() || typeof content !== 'string' || !content.trim()) return err(422, 'VALIDATION_ERROR', 'A document needs a title and content');
        }
        const at = now();
        const w = { id: crypto.randomUUID(), title: title.trim(), path: pathOf(title), createdAt: at, completedAt: null, factsReady: false, facts: stubFacts(iso(at + 30 * 60000)), retryAvailable: false, commitFailedOnce: false, failure: null, retrying: null };
        enter(w, 'document_submitted', at);
        store.workflows.set(w.id, w);
        return ok({ workflow_id: w.id, workflow_type: 'document_extraction', state: w.state, created_at: iso(at) }, 202);
      }),
    },
    { method: 'GET', path: `${BASE}/:id`, handle: withWorkflow((_req, w) => ok(view(w))) },
    {
      method: 'GET', path: `${BASE}/:id/facts`,
      handle: withWorkflow(({ query }, w) => {
        const disposition = query.get('disposition');
        if (disposition && !DISPOSITIONS.includes(disposition)) return err(422, 'VALIDATION_ERROR', `disposition must be one of ${DISPOSITIONS.join(', ')}`);
        const limit = Number(query.get('limit') ?? 25), offset = Number(query.get('offset') ?? 0);
        if (!Number.isInteger(limit) || limit < 1 || limit > 500 || !Number.isInteger(offset) || offset < 0) return err(422, 'VALIDATION_ERROR', 'limit must be 1-500 and offset 0 or more');
        const all = w.factsReady ? w.facts.filter((f) => !disposition || f.disposition === disposition) : [];
        return ok({ facts: all.slice(offset, offset + limit).map((f) => factView(w, f)), total: all.length, limit, offset });
      }),
    },
    {
      method: 'POST', path: `${BASE}/:id/facts/:fid/claim`,
      handle: withWorkflow(({ params }, w, user) => {
        const f = w.factsReady && factOf(w, params.fid);
        if (!f) return noFact();
        const previous = factView(w, f).claimed_by;
        const at = now();
        Object.assign(f, { claimed_by: user.id, claimed_at: iso(at), claim_expires_at: iso(at + CLAIM_MS) });
        return ok({ fact_id: f.id, claimed_by: f.claimed_by, claimed_at: f.claimed_at, claim_expires_at: f.claim_expires_at, ...(previous && previous !== user.id ? { previous_holder: previous } : {}) });
      }),
    },
    {
      method: 'POST', path: `${BASE}/:id/facts/:fid/release`,
      handle: withWorkflow(({ params }, w, user) => {
        const f = w.factsReady && factOf(w, params.fid);
        if (!f) return noFact();
        const holder = factView(w, f).claimed_by;
        if (holder && holder !== user.id) return err(409, 'CONFLICT', 'This fact is claimed by someone else');
        Object.assign(f, { claimed_by: null, claimed_at: null, claim_expires_at: null });
        return ok({ fact_id: f.id, claimed_by: null, claimed_at: null, claim_expires_at: null });
      }),
    },
    {
      method: 'POST', path: `${BASE}/:id/facts/:fid/review`,
      handle: withWorkflow(({ params, body }, w, user) => {
        const f = w.factsReady && factOf(w, params.fid);
        if (!f) return noFact();
        const stage = GATE_STAGE[w.state];
        if (!stage) return err(409, 'CONFLICT', `Workflow is ${w.state}, not at a review gate`);
        if (!Number.isInteger(body?.lock_version) || !['accept', 'reject'].includes(body?.decision) || body?.review_stage !== stage) {
          return err(422, 'VALIDATION_ERROR', `Send lock_version, decision (accept or reject) and review_stage ${stage}`);
        }
        if (body.lock_version !== f.lock_version || f.disposition !== DECIDABLE[stage]) return err(409, 'CONFLICT', 'The fact changed since it was read; reload and retry');
        const holder = factView(w, f).claimed_by;
        if (holder && holder !== user.id) return err(409, 'CONFLICT', 'This fact is claimed by someone else');
        Object.assign(f, { disposition: body.decision === 'accept' ? 'accepted' : 'rejected', lock_version: f.lock_version + 1, stale: false, claimed_by: null, claimed_at: null, claim_expires_at: null });
        afterReview(w);
        return ok({ fact_id: f.id, disposition: f.disposition, lock_version: f.lock_version, review_decision_id: crypto.randomUUID() });
      }),
    },
    {
      method: 'POST', path: `${BASE}/:id/approve`,
      handle: withWorkflow((_req, w) => {
        const retry = w.state === 'commit_failed' && w.retryAvailable;
        if (w.state !== 'awaiting_final_approval' && !retry) return err(409, 'CONFLICT', `Workflow is ${w.state}; it can only be approved at final approval or after a failed commit`);
        enter(w, 'committing', now());
        return ok(view(w), 202);
      }),
    },
    {
      method: 'GET', path: '/api/v1/knowledge-maintenance/ontology/export',
      handle: (req) => {
        const user = userForToken((req.headers.authorization || '').replace(/^Bearer\s+/i, ''));
        if (!user) return err(401, 'UNAUTHENTICATED', 'Sign in to continue.');
        if (!user.roles.some((r) => TECHNICAL.includes(r))) return err(403, 'FORBIDDEN', 'This account is not a Technical User.');
        const format = req.query?.get?.('format') || 'ttl';
        if (format !== 'ttl') return err(422, 'VALIDATION_ERROR', 'Only format=ttl is supported');
        return ok(SAMPLE_TTL, 200, { 'Content-Type': 'text/turtle; charset=utf-8' });
      },
    },
  ];
}
