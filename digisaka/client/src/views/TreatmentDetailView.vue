<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { api } from '../api.js';
import PageHeader from '../components/PageHeader.vue';

const route = useRoute(), router = useRouter();
const stage = Number(route.params.stage);

const STAGE_META = {
  1: { emoji: '🟡', tag: 'Suspected Stage 1', group: 'Early Treatment Consideration' },
  2: { emoji: '🟠', tag: 'Suspected Stage 2', group: 'Developing Treatment Consideration' },
  3: { emoji: '🟠', tag: 'Suspected Stage 3', group: 'Treatment Consideration' },
  4: { emoji: '🔴', tag: 'Suspected Stage 4 (Advanced)', group: 'Priority Treatment Consideration' },
};
const meta = STAGE_META[stage] ?? STAGE_META[1];

const schedules = ref([]), loading = ref(true), error = ref(''), saving = ref(false);
const bulk = computed(() => schedules.value.find((s) => s.bulkId === route.params.bulkId));
const group = computed(() => bulk.value?.groups.find((g) => g.stage === stage));

const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const YEAR = 2026;
const stepDate = (s) => new Date(s.year ?? YEAR, MONTHS.indexOf(s.month), s.day);
const fmtDate = (s) => `${s.month} ${s.day}, ${s.year ?? YEAR}`;

// The prototype's treatment dates are fixed to August 2026, so "today" is fixed to the prototype's
// demo day too. Swap this for `new Date()` once schedules are generated from the real scan date.
const TODAY = new Date(2026, 7, 17);
const DAY = 86400000;
const daysFromToday = (s) => Math.round((stepDate(s) - TODAY) / DAY);
const isDone = (s) => s.status === 'Applied';
const isMissed = (s) => !isDone(s) && daysFromToday(s) < 0;

// Each step gets a look so the calendar, the timeline and the "up next" card agree.
const KIND = {
  Treatment: { color: 'gold', icon: '🔥', tag: 'TREATMENT', proof: true },
  'Follow-up': { color: 'blue', icon: '🔵', tag: 'FOLLOW-UP', proof: true },
  'Re-assessment': { color: 'plum', icon: '🔍', tag: 'REASSESS', proof: false },
};
const kind = (s) => KIND[s.label] ?? { color: 'gold', icon: '🔥', tag: s.label.toUpperCase(), proof: false };
const stateOf = (s) => (isDone(s) ? 'done' : isMissed(s) ? 'missed' : 'upcoming');

const steps = computed(() => [...(group.value?.schedule ?? [])].sort((a, b) => stepDate(a) - stepDate(b)));
const doneCount = computed(() => steps.value.filter(isDone).length);
const nextStep = computed(() => steps.value.find((s) => !isDone(s)));
const overdueText = (s) => {
  const d = daysFromToday(s);
  if (d < 0) return `${-d} DAY${d === -1 ? '' : 'S'} OVERDUE`;
  return d === 0 ? 'DUE TODAY' : `IN ${d} DAY${d === 1 ? '' : 'S'}`;
};

async function load() {
  loading.value = true; error.value = '';
  try { schedules.value = (await api.get('/api/schedules')).schedules; }
  catch (e) { error.value = e.message; }
  finally { loading.value = false; }
}
onMounted(load);

async function saveStep(step, patch) {
  if (!bulk.value || saving.value) return false;
  saving.value = true; error.value = '';
  const groups = bulk.value.groups.map((g) => g.stage !== stage ? g : { ...g, schedule: g.schedule.map((s) => s.label === step.label ? { ...s, ...patch } : s) });
  try {
    await api.put(`/api/schedules/${encodeURIComponent(bulk.value.bulkId)}`, { groups });
    bulk.value.groups = groups;
    return true;
  } catch (e) { error.value = e.message; return false; }
  finally { saving.value = false; }
}

