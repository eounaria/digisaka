<script setup>
import { computed, onMounted, ref } from 'vue';
import { RouterLink } from 'vue-router';
import { useCycleStore } from '../stores/cycle.js';
import { useProposalStore } from '../stores/proposal.js';
import EvidenceCharts from './EvidenceCharts.vue';
import SprayLog from './SprayLog.vue';
import WeatherRisk from './WeatherRisk.vue';

const props = defineProps({
  line: { type: String, required: true },
  week: { type: String, required: true },
});
const emit = defineEmits(['back', 'new-scan']);

const cycle = useCycleStore();
const proposalStore = useProposalStore();
const page = ref(0);
const note = ref('');
const PAGES = ['Weather risk', 'Spray log', 'Fungicide options', 'Product details', 'Decision', 'Schedule'];
const proposal = computed(() => proposalStore.proposal);
const treatment = computed(() => proposal.value?.treatment ?? null);
const status = computed(() => proposalStore.status);
const isTerminal = computed(() => ['proposal', 'monitoring', 'review'].includes(cycle.phase));

onMounted(() => {
  if (cycle.phase === 'proposal') loadProposal();
  else proposalStore.reset();
});

async function loadProposal() {
  await proposalStore.load(props.line, props.week);
}

async function closeWeek() {
  await cycle.close(props.line, props.week);
  if (cycle.phase === 'proposal') await loadProposal();
}

async function retryCycle() {
  await cycle.retry();
  if (cycle.phase === 'proposal') await loadProposal();
}

async function resumeCycle() {
  await cycle.resume();
  if (cycle.phase === 'proposal') await loadProposal();
}

async function showOptions() {
  if (cycle.phase === 'proposal' && proposalStore.phase !== 'ready') await loadProposal();
  page.value = 2;
}

async function decide(decision) {
  await proposalStore.decide(decision, note.value);
  if (!proposalStore.error) {
    note.value = '';
    page.value = 5;
  }
}
</script>

