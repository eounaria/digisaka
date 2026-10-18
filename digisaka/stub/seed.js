// Fixed seed for the stub scheduler. "Today" is 2026-W24, matching the app. Each line is a named
// scenario; the data decides what happens, nothing is switched. Weekly values are null where the
// real feed would have a gap. `evidence` is the rules' reading of a cycle, null for a cycle with no trend stage.
const wk = (week, yls, yli, rainfall_mm) => ({ week, yls, yli, rainfall_mm });

const seed = () => ({
  // Filled while the stub runs: scans (diagnoses), closed-week cycles (runs) and id counters.
  diagnoses: {}, uploads: {}, runs: {}, nextId: 1,
  // proposal_id -> {decision, note?}. L02's proposal was approved before it was applied.
  decisions: { 'p-L02-23': { decision: 'approved' } },
  lines: {
    // Nothing recorded yet.
    L01: { weeks: [], cycles: [], proposals: [], applications: [], leaves: 0 },
    // An applied proposal.
    L02: {
      weeks: [wk('2026-W20', 9, 5, 10), wk('2026-W21', 8, 5, 14), wk('2026-W22', 7, 4, 20), wk('2026-W23', 6, 4, 28)],
      cycles: [{
        cycle_id: 'c-L02-23', week: '2026-W23', status: 'done', outcome: 'proposal', outcome_reason: null,
        evidence: {
          disease: { worsening_direction: 'lower', consecutive_weeks: 2, compared_weeks: ['2026-W21', '2026-W22', '2026-W23'], worsening: true },
          rainfall: { window_weeks: 2, min_total_mm: 0, recent_weeks: ['2026-W22', '2026-W23'], previous_weeks: ['2026-W20', '2026-W21'], recent_total_mm: 48, previous_total_mm: 24, favourable: true },
        },
      }],
      proposals: [{ proposal_id: 'p-L02-23', cycle_id: 'c-L02-23', option_id: 'opt-protectant', status: 'applied', week: '2026-W23', window_start: '2026-06-03', window_end: '2026-06-05' }],
      applications: [{ proposal_id: 'p-L02-23', applied_on: '2026-06-04' }],
      leaves: 12,
    },
    // A proposal waiting for a decision.
    L03: {
      weeks: [wk('2026-W20', 9, 5, 15), wk('2026-W21', 8, 5, 20), wk('2026-W22', 7, 4, 32), wk('2026-W23', 6, 4, 40), wk('2026-W24', 5, 3, 44)],
      cycles: [{
        cycle_id: 'c-L03-24', week: '2026-W24', status: 'done', outcome: 'proposal', outcome_reason: null,
        evidence: {
          disease: { worsening_direction: 'lower', consecutive_weeks: 2, compared_weeks: ['2026-W22', '2026-W23', '2026-W24'], worsening: true },
          rainfall: { window_weeks: 2, min_total_mm: 0, recent_weeks: ['2026-W23', '2026-W24'], previous_weeks: ['2026-W21', '2026-W22'], recent_total_mm: 84, previous_total_mm: 52, favourable: true },
        },
      }],
      proposals: [{ proposal_id: 'p-L03-24', cycle_id: 'c-L03-24', option_id: 'opt-protectant', status: 'proposed', week: '2026-W24', window_start: '2026-06-10', window_end: '2026-06-12' }],
      applications: [],
      leaves: 15,
    },
    // Ready to scan this week (the default demo line); last week had a gap in the YLI reading.
    L04: {
      weeks: [wk('2026-W20', 9, 5, 18), wk('2026-W21', 9, 6, 22), wk('2026-W22', 8, null, 30), wk('2026-W23', 8, 5, 26), wk('2026-W24', null, null, 12)],
      cycles: [{
        cycle_id: 'c-L04-23', week: '2026-W23', status: 'done', outcome: 'continue_monitoring', outcome_reason: 'disease_not_worsening',
        evidence: {
          disease: { worsening_direction: 'lower', consecutive_weeks: 2, compared_weeks: ['2026-W21', '2026-W22', '2026-W23'], worsening: false },
          rainfall: { window_weeks: 2, min_total_mm: 0, recent_weeks: ['2026-W22', '2026-W23'], previous_weeks: ['2026-W20', '2026-W21'], recent_total_mm: 56, previous_total_mm: 40, favourable: true },
        },
      }],
      proposals: [], applications: [], leaves: 9,
    },
    // The rules could not decide: human review, and no evidence for the cycle.
    L05: {
      weeks: [wk('2026-W21', 8, 4, 12), wk('2026-W22', null, null, 18), wk('2026-W23', 6, 3, null), wk('2026-W24', 5, 3, null)],
      cycles: [{ cycle_id: 'c-L05-24', week: '2026-W24', status: 'done', outcome: 'human_review_required', outcome_reason: 'missing_feed_value', evidence: null }],
      proposals: [{
        proposal_id: 'p-L05-24', cycle_id: 'c-L05-24', option_id: 'opt-protectant', status: 'proposed', week: '2026-W24', window_start: '2026-06-15', window_end: '2026-06-17',
        reason: 'The scheduler could not check this week against the rules, so a person has to decide.',
        constraints: ['Weather and scan data for 2026-W22 and 2026-W23 is missing.', 'Check the field before treating.'],
      }],
      applications: [], leaves: 7,
    },
    // Monitoring so far; closing its next week fails (ticket 03).
    L06: {
      weeks: [wk('2026-W21', 9, 6, 20), wk('2026-W22', 9, 6, 22), wk('2026-W23', 9, 5, 25)],
      cycles: [{ cycle_id: 'c-L06-23', week: '2026-W23', status: 'done', outcome: 'continue_monitoring', outcome_reason: 'disease_not_worsening', evidence: null }],
      proposals: [], applications: [], leaves: 6,
    },
  },
});

// Holds the live copy of the seed; reset swaps in a fresh one.
export function createSeedStore() {
  const store = { data: seed(), reset() { store.data = seed(); } };
  return store;
}
