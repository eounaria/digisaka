<script setup>
import { RouterLink } from 'vue-router';
import { computed, onMounted, onBeforeUnmount, ref, nextTick, watch } from 'vue';
import PageHeader from '../components/PageHeader.vue';
import Icon from '../components/Icon.vue';
import { useScanStore, outcomeLabel, MAX_LEAVES } from '../stores/scan.js';
import { useFarmStore } from '../stores/farm.js';
import { useCycleStore } from '../stores/cycle.js';
import { groupLeaves } from '../helpers/groups.js';
import { previousWeek, nextWeek, isoWeekOf, weekStart, weekEnd } from '../helpers/week.js';
import { outcomeReasonText } from '../helpers/messages.js';
import { todayIso, fromIso } from '../helpers/today.js';

const scan = useScanStore(), farm = useFarmStore(), cycle = useCycleStore();
const step = ref(1); // 1 Select Leaves, 2 Bulk Assess, 3 Results
const STEPS = ['Select Leaves', 'Bulk Assess', 'Results'];
const AGENT_STEPS = ['Leaf Images Collected', 'Black Sigatoka Validation', 'Individual Stage Assessment', 'Stage Groups Organized', 'Human Verification', 'Treatment Recommendation', 'Schedule Review'];
const maxDate = todayIso();                 // scans can't be added to a future week
const dateInput = ref(maxDate);
const weekRange = computed(() => (scan.weekOk ? `${weekStart(scan.week)} to ${weekEnd(scan.week)}` : ''));
const atLatest = computed(() => scan.week >= isoWeekOf(fromIso(maxDate)));
const gallery = ref(null), camera = ref(null), rescanInput = ref(null), logBox = ref(null);
const rescanId = ref(null);
const previews = new Map();

onMounted(async () => {
  await farm.loadLines();
  if (!scan.line && farm.lines.length) scan.select(farm.lines[0], scan.week);
});
onBeforeUnmount(() => { cycle.stop(); for (const u of previews.values()) URL.revokeObjectURL(u); });

const preview = (leaf) => {
  if (!previews.has(leaf.id)) previews.set(leaf.id, URL.createObjectURL(leaf.file));
  return previews.get(leaf.id);
};
const setLine = (e) => scan.select(e.target.value, scan.week);
const setDate = () => { if (dateInput.value) scan.select(scan.line, isoWeekOf(fromIso(dateInput.value))); };
const stepWeek = (fn) => {
  const w = fn(scan.week);
  const start = weekStart(w);
  dateInput.value = start > maxDate ? maxDate : start;
  scan.select(scan.line, w);
};
const picked = (e) => { scan.addFiles([...e.target.files]); e.target.value = ''; };
const startRescan = (id) => { rescanId.value = id; rescanInput.value.click(); };
const rescanPicked = (e) => { const f = e.target.files[0]; e.target.value = ''; if (f) scan.rescan(rescanId.value, f); };

async function assess() {
  step.value = 2;
  await scan.assess();
}
function startOver() { cycle.reset(); scan.leaves = []; scan.log = []; step.value = 1; }
const groups = computed(() => groupLeaves(scan.leaves));
function confirmSchedule() { cycle.close(scan.line, scan.week); }

const needsAnswer = computed(() => scan.leaves.filter((l) => l.phase === 'confirm' || l.phase === 'rescan'));
const failed = computed(() => scan.leaves.filter((l) => l.phase === 'failed'));
const allDone = computed(() => scan.leaves.length > 0 && scan.leaves.every((l) => l.phase === 'done'));
// Which agent step is running: validating, then assessing (waiting on answers), then grouped.
const agentIndex = computed(() => (scan.assessing ? 1 : needsAnswer.value.length || failed.value.length ? 2 : 3));
const status = computed(() => (scan.assessing ? 'Validating...' : needsAnswer.value.length ? 'Waiting for your confirmation' : failed.value.length ? 'Some leaves failed' : 'Validated'));
const canContinue = computed(() => allDone.value && !scan.assessing);

watch(() => scan.log.length, async () => { await nextTick(); if (logBox.value) logBox.value.scrollTop = logBox.value.scrollHeight; });
</script>