<template>
  <section class="journey" aria-label="Treatment review">
    <ol class="journey-steps" aria-label="Treatment review progress">
      <li v-for="(label, index) in PAGES" :key="label" :class="{ active: page === index, done: page > index }">
        <span>{{ page > index ? '✓' : index + 1 }}</span><small>{{ label }}</small>
      </li>
    </ol>

    <template v-if="page === 0">
      <WeatherRisk :line="line" :week="week" :refresh-key="cycle.phase" />
      <div class="nav">
        <button type="button" @click="emit('back')">Back to results</button>
        <button class="primary" type="button" @click="page = 1">Continue to spray log</button>
      </div>
    </template>

    <template v-else-if="page === 1">
      <SprayLog :line="line" :week="week" />
      <section class="card cycle-card" aria-live="polite">
        <h2>Generate this week's treatment assessment</h2>
        <p>Confirming closes {{ week }} for line {{ line }}. No more scans can be added to this week. The scheduler will determine whether a treatment proposal is appropriate.</p>
        <p v-if="cycle.error" class="error" role="alert">{{ cycle.error }}</p>
        <p v-if="cycle.phase === 'closing' || cycle.phase === 'running'" class="hint" role="status">The scheduler is assessing this line-week…</p>
        <p v-if="cycle.phase === 'failed' && cycle.cycle?.failure_reason" class="error" role="alert">{{ cycle.cycle.failure_reason }}</p>
        <p v-else-if="cycle.phase === 'timeout'" class="hint" role="status">The scheduler is taking longer than expected. You can check its status again.</p>
        <p v-else-if="cycle.phase === 'error'" class="error" role="alert">The scheduler status could not be loaded.</p>
        <template v-if="cycle.phase === 'idle'">
          <button class="primary" type="button" :disabled="cycle.busy" @click="closeWeek">Confirm &amp; Schedule</button>
        </template>
        <template v-else-if="cycle.phase === 'failed'">
          <button class="primary" type="button" :disabled="cycle.busy" @click="retryCycle">Retry assessment</button>
        </template>
        <template v-else-if="cycle.phase === 'timeout' || cycle.phase === 'error'">
          <button type="button" :disabled="cycle.busy" @click="resumeCycle">Check status again</button>
        </template>
        <template v-else-if="isTerminal">
          <p v-if="cycle.phase === 'proposal'" class="outcome">The scheduler returned a treatment proposal.</p>
          <p v-else-if="cycle.phase === 'monitoring'" class="outcome">The scheduler recommends continued monitoring; it did not return a treatment proposal.</p>
          <p v-else class="outcome">The scheduler requires human review; it did not return a treatment proposal.</p>
          <button class="primary" type="button" @click="showOptions">Continue to fungicide options</button>
        </template>
      </section>
      <div class="nav"><button type="button" :disabled="cycle.busy" @click="page = 0">Back</button></div>
    </template>

    <template v-else-if="page === 2">
      <section class="card">
        <div class="heading-row"><h2>Fungicide options</h2><span class="badge">Scheduler recommendation</span></div>
        <template v-if="cycle.phase === 'proposal' && proposalStore.phase === 'ready' && proposal">
          <article class="option">
            <div>
              <span class="eyebrow">Returned for this line-week</span>
              <h3>{{ treatment?.name ?? treatment?.id ?? 'Treatment details unavailable' }}</h3>
              <p>{{ proposal.reason }}</p>
            </div>
            <span class="badge selected">Recommended</span>
          </article>
          <p class="hint">The scheduler returned one proposal. It does not provide an alternative-product catalog or product-selection endpoint, so no additional options are shown.</p>
        </template>
        <p v-else-if="proposalStore.phase === 'loading'" class="hint" role="status">Loading the scheduler proposal…</p>
        <p v-else-if="proposalStore.phase === 'error'" class="error" role="alert">{{ proposalStore.error }} <button type="button" @click="loadProposal">Try again</button></p>
        <div v-else class="empty">
          <h3>No fungicide proposal was returned</h3>
          <p>{{ cycle.phase === 'review' ? 'The scheduler requires human review.' : 'The scheduler recommends continued monitoring.' }} Product options are not available for this result.</p>
        </div>
      </section>
      <div class="nav">
        <button type="button" @click="page = 1">Back</button>
        <button class="primary" type="button" :disabled="!proposal" @click="page = 3">Continue to product details</button>
      </div>
    </template>

    <template v-else-if="page === 3">
      <section class="card">
        <h2>Product details</h2>
        <template v-if="proposal">
          <div class="product-title">
            <span class="eyebrow">Scheduler proposal</span>
            <h3>{{ treatment?.name ?? 'Treatment details unavailable' }}</h3>
            <p v-if="treatment?.id">Product ID: {{ treatment.id }}</p>
          </div>
          <div class="detail-grid">
            <div><span>Application window</span><strong>{{ proposal.window?.start ?? '—' }} to {{ proposal.window?.end ?? '—' }}</strong></div>
            <div><span>Next assessment</span><strong>{{ proposal.next_assessment ?? 'Not provided' }}</strong></div>
            <div><span>Active ingredient</span><strong>Not provided</strong></div>
            <div><span>FRAC code / mode</span><strong>Not provided</strong></div>
            <div><span>Rate, price, manufacturer</span><strong>Not provided</strong></div>
            <div><span>Label and registration</span><strong>Not verified</strong></div>
          </div>
          <p class="reason">{{ proposal.reason }}</p>
          <ul v-if="proposal.constraints?.length" class="constraints">
            <li v-for="constraint in proposal.constraints" :key="constraint">{{ constraint }}</li>
          </ul>
          <p class="disclaimer">Do not infer a rate or product eligibility from missing information. Check the registered label and consult an agricultural specialist.</p>
        </template>
        <div v-else class="empty"><p>No product details are available because this cycle returned no treatment proposal.</p></div>
      </section>
      <div class="nav">
        <button type="button" @click="page = 2">Back to options</button>
        <button class="primary" type="button" :disabled="!proposal" @click="page = 4">Continue to decision</button>
      </div>
    </template>

    <template v-else-if="page === 4">
      <section class="card decision-card">
        <div class="heading-row"><h2>Your decision</h2><span class="badge" :class="status">{{ status }}</span></div>
        <template v-if="proposal">
          <h3>{{ treatment?.name ?? 'Treatment details unavailable' }}</h3>
          <p>Line {{ line }} · {{ week }}</p>
          <p v-if="proposal.window">Proposed application window: {{ proposal.window.start }} to {{ proposal.window.end }}</p>
          <p>{{ proposal.reason }}</p>
          <label v-if="status === 'proposed'" class="note-label" for="decision-note">Decision note (optional)</label>
          <textarea v-if="status === 'proposed'" id="decision-note" v-model="note" rows="3" placeholder="Add a note for this decision"></textarea>
          <p v-if="proposalStore.error" class="error" role="alert">{{ proposalStore.error }}</p>
          <p v-if="proposal.decision?.note" class="hint">Saved note: {{ proposal.decision.note }}</p>
          <div v-if="status === 'proposed'" class="decision-actions">
            <button type="button" class="reject" :disabled="proposalStore.busy" @click="decide('rejected')">Reject</button>
            <button type="button" class="primary" :disabled="proposalStore.busy" @click="decide('approved')">Approve</button>
          </div>
          <p v-else class="hint">This proposal has already been {{ status }}. Its decision cannot be changed here.</p>
        </template>
        <div v-else class="empty">
          <h3>No treatment decision is available</h3>
          <p>The scheduler did not return a proposal. Review the scheduler outcome before making treatment decisions.</p>
        </div>
      </section>
      <div class="nav">
        <button type="button" @click="page = 3">Back to product details</button>
        <button v-if="proposal && status !== 'proposed'" class="primary" type="button" @click="page = 5">View schedule status</button>
      </div>
    </template>

    <template v-else>
      <section class="card schedule-card" aria-live="polite">
        <template v-if="proposal && status === 'proposed'">
          <span class="schedule-icon waiting">…</span>
          <h2>Treatment schedule awaiting decision</h2>
          <p>{{ treatment?.name ?? 'Proposed treatment' }} · Line {{ line }} · {{ week }}</p>
          <p v-if="proposal.window">Apply {{ proposal.window.start }} to {{ proposal.window.end }}.</p>
          <button type="button" class="primary" @click="page = 4">Review proposal decision</button>
        </template>
        <template v-else-if="proposal && status === 'approved'">
          <span class="schedule-icon approved">✓</span>
          <h2>Treatment schedule approved</h2>
          <p>{{ treatment?.name ?? 'Approved treatment' }} · Line {{ line }} · {{ week }}</p>
          <p v-if="proposal.window">Apply {{ proposal.window.start }} to {{ proposal.window.end }}.</p>
          <p v-if="proposal.next_assessment">Next assessment: {{ proposal.next_assessment }}</p>
          <RouterLink class="link-button" :to="`/treatment/${encodeURIComponent(line)}/${encodeURIComponent(week)}`">Open full treatment schedule</RouterLink>
        </template>
        <template v-else-if="proposal && status === 'applied'">
          <span class="schedule-icon approved">✓</span>
          <h2>Treatment application recorded</h2>
          <p>{{ treatment?.name ?? 'Recorded treatment' }} · Line {{ line }} · {{ week }}</p>
          <p>Applied on {{ proposalStore.appliedOn }}.</p>
          <RouterLink class="link-button" :to="`/treatment/${encodeURIComponent(line)}/${encodeURIComponent(week)}`">Open full treatment schedule</RouterLink>
        </template>
        <template v-else-if="proposal && status === 'rejected'">
          <span class="schedule-icon review">!</span>
          <h2>Human review required</h2>
          <p>This proposal was rejected. No treatment schedule was approved.</p>
          <p v-if="proposalStore.cycle?.outcome_reason">Reason: {{ proposalStore.cycle.outcome_reason }}</p>
        </template>
        <template v-else-if="cycle.phase === 'review'">
          <span class="schedule-icon review">!</span>
          <h2>Human review required</h2>
          <p>The scheduler did not return a treatment proposal or approved schedule.</p>
        </template>
        <template v-else>
          <span class="schedule-icon waiting">i</span>
          <h2>No treatment schedule was generated</h2>
          <p>The scheduler recommends continued monitoring for this line-week.</p>
        </template>
      </section>
      <EvidenceCharts v-if="cycle.cycle?.cycle_id" :cycle-id="cycle.cycle.cycle_id" />
      <div class="nav">
        <button type="button" @click="page = 4">Back</button>
        <button type="button" @click="emit('new-scan')">New scan</button>
      </div>
    </template>
  </section>