// Checking a treatment step needs a photo first (like the prototype); unchecking is direct.
const proof = ref(null);                       // { step, file, preview }
const outcome = ref({ open: false, step: null, picked: '' });
function onCheck(step, ev) {
  const checked = ev.target.checked;
  if (checked && kind(step).proof) { ev.target.checked = false; proof.value = { step, file: null, preview: '' }; return; }
  markDone(step, checked);
}
async function markDone(step, checked, extra = {}) {
  const ok = await saveStep(step, { status: checked ? 'Applied' : 'Confirmed', ...extra });
  // The last step closes the cycle: ask what actually happened to the leaf.
  if (ok && checked && step.label === 'Re-assessment') outcome.value = { open: true, step, picked: '' };
}
function pickProof(ev) {
  const f = ev.target.files?.[0];
  if (!f || !proof.value) return;
  const r = new FileReader();
  r.onload = (e) => { if (proof.value) proof.value = { ...proof.value, file: f, preview: e.target.result }; };
  r.readAsDataURL(f);
}
async function confirmProof() {
  const { step, file } = proof.value;
  await markDone(step, true, { proof: { name: file.name, at: new Date().toISOString() } });
  proof.value = null;
}
const OUTCOMES = {
  improved: { icon: '✅', title: 'Cycle Complete', desc: "Nice work — the plant is looking healthy. We'll close this cycle and keep it on routine monitoring.", banner: '✅ Cycle Complete — Healthy', cls: 'ok' },
  same: { icon: '⚠️', title: 'No Improvement Yet', desc: 'No change after the full cycle. A follow-up scan will help confirm whether a new treatment approach or specialist review is needed.', banner: '⚠️ Escalation Needed — Rescan Recommended', cls: 'warn' },
  worse: { icon: '⚠️', title: 'Symptoms Persisting', desc: "The full cycle didn't resolve it. We recommend a fresh scan to confirm current stage, and flagging this for an agricultural specialist.", banner: '⚠️ Escalation Needed — Rescan Recommended', cls: 'warn' },
};
async function submitOutcome(result) {
  outcome.value.picked = result;
  await saveStep(outcome.value.step, { outcome: result });
}
const closeOutcome = () => { outcome.value = { open: false, step: null, picked: '' }; };
const rescan = () => { closeOutcome(); router.push('/scan'); };
const finalOutcome = computed(() => OUTCOMES[steps.value.find((s) => s.label === 'Re-assessment')?.outcome]);

// Everything is laid out month by month: one calendar and one timeline section per month.
const months = computed(() => {
  const order = [];
  const by = new Map();
  const logged = steps.value.length ? { label: 'Suspected Disease Logged', desc: `${meta.tag.replace('Suspected', 'Suspected Black Sigatoka —')}`, ...shiftDays(steps.value[0], -5), logged: true, status: 'Applied' } : null;
  [...(logged ? [logged] : []), ...steps.value].forEach((s) => {
    const key = `${s.year ?? YEAR}-${s.month}`;
    if (!by.has(key)) { by.set(key, { month: s.month, year: s.year ?? YEAR, steps: [] }); order.push(key); }
    by.get(key).steps.push(s);
  });
  return order.map((k) => {
    const m = by.get(k);
    const first = new Date(m.year, MONTHS.indexOf(m.month), 1);
    const days = new Date(m.year, MONTHS.indexOf(m.month) + 1, 0).getDate();
    const cells = [...Array((first.getDay() + 6) % 7).fill(null), ...Array.from({ length: days }, (_, i) => i + 1)];
    const todayHere = TODAY.getMonth() === MONTHS.indexOf(m.month) && TODAY.getFullYear() === m.year ? TODAY.getDate() : null;
    return { ...m, cells, todayHere, byDay: Object.fromEntries(m.steps.filter((s) => !s.logged).map((s) => [s.day, s])), total: m.steps.filter((s) => !s.logged).length, done: m.steps.filter((s) => !s.logged && isDone(s)).length };
  });
});