<template>
  <div class="page">
    <PageHeader :title="step === 2 ? 'Black Sigatoka Validation' : step === 3 ? 'Bulk Assessment Result' : 'Leaf Scan'"
                :subtitle="step === 1 ? 'Scan or select banana leaves to check for signs of Black Sigatoka' : ''" />

    <ol class="stepper" aria-label="Progress">
      <template v-for="(label, i) in STEPS" :key="label">
        <li v-if="i" class="conn" aria-hidden="true"></li>
        <li :class="['dot', { active: step === i + 1 }]" :aria-current="step === i + 1 ? 'step' : undefined">
          <span>{{ i + 1 }}</span><small>{{ label }}</small>
        </li>
      </template>
    </ol>

    <!-- Step 1: Select Leaves -->
    <template v-if="step === 1">
      <section class="card pick">
        <label>Line
          <select :value="scan.line" @change="setLine">
            <option v-if="!farm.lines.length" value="">No lines available</option>
            <option v-for="l in farm.lines" :key="l" :value="l">{{ l }}</option>
          </select>
        </label>
        <div class="week">
          <label>Date <input v-model="dateInput" type="date" :max="maxDate" @change="setDate"></label>
          <button type="button" @click="stepWeek(previousWeek)">Previous week</button>
          <button type="button" :disabled="atLatest" @click="stepWeek(nextWeek)">Next week</button>
        </div>
        <p class="hint">Week {{ scan.week }} ({{ weekRange }})</p>
        <p v-if="farm.linesError" class="err" role="alert">{{ farm.linesError }}</p>
      </section>

      <div class="frame" aria-hidden="true">
        <span class="br tl"></span><span class="br tr"></span><span class="br bl"></span><span class="br bb"></span>
        <Icon name="scan" :size="90" />
        <p>Position the banana leaf inside the frame</p>
      </div>
      <p class="hint center">Good lighting • Clear leaf • Symptoms visible</p>

      <div class="capture">
        <button class="gallery" :disabled="scan.leaves.length >= MAX_LEAVES" @click="gallery.click()"><span class="tile"><Icon name="folder" :size="26" /></span>Gallery</button>
        <button class="shutter" :disabled="scan.leaves.length >= MAX_LEAVES" aria-label="Take photo" @click="camera.click()"><span></span></button>
      </div>
      <input ref="camera" type="file" accept="image/*" capture="environment" hidden @change="picked">
      <input ref="gallery" type="file" accept="image/*" multiple hidden @change="picked">

      <div class="head">
        <strong class="count">{{ scan.leaves.length }} leaves selected</strong>
        <button v-if="scan.leaves.length" class="link" @click="scan.clear()">Clear all</button>
      </div>
      <p v-if="scan.notice" class="err" role="alert">{{ scan.notice }}</p>
      <ul class="grid">
        <li v-for="(l, i) in scan.leaves" :key="l.id" class="thumb">
          <img :src="preview(l)" :alt="`Leaf ${i + 1}`">
          <span class="pill">Leaf {{ i + 1 }}</span>
          <button class="x" :aria-label="`Remove leaf ${i + 1}`" @click="scan.remove(l.id)"><Icon name="plus" :size="12" /></button>
        </li>
        <li v-if="scan.leaves.length < MAX_LEAVES"><button class="add" aria-label="Add leaves" @click="gallery.click()"><Icon name="plus" :size="22" /></button></li>
      </ul>

      <button class="primary wide" :disabled="!scan.canAssess" @click="assess">
        Assess All Leaves{{ scan.leaves.length ? ` (${scan.leaves.length})` : '' }}
      </button>
      <p v-if="!scan.leaves.length" class="hint center">No leaves added yet.</p>

      <section class="card soon" aria-disabled="true">
        <h2>Not available yet</h2>
        <label class="off">Stage override <select disabled><option>Use QA's stage</option></select></label>
        <label class="off">Treatment history <select disabled><option>Not available yet</option></select></label>
      </section>
    </template>

    <!-- Step 2: Bulk Assess -->
    <template v-else-if="step === 2">
      <section class="card summary">
        <div><span>Line</span><b>{{ scan.line }}</b></div>
        <div><span>Week</span><b>{{ scan.week }}</b></div>
        <div><span>Status</span><b class="status">{{ status }}</b></div>
      </section>

      <section class="card agent">
        <h2>BULK ASSESSMENT AGENT</h2>
        <ol>
          <li v-for="(s, i) in AGENT_STEPS" :key="s" :class="{ done: i < agentIndex, now: i === agentIndex, later: i > agentIndex }">
            <span class="mark">{{ i < agentIndex ? '✓' : i + 1 }}</span>{{ s }}
          </li>
        </ol>
      </section>

      <div v-if="scan.assessing" class="loader" aria-hidden="true"><i></i><Icon name="scan" :size="38" /></div>
      <p class="center big">{{ scan.assessing ? `Validating & Assessing ${scan.leaves.length} Leaves...` : status }}</p>

      <section v-if="needsAnswer.length" class="card answers" aria-live="polite">
        <h2>Needs your confirmation</h2>
        <div v-for="l in needsAnswer" :key="l.id" class="ask">
          <img :src="preview(l)" :alt="`Leaf ${scan.leaves.indexOf(l) + 1}`">
          <div v-if="l.phase === 'confirm'">
            <strong>Leaf {{ scan.leaves.indexOf(l) + 1 }}{{ l.stage ? ` — ${l.stage}` : '' }}</strong>
            <p>Do you see these on the leaf?</p>
            <ul class="checks"><li v-for="c in l.checklist" :key="c">{{ c }}</li></ul>
            <p v-if="l.error" class="err" role="alert">{{ l.error }}</p>
            <button class="primary" @click="scan.confirm(l.id, true)">Yes</button>
            <button @click="scan.confirm(l.id, false)">No</button>
          </div>
          <div v-else>
            <strong>Leaf {{ scan.leaves.indexOf(l) + 1 }} — retake</strong>
            <p>QA could not match the symptoms. Take a new photo of the same leaf.</p>
            <p v-if="l.error" class="err" role="alert">{{ l.error }}</p>
            <button class="primary" @click="startRescan(l.id)">Retake</button>
          </div>
        </div>
      </section>
      <input ref="rescanInput" type="file" accept="image/*" capture="environment" hidden @change="rescanPicked">

      <section v-if="failed.length && !scan.assessing" class="card">
        <p v-for="l in failed" :key="l.id" class="err" role="alert">Leaf {{ scan.leaves.indexOf(l) + 1 }}: {{ l.error }}</p>
        <button class="primary" @click="scan.assess()">Retry failed leaves</button>
      </section>

      <div ref="logBox" class="log" role="log" aria-label="Assessment log">
        <p v-for="(e, i) in scan.log" :key="i" :class="e.kind">{{ e.text }}</p>
      </div>

      <div class="nav">
        <button :disabled="scan.assessing" @click="step = 1">Back</button>
        <button class="primary" :disabled="!canContinue" @click="step = 3">View results</button>
      </div>
    </template>

    <!-- Step 3: Results, grouped by stage; Confirm & Schedule closes the week and follows the cycle -->
    <template v-else>
      <section class="card">
        <h2>Leaves in this Bulk</h2>
        <div v-for="g in groups.stages" :key="g.label" class="group">
          <b>{{ g.label }} <small>({{ g.leaves.length }})</small></b>
          <ul class="results"><li v-for="l in g.leaves" :key="l.id"><img :src="preview(l)" :alt="`Leaf ${scan.leaves.indexOf(l) + 1}`">Leaf {{ scan.leaves.indexOf(l) + 1 }}</li></ul>
        </div>
        <div v-if="groups.healthy.length" class="group">
          <b>Healthy <small>({{ groups.healthy.length }})</small></b>
          <ul class="results"><li v-for="l in groups.healthy" :key="l.id"><img :src="preview(l)" :alt="`Leaf ${scan.leaves.indexOf(l) + 1}`">Leaf {{ scan.leaves.indexOf(l) + 1 }}</li></ul>
        </div>
        <div v-if="groups.unvalidated.length" class="group">
          <b>Unvalidated / Review Required <small>({{ groups.unvalidated.length }})</small></b>
          <ul class="results"><li v-for="l in groups.unvalidated" :key="l.id"><img :src="preview(l)" :alt="`Leaf ${scan.leaves.indexOf(l) + 1}`">Leaf {{ scan.leaves.indexOf(l) + 1 }} — {{ outcomeLabel(l.outcome) }}</li></ul>
        </div>
        <p class="hint">This is an AI-assisted assessment and not a confirmed diagnosis. Results should be verified by an agricultural specialist before treatment decisions.</p>
      </section>

      <section class="card" aria-live="polite">
        <p v-if="cycle.error" class="err" role="alert">{{ cycle.error }}</p>
        <template v-if="cycle.phase === 'idle'">
          <p>Confirm &amp; Schedule closes {{ scan.week }} for line {{ scan.line }} and works out a treatment. No more scans can be added to this week.</p>
          <button class="primary" :disabled="cycle.busy" @click="confirmSchedule">Confirm &amp; Schedule</button>
        </template>
        <template v-else-if="cycle.phase === 'closing' || cycle.phase === 'running'">
          <h2>Working out a treatment...</h2>
          <p class="hint">This usually takes under a minute.</p>
        </template>
        <template v-else-if="cycle.phase === 'proposal'">
          <h2>A treatment proposal is ready</h2>
          <RouterLink class="btn primary" :to="`/treatment/${encodeURIComponent(scan.line)}/${encodeURIComponent(scan.week)}`">Open proposal</RouterLink>
        </template>
        <template v-else-if="cycle.phase === 'monitoring'">
          <h2>No treatment needed yet</h2>
          <p v-if="cycle.cycle?.outcome_reason">{{ outcomeReasonText(cycle.cycle.outcome_reason) }}</p>
          <p class="hint">Keep monitoring this line and scan again next week.</p>
        </template>
        <template v-else-if="cycle.phase === 'review'">
          <h2>Human review required</h2>
          <p>No treatment is proposed for this week. An expert needs to look at this line.</p>
          <p v-if="cycle.cycle?.outcome_reason">Reason: {{ outcomeReasonText(cycle.cycle.outcome_reason) }}</p>
        </template>
        <template v-else-if="cycle.phase === 'failed'">
          <h2>The cycle failed</h2>
          <p v-if="cycle.cycle?.failure_reason">Reason: {{ cycle.cycle.failure_reason }}</p>
          <button class="primary" :disabled="cycle.busy" @click="cycle.retry()">Retry</button>
        </template>
        <template v-else>
          <h2>{{ cycle.phase === 'timeout' ? 'This is taking too long' : 'Could not load the cycle' }}</h2>
          <button class="primary" @click="cycle.resume()">Check again</button>
        </template>
      </section>
      <div class="nav"><button :disabled="cycle.phase !== 'idle'" @click="step = 2">Back</button><button v-if="cycle.phase !== 'closing' && cycle.phase !== 'running'" @click="startOver">New scan</button></div>
    </template>
  </div>
