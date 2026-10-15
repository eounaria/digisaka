<script setup>
import { computed, onMounted, onBeforeUnmount, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import PageHeader from '../components/PageHeader.vue';
import { useProposalStore } from '../stores/proposal.js';
import { isValidWeek, weekStart } from '../helpers/week.js';
import { todayIso, today as nowDate } from '../helpers/today.js';

const route = useRoute(), store = useProposalStore();
const lineId = computed(() => String(route.params.lineId));
const week = computed(() => String(route.params.week));
const load = () => store.load(lineId.value, week.value);
onMounted(load);
watch([lineId, week], load);
onBeforeUnmount(() => store.run++);

const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const DAY = 86400000;
const parse = (iso) => { const [y, m, d] = iso.split('-').map(Number); return new Date(y, m - 1, d); };
const iso = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
const fmt = (s) => { const d = parse(s); return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`; };
const short = (s) => { const d = parse(s); return `${MONTHS[d.getMonth()].slice(0, 3)} ${d.getDate()}`; };
const today = () => todayIso();

const p = computed(() => store.proposal);
const status = computed(() => store.status);
const rejected = computed(() => status.value === 'rejected');
const applied = computed(() => status.value === 'applied');

// Each step gets a look so the calendar, the timeline and the "up next" card agree.
const KIND = {
  Treatment: { color: 'gold', icon: '🔥', tag: 'TREATMENT' },
  'Re-assessment': { color: 'plum', icon: '🔍', tag: 'REASSESS' },
};
const treatmentName = computed(() => p.value?.treatment?.name ?? p.value?.treatment?.id ?? 'Treatment');
const window_ = computed(() => p.value?.window);
const nextAssessmentText = computed(() => (reassessDate.value ? `week of ${fmt(reassessDate.value)}` : p.value?.next_assessment));
const reassessDate = computed(() => (isValidWeek(p.value?.next_assessment) ? weekStart(p.value.next_assessment) : null));

function stateOf(ev) {
  if (rejected.value) return 'rejected';
  if (ev.kind === 'Treatment') return applied.value ? 'done' : ev.end < today() ? 'missed' : 'upcoming';
  return ev.date < today() ? 'due' : 'upcoming';
}
const BADGE = { done: 'DONE', missed: 'MISSED', upcoming: 'UPCOMING', due: 'DUE', rejected: 'NOT GOING AHEAD' };

// Steps: the treatment window and the next-assessment week, both from the proposal.
const steps = computed(() => {
  if (!window_.value) return [];
  const out = [{ kind: 'Treatment', label: 'Treatment', date: window_.value.start, end: window_.value.end, desc: `${treatmentName.value}. Apply between ${fmt(window_.value.start)} and ${fmt(window_.value.end)}.` }];
  if (reassessDate.value && !rejected.value) out.push({ kind: 'Re-assessment', label: 'Re-assessment', date: reassessDate.value, end: reassessDate.value, desc: `Scan this line again in the week of ${fmt(reassessDate.value)}.` });
  return out;
});
// Every day of the treatment window is an event on the calendar (capped at five weeks).
const events = computed(() => steps.value.flatMap((s) => {
  const days = [];
  for (let d = parse(s.date), n = 0; iso(d) <= s.end && n < 35; d = new Date(d.getTime() + DAY), n++) days.push({ ...s, day: iso(d) });
  return days;
}));
const nextStep = computed(() => (rejected.value ? null : steps.value.find((s) => stateOf(s) !== 'done')));
const dayDiff = (s) => Math.round((parse(s) - parse(today())) / DAY);
const whenText = (s) => {
  const d = dayDiff(s.kind === 'Treatment' && s.date < today() ? s.end : s.date);
  if (d < 0) return `${-d} DAY${d === -1 ? '' : 'S'} AGO`;
  return d === 0 ? 'TODAY' : `IN ${d} DAY${d === 1 ? '' : 'S'}`;
};

const months = computed(() => {
  const order = [], by = new Map();
  events.value.forEach((e) => {
    const key = e.day.slice(0, 7);
    if (!by.has(key)) { by.set(key, { key, events: {} }); order.push(key); }
    by.get(key).events[Number(e.day.slice(8))] = e;
  });
  return order.sort().map((k) => {
    const m = by.get(k); const [y, mo] = k.split('-').map(Number);
    const first = new Date(y, mo - 1, 1), days = new Date(y, mo, 0).getDate();
    const cells = [...Array((first.getDay() + 6) % 7).fill(null), ...Array.from({ length: days }, (_, i) => i + 1)];
    const t = nowDate();
    const todayHere = t.getFullYear() === y && t.getMonth() === mo - 1 ? t.getDate() : null;
    const mine = steps.value.filter((s) => s.date.startsWith(k));
    return { ...m, month: MONTHS[mo - 1], year: y, cells, todayHere, steps: mine, done: mine.filter((s) => stateOf(s) === 'done').length };
  });
});

const BANNER = computed(() => {
  if (applied.value) return { cls: 'ok', icon: '✓', text: `Treatment applied on ${fmt(store.appliedOn)}` };
  if (rejected.value) return { cls: 'bad', icon: '!', text: `Human Review Required${store.cycle?.outcome_reason ? ` — ${store.cycle.outcome_reason}` : ''}` };
  if (status.value === 'approved') return { cls: 'ok', icon: '✓', text: 'Approved — apply during the treatment window' };
  return { cls: 'wait', icon: '•', text: 'Proposed — awaiting your decision' };
});

const note = ref('');
const dateSheet = ref(null); // { value }
const openDate = () => { const t = today(); dateSheet.value = { value: t }; };
async function decide(decision) { await store.decide(decision, note.value); if (!store.error) note.value = ''; }
async function confirmDate() {
  await store.apply(dateSheet.value.value);
  if (!store.error || store.status === 'applied') dateSheet.value = null;
}
</script>

<template>
  <div class="page narrow">
    <PageHeader :title="treatmentName" :subtitle="`Line ${lineId} · ${week}`" />
    <p v-if="store.phase === 'loading'" class="empty">Loading…</p>
    <p v-else-if="store.phase === 'error'" class="error">{{ store.error }} <button class="mark" type="button" @click="load">Try again</button></p>
    <p v-else-if="store.phase === 'notfound'" class="empty">This week's treatment couldn't be found.</p>
    <template v-else-if="store.phase === 'ready' && p">
      <p v-if="store.error" class="error">{{ store.error }}</p>
      <div class="banner" :class="BANNER.cls"><span class="tick">{{ BANNER.icon }}</span>{{ BANNER.text }}</div>

      <section class="prop-card">
        <h3>{{ treatmentName }}</h3>
        <p class="meta">Apply {{ fmt(p.window.start) }} to {{ fmt(p.window.end) }} · next assessment {{ nextAssessmentText }}</p>
        <p>{{ p.reason }}</p>
        <ul v-if="p.constraints?.length"><li v-for="c in p.constraints" :key="c">{{ c }}</li></ul>
        <template v-if="status === 'proposed'">
          <textarea v-model="note" rows="2" placeholder="Note (optional)" aria-label="Decision note"></textarea>
          <div class="btns">
            <button class="danger" type="button" :disabled="store.busy" @click="decide('rejected')">Reject</button>
            <button type="button" :disabled="store.busy" @click="decide('approved')">Approve</button>
          </div>
        </template>
        <p v-else-if="p.decision?.note" class="noted">Note: {{ p.decision.note }}</p>
      </section>

      <section v-for="m in months" :key="'cal' + m.key" class="cal-card">
        <header><h4>{{ m.month }} {{ m.year }}</h4><span class="plant">Line {{ lineId }}</span></header>
        <div class="grid">
          <span v-for="d in ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']" :key="d" class="dow">{{ d }}</span>
          <template v-for="(c, i) in m.cells" :key="i">
            <span v-if="!c" />
            <span v-else-if="m.events[c]" class="cell ev" :class="[stateOf(m.events[c]), KIND[m.events[c].kind].color, { today: c === m.todayHere }]">
              <em class="badge">{{ BADGE[stateOf(m.events[c])] }}</em>
              <b>{{ c }}</b>
              <i>{{ stateOf(m.events[c]) === 'done' ? '✓' : KIND[m.events[c].kind].icon }}</i>
              <small>{{ stateOf(m.events[c]) === 'missed' ? 'MISSED' : KIND[m.events[c].kind].tag }}</small>
            </span>
            <span v-else class="cell" :class="{ today: c === m.todayHere }">{{ c }}</span>
          </template>
        </div>
      </section>

      <template v-if="nextStep">
        <div class="eyebrow">Up next</div>
        <div class="next-card" :class="stateOf(nextStep) === 'missed' ? 'missed' : 'upcoming'">
          <span class="ico">{{ KIND[nextStep.kind].icon }}</span>
          <div class="txt">
            <small class="up">Up next</small>
            <h3>{{ nextStep.label }}{{ stateOf(nextStep) === 'missed' ? ' — Missed' : '' }}</h3>
            <p class="when">{{ nextStep.kind === 'Treatment' ? `Window ${short(nextStep.date)} to ${short(nextStep.end)}` : `Scheduled on ${fmt(nextStep.date)}` }}</p>
            <span class="pill" :class="{ late: stateOf(nextStep) === 'missed' }">{{ whenText(nextStep) }}</span>
            <p class="note">{{ nextStep.desc }}</p>
          </div>
        </div>
      </template>

      <section v-for="m in months" :key="'tl' + m.key" class="timeline">
        <header><h3>{{ m.month }} {{ m.year }} — Detailed Timeline</h3><span class="count">{{ m.done }} / {{ m.steps.length }} done</span></header>
        <ol>
          <li v-for="s in m.steps" :key="s.kind" :class="[stateOf(s), KIND[s.kind].color]">
            <span class="node"><template v-if="stateOf(s) === 'done'">✓</template></span>
            <div class="date">{{ s.kind === 'Treatment' ? `${short(s.date)} – ${short(s.end)}` : short(s.date) }}</div>
            <div class="card">
              <h5>{{ s.label }}</h5>
              <p class="desc">{{ s.desc }}</p>
              <template v-if="s.kind === 'Treatment'">
                <button v-if="status === 'approved'" class="mark" type="button" :disabled="store.busy" @click="openDate">Mark as done</button>
                <p v-else-if="applied" class="desc">Applied on {{ fmt(store.appliedOn) }}.</p>
                <p v-else-if="status === 'proposed'" class="desc">Approve the proposal to record this treatment.</p>
                <p class="soon">📷 Proof of treatment photo — not available yet</p>
              </template>
              <p v-else class="soon">📝 Re-assessment outcome — not available yet</p>
            </div>
          </li>
        </ol>
      </section>

      <section class="timeline">
        <header><h3>Coming later</h3></header>
        <ol>
          <li class="soon blue">
            <span class="node"></span>
            <div class="card soon-card">
              <h5>Follow-up</h5>
              <p class="desc">Follow-up steps aren't scheduled yet.</p>
              <label class="check"><input type="checkbox" disabled />Mark as done</label>
            </div>
          </li>
        </ol>
      </section>
    </template>
    <p class="disclaimer">AI-assisted scheduling should be verified by an agricultural specialist before treatment decisions.</p>

    <div v-if="dateSheet" class="veil" @mousedown.self="dateSheet = null">
      <div class="sheet" role="dialog" aria-modal="true" aria-label="Date applied">
        <h4>When was it applied?</h4>
        <p class="sub">Pick the date the treatment was applied.</p>
        <input v-model="dateSheet.value" class="datefield" type="date" :max="todayIso()" aria-label="Date applied" />
        <p v-if="store.error" class="error">{{ store.error }}</p>
        <div class="btns"><button class="ghost" type="button" @click="dateSheet = null">Cancel</button><button type="button" :disabled="!dateSheet.value || store.busy" @click="confirmDate">Record</button></div>
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
li.logged .node, li.done .node { border-color: #2E8B57; color: #2E8B57; background: #fff; }
li.gold .node { border-color: #F2B531; background: radial-gradient(circle, #F4B83A 45%, #fff 50%); }
li.gold h5 { color: #9A6A00; }
li.blue .node { border-color: #3A7BD5; background: radial-gradient(circle, #3A7BD5 45%, #fff 50%); }
li.blue h5 { color: #2857B0; }
li.plum .node { border-color: #B8A5D8; background: radial-gradient(circle, #CDBBEA 45%, #fff 50%); }
li.done .node, li.logged .node { background: #fff !important; }
li.done h5 { text-decoration: line-through; opacity: .7; }
.banner.warn { background: #FCE7C8; color: #8A5A00; } .banner.warn .tick { background: #D98A00; }
.veil { position: fixed; inset: 0; z-index: 60; display: grid; place-items: end center; background: rgba(15, 30, 20, .5); animation: vfade .18s var(--ease, ease); }
.sheet { width: min(520px, 100%); padding: 22px; border-radius: 22px 22px 0 0; background: var(--card); box-shadow: 0 -12px 40px rgba(0,0,0,.25); animation: vup .24s var(--ease, ease); }
@media (min-width: 700px) { .veil { place-items: center; } .sheet { border-radius: 22px; } }
@keyframes vfade { from { opacity: 0; } } @keyframes vup { from { transform: translateY(24px); opacity: 0; } }
.sheet h4 { font: 800 19px var(--font-display); margin-bottom: 6px; }
.sub { color: var(--ink-soft); font-size: 14px; margin-bottom: 14px; }
.btns { display: flex; gap: 10px; } .btns button { flex: 1; padding: 13px; border: 0; border-radius: 14px; background: var(--forest); color: #fff; font: 800 15px var(--font-display); }
.btns button.ghost { background: none; border: 1px solid var(--line); color: var(--ink); } .btns button:disabled { opacity: .45; }
.disclaimer { margin-top: 20px; font-size: 12.5px; color: var(--ink-soft); text-align: center; }
@media (max-width: 560px) {
  .cell.ev { min-height: 62px; } .cell.ev small { display: none; } .dow { font-size: 10px; }
  .next-card { flex-direction: column; gap: 10px; }
}
.prop-card { padding: 18px; margin-bottom: 18px; border-radius: 20px; background: var(--card); box-shadow: var(--shadow); }
.prop-card h3 { font: 800 20px var(--font-display); color: var(--forest); margin-bottom: 4px; }
.prop-card .meta { color: var(--ink-soft); font-size: 14px; margin-bottom: 10px; }
.prop-card ul { margin: 8px 0 0 18px; color: var(--ink-soft); font-size: 14px; }
.prop-card textarea { width: 100%; margin-top: 12px; padding: 10px 12px; border: 1px solid var(--line); border-radius: 12px; font: 500 14px var(--font-body); resize: vertical; }
.prop-card .btns { margin-top: 12px; }
.btns .danger { background: #fff; color: var(--danger); border: 1.5px solid var(--danger); }
.noted { margin-top: 10px; font-size: 14px; color: var(--ink-soft); }
.banner.bad { background: #FBE4E2; color: #A62A20; } .banner.bad .tick { background: #D8352A; }
.banner.wait { background: #E3F2F0; color: #1F7C74; } .banner.wait .tick { background: #1F7C74; }
.cell.ev.rejected { background: #F1F1EF; border-color: #D5D5D0; color: #8B8B85; }
.cell.ev.rejected .badge { background: #8B8B85; color: #fff; }
.mark { margin-top: 10px; padding: 10px 16px; border: 0; border-radius: 12px; background: var(--forest); color: #fff; font: 800 14px var(--font-display); }
.mark:disabled { opacity: .45; }
.soon { margin-top: 10px; font: 700 14px var(--font-body); color: var(--ink-soft); opacity: .55; }
.soon-card { opacity: .55; }
.soon-card .check input { cursor: not-allowed; }
.datefield { width: 100%; padding: 12px; margin-bottom: 14px; border: 1px solid var(--line); border-radius: 12px; font: 600 15px var(--font-body); }
li.rejected .node { border-color: #BDBDB6; } li.rejected h5 { color: #8B8B85; }
li.soon .node { border-color: #D5D5D0; }
</style>
