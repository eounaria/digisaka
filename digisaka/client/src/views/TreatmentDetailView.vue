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
const monthIndex = (name) => MONTHS.indexOf(name);
const stepDate = (s) => new Date(2026, monthIndex(s.month), s.day);
const fmtDate = (s) => `${s.month} ${s.day}, 2026`;

const STATUS_META = {
  Suggested: { label: 'Suggested', chip: 'amber' },
  Confirmed: { label: 'Confirmed', chip: 'blue' },
  Applied: { label: 'Applied', chip: 'green' },
  Unknown: { label: 'Not sure yet', chip: 'grey' },
  'Follow-up Required': { label: 'Needs follow-up', chip: 'red' },
};

const nextStep = computed(() => group.value?.schedule.find((s) => s.status !== 'Applied'));

async function load() {
  loading.value = true; error.value = '';
  try { schedules.value = (await api.get('/api/schedules')).schedules; }
  catch (e) { error.value = e.message; }
  finally { loading.value = false; }
}
onMounted(load);

async function setStatus(step, status) {
  if (!bulk.value) return;
  saving.value = true;
  const groups = bulk.value.groups.map((g) => g.stage !== stage ? g : { ...g, schedule: g.schedule.map((s) => s === step ? { ...s, status } : s) });
  try {
    await api.put(`/api/schedules/${encodeURIComponent(bulk.value.bulkId)}`, { groups });
    bulk.value.groups = groups;
  } catch (e) { error.value = e.message; }
  finally { saving.value = false; }
}

// A light month calendar for each month this stage's steps fall in — real dates, not a demo.
const calendars = computed(() => {
  if (!group.value) return [];
  const byMonth = new Map();
  group.value.schedule.forEach((s) => { if (!byMonth.has(s.month)) byMonth.set(s.month, []); byMonth.get(s.month).push(s); });
  return [...byMonth.entries()].map(([month, steps]) => {
    const first = new Date(2026, monthIndex(month), 1);
    const daysInMonth = new Date(2026, monthIndex(month) + 1, 0).getDate();
    const leadBlanks = (first.getDay() + 6) % 7; // Monday-first grid
    const cells = [...Array(leadBlanks).fill(null), ...Array.from({ length: daysInMonth }, (_, i) => i + 1)];
    return { month, cells, steps: Object.fromEntries(steps.map((s) => [s.day, s])) };
  });
});
</script>

<template>
  <div class="page narrow">
    <PageHeader :title="`${meta.tag}`" :subtitle="bulk ? `${bulk.plant} · ${bulk.bulkId}` : ''" />
    <p v-if="error" class="error">{{ error }}</p>
    <p v-else-if="!loading && !group" class="empty">This stage's schedule couldn't be found.</p>
    <template v-else-if="group">
      <div class="window-card"><span class="emoji">{{ meta.emoji }}</span><div><b>{{ meta.group }}</b><small>Suggested window: {{ group.window }}</small></div></div>

      <div v-if="nextStep" class="next-card">
        <div class="eyebrow">Next suggested action</div>
        <div class="row"><b>{{ nextStep.label }}</b><span class="chip" :class="STATUS_META[nextStep.status].chip">{{ STATUS_META[nextStep.status].label }}</span></div>
        <small>{{ fmtDate(nextStep) }} — {{ nextStep.desc }}</small>
      </div>

      <div v-for="cal in calendars" :key="cal.month" class="cal-card">
        <h4>{{ cal.month }} 2026</h4>
        <div class="grid">
          <span v-for="d in ['M','T','W','T','F','S','S']" :key="d" class="dow">{{ d }}</span>
          <span v-for="(c, i) in cal.cells" :key="i" class="cell" :class="c && cal.steps[c] ? STATUS_META[cal.steps[c].status].chip : ''">{{ c }}</span>
        </div>
      </div>

      <div class="section-label">Treatment steps</div>
      <div v-for="s in group.schedule" :key="s.label" class="step-card">
        <div class="row">
          <div><b>{{ s.label }}</b><small class="date">{{ fmtDate(s) }}</small></div>
          <span class="chip" :class="STATUS_META[s.status].chip">{{ STATUS_META[s.status].label }}</span>
        </div>
        <p>{{ s.desc }}</p>
        <div class="actions">
          <template v-if="s.status === 'Suggested'">
            <button :disabled="saving" @click="setStatus(s, 'Confirmed')">Confirm</button>
            <button class="ghost" :disabled="saving" @click="setStatus(s, 'Unknown')">Not sure yet</button>
          </template>
          <template v-else-if="s.status === 'Confirmed'">
            <button :disabled="saving" @click="setStatus(s, 'Applied')">Mark as applied</button>
            <button class="ghost" :disabled="saving" @click="setStatus(s, 'Unknown')">Not sure yet</button>
          </template>
          <template v-else-if="s.status === 'Unknown'">
            <button :disabled="saving" @click="setStatus(s, 'Confirmed')">Confirm now</button>
          </template>
          <template v-else-if="s.status === 'Follow-up Required'">
            <button :disabled="saving" @click="setStatus(s, 'Applied')">Mark as applied</button>
          </template>
          <template v-else>
            <button class="ghost" :disabled="saving" @click="setStatus(s, 'Follow-up Required')">Needs follow-up</button>
          </template>
        </div>
      </div>
    </template>
    <p class="disclaimer">AI-assisted scheduling should be verified by an agricultural specialist before treatment decisions.</p>
  </div>
