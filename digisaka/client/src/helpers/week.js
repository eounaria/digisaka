// ISO 8601 week keys ("YYYY-Www") as the scheduler expects them.
const pad = (n) => String(n).padStart(2, '0');

function isoParts(year0, month, dayOfMonth) {
  const d = new Date(Date.UTC(year0, month, dayOfMonth));
  const day = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - day); // Thursday of this ISO week decides the year
  const year = d.getUTCFullYear();
  const week = Math.ceil(((d - Date.UTC(year, 0, 1)) / 86400000 + 1) / 7);
  return { year, week };
}

const weeksInYear = (year) => isoParts(year, 11, 28).week; // 28 Dec is always in the last week

// Uses the date's local calendar day, so `new Date()` gives the week the user is in.
export function isoWeekOf(date) {
  const { year, week } = isoParts(date.getFullYear(), date.getMonth(), date.getDate());
  return `${year}-W${pad(week)}`;
}

export function isValidWeek(value) {
  const m = /^(\d{4})-W(\d{2})$/.exec(value ?? '');
  if (!m) return false;
  const week = Number(m[2]);
  return week >= 1 && week <= weeksInYear(Number(m[1]));
}

export function nextWeek(key) {
  const [year, week] = parse(key);
  return week < weeksInYear(year) ? `${year}-W${pad(week + 1)}` : `${year + 1}-W01`;
}

export function previousWeek(key) {
  const [year, week] = parse(key);
  return week > 1 ? `${year}-W${pad(week - 1)}` : `${year - 1}-W${pad(weeksInYear(year - 1))}`;
}

function parse(key) {
  if (!isValidWeek(key)) throw new RangeError(`Invalid week: ${key}`);
  return [Number(key.slice(0, 4)), Number(key.slice(6))];
}

// The Monday of an ISO week, as YYYY-MM-DD (UTC arithmetic, so no timezone shift).
export function weekStart(key) {
  const [year, week] = parse(key);
  const jan4 = new Date(Date.UTC(year, 0, 4));
  const monday = new Date(jan4.getTime() + ((week - 1) * 7 - ((jan4.getUTCDay() || 7) - 1)) * 86400000);
  return monday.toISOString().slice(0, 10);
}

// The Sunday of an ISO week, as YYYY-MM-DD.
export function weekEnd(key) {
  const d = new Date(weekStart(key) + 'T00:00:00Z');
  d.setUTCDate(d.getUTCDate() + 6);
  return d.toISOString().slice(0, 10);
}
