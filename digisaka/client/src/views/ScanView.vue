<script setup>
import { computed, onMounted, onBeforeUnmount, ref } from 'vue';
import PageHeader from '../components/PageHeader.vue';
import Icon from '../components/Icon.vue';
import { useScanStore, outcomeLabel, MAX_LEAVES } from '../stores/scan.js';
import { useFarmStore } from '../stores/farm.js';
import { previousWeek, nextWeek } from '../helpers/week.js';

const scan = useScanStore(), farm = useFarmStore();
const weekInput = ref(scan.week);
const gallery = ref(null), camera = ref(null), rescanInput = ref(null);
const rescanId = ref(null);
const previews = new Map();

onMounted(async () => {
  await farm.loadLines();
  if (!scan.line && farm.lines.length) scan.select(farm.lines[0], scan.week);
});
onBeforeUnmount(() => { for (const u of previews.values()) URL.revokeObjectURL(u); });

const preview = (leaf) => {
  if (!previews.has(leaf.id)) previews.set(leaf.id, URL.createObjectURL(leaf.file));
  return previews.get(leaf.id);
};
const setLine = (e) => scan.select(e.target.value, scan.week);
const setWeek = (w) => { weekInput.value = w; scan.select(scan.line, w); };
const submitWeek = () => setWeek(weekInput.value.trim().toUpperCase());
const stepWeek = (fn) => { try { setWeek(fn(scan.week)); } catch { /* the invalid-week message is already showing */ } };
const picked = (e) => { scan.addFiles([...e.target.files]); e.target.value = ''; };
const startRescan = (id) => { rescanId.value = id; rescanInput.value.click(); };
const rescanPicked = (e) => { const f = e.target.files[0]; e.target.value = ''; if (f) scan.rescan(rescanId.value, f); };
const status = (l) => ({
  queued: 'Ready', uploading: 'Checking with QA...', failed: 'Failed', confirm: 'Needs your confirmation',
  rescan: 'Retake this leaf', waiting: 'Waiting for QA',
  done: `${outcomeLabel(l.outcome)}${l.stage ? ` (${l.stage})` : ''}`,
}[l.phase]);
const adding = computed(() => !scan.assessing && scan.leaves.length < MAX_LEAVES);
</script>

