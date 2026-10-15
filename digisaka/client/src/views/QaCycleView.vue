<script setup>
import { reactive, ref, computed, watch, onBeforeUnmount } from 'vue';
import { useRoute, RouterLink } from 'vue-router';
import PageHeader from '../components/PageHeader.vue';
import { scheduler } from '../scheduler/session.js';
import { createCycleFlow } from '../scheduler/cycleFlow.js';

const route = useRoute();
const cycleId = computed(() => String(route.params.cycleId));
const note = ref(''), appliedOn = ref(new Date().toISOString().slice(0, 10));

// One flow per cycle with its own state; the old one stops polling when the cycle changes or the screen closes.
const flow = ref(null);
const state = computed(() => flow.value.state);
function start() {
  flow.value?.stop();
  flow.value = createCycleFlow({ client: scheduler, cycleId: cycleId.value, state: reactive({}) });
  flow.value.start();
}
start();
watch(cycleId, start);
onBeforeUnmount(() => flow.value.stop());

const back = computed(() => (state.value.cycle ? `/qa/lines/${encodeURIComponent(state.value.cycle.line_id)}?week=${encodeURIComponent(state.value.cycle.week)}` : '/qa'));
</script>

<template>
  <PageHeader title="Treatment cycle" :subtitle="state.cycle ? `Line ${state.cycle.line_id}, week ${state.cycle.week}` : ''"><RouterLink :to="back">Back to the line</RouterLink></PageHeader>
  <div class="err" role="alert">{{ state.error }}</div>

  <section v-if="state.phase === 'loading' || state.phase === 'running'" class="card">
    <h2>Working out a treatment...</h2>
    <p>This usually takes under a minute.</p>
  </section>

  <section v-else-if="state.phase === 'timeout'" class="card">
    <h2>This is taking too long</h2>
    <p>The cycle did not finish in time. It may still complete.</p>
    <button class="primary" @click="start">Check again</button>
  </section>

  <section v-else-if="state.phase === 'error'" class="card">
    <h2>Could not load the cycle</h2>
    <button class="primary" @click="start">Try again</button>
  </section>

  <section v-else-if="state.phase === 'failed'" class="card">
    <h2>The cycle failed</h2>
    <p v-if="state.cycle.failure_reason">Reason: {{ state.cycle.failure_reason }}</p>
    <button class="primary" :disabled="state.busy" @click="flow.retry()">Retry</button>
  </section>

  <section v-else-if="state.phase === 'review'" class="card">
    <h2>Human review required</h2>
    <p>No treatment is proposed for this week. An expert needs to look at this line.</p>
    <p v-if="state.cycle?.outcome_reason">Reason: {{ state.cycle.outcome_reason }}</p>
  </section>

  <template v-else-if="state.proposal">
    <section class="card">
      <h2>{{ state.proposal.treatment.name ?? state.proposal.treatment.id }}</h2>
      <p>Apply between {{ state.proposal.window.start }} and {{ state.proposal.window.end }}.</p>
      <p>{{ state.proposal.reason }}</p>
      <template v-if="state.proposal.constraints?.length"><h3>Constraints</h3><ul><li v-for="c in state.proposal.constraints" :key="c">{{ c }}</li></ul></template>
      <p>Next assessment: {{ state.proposal.next_assessment }}</p>
    </section>

    <section v-if="state.phase === 'proposal'" class="card">
      <h2>Your decision</h2>
      <label for="note">Note (optional)</label><input id="note" v-model="note">
      <div class="row">
        <button class="primary" :disabled="state.busy" @click="flow.decide('approved', note || undefined)">Approve</button>
        <button :disabled="state.busy" @click="flow.decide('rejected', note || undefined)">Reject</button>
      </div>
    </section>
    <section v-else-if="state.phase === 'rejected'" class="card"><h2>Rejected</h2><p>This proposal was rejected. The line needs human review.</p></section>
    <section v-else-if="state.phase === 'approved'" class="card">
      <h2>Approved: record the application</h2>
      <label for="applied">Date applied</label><input id="applied" v-model="appliedOn" type="date">
      <button class="primary" :disabled="state.busy" @click="flow.apply(appliedOn)">Record application</button>
    </section>
    <section v-else-if="state.phase === 'applied'" class="card"><h2>Applied</h2><p>Recorded on {{ state.appliedOn }}.</p></section>
  </template>
</template>

<style scoped>
.card { background: var(--card); border: 1px solid var(--line); border-radius: var(--radius-md); box-shadow: var(--shadow); padding: 16px; margin-bottom: 16px; max-width: 520px; display: grid; gap: 8px; }
.row { display: flex; gap: 8px; }
</style>