</template>

<style scoped>
.narrow { max-width: 640px; }
.error { color: var(--danger); font-weight: 700; }
.empty { padding: 30px; text-align: center; color: var(--ink-soft); border: 1.5px dashed var(--line); border-radius: var(--radius-md); background: var(--card); }
.window-card { display: flex; align-items: center; gap: 14px; padding: 16px; margin-bottom: 18px; border-radius: var(--radius-md); background: var(--tint); }
.window-card .emoji { font-size: 26px; }
.window-card b { display: block; font: 800 15px var(--font-display); color: var(--forest); }
.window-card small { color: var(--ink-soft); }
.next-card { padding: 16px; margin-bottom: 18px; border-radius: var(--radius-md); background: var(--card); border: 1px solid var(--line); box-shadow: var(--shadow); }
.next-card .eyebrow { font: 800 11px var(--font-display); letter-spacing: .08em; text-transform: uppercase; color: var(--ink-soft); margin-bottom: 6px; }
.next-card small { color: var(--ink-soft); }
.row { display: flex; align-items: center; justify-content: space-between; gap: 10px; }
.chip { flex: none; padding: 4px 11px; border-radius: 999px; font: 800 12px var(--font-body); white-space: nowrap; }
.chip.amber { background: #FFF1DC; color: #9C6B00; }
.chip.blue { background: #E8F0FE; color: #2857B0; }
.chip.green { background: var(--tint); color: var(--forest); }
.chip.grey { background: #EEF1EE; color: var(--ink-soft); }
.chip.red { background: var(--warn-tint); color: #B4432A; }
.cal-card { padding: 16px; margin-bottom: 18px; border-radius: var(--radius-md); background: var(--card); border: 1px solid var(--line); box-shadow: var(--shadow); }
.cal-card h4 { font: 800 15px var(--font-display); color: var(--forest); margin-bottom: 10px; }
.grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; text-align: center; }
.dow { font-size: 11px; font-weight: 800; color: var(--ink-soft); padding-bottom: 4px; }
.cell { aspect-ratio: 1; display: grid; place-items: center; border-radius: 8px; font-size: 13px; font-weight: 700; color: var(--ink); }
.cell.amber { background: #FFF1DC; color: #9C6B00; } .cell.blue { background: #E8F0FE; color: #2857B0; }
.cell.green { background: var(--tint); color: var(--forest); } .cell.red { background: var(--warn-tint); color: #B4432A; }
.section-label { margin: 22px 0 12px; font: 800 12px var(--font-display); letter-spacing: .08em; text-transform: uppercase; color: var(--ink-soft); }
.step-card { padding: 16px; margin-bottom: 12px; border-radius: var(--radius-md); background: var(--card); border: 1px solid var(--line); box-shadow: var(--shadow); }
.step-card b { font: 800 15px var(--font-display); }
.step-card .date { display: block; color: var(--ink-soft); font-size: 13px; }
.step-card p { margin: 8px 0 12px; color: var(--ink-soft); font-size: 14px; }
.actions { display: flex; gap: 10px; }
.actions button { padding: 9px 16px; border: 0; border-radius: 12px; background: var(--forest); color: #fff; font: 800 13.5px var(--font-display); }
.actions button.ghost { background: none; border: 1px solid var(--line); color: var(--forest); }
.actions button:disabled { opacity: .6; }
.disclaimer { margin-top: 20px; font-size: 12.5px; color: var(--ink-soft); text-align: center; }
</style>
