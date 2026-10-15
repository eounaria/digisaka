import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { setTokenProvider } from '../api.js';
import { useWorkflowsStore } from './workflows.js';

const json = (status, body) => ({ status, ok: status < 400, json: async () => body });
const ID = '3fb2718a-406f-4c36-bfac-6dcae19c7b70';
const created = { workflow_id: ID, workflow_type: 'maintenance', state: 'document_submitted', created_at: '2026-10-16T06:00:00Z' };
let fetchMock, mem;

beforeEach(() => {
  setActivePinia(createPinia());
  setTokenProvider(() => 'TOK');
  fetchMock = vi.fn();
  vi.stubGlobal('fetch', fetchMock);
  mem = {};
  vi.stubGlobal('localStorage', { getItem: (k) => mem[k] ?? null, setItem: (k, v) => { mem[k] = String(v); }, removeItem: (k) => { delete mem[k]; } });
});
afterEach(() => { vi.unstubAllGlobals(); setTokenProvider(() => null); });

describe('submitting text', () => {
  it('posts the document, adds the workflow to the list and keeps it for this user', async () => {
    fetchMock.mockResolvedValue(json(202, created));
    const s = useWorkflowsStore(); s.load('a@x.org');
    const w = await s.submitText('Paviso report', 'Some text.');
    expect(fetchMock.mock.calls[0][0]).toBe('/api/v1/knowledge-maintenance/workflows');
    expect(JSON.parse(fetchMock.mock.calls[0][1].body)).toEqual({ document: { title: 'Paviso report', content: 'Some text.' } });
    expect(w.id).toBe(ID);
    expect(s.items).toEqual([{ id: ID, title: 'Paviso report', state: 'document_submitted', createdAt: '2026-10-16T06:00:00Z' }]);
    const again = useWorkflowsStore(); again.load('a@x.org');
    expect(again.items).toHaveLength(1);
    again.load('b@x.org');
    expect(again.items).toHaveLength(0);
  });
  it('shows the API message and adds nothing when the document is refused', async () => {
    fetchMock.mockResolvedValue(json(422, { error: { code: 'VALIDATION_ERROR', message: 'Document has no text', details: {} } }));
    const s = useWorkflowsStore(); s.load('a@x.org');
    await s.submitText('t', '   ');
    expect(s.error).toBe('Document has no text');
    expect(s.items).toEqual([]);
    expect(s.busy).toBe(false);
  });
});

describe('submitting a PDF', () => {
  it('posts a multipart form with the file and the title', async () => {
    fetchMock.mockResolvedValue(json(202, created));
    const s = useWorkflowsStore(); s.load('a@x.org');
    const file = new Blob(['%PDF'], { type: 'application/pdf' });
    await s.submitFile(file, 'Terminal report');
    const body = fetchMock.mock.calls[0][1].body;
    expect(body).toBeInstanceOf(FormData);
    expect(body.get('title')).toBe('Terminal report');
    expect(body.get('file')).toBeInstanceOf(Blob);
    expect(s.items[0].title).toBe('Terminal report');
  });
});

describe('opening by id', () => {
  it('adds a workflow that was submitted elsewhere, once', async () => {
    fetchMock.mockResolvedValue(json(200, { ...created, state: 'awaiting_extraction_review' }));
    const s = useWorkflowsStore(); s.load('a@x.org');
    await s.open(` ${ID} `);
    await s.open(ID);
    expect(fetchMock.mock.calls[0][0]).toBe(`/api/v1/knowledge-maintenance/workflows/${ID}`);
    expect(s.items).toHaveLength(1);
    expect(s.items[0]).toMatchObject({ id: ID, state: 'awaiting_extraction_review' });
  });
  it('shows the API message for an unknown id and adds nothing', async () => {
    fetchMock.mockResolvedValue(json(404, { error: { code: 'NOT_FOUND', message: "Workflow 'x' not found", details: {} } }));
    const s = useWorkflowsStore(); s.load('a@x.org');
    expect(await s.open('x')).toBeNull();
    expect(s.error).toBe("Workflow 'x' not found");
    expect(s.items).toEqual([]);
  });
});

describe('the list', () => {
  it('forgets a workflow from this browser without calling the API', async () => {
    fetchMock.mockResolvedValue(json(202, created));
    const s = useWorkflowsStore(); s.load('a@x.org');
    await s.submitText('t', 'x');
    fetchMock.mockClear();
    s.forget(ID);
    expect(s.items).toEqual([]);
    expect(fetchMock).not.toHaveBeenCalled();
  });
  it('works when storage is unavailable', async () => {
    vi.stubGlobal('localStorage', { getItem() { throw new Error('no'); }, setItem() { throw new Error('no'); } });
    fetchMock.mockResolvedValue(json(202, created));
    const s = useWorkflowsStore(); s.load('a@x.org');
    await s.submitText('t', 'x');
    expect(s.items).toHaveLength(1);
  });
});