<template>
  <div class="page">
    <PageHeader title="Disease Detection" subtitle="Scan banana leaves for signs of Black Sigatoka" />

    <section class="card pick">
      <label>Line
        <select :value="scan.line" :disabled="scan.assessing" @change="setLine">
          <option v-if="!farm.lines.length" value="">No lines available</option>
          <option v-for="l in farm.lines" :key="l" :value="l">{{ l }}</option>
        </select>
      </label>
      <form class="week" novalidate @submit.prevent="submitWeek">
        <label>Week
          <input v-model="weekInput" placeholder="2026-W24" :disabled="scan.assessing">
        </label>
        <button type="button" :disabled="!scan.weekOk || scan.assessing" @click="stepWeek(previousWeek)">Previous</button>
        <button type="submit" :disabled="scan.assessing">Go</button>
        <button type="button" :disabled="!scan.weekOk || scan.assessing" @click="stepWeek(nextWeek)">Next</button>
      </form>
      <p v-if="farm.linesError" class="err" role="alert">{{ farm.linesError }}</p>
      <p v-if="!scan.weekOk" class="err" role="alert">That is not a valid week. Use the form 2026-W24.</p>
    </section>

    <section class="card">
      <div class="head">
        <h2>Leaves ({{ scan.leaves.length }}/{{ MAX_LEAVES }})</h2>
        <button v-if="scan.leaves.length" class="link" :disabled="scan.assessing" @click="scan.clear()">Clear all</button>
      </div>
      <p class="hint">Good lighting • Clear leaf • Symptoms visible</p>
      <div class="adders">
        <button :disabled="!adding" @click="camera.click()"><Icon name="scan" /> Take photo</button>
        <button :disabled="!adding" @click="gallery.click()"><Icon name="upload" /> Choose from gallery</button>
      </div>
      <input ref="camera" type="file" accept="image/*" capture="environment" hidden @change="picked">
      <input ref="gallery" type="file" accept="image/*" multiple hidden @change="picked">
      <input ref="rescanInput" type="file" accept="image/*" capture="environment" hidden @change="rescanPicked">
      <p v-if="scan.notice" class="err" role="alert">{{ scan.notice }}</p>
      <p v-if="!scan.leaves.length" class="hint">No leaves added yet.</p>

      <ul class="leaves">
        <li v-for="(l, i) in scan.leaves" :key="l.id" :class="['leaf', l.phase]">
          <img :src="preview(l)" :alt="`Leaf ${i + 1}`">
          <div class="body">
            <strong>Leaf {{ i + 1 }}</strong>
            <span class="status">{{ status(l) }}</span>
            <p v-if="l.error" class="err" role="alert">{{ l.error }}</p>

            <div v-if="l.phase === 'confirm'" class="confirm">
              <p>Do you see these on the leaf?</p>
              <ul class="checks"><li v-for="c in l.checklist" :key="c">{{ c }}</li></ul>
              <button class="primary" @click="scan.confirm(l.id, true)">Yes</button>
              <button @click="scan.confirm(l.id, false)">No</button>
            </div>
            <div v-if="l.phase === 'rescan'" class="confirm">
              <p>QA could not match the symptoms. Take a new photo of the same leaf.</p>
              <button class="primary" @click="startRescan(l.id)">Retake</button>
            </div>
            <p v-if="l.phase === 'done' && l.outcome === 'referral'" class="hint">Refer this leaf to an expert.</p>
          </div>
          <button v-if="!scan.assessing && ['queued', 'failed', 'done'].includes(l.phase)" class="icon-btn" :aria-label="`Remove leaf ${i + 1}`" @click="scan.remove(l.id)"><Icon name="trash" /></button>
        </li>
      </ul>

      <button class="primary wide" :disabled="!scan.canAssess" @click="scan.assess()">
        {{ scan.assessing ? 'Assessing...' : `Assess All Leaves${scan.leaves.length ? ` (${scan.leaves.length})` : ''}` }}
      </button>
    </section>

    <section class="card soon" aria-disabled="true">
      <h2>Not available yet</h2>
      <label class="off">Stage override <select disabled><option>Use QA's stage</option></select></label>
      <label class="off">Treatment history <select disabled><option>Not available yet</option></select></label>
    </section>
  </div>
</template>

<style scoped>
.card { background: var(--card); border: 1px solid var(--line); border-radius: var(--radius-md); box-shadow: var(--shadow); padding: 16px; margin-bottom: 16px; max-width: 720px; display: grid; gap: 12px; }
h2 { font: 800 18px var(--font-display); color: var(--forest); }
.pick, .week { display: flex; flex-wrap: wrap; gap: 8px; align-items: flex-end; }
.pick { display: grid; }
label { display: grid; gap: 4px; font-weight: 700; color: var(--ink-soft); }
input, select, button { padding: 10px 12px; border: 1px solid var(--line); border-radius: var(--radius-sm); background: #fff; }
button:disabled, select:disabled, input:disabled { opacity: .55; cursor: not-allowed; }
button.primary { background: var(--forest); border-color: var(--forest); color: #fff; font-weight: 800; }
button.wide { width: 100%; padding: 14px; }
.head { display: flex; justify-content: space-between; align-items: center; }
.link { border: 0; background: none; color: var(--warn); font-weight: 700; }
.adders { display: flex; flex-wrap: wrap; gap: 8px; }
.adders button { display: inline-flex; align-items: center; gap: 6px; }
.hint { color: var(--ink-soft); }
.err { color: var(--danger); }
.leaves { display: grid; gap: 10px; }
.leaf { display: flex; gap: 12px; align-items: flex-start; padding: 10px; border: 1px solid var(--line); border-radius: var(--radius-sm); }
.leaf img { width: 72px; height: 72px; object-fit: cover; border-radius: 10px; }
.body { flex: 1; display: grid; gap: 4px; }
.status { color: var(--ink-soft); }
.leaf.done .status { color: var(--forest); font-weight: 700; }
.leaf.failed { background: var(--warn-tint); }
.leaf.confirm, .leaf.rescan { background: var(--tint); }
.confirm { display: grid; gap: 6px; justify-items: start; }
.confirm button + button { margin-left: 0; }
.checks { list-style: disc; padding-left: 20px; }
.icon-btn { border: 0; background: none; color: var(--ink-soft); padding: 6px; }
.soon { opacity: .6; }
</style>