</template>

<style scoped>
.card { background: var(--card); border: 1px solid var(--line); border-radius: var(--radius-md); box-shadow: var(--shadow); padding: 16px; margin-bottom: 16px; max-width: 720px; display: grid; gap: 12px; }
h2 { font: 800 14px var(--font-display); color: var(--forest); letter-spacing: .04em; }
.page > * { max-width: 720px; }
.pick { display: grid; }
.week { display: flex; flex-wrap: wrap; gap: 8px; align-items: flex-end; }
label { display: grid; gap: 4px; font-weight: 700; color: var(--ink-soft); }
input, select, button { padding: 10px 12px; border: 1px solid var(--line); border-radius: var(--radius-sm); background: #fff; }
button:disabled, select:disabled { opacity: .55; cursor: not-allowed; }
button.primary { background: var(--forest); border-color: var(--forest); color: #fff; font-weight: 800; }
button.wide { width: 100%; padding: 14px; margin: 20px 0 8px; border-radius: 14px; }
.hint { color: var(--ink-soft); font-size: 13px; }
.center { text-align: center; }
.err { color: var(--danger); }

.stepper { display: flex; align-items: flex-start; list-style: none; margin-bottom: 20px; }
.dot { display: grid; justify-items: center; gap: 6px; }
.dot span { width: 32px; height: 32px; border-radius: 50%; display: grid; place-items: center; font-weight: 800; background: var(--line); color: var(--ink-soft); }
.dot small { font-size: 11px; color: var(--ink-soft); }
.dot.active span { background: var(--forest); color: #fff; }
.dot.active small { color: var(--forest); font-weight: 800; }
.conn { flex: 1; height: 2px; background: var(--line); margin: 15px 8px 0; }

.frame { position: relative; aspect-ratio: 1.5; border-radius: 20px; background: linear-gradient(#08783F, #0D3D1E); display: grid; place-items: center; color: rgba(255,255,255,.15); }
.frame p { position: absolute; bottom: 18px; color: #fff; font-weight: 700; font-size: 13px; }
.br { position: absolute; width: 28px; height: 28px; border: 0 solid var(--banana); }
.tl { top: 14px; left: 14px; border-width: 3px 0 0 3px; } .tr { top: 14px; right: 14px; border-width: 3px 3px 0 0; }
.bl { bottom: 14px; left: 14px; border-width: 0 0 3px 3px; } .bb { bottom: 14px; right: 14px; border-width: 0 3px 3px 0; }
.capture { display: flex; justify-content: center; align-items: center; gap: 40px; margin: 20px 0 24px; }
.gallery { display: grid; justify-items: center; gap: 6px; border: 0; background: none; font-size: 12px; padding: 0; }
.tile { width: 56px; height: 56px; border-radius: 16px; background: var(--beige); color: var(--banana); display: grid; place-items: center; }
.shutter { width: 64px; height: 64px; padding: 6px; border-radius: 50%; border: 3px solid var(--forest); }
.shutter span { display: block; width: 100%; height: 100%; border-radius: 50%; background: var(--forest); }
.head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.count { color: var(--forest); }
.link { border: 0; background: none; color: var(--ink-soft); font-weight: 700; padding: 0; }
.grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }
.thumb { position: relative; aspect-ratio: 1; }
.thumb img { width: 100%; height: 100%; object-fit: cover; border-radius: 14px; }
.pill { position: absolute; bottom: 6px; left: 50%; transform: translateX(-50%); background: var(--forest); color: #fff; font: 800 9.5px var(--font-body); padding: 2px 8px; border-radius: 10px; white-space: nowrap; }
.x { position: absolute; top: -6px; right: -6px; width: 22px; height: 22px; padding: 0; border: 0; border-radius: 50%; background: #e53935; color: #fff; display: grid; place-items: center; }
.x :deep(svg) { transform: rotate(45deg); }
.add { width: 100%; aspect-ratio: 1; border: 2px dashed var(--leaf-soft); border-radius: 14px; color: var(--forest); background: none; display: grid; place-items: center; padding: 0; }
.soon { opacity: .6; margin-top: 16px; }

.summary { grid-template-columns: repeat(3, 1fr); }
.summary span { display: block; color: var(--ink-soft); font-size: 12px; }
.status { color: var(--forest); }
.agent ol { list-style: none; display: grid; gap: 8px; padding: 0; }
.agent li { display: flex; gap: 10px; align-items: center; }
.mark { width: 22px; height: 22px; border-radius: 50%; display: grid; place-items: center; font: 800 11px var(--font-body); background: var(--line); color: var(--ink-soft); }
.agent .done .mark { background: var(--forest); color: #fff; }
.agent .now { font-weight: 800; color: var(--forest); } .agent .now .mark { background: var(--banana); color: var(--ink); }
.agent .later { color: var(--ink-soft); }
.loader { position: relative; width: 150px; height: 150px; margin: 8px auto; display: grid; place-items: center; color: var(--forest); }
.loader i { position: absolute; inset: 0; border-radius: 50%; border: 4px solid var(--tint); border-top-color: var(--forest); animation: spin 1.6s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.big { font: 800 17px var(--font-display); color: var(--forest); margin-bottom: 16px; }
.log { height: 190px; overflow-y: auto; background: rgba(255,255,255,.75); border: 1px solid #dde3db; border-radius: 12px; padding: 10px 12px; font: 11.5px/1.3 ui-monospace, monospace; margin-bottom: 16px; }
.log p { margin-bottom: 6px; }
.log .agent { font-weight: 800; } .log .step { color: var(--teal); } .log .ok { font-weight: 800; } .log .bad { color: var(--danger); font-weight: 800; }
.ask { display: flex; gap: 12px; }
.ask img { width: 72px; height: 72px; object-fit: cover; border-radius: 10px; }
.ask > div { display: grid; gap: 6px; justify-items: start; }
.checks { list-style: disc; padding-left: 20px; }
.nav { display: flex; gap: 8px; justify-content: space-between; }
.results { display: flex; flex-wrap: wrap; gap: 8px 16px; margin: 6px 0 12px; }
.btn { display: inline-block; padding: 10px 12px; border-radius: var(--radius-sm); text-align: center; }
.btn.primary { background: var(--forest); color: #fff; font-weight: 800; }
.results li { display: flex; gap: 10px; align-items: center; }
.results img { width: 48px; height: 48px; object-fit: cover; border-radius: 10px; }
</style>