function shiftDays(step, delta) {
  const d = new Date(stepDate(step).getTime() + delta * DAY);
  return { month: MONTHS[d.getMonth()], day: d.getDate(), year: d.getFullYear() };
}
const shortDate = (s) => `${s.month.slice(0, 3)} ${s.day}`;
</script>


<template>
  <div class="page narrow">
    <PageHeader :title="meta.tag" :subtitle="bulk ? `${bulk.plant} · ${bulk.bulkId}` : ''" />
    <p v-if="error" class="error">{{ error }}</p>
    <p v-if="!loading && !group && !error" class="empty">This stage's schedule couldn't be found.</p>
    <template v-else-if="group">
      <div class="banner" :class="finalOutcome?.cls"><span class="tick">✓</span>{{ finalOutcome ? finalOutcome.banner : 'Schedule Generated' }}</div>

      <section v-for="m in months" :key="'cal' + m.month + m.year" class="cal-card">
        <header><h4>{{ m.month }} {{ m.year }}</h4><span class="plant">{{ bulk?.plant.replace('Banana ', '') }}</span></header>
        <div class="grid">
          <span v-for="d in ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']" :key="d" class="dow">{{ d }}</span>
          <template v-for="(c, i) in m.cells" :key="i">
            <span v-if="!c" />
            <span v-else-if="m.byDay[c]" class="cell ev" :class="[stateOf(m.byDay[c]), kind(m.byDay[c]).color, { today: c === m.todayHere }]">
              <em class="badge">{{ stateOf(m.byDay[c]) === 'missed' ? 'MISSED' : stateOf(m.byDay[c]) === 'done' ? 'DONE' : 'UPCOMING' }}</em>
              <b>{{ c }}</b>
              <i>{{ stateOf(m.byDay[c]) === 'done' ? '✓' : kind(m.byDay[c]).icon }}</i>
              <small>{{ stateOf(m.byDay[c]) === 'missed' ? 'MISSED' : kind(m.byDay[c]).tag }}</small>
            </span>
            <span v-else class="cell" :class="{ today: c === m.todayHere }">{{ c }}</span>
          </template>
        </div>
      </section>

      <template v-if="nextStep">
        <div class="eyebrow">Up next</div>
        <div class="next-card" :class="stateOf(nextStep)">
          <span class="ico">{{ kind(nextStep).icon }}</span>
          <div class="txt">
            <small class="up">Up next</small>
            <h3>{{ nextStep.label }}{{ isMissed(nextStep) ? ' — Missed' : '' }}</h3>
            <p class="when">Scheduled on {{ fmtDate(nextStep) }}</p>
            <span class="pill" :class="{ late: isMissed(nextStep) }"><span v-if="isMissed(nextStep)">🔥</span>{{ overdueText(nextStep) }}</span>
            <p class="note">{{ isMissed(nextStep) ? `This was scheduled for ${nextStep.month} ${nextStep.day} and hasn't been marked done yet. Please complete it as soon as possible.` : nextStep.desc }}</p>
          </div>
        </div>
      </template>

      <section v-for="m in months" :key="'tl' + m.month + m.year" class="timeline">
        <header><h3>{{ m.month }} {{ m.year }} — Detailed Timeline</h3><span class="count">{{ m.done }} / {{ m.total }} done</span></header>
        <ol>
          <li v-for="s in m.steps" :key="s.label + s.day" :class="[s.logged ? 'logged' : stateOf(s), s.logged ? 'green' : kind(s).color]">
            <span class="node"><template v-if="s.logged || isDone(s)">✓</template></span>
            <div class="date">{{ shortDate(s) }}</div>
            <div class="card">
              <h5>{{ s.label }}</h5>
              <p v-if="s.logged" class="desc">{{ s.desc }}</p>
              <template v-else>
                <p v-if="!kind(s).proof" class="desc">{{ s.desc }}</p>
                <label class="check"><input type="checkbox" :checked="isDone(s)" :disabled="saving" @change="onCheck(s, $event)" />Mark as done</label>
                <p v-if="kind(s).proof" class="proof" :class="{ ok: s.proof }">{{ s.proof ? `📷 Photo attached — ${s.proof.name}` : '📷 Photo proof required' }}</p>
              </template>
            </div>
          </li>
        </ol>
      </section>
    </template>
    <p class="disclaimer">AI-assisted scheduling should be verified by an agricultural specialist before treatment decisions.</p>

    <div v-if="proof" class="veil" @mousedown.self="proof = null">
      <div class="sheet" role="dialog" aria-modal="true" aria-label="Proof of treatment required">
        <h4>📸 Proof of Treatment Required</h4>
        <p class="sub">Upload a photo showing the {{ proof.step.label }} was applied before marking this step as done.</p>
        <label class="upload" :class="{ has: proof.preview }">
          <template v-if="!proof.preview"><span class="big">📷</span><b>Tap to upload a photo</b><small>JPG or PNG</small></template>
          <template v-else><img :src="proof.preview" alt="Selected proof" /><small>{{ proof.file.name }} · tap to change</small></template>
          <input type="file" accept="image/*" hidden @change="pickProof" />
        </label>
        <p class="warnline">⚠️ This step can't be checked off without a photo.</p>
        <div class="btns"><button class="ghost" type="button" @click="proof = null">Cancel</button><button type="button" :disabled="!proof.file || saving" @click="confirmProof">Confirm &amp; Mark Done</button></div>
      </div>
    </div>

    <div v-if="outcome.open" class="veil">
      <div class="sheet" role="dialog" aria-modal="true">
        <template v-if="!outcome.picked">
          <h4>How does the leaf look now?</h4>
          <p class="sub">You've completed the full treatment cycle. Let us know the result so we can update the plan.</p>
          <button class="opt" type="button" @click="submitOutcome('improved')"><span>✅</span>Symptoms improved / gone</button>
          <button class="opt" type="button" @click="submitOutcome('same')"><span>🟡</span>No visible change</button>
          <button class="opt" type="button" @click="submitOutcome('worse')"><span>⚠️</span>Symptoms are the same or worse</button>
        </template>
        <template v-else>
          <div class="result"><div class="ric">{{ OUTCOMES[outcome.picked].icon }}</div><h4>{{ OUTCOMES[outcome.picked].title }}</h4><p class="sub">{{ OUTCOMES[outcome.picked].desc }}</p></div>
          <div class="btns"><button type="button" @click="outcome.picked === 'improved' ? closeOutcome() : rescan()">{{ outcome.picked === 'improved' ? 'Done' : 'Rescan Leaf' }}</button></div>
        </template>
      </div>
    </div>
  </div>
