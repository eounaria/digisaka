// Drives the real lines, line-history and evidence stores (and the shared api.js) against the in-process stub.
import { describe, it, expect } from 'vitest';
import { useStub } from './harness.js';
import { useAuthStore } from '../stores/auth.js';
import { useLinesStore, dashboardSummary, proposalRows } from '../stores/lines.js';
import { useLineHistoryStore } from '../stores/lineHistory.js';
import { useEvidenceStore } from '../stores/evidence.js';
import { diseaseCaption, rainfallCaption } from '../helpers/evidence.js';

const ctx = useStub();

describe('lines store against the stub', () => {
  it('loads every seed line for the dashboard and schedule list', async () => {
    const s = useLinesStore();
    await s.load();
    expect(s.error).toBe('');
    expect(s.statuses.map((l) => l.line_id)).toEqual(['L01', 'L02', 'L03', 'L04', 'L05', 'L06']);
    expect(s.withProposals.map((l) => l.line_id)).toEqual(['L02', 'L03', 'L05']);
    expect(dashboardSummary(s.statuses)).toMatchObject({ lines: 6, awaitingDecision: 2, humanReview: 1 });
    expect(proposalRows(s.byId('L02'))[0].appliedOn).toBe('2026-06-04');
  });
  it('shows the Practitioner message when a Technical User is signed in', async () => {
    const auth = useAuthStore();
    await auth.signIn('admin@digisaka.test', 'pw');
    const s = useLinesStore();
    await s.load();
    expect(s.error).toBe('This account is not a Practitioner.');
  });
});

describe('line history store against the stub', () => {
  it('shows three weeks including a gap', async () => {
    const s = useLineHistoryStore();
    await s.load('L04', '2026-W24');
    expect(s.phase).toBe('ready');
    expect(s.weeks).toHaveLength(3);
    expect(s.weeks.some((w) => w.yli === null)).toBe(true);
  });
  it('reports an unknown line in words', async () => {
    const s = useLineHistoryStore();
    await s.load('L99', '2026-W24');
    expect(s).toMatchObject({ phase: 'error', error: 'That line does not exist.' });
  });
});

describe('evidence store against the stub', () => {
  it('loads evidence the captions can read', async () => {
    const s = useEvidenceStore();
    await s.load('c-L03-24');
    expect(s.phase).toBe('ready');
    expect(diseaseCaption(s.evidence)).toBe('YLS fell two weeks in a row (7 to 6 to 5).');
    expect(rainfallCaption(s.evidence)).toBe('Rain over the last 2 weeks: 84 mm, up from 52 mm.');
  });
  it('a cycle without trend evidence is the none state', async () => {
    const s = useEvidenceStore();
    await s.load('c-L05-24');
    expect(s).toMatchObject({ phase: 'none', error: '' });
  });
});
