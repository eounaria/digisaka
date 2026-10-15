// The app's "today". The stub scheduler data ends at 2026-W24, so the app treats a Wednesday of that
// week as the current date instead of the real clock. Set `null` to use the real date again.
const DEMO_TODAY = new Date(2026, 5, 10);

export const today = () => (DEMO_TODAY ? new Date(DEMO_TODAY) : new Date());
export const todayIso = () => toIso(today());

export function toIso(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}
// A YYYY-MM-DD string as a local date (not UTC, so the day never shifts).
export function fromIso(s) {
  const [y, m, d] = s.split('-').map(Number);
  return new Date(y, m - 1, d);
}