</template>

<style scoped>
.journey { display: grid; gap: 16px; }
.journey-steps { display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: 8px; list-style: none; margin: 0 0 6px; padding: 0; }
.journey-steps li { min-width: 0; display: grid; justify-items: center; gap: 5px; text-align: center; color: var(--ink-soft); }
.journey-steps li span { display: grid; place-items: center; width: 30px; height: 30px; border: 1px solid var(--line); border-radius: 50%; background: var(--card); font-weight: 800; }
.journey-steps li small { font-size: .72rem; }
.journey-steps li.active { color: var(--forest); font-weight: 800; }
.journey-steps li.active span, .journey-steps li.done span { border-color: var(--forest); background: var(--forest); color: #fff; }
.card { padding: 20px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); box-shadow: var(--shadow); }
.card h2 { margin: 0 0 10px; color: var(--forest); font: 800 17px var(--font-display); }
.card p { font-size: .92rem; line-height: 1.5; }
.cycle-card > p:first-of-type { max-width: 850px; }
.heading-row { display: flex; justify-content: space-between; align-items: center; gap: 12px; }
.heading-row h2 { margin: 0; }
.badge { padding: 5px 11px; border-radius: 999px; background: var(--beige); color: var(--ink-soft); font-size: .75rem; font-weight: 800; text-transform: capitalize; }
.badge.selected, .badge.approved { background: var(--tint); color: var(--forest); }
.badge.proposed { background: var(--warn-tint); color: var(--warn); }
.badge.rejected { background: #fbdada; color: var(--danger); }
.option { display: flex; justify-content: space-between; align-items: start; gap: 14px; margin: 16px 0; padding: 16px; border: 1px solid var(--line); border-radius: 12px; background: var(--card); }
.option h3, .product-title h3, .decision-card h3 { margin: 5px 0; color: var(--ink); font-size: 1.05rem; }
.option p { margin-bottom: 0; }
.eyebrow { color: var(--ink-soft); font-size: .75rem; font-weight: 800; letter-spacing: .05em; text-transform: uppercase; }
.hint, .reason { color: var(--ink-soft); }
.empty { padding: 20px; border: 1px dashed var(--line); border-radius: 12px; color: var(--ink-soft); }
.empty h3 { color: var(--ink); }
.product-title { margin: 8px 0 16px; }
.product-title p { color: var(--ink-soft); }
.detail-grid { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 10px; }
.detail-grid > div { display: grid; gap: 5px; padding: 12px; border-radius: 10px; background: var(--tint); }
.detail-grid span { color: var(--ink-soft); font-size: .78rem; }
.detail-grid strong { font-size: .9rem; }
.constraints { padding-left: 20px; }
.disclaimer { padding: 12px; border-radius: 10px; background: var(--beige); color: var(--ink-soft); font-size: .82rem; line-height: 1.45; }
.note-label { display: block; margin: 14px 0 6px; font-size: .85rem; font-weight: 700; }
textarea { display: block; width: 100%; padding: 10px 12px; border: 1px solid var(--line); border-radius: var(--radius-sm); font: inherit; resize: vertical; }
.decision-actions { display: flex; justify-content: flex-end; gap: 10px; margin-top: 16px; }
.decision-actions button { min-width: 120px; }
.reject { background: #fff; border: 1px solid var(--danger); color: var(--danger); }
.error { color: var(--danger); }
.outcome { color: var(--ink-soft); }
.schedule-card { display: grid; justify-items: start; gap: 8px; padding: 24px; }
.schedule-icon { display: grid; place-items: center; width: 42px; height: 42px; border-radius: 50%; font-weight: 800; font-size: 1.25rem; }
.schedule-icon.waiting { background: var(--warn-tint); color: var(--warn); }
.schedule-icon.approved { background: var(--tint); color: var(--forest); }
.schedule-icon.review { background: #fbdada; color: var(--danger); }
.link-button { display: inline-flex; align-items: center; min-height: 42px; padding: 0 16px; border-radius: var(--radius-sm); background: var(--forest); color: #fff; font-weight: 800; text-decoration: none; }
.nav { display: flex; justify-content: space-between; gap: 10px; }
.nav button { min-height: 42px; padding: 8px 14px; border: 1px solid var(--line); border-radius: var(--radius-sm); background: #fff; color: var(--ink); font: 700 14px var(--font-body); }
.nav button.primary, .cycle-card button.primary, .decision-actions button.primary { border-color: var(--forest); background: var(--forest); color: #fff; }
.nav button:disabled, button:disabled { opacity: .55; cursor: not-allowed; }
@media (max-width: 760px) {
  .journey-steps { grid-template-columns: repeat(3, minmax(0, 1fr)); row-gap: 12px; }
  .detail-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
@media (max-width: 520px) {
  .heading-row, .option { flex-direction: column; }
  .detail-grid { grid-template-columns: minmax(0, 1fr); }
  .decision-actions { flex-direction: column; }
  .decision-actions button { width: 100%; min-height: 42px; }
}
</style>
