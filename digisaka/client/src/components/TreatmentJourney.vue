<script setup>
import { computed, onMounted, ref } from 'vue';
import { RouterLink } from 'vue-router';
import { useCycleStore } from '../stores/cycle.js';
import { useProposalStore } from '../stores/proposal.js';
import { usePrototypeStore } from '../stores/prototype.js';
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
const prototypeStore = usePrototypeStore();
const page = ref(0);
const note = ref('');
const PAGES = ['Weather risk', 'Spray log', 'Fungicide options', 'Product details', 'Decision', 'Schedule'];
const proposal = computed(() => proposalStore.proposal);
const treatment = computed(() => proposal.value?.treatment ?? null);
const selectedProduct = computed(() => prototypeStore.data?.products?.find((item) => item.id === prototypeStore.data.selected_option_id) ?? null);
const detailProduct = computed(() => prototypeStore.data?.products?.find((item) => item.id === prototypeStore.data.detail_option_id) ?? selectedProduct.value);
const eligibleProducts = computed(() => prototypeStore.data?.products?.filter((item) => item.eligibility === 'Eligible in prototype data') ?? []);
const excludedProducts = computed(() => prototypeStore.data?.products?.filter((item) => item.eligibility !== 'Eligible in prototype data') ?? []);
const confirmedOptionIds = computed(() => prototypeStore.confirmedOptionIds ?? []);
const isConfirmed = (id) => confirmedOptionIds.value.includes(id);
const confirmedProducts = computed(() => prototypeStore.data?.products?.filter((item) => isConfirmed(item.id)) ?? []);
const status = computed(() => proposalStore.status);
const isTerminal = computed(() => ['proposal', 'monitoring', 'review'].includes(cycle.phase));
const assessing = computed(() => ['closing', 'running'].includes(cycle.phase));

