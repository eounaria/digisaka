<script setup>
import { reactive, ref, computed, watch } from 'vue';
import { useRoute, useRouter, RouterLink } from 'vue-router';
import PageHeader from '../components/PageHeader.vue';
import { scheduler } from '../scheduler/session.js';
import { createScanFlow, sessionLabel } from '../scheduler/scanFlow.js';
import { fileToPayload } from '../scheduler/image.js';
import { isValidWeek, isoWeekOf, previousWeek, nextWeek } from '../scheduler/week.js';

const route = useRoute(), router = useRouter();
const line = computed(() => String(route.params.lineId));
const week = computed(() => (typeof route.query.week === 'string' ? route.query.week : isoWeekOf(new Date())));
const weekInput = ref(week.value);
const weekOk = computed(() => isValidWeek(week.value));
const picked = ref(null), fileError = ref(''), fileInput = ref(null);

// One flow per line-week with its own state, so a request still in flight for the previous one cannot write into the new one.
const make = () => createScanFlow({ client: scheduler, line: line.value, week: week.value, state: reactive({}) });
const flow = ref(make());
const state = computed(() => flow.value.state);
function start() {
  flow.value = make();
  weekInput.value = week.value;
  if (weekOk.value) flow.value.refresh();
}
start();
function goWeek(w) { router.push({ query: { week: w } }); }
function submitWeek() { goWeek(weekInput.value.trim().toUpperCase()); }

async function upload() {
  fileError.value = '';
  if (!picked.value) { fileError.value = 'Choose a leaf image first.'; return; }
  const f = flow.value;
  try {
    await f.upload(await fileToPayload(picked.value));
    if (!f.state.error) { picked.value = null; if (fileInput.value) fileInput.value.value = ''; }
  } catch (e) { fileError.value = e.message; }
}
const canUpload = computed(() => state.value.phase !== 'confirm' && !state.value.cycle);
const canClose = computed(() => !state.value.cycle && state.value.phase !== 'confirm' && (state.value.sessions ?? []).some((s) => s.finished));
async function close() {
  if (!confirm(`Close ${week.value} for line ${line.value}? No more scans can be added.`)) return;
  const f = flow.value;
  await f.close();
  if (f === flow.value && f.state.cycle) router.push(`/qa/cycles/${encodeURIComponent(f.state.cycle.cycle_id)}`);
}

watch(() => [line.value, week.value], start);
</script>

<template>
  <PageHeader :title="`Line ${line}`" :subtitle="`Week ${week}`"><RouterLink to="/qa">All lines</RouterLink></PageHeader>

  <form class="week" novalidate @submit.prevent="submitWeek">
    <button type="button" :disabled="!weekOk" @click="goWeek(previousWeek(week))">Previous</button>
    <input v-model="weekInput" aria-label="Week" placeholder="2026-W24">
    <button type="submit">Go</button>
    <button type="button" :disabled="!weekOk" @click="goWeek(nextWeek(week))">Next</button>
  </form>
  <p v-if="!weekOk" class="err" role="alert">That is not a valid week. Use the form 2026-W24.</p>

  <template v-else>
    <div class="err" role="alert">{{ state.error || fileError }}</div>

    <section v-if="canUpload" class="card">
      <h2>{{ state.phase === 'rescan' ? 'Re-scan this leaf' : 'Scan a leaf' }}</h2>
      <p v-if="state.phase === 'rescan'">QA could not match the symptoms. Upload a new photo of the same leaf.</p>
      <input ref="fileInput" type="file" accept="image/*" aria-label="Leaf image" @change="picked = $event.target.files[0] ?? null">
      <button class="primary" :disabled="state.busy" @click="upload">{{ state.busy ? 'Uploading...' : 'Upload' }}</button>
      <p v-if="state.phase === 'done'" class="result">Result: {{ sessionLabel({ outcome: state.outcome, stage: state.stage }) }}</p>
    </section>

    <section v-if="state.phase === 'confirm'" class="card">
      <h2>Confirm symptoms{{ state.stage ? ` (${state.stage})` : '' }}</h2>
      <p>Do you see these on the leaf?</p>
      <ul><li v-for="s in state.checklist" :key="s">{{ s }}</li></ul>
      <button class="primary" :disabled="state.busy" @click="flow.value.confirm(true)">Yes</button>
      <button :disabled="state.busy" @click="flow.value.confirm(false)">No</button>
    </section>

    <section class="card">
      <h2>Close the week</h2>
      <template v-if="state.cycle">
        <p>This week is closed.</p>
        <RouterLink :to="`/qa/cycles/${encodeURIComponent(state.cycle.cycle_id)}`">View the cycle</RouterLink>
      </template>
      <template v-else>
        <p>Close the week when all leaves are scanned. This starts the treatment cycle.</p>
        <button class="primary" :disabled="!canClose || state.busy" @click="close">Close week</button>
      </template>
    </section>

    <section class="card">
      <h2>Sessions so far</h2>
      <p v-if="!state.sessions?.length">No scans yet this week.</p>
      <ul v-else><li v-for="s in state.sessions" :key="s.qa_output_id">{{ sessionLabel(s) }}</li></ul>
    </section>
  </template>
</template>

<style scoped>
.week { display: flex; gap: 8px; margin-bottom: 16px; }
.card { background: var(--card); border: 1px solid var(--line); border-radius: var(--radius-md); box-shadow: var(--shadow); padding: 16px; margin-bottom: 16px; max-width: 520px; display: grid; gap: 8px; }
</style>
