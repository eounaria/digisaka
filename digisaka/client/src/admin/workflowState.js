// Plain words and a tone for the Knowledge Maintenance workflow states.
const STATES = {
  document_submitted: ['Submitted', 'neutral'],
  extracting: ['Extracting facts', 'neutral'],
  restoring_verifying: ['Restoring and checking facts', 'neutral'],
  awaiting_extraction_review: ['Waiting for extraction review', 'warn'],
  canonicalizing: ['Matching entities', 'neutral'],
  validating: ['Validating against the ontology', 'neutral'],
  correcting_revalidating: ['Correcting and re-validating', 'neutral'],
  awaiting_final_approval: ['Waiting for final approval', 'warn'],
  committing: ['Committing', 'neutral'],
  commit_failed: ['Commit failed', 'bad'],
  completed: ['Completed', 'good'],
  cancelled: ['Cancelled', 'neutral'],
  failed: ['Failed', 'bad'],
};
export const stateLabel = (s) => STATES[s]?.[0] ?? s;
export const stateTone = (s) => STATES[s]?.[1] ?? 'neutral';