onMounted(() => {
  if (cycle.phase === 'proposal') loadProposal();
  else proposalStore.reset();
  prototypeStore.load(props.line, props.week);
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

function confirmSampleProduct() {
  if (detailProduct.value && prototypeStore.confirmSample(detailProduct.value.id)) page.value = 2;
}

function showProductDetails(optionId) {
  if (prototypeStore.data) prototypeStore.data.detail_option_id = optionId;
  page.value = 3;
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
        <p class="cycle-description">Confirming closes {{ week }} for line {{ line }}. No more scans can be added to this week. The scheduler will determine whether a treatment proposal is appropriate.</p>
        <p v-if="cycle.error" class="error" role="alert">{{ cycle.error }}</p>
        <p v-if="cycle.phase === 'closing' || cycle.phase === 'running'" class="hint" role="status">The scheduler is assessing this line-week…</p>
        <p v-if="cycle.phase === 'failed' && cycle.cycle?.failure_reason" class="error" role="alert">{{ cycle.cycle.failure_reason }}</p>
        <p v-else-if="cycle.phase === 'timeout'" class="hint" role="status">The scheduler is taking longer than expected. You can check its status again.</p>
        <p v-else-if="cycle.phase === 'error'" class="error" role="alert">The scheduler status could not be loaded.</p>
        <template v-if="cycle.phase === 'idle' || assessing">
          <button class="primary journey-cta confirm-button" type="button" :disabled="cycle.busy || assessing" :aria-busy="assessing" @click="closeWeek">
            <span v-if="assessing" class="button-spinner" aria-hidden="true"></span>
            <span v-if="assessing">Assessing this week…</span>
            <span v-else>Confirm &amp; Schedule</span>
          </button>
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
          <button class="primary journey-cta" type="button" @click="showOptions">Continue to fungicide options</button>
        </template>
      </section>
      <div class="nav"><button type="button" :disabled="cycle.busy" @click="page = 0">Back</button></div>
    </template>

    <template v-else-if="page === 2">
      <section class="card">
        <div class="heading-row"><h2>Fungicide options</h2><span class="badge">{{ prototypeStore.enabled ? 'Prototype catalog' : 'Scheduler recommendation' }}</span></div>
        <p v-if="prototypeStore.phase === 'error'" class="error" role="alert">Prototype catalog could not be loaded: {{ prototypeStore.error }}</p>
        <p v-else-if="prototypeStore.phase === 'loading'" class="hint" role="status">Loading prototype catalog…</p>
        <template v-if="prototypeStore.enabled && prototypeStore.data">
          <section class="recommended-action">
            <p class="eyebrow">Recommended action · sample</p>
            <div class="action-chips">
              <span class="action-chip preventive" :class="{ active: prototypeStore.data.recommended_action.preventive }">{{ prototypeStore.data.recommended_action.preventive ? '✓ ' : '' }}Preventive</span>
              <span class="action-chip mechanical" :class="{ active: prototypeStore.data.recommended_action.mechanical }">{{ prototypeStore.data.recommended_action.mechanical ? '✓ ' : '' }}Mechanical</span>
              <span class="action-chip treatment" :class="{ active: prototypeStore.data.recommended_action.treatment }">{{ prototypeStore.data.recommended_action.treatment ? '✓ ' : '' }}Treatment</span>
              <span class="action-chip monitor" :class="{ active: prototypeStore.data.recommended_action.monitor }">{{ prototypeStore.data.recommended_action.monitor ? '✓ ' : '' }}Monitor</span>
              <span class="action-chip provisional">{{ prototypeStore.data.recommended_action.provisional_label }}</span>
            </div>
            <p>{{ prototypeStore.data.recommended_action.summary }}</p>
          </section>
          <div class="catalog-list">
            <p class="sample-disclaimer">{{ prototypeStore.data.label }}</p>
            <div class="catalog-heading">
              <h3>Fungicide options</h3>
              <span>{{ eligibleProducts.length }} eligible · {{ excludedProducts.length }} excluded</span>
            </div>
            <section class="combo-option" aria-label="Recommended prototype combination">
              <div class="combo-heading">
                <div>
                  <span class="eyebrow">Recommended option · prototype only</span>
                  <h3>Two-product sample combination</h3>
                </div>
                <span class="badge selected">Sample pick</span>
              </div>
              <p class="combo-warning">These are two separate sample options grouped for the UI preview. Compatibility has not been assessed; this is not an instruction to mix or apply them.</p>
              <article v-for="product in eligibleProducts" :key="product.id" class="product-option" :class="{ chosen: isConfirmed(product.id) }">
                <div class="product-copy">
                  <span class="eyebrow">{{ product.group }}</span>
                  <h4>{{ product.name }}</h4>
                  <p>{{ product.efficacy }} · {{ product.price }}</p>
                  <p class="product-meta">FRAC {{ product.frac_code }} · {{ product.mobility }}</p>
                </div>
                <div class="option-actions">
                  <span v-if="isConfirmed(product.id)" class="badge selected">In sample selection</span>
                  <button type="button" class="details-button" @click="showProductDetails(product.id)">View details</button>
                </div>
              </article>
            </section>
            <section class="excluded-list" aria-label="Excluded prototype products">
              <div class="excluded-heading">
                <div>
                  <h3>Excluded sample fungicides</h3>
                  <p>These are excluded in the prototype catalog and are not recommended.</p>
                </div>
                <span class="badge rejected">{{ excludedProducts.length }} excluded</span>
              </div>
              <article v-for="product in excludedProducts" :key="product.id" class="excluded-option">
                <div>
                  <h4>{{ product.name }}</h4>
                  <p>FRAC {{ product.frac_code }} · {{ product.resistance_note }}</p>
                </div>
                <span v-if="isConfirmed(product.id)" class="badge rejected">Insisted for preview</span>
                <button type="button" class="details-button" @click="showProductDetails(product.id)">View details</button>
              </article>
            </section>
            <section v-if="confirmedProducts.length" class="confirmed-list" aria-label="Confirmed sample products">
              <h3>Your sample selections <span>{{ confirmedProducts.length }}</span></h3>
              <p>Selections are for UI preview only; they are not sent to or used by the scheduler.</p>
              <ul>
                <li v-for="product in confirmedProducts" :key="product.id">
                  <span>{{ product.name }} <small v-if="product.eligibility !== 'Eligible in prototype data'">· Excluded in sample</small></span>
                  <button type="button" @click="prototypeStore.removeSample(product.id)">Remove</button>
                </li>
              </ul>
            </section>
          </div>
        </template>
        <template v-else-if="cycle.phase === 'proposal' && proposalStore.phase === 'ready' && proposal">
          <article class="option">
            <div>
              <span class="eyebrow">Returned for this line-week</span>
              <h3>{{ treatment?.name ?? treatment?.id ?? 'Treatment details unavailable' }}</h3>
              <p>{{ proposal.reason }}</p>
            </div>
            <span class="badge selected">Recommended</span>
          </article>
          <template v-if="!prototypeStore.enabled">
            <p class="hint">The scheduler returned one proposal. Alternative products are not available.</p>
          </template>
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
        <button v-if="proposal" class="primary" type="button" @click="page = 3">Review scheduler proposal</button>
      </div>
    </template>

    <template v-else-if="page === 3">
      <section class="card">
        <h2>Product details</h2>
        <template v-if="proposal || (prototypeStore.enabled && detailProduct)">
          <div class="product-title">
            <span class="eyebrow">{{ prototypeStore.enabled && detailProduct ? (detailProduct.eligibility === 'Eligible in prototype data' ? 'Eligible sample · details' : 'Excluded sample · details') : 'Scheduler proposal' }}</span>
            <h3>{{ detailProduct?.name ?? treatment?.name ?? 'Treatment details unavailable' }}</h3>
            <p v-if="detailProduct">{{ detailProduct.group }} · FRAC {{ detailProduct.frac_code }}</p>
            <p v-else-if="treatment?.id">Product ID: {{ treatment.id }}</p>
          </div>
          <div class="detail-grid">
            <div><span>Application window</span><strong>{{ proposal?.window?.start ?? '—' }} to {{ proposal?.window?.end ?? '—' }}</strong></div>
            <div><span>Next assessment</span><strong>{{ proposal?.next_assessment ?? 'Not provided' }}</strong></div>
            <div><span>Active ingredient</span><strong>{{ detailProduct?.active_ingredient ?? treatment?.active_ingredient ?? 'Not provided' }}</strong></div>
            <div><span>Formulation / mobility</span><strong>{{ detailProduct ? `${detailProduct.formulation} · ${detailProduct.mobility}` : 'Not provided' }}</strong></div>
            <div><span>FRAC code / mode</span><strong>{{ detailProduct ? `FRAC ${detailProduct.frac_code} · ${detailProduct.mode_of_action}` : treatment?.frac_code ? `FRAC ${treatment.frac_code}` : 'Not provided' }}</strong></div>
            <div><span>Rate / price</span><strong>{{ detailProduct ? `${detailProduct.rate} · ${detailProduct.price}` : 'Not provided' }}</strong></div>
            <div><span>Rainfast / interval</span><strong>{{ detailProduct ? `${detailProduct.rainfast} · ${detailProduct.interval}` : 'Not provided' }}</strong></div>
            <div><span>Label and registration</span><strong>{{ detailProduct ? 'Not verified · sample only' : 'Not verified' }}</strong></div>
          </div>
          <p v-if="detailProduct" class="reason">Resistance note: {{ detailProduct.resistance_note }}</p>
          <p v-if="detailProduct && detailProduct.eligibility !== 'Eligible in prototype data'" class="excluded-warning">
            This product is excluded and not recommended in the prototype. Insisting here records only a local UI selection; it does not make the product eligible or safe to use.
          </p>
          <p v-if="proposal?.reason" class="reason">{{ proposal.reason }}</p>
          <ul v-if="proposal?.constraints?.length" class="constraints">
            <li v-for="constraint in proposal.constraints" :key="constraint">{{ constraint }}</li>
          </ul>
          <p class="disclaimer">{{ detailProduct ? prototypeStore.data.label : 'Do not infer a rate or product eligibility from missing information. Check the registered label and consult an agricultural specialist.' }}</p>
          <p v-if="!proposal" class="hint">Sample product details are for layout preview only. Confirmations remain local and do not update a proposal.</p>
          <button v-if="prototypeStore.enabled && detailProduct" type="button" class="journey-cta sample-confirm" :class="{ 'insist-button': detailProduct.eligibility !== 'Eligible in prototype data' }" @click="confirmSampleProduct">
            {{ detailProduct.eligibility === 'Eligible in prototype data' ? 'Confirm for sample preview' : 'Insist on excluded sample option' }}
          </button>
          <p v-if="detailProduct && isConfirmed(detailProduct.id)" class="confirmed-message" role="status">This product is already in your sample selection.</p>
        </template>
        <div v-else class="empty"><p>No product details are available because this cycle returned no treatment proposal.</p></div>
      </section>
      <div class="nav">
        <button type="button" @click="page = 2">Back to options</button>
        <button v-if="proposal" class="primary" type="button" @click="page = 4">Continue to decision</button>
      </div>
    </template>

    <template v-else-if="page === 4">
      <section class="card decision-card">
        <div class="heading-row"><h2>Your decision</h2><span class="badge" :class="status">{{ status }}</span></div>
        <template v-if="proposal">
          <h3>{{ selectedProduct?.name ?? treatment?.name ?? 'Treatment details unavailable' }}</h3>
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
.cycle-card { display: grid; gap: 12px; }
.cycle-card h2 { margin-bottom: 0; }
.cycle-card .cycle-description { margin: 0; }
.journey-steps { display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: 8px; list-style: none; margin: 0 0 6px; padding: 0; }
.journey-steps li { min-width: 0; display: grid; justify-items: center; gap: 5px; text-align: center; color: var(--ink-soft); }
.journey-steps li span { display: grid; place-items: center; width: 30px; height: 30px; border: 1px solid var(--line); border-radius: 50%; background: var(--card); font-weight: 800; }
.journey-steps li small { font-size: .72rem; }
.journey-steps li.active { color: var(--forest); font-weight: 800; }
.journey-steps li.active span, .journey-steps li.done span { border-color: var(--forest); background: var(--forest); color: #fff; }
.card { padding: 20px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); box-shadow: var(--shadow); }
.card h2 { margin: 0 0 10px; color: var(--forest); font: 800 17px var(--font-display); }
.card p { font-size: .92rem; line-height: 1.5; }
.cycle-description { max-width: none; }
.heading-row { display: flex; justify-content: space-between; align-items: center; gap: 12px; }
.heading-row h2 { margin: 0; }
.badge { padding: 5px 11px; border-radius: 999px; background: var(--beige); color: var(--ink-soft); font-size: .75rem; font-weight: 800; text-transform: capitalize; }
.badge.selected, .badge.approved { background: var(--tint); color: var(--forest); }
.badge.proposed { background: var(--warn-tint); color: var(--warn); }
.badge.rejected { background: #fbdada; color: var(--danger); }
.option { display: flex; justify-content: space-between; align-items: start; gap: 14px; margin: 16px 0; padding: 16px; border: 1px solid var(--line); border-radius: 12px; background: var(--card); }
.option.chosen { border-color: var(--forest); box-shadow: inset 0 0 0 1px var(--forest); }
.combo-option, .excluded-list, .confirmed-list { display: grid; gap: 12px; padding: 16px; border: 1px solid var(--line); border-radius: 14px; background: var(--card); }
.combo-option { border: 2px solid var(--forest); }
.combo-heading, .excluded-heading { display: flex; justify-content: space-between; align-items: start; gap: 12px; }
.combo-heading h3, .excluded-heading h3, .confirmed-list h3 { margin: 3px 0 0; color: var(--ink); font-size: 1rem; }
.combo-warning, .excluded-heading p, .confirmed-list > p { color: var(--ink-soft); font-size: .82rem !important; line-height: 1.45; }
.product-option, .excluded-option { display: flex; justify-content: space-between; align-items: center; gap: 14px; padding: 14px; border: 1px solid var(--line); border-radius: 12px; background: #fff; transition: border-color .15s, box-shadow .15s, transform .15s; }
.product-option:hover, .excluded-option:hover { border-color: var(--leaf); box-shadow: 0 4px 12px rgba(16, 24, 40, .1); transform: translateY(-1px); }
.product-option.chosen { border-color: var(--forest); box-shadow: inset 0 0 0 1px var(--forest); }
.product-copy { min-width: 0; }
.product-option h4, .excluded-option h4 { margin: 4px 0; color: var(--ink); font-size: .95rem; }
.product-option p, .excluded-option p { margin: 0; font-size: .84rem; line-height: 1.45; }
.excluded-list { border-color: #efc7c7; background: #fffdfd; }
.excluded-option { border-color: #f0dddd; }
.confirmed-list { background: #f6fbf7; }
.confirmed-list h3 span { display: inline-grid; place-items: center; min-width: 23px; height: 23px; margin-left: 4px; padding: 0 5px; border-radius: 999px; background: var(--tint); color: var(--forest); font-size: .78rem; }
.confirmed-list ul { display: grid; gap: 6px; }
.confirmed-list li { display: flex; justify-content: space-between; align-items: center; gap: 10px; padding: 8px 0; border-top: 1px solid var(--line); }
.confirmed-list li small { color: var(--danger); }
.confirmed-list li button { border: 0; background: transparent; color: var(--forest); font-weight: 800; text-decoration: underline; }
.catalog-list { display: grid; gap: 10px; }
.recommended-action { display: grid; gap: 10px; margin: 14px 0 18px; padding: 14px; border: 1px solid var(--line); border-radius: 12px; background: #f8faf8; }
.recommended-action > p:last-child { margin: 0; }
.action-chips { display: flex; flex-wrap: wrap; gap: 7px; }
.action-chip { padding: 5px 10px; border: 1px solid #aeb8b1; border-radius: 999px; color: var(--ink-soft); font-size: .75rem; font-weight: 800; }
.action-chip.preventive.active { border-color: #0b4f8a; background: #dcefff; color: #0b4f8a; }
.action-chip.mechanical.active { border-color: #0b5a1f; background: #e3f4e6; color: #0b5a1f; }
.action-chip.treatment.active { border-color: var(--warn); background: var(--warn-tint); color: var(--warn); }
.action-chip.monitor.active { border-color: var(--forest); background: var(--tint); color: var(--forest); }
.action-chip.provisional { border: 0; background: var(--beige); }
.catalog-heading { display: flex; justify-content: space-between; align-items: baseline; gap: 10px; }
.catalog-heading h3 { margin: 0; color: var(--forest); font: 800 1rem var(--font-display); }
.catalog-heading span { color: var(--ink-soft); font-size: .8rem; }
.sample-disclaimer { padding: 10px 12px; border-radius: 10px; background: #e5e7eb; color: #374151; font-size: .82rem; font-weight: 700; }
.product-meta { color: var(--ink-soft); font-size: .82rem !important; }
.option-actions { display: grid; justify-items: end; gap: 8px; }
.option-actions button { min-height: 38px; padding: 6px 12px; border: 1px solid var(--line); border-radius: var(--radius-sm); background: #fff; color: var(--ink); font-weight: 700; cursor: pointer; }
.option-actions .details-button { border: 0; color: var(--forest); text-decoration: underline; }
.excluded { padding: 12px; border-radius: 10px; background: var(--beige); font-size: .85rem; }
.excluded summary { cursor: pointer; font-weight: 700; }
.excluded ul { padding-left: 20px; color: var(--ink-soft); line-height: 1.6; }
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
.excluded-warning { padding: 12px; border-radius: 10px; background: #fbdada; color: #7a1515; font-size: .84rem !important; line-height: 1.5; }
.confirmed-message { color: var(--forest); font-size: .85rem !important; font-weight: 800; }
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
.journey-cta { display: inline-flex; min-height: 44px; align-items: center; justify-content: center; gap: 10px; padding: 0 18px; border: 1px solid var(--forest); border-radius: var(--radius-sm); background: var(--forest); color: #fff; font: 800 14px var(--font-body); text-align: center; transition: background .15s, box-shadow .15s, transform .15s; }
.journey-cta:hover:not(:disabled) { background: var(--forest-deep); box-shadow: 0 4px 12px rgba(6, 85, 44, .2); transform: translateY(-1px); }
.sample-confirm { align-self: start; }
.insist-button { border-color: #a92c2c; background: #a92c2c; }
.insist-button:hover:not(:disabled) { background: #7a1515; }
.confirm-button { box-shadow: 0 3px 9px rgba(6, 85, 44, .16); }
.button-spinner { width: 17px; height: 17px; border: 2px solid rgba(255,255,255,.4); border-top-color: #fff; border-radius: 50%; animation: button-spin .8s linear infinite; }
@keyframes button-spin { to { transform: rotate(360deg); } }
@media (max-width: 760px) {
  .journey-steps { grid-template-columns: repeat(3, minmax(0, 1fr)); row-gap: 12px; }
  .detail-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
@media (max-width: 520px) {
  .heading-row, .option { flex-direction: column; }
  .product-option, .excluded-option, .combo-heading, .excluded-heading { align-items: stretch; flex-direction: column; }
  .option-actions { justify-items: stretch; }
  .journey-cta { width: 100%; }
  .detail-grid { grid-template-columns: minmax(0, 1fr); }
  .decision-actions { flex-direction: column; }
  .decision-actions button { width: 100%; min-height: 42px; }
}
</style>