</template>

<style scoped>
.narrow { max-width: 760px; }
.error { color: var(--danger); font-weight: 700; }
.empty { padding: 30px; text-align: center; color: var(--ink-soft); border: 1.5px dashed var(--line); border-radius: var(--radius-md); background: var(--card); }
.banner { display: flex; align-items: center; gap: 10px; padding: 12px 18px; margin-bottom: 14px; border-radius: 999px; background: #D5E9DB; color: var(--forest); font: 800 15px var(--font-display); }
.banner .tick { display: grid; place-items: center; width: 22px; height: 22px; border-radius: 6px; background: var(--forest); color: #fff; font-size: 14px; }
.cal-card { padding: 18px; margin-bottom: 18px; border-radius: 20px; background: var(--card); box-shadow: var(--shadow); }
.cal-card header { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 12px; }
.cal-card h4 { font: 800 20px var(--font-display); color: var(--forest); }
.plant { font: 700 12px var(--font-body); color: var(--teal); }
.grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 6px; text-align: center; }
.dow { font: 800 12px var(--font-body); color: var(--ink-soft); padding-bottom: 6px; }
.cell { position: relative; display: grid; place-items: center; min-height: 40px; border-radius: 12px; font: 700 14px var(--font-body); color: var(--ink); border: 2px solid transparent; }
.cell.today { border-color: var(--forest); background: var(--tint); font-weight: 800; color: var(--forest); }
.cell.ev { min-height: 74px; align-content: center; gap: 1px; padding: 8px 2px 4px; border: 2px solid; transition: transform .18s var(--ease, ease); }
.cell.ev:hover { transform: translateY(-2px); }
.cell.ev b { font: 800 16px var(--font-display); }
.cell.ev i { font-style: normal; font-size: 18px; line-height: 1; }
.cell.ev small { font: 800 9.5px var(--font-body); letter-spacing: .03em; }
.badge { position: absolute; top: -9px; right: -4px; padding: 1px 6px; border-radius: 6px; font: 800 9px var(--font-body); font-style: normal; background: #F4B83A; color: #6B4A00; }
.cell.ev.upcoming { background: #E3F2F0; border-color: #A8D6D0; color: #1F7C74; }
.cell.ev.missed { background: #FBE4E2; border-color: #F0A9A3; color: #C4372B; }
.cell.ev.missed .badge { background: #D8352A; color: #fff; }
.cell.ev.done { background: #E4F3E8; border-color: #9BD0AB; color: var(--forest); }
.cell.ev.done .badge { background: #2E8B57; color: #fff; }
.eyebrow { margin: 22px 0 10px; font: 800 13px 'JetBrains Mono', ui-monospace, monospace; letter-spacing: .14em; text-transform: uppercase; color: var(--ink-soft); }
.next-card { display: flex; gap: 16px; padding: 18px; margin-bottom: 22px; border-radius: 22px; background: var(--card); border: 1.5px solid #F0A9A3; box-shadow: 0 8px 28px rgba(216, 53, 42, .14); }
.next-card.upcoming { border-color: #A8D6D0; box-shadow: 0 8px 28px rgba(31, 124, 116, .12); }
.next-card .ico { display: grid; place-items: center; flex: none; width: 52px; height: 52px; border-radius: 16px; background: #FBE4E2; font-size: 26px; }
.next-card.upcoming .ico { background: #E3F2F0; }
.next-card .up { display: block; font: 700 12px 'JetBrains Mono', ui-monospace, monospace; letter-spacing: .1em; text-transform: uppercase; color: var(--ink-soft); }
.next-card h3 { font: 800 22px var(--font-display); margin: 2px 0; }
.when { color: var(--ink-soft); font-size: 15px; }
.pill { display: inline-flex; gap: 6px; margin: 10px 0; padding: 6px 14px; border-radius: 999px; background: #E3F2F0; color: #1F7C74; font: 800 13px var(--font-body); letter-spacing: .02em; }
.pill.late { background: #FBE0DD; color: #C4372B; }
.note { color: var(--ink-soft); font-size: 14px; }
.timeline { margin-bottom: 20px; }
.timeline header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
.timeline h3 { font: 800 22px var(--font-display); color: var(--forest); }
.count { padding: 6px 14px; border-radius: 999px; background: #DDEFEA; color: var(--teal); font: 800 13px var(--font-body); }
.timeline ol { list-style: none; margin: 0; padding: 0; position: relative; }
.timeline ol::before { content: ''; position: absolute; left: 13px; top: 14px; bottom: 14px; width: 2px; background: #B9D9C4; }
.timeline li { position: relative; padding: 0 0 18px 46px; }
.node { position: absolute; left: 0; top: 0; display: grid; place-items: center; width: 28px; height: 28px; border-radius: 50%; border: 2px solid; background: #fff; font-size: 14px; font-weight: 800; }
.timeline .date { font: 700 15px var(--font-body); color: var(--ink-soft); margin-bottom: 6px; }
.timeline .card { padding: 16px 18px; border-radius: 18px; background: var(--card); box-shadow: var(--shadow); }
.timeline h5 { font: 800 18px var(--font-display); margin-bottom: 8px; }
.desc { color: var(--ink-soft); font-size: 15px; }
.desc + .check { margin-top: 10px; }
.check { display: flex; align-items: center; gap: 10px; font-size: 16px; cursor: pointer; }
.check input { width: 20px; height: 20px; accent-color: var(--forest); }
.proof { margin-top: 10px; font: 700 14px var(--font-body); color: #E5654A; }
li.logged .node, li.done .node { border-color: #2E8B57; color: #2E8B57; background: #fff; }
li.gold .node { border-color: #F2B531; background: radial-gradient(circle, #F4B83A 45%, #fff 50%); }
li.gold h5 { color: #9A6A00; }
li.blue .node { border-color: #3A7BD5; background: radial-gradient(circle, #3A7BD5 45%, #fff 50%); }
li.blue h5 { color: #2857B0; }
li.plum .node { border-color: #B8A5D8; background: radial-gradient(circle, #CDBBEA 45%, #fff 50%); }
li.done .node, li.logged .node { background: #fff !important; }
li.done h5 { text-decoration: line-through; opacity: .7; }
.banner.warn { background: #FCE7C8; color: #8A5A00; } .banner.warn .tick { background: #D98A00; }
.proof.ok { color: var(--forest); }
.veil { position: fixed; inset: 0; z-index: 60; display: grid; place-items: end center; background: rgba(15, 30, 20, .5); animation: vfade .18s var(--ease, ease); }
.sheet { width: min(520px, 100%); padding: 22px; border-radius: 22px 22px 0 0; background: var(--card); box-shadow: 0 -12px 40px rgba(0,0,0,.25); animation: vup .24s var(--ease, ease); }
@media (min-width: 700px) { .veil { place-items: center; } .sheet { border-radius: 22px; } }
@keyframes vfade { from { opacity: 0; } } @keyframes vup { from { transform: translateY(24px); opacity: 0; } }
.sheet h4 { font: 800 19px var(--font-display); margin-bottom: 6px; }
.sub { color: var(--ink-soft); font-size: 14px; margin-bottom: 14px; }
.upload { display: grid; justify-items: center; gap: 4px; padding: 26px 14px; border: 2px dashed var(--line); border-radius: 16px; cursor: pointer; text-align: center; }
.upload:hover { border-color: var(--leaf); } .upload .big { font-size: 28px; } .upload small { color: var(--ink-soft); }
.upload.has { padding: 10px; } .upload img { width: 100%; max-height: 260px; object-fit: cover; border-radius: 12px; }
.warnline { margin: 12px 0 16px; font: 700 13px var(--font-body); color: #D3542F; }
.btns { display: flex; gap: 10px; } .btns button { flex: 1; padding: 13px; border: 0; border-radius: 14px; background: var(--forest); color: #fff; font: 800 15px var(--font-display); }
.btns button.ghost { background: none; border: 1px solid var(--line); color: var(--ink); } .btns button:disabled { opacity: .45; }
.opt { display: flex; align-items: center; gap: 12px; width: 100%; margin-bottom: 10px; padding: 14px 16px; border: 1px solid var(--line); border-radius: 14px; background: var(--card); font: 700 15px var(--font-body); text-align: left; }
.opt:hover { border-color: var(--leaf); background: var(--tint); }
.result { text-align: center; margin-bottom: 16px; } .result .ric { font-size: 40px; }
.disclaimer { margin-top: 20px; font-size: 12.5px; color: var(--ink-soft); text-align: center; }
@media (max-width: 560px) {
  .cell.ev { min-height: 62px; } .cell.ev small { display: none; } .dow { font-size: 10px; }
  .next-card { flex-direction: column; gap: 10px; }
}
</style>
