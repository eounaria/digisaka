import { ref } from 'vue';

/** Build a query string, leaving out empty values. */
export const qs = (o) => {
  const p = new URLSearchParams();
  for (const [k, v] of Object.entries(o)) if (v !== undefined && v !== null && v !== '') p.set(k, v);
  return p.toString();
};

// The database stores UTC as "YYYY-MM-DD HH:MM:SS".
export const toDate = (s) => (s ? new Date(String(s).replace(' ', 'T') + 'Z') : null);
export const fmtDate = (s) => (s ? toDate(s).toLocaleDateString('en-CA') : '—');
export const fmtDateTime = (s) => (s ? toDate(s).toLocaleString('en-CA', { hour12: false, dateStyle: 'short', timeStyle: 'short' }).replace(',', '') : '—');
export const fmtTime = (s) => (s ? toDate(s).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '—');
export function ago(s) {
  const m = Math.max(0, Math.round((Date.now() - toDate(s)) / 60000));
  if (m < 1) return 'now';
  if (m < 60) return `${m}m`;
  if (m < 1440) return `${Math.round(m / 60)}h`;
  return `${Math.round(m / 1440)}d`;
}
export const bytes = (n) => (n < 1024 ? `${n} B` : n < 1048576 ? `${Math.round(n / 1024)} KB` : `${(n / 1048576).toFixed(1)} MB`);
export const confidence = (c) => (c == null ? '—' : `${(c * 100).toFixed(1)}%`);
export const compact = (n) => new Intl.NumberFormat('en', { notation: 'compact', maximumFractionDigits: 1 }).format(n);

export const STAGE = { extracted: ['Extracted', 'neutral'], corrected: ['Corrected', 'warn'], confirmed: ['Confirmed', 'good'], rejected: ['Rejected', 'bad'] };
export const DOC_TONE = { Queued: 'neutral', Extracted: 'good', 'Needs review': 'warn', Confirmed: 'good' };
export const ACTION = {
  UPLOAD: 'Uploaded', EXTRACT: 'Extraction completed', CORRECT: 'Corrected', CONFIRM: 'Confirmed', UNCONFIRM: 'Un-confirmed', REJECT: 'Rejected', RESTORE: 'Restored',
  CREATE: 'Created', UPDATE: 'Updated', DELETE: 'Deleted', MOVE: 'Moved', IMPORT: 'Imported',
};
export const ACTION_ICON = { EXTRACT: '↻', CONFIRM: '✓', UPLOAD: '↑', CORRECT: '✎', DELETE: '✕', REJECT: '✕', MOVE: '↔' };

/** Wraps an async loader so only the latest call's result is used and errors surface as text. */
export function useLoader(fn) {
  const loading = ref(true), error = ref('');
  let seq = 0;
  async function run(...args) {
    const mine = ++seq; loading.value = true; error.value = '';
    try { const r = await fn(...args); if (mine === seq) return r; }
    catch (e) { if (mine === seq) error.value = e.message; }
    finally { if (mine === seq) loading.value = false; }
    return undefined;
  }
  return { loading, error, run };
}
