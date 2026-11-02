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
const sampleDecision = ref('');
const PAGES = ['Weather', 'Spray log', 'Fungicides', 'Decision', 'Schedule'];
const activeStep = computed(() => page.value <= 1 ? page.value : page.value <= 3 ? 2 : page.value - 1);
const pageTitle = computed(() => {
  if (page.value === 0) return 'Weather risk';
  if (page.value === 1) return 'Spray log';
  if (page.value === 2) return 'Fungicide options';
  if (page.value === 3) return 'Fungicide details';
  if (page.value === 4) return 'Decision';
  return sampleDecision.value ? 'Decision status' : 'Treatment schedule';
});
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
  if (detailProduct.value && prototypeStore.confirmSample(detailProduct.value.id)) {
    sampleDecision.value = '';
    page.value = 2;
  }
}

function removeSampleProduct(optionId) {
  prototypeStore.removeSample(optionId);
  sampleDecision.value = '';
}

function decideSample(decision) {
  sampleDecision.value = decision;
  page.value = 5;
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
    <header class="journey-page-header">
      <div>
        <h1>{{ pageTitle }}</h1>
        <p>Line {{ line }} · {{ week }}</p>
      </div>
      <span v-if="page === 5 && sampleDecision" class="journey-status" :class="sampleDecision">
        {{ sampleDecision === 'approved' ? 'Sample approved' : 'Sample rejected' }}
      </span>
      <span v-else-if="page === 5 && proposal" class="journey-status" :class="status">
        {{ status === 'proposed' ? 'Awaiting your decision' : status }}
      </span>
    </header>
    <ol class="journey-steps" aria-label="Treatment review progress">
      <li v-for="(label, index) in PAGES" :key="label" :class="{ active: activeStep === index, done: activeStep > index }">
        <span>{{ activeStep > index ? '✓' : index + 1 }}</span><small>{{ label }}</small>
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
      <section class="fungicide-page">
        <div class="heading-row"><h2>Fungicide options</h2><span class="badge">{{ prototypeStore.enabled ? 'Prototype catalog' : 'Scheduler recommendation' }}</span></div>
        <p v-if="prototypeStore.phase === 'error'" class="error" role="alert">Prototype catalog could not be loaded: {{ prototypeStore.error }}</p>
        <p v-else-if="prototypeStore.phase === 'loading'" class="hint" role="status">Loading prototype catalog…</p>
        <template v-if="prototypeStore.enabled && prototypeStore.data">
          <div class="fungicide-layout">
            <main class="catalog-main">
              <p class="sample-disclaimer">{{ prototypeStore.data.label }}</p>
              <div class="catalog-heading">
                <h3>Fungicide options</h3>
                <span>{{ eligibleProducts.length }} eligible · {{ excludedProducts.length }} excluded</span>
              </div>
              <section class="combo-option" aria-label="Recommended prototype combination">
              <div class="combo-heading">
                <div>
                  <h3>Group A: contact, multi-site protectants</h3>
                  <p>Two separate products in this sample group · prototype only</p>
                </div>
                <span class="badge selected">Recommended</span>
              </div>
              <p class="combo-warning">These are separate product choices, not a combination to mix. Compatibility has not been assessed, and this is not application guidance.</p>
              <div class="combination-products">
                <button v-for="product in eligibleProducts" :key="product.id" type="button" class="product-option" :class="{ chosen: isConfirmed(product.id) }" :aria-label="`View details for ${product.name}`" @click="showProductDetails(product.id)">
                  <span class="product-copy">
                    <span class="product-name">{{ product.name }}</span>
                    <span class="product-meta">
                      <span class="product-price">{{ product.price }}</span>
                      <span class="frac-label">FRAC {{ product.frac_code }}</span>
                      <span>{{ product.mobility }}</span>
                    </span>
                  </span>
                  <span class="product-action">
                    <span v-if="isConfirmed(product.id)" class="selection-state">Selected</span>
                    <span class="product-link" aria-hidden="true">View details <b>→</b></span>
                  </span>
                </button>
              </div>
              </section>
              <section class="excluded-list" aria-label="Excluded prototype products">
              <div class="excluded-heading">
                <div>
                  <span class="eyebrow">Use caution</span>
                  <h3>Excluded FRAC groups</h3>
                  <p>Restricted in this sample history and not recommended.</p>
                </div>
                <span class="badge rejected">{{ excludedProducts.length }} excluded</span>
              </div>
              <div class="excluded-products">
                <button v-for="product in excludedProducts" :key="product.id" type="button" class="excluded-option" :aria-label="`View excluded product details for ${product.name}`" @click="showProductDetails(product.id)">
                  <span class="excluded-mark" aria-hidden="true">!</span>
                  <span class="excluded-copy">
                    <span class="product-name">{{ product.name }}</span>
                    <span class="product-meta"><span class="frac-label">FRAC {{ product.frac_code }}</span> · {{ product.resistance_note }}</span>
                  </span>
                  <span class="product-action">
                    <span v-if="isConfirmed(product.id)" class="selection-state insisted">Insisted</span>
                    <span class="product-link" aria-hidden="true">View details <b>→</b></span>
                  </span>
                </button>
              </div>
              </section>
            </main>
            <aside class="fungicide-sidebar">
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
              <section v-if="confirmedProducts.length" class="confirmed-list" aria-label="Confirmed sample products">
              <h3>Your sample selections <span>{{ confirmedProducts.length }}</span></h3>
              <p>Selections are for UI preview only; they are not sent to or used by the scheduler.</p>
              <ul>
                <li v-for="product in confirmedProducts" :key="product.id">
                  <span>{{ product.name }} <small v-if="product.eligibility !== 'Eligible in prototype data'">· Excluded in sample</small></span>
                  <button type="button" class="text-action" @click="removeSampleProduct(product.id)">Remove</button>
                </li>
              </ul>
              </section>
              <div v-if="confirmedProducts.length" class="options-continue">
                <p>Review your sample selections and record a prototype-only decision.</p>
                <button type="button" class="journey-cta" @click="page = 4">Continue to decision</button>
              </div>
            </aside>
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
      <section class="card product-detail-page">
        <div class="heading-row product-page-heading">
          <div>
            <span class="eyebrow">Fungicide details</span>
            <h2>Product information</h2>
          </div>
          <span class="badge" :class="detailProduct?.eligibility === 'Eligible in prototype data' ? 'selected' : detailProduct ? 'rejected' : 'proposed'">
            {{ detailProduct ? (detailProduct.eligibility === 'Eligible in prototype data' ? 'Sample catalog' : 'Excluded sample') : 'Scheduler proposal' }}
          </span>
        </div>
        <template v-if="proposal || (prototypeStore.enabled && detailProduct)">
          <div class="product-detail-layout">
            <div class="product-detail-main">
              <section class="detail-section product-identity">
                <div class="product-name-row">
                  <h3>{{ detailProduct?.name ?? treatment?.name ?? 'Treatment details unavailable' }}</h3>
                  <span v-if="detailProduct" class="badge muted">Sample data</span>
                </div>
                <p v-if="detailProduct" class="product-category">{{ detailProduct.group }} <span>·</span> FRAC {{ detailProduct.frac_code }}</p>
                <p v-else-if="treatment?.id" class="product-category">Product ID: {{ treatment.id }}</p>
                <div class="detail-rows">
                  <div class="detail-row"><span>Manufacturer</span><strong>{{ detailProduct?.manufacturer ?? 'Not recorded' }}</strong></div>
                  <div class="detail-row"><span>Formulation</span><strong>{{ detailProduct?.formulation ?? treatment?.formulation ?? 'Not provided' }}</strong></div>
                  <div class="detail-row"><span>Price</span><strong>{{ detailProduct?.price ?? 'Not provided' }}</strong></div>
                </div>
              </section>

              <section v-if="detailProduct" class="detail-section resistance-card" :class="{ 'is-excluded': detailProduct.eligibility !== 'Eligible in prototype data' }">
                <p class="section-kicker">{{ detailProduct.eligibility !== 'Eligible in prototype data' ? 'Eligibility caution' : 'Resistance caution' }}</p>
                <p>{{ detailProduct.eligibility !== 'Eligible in prototype data' ? `This product is excluded in the prototype catalog and is not recommended. Insisting records only a local preview selection; it does not make the product eligible or safe to use. ${detailProduct.resistance_note}` : detailProduct.resistance_note }}</p>
              </section>
              <p v-else-if="proposal?.reason" class="detail-section proposal-reason">{{ proposal.reason }}</p>

              <section class="detail-section">
                <h3 class="detail-section-title">Identity and classification</h3>
                <div class="detail-rows">
                  <div class="detail-row"><span>Active ingredient</span><strong>{{ detailProduct?.active_ingredient ?? treatment?.active_ingredient ?? 'Not provided' }}</strong></div>
                  <div class="detail-row"><span>Chemical group</span><strong>{{ detailProduct?.chemical_group ?? 'Not provided' }}</strong></div>
                  <div class="detail-row"><span>FRAC code</span><strong>{{ detailProduct ? detailProduct.frac_code : treatment?.frac_code ?? 'Not provided' }}</strong></div>
                  <div class="detail-row"><span>Mode of action</span><strong>{{ detailProduct?.mode_of_action ?? treatment?.mode_of_action ?? 'Not provided' }}</strong></div>
                </div>
                <p class="mobility-label">Plant mobility</p>
                <div class="mobility-pills">
                  <span class="mobility-pill" :class="{ active: detailProduct?.mobility === 'Contact' }">Contact</span>
                  <span class="mobility-pill" :class="{ active: detailProduct?.mobility === 'Translaminar' }">Translaminar</span>
                  <span class="mobility-pill" :class="{ active: detailProduct?.mobility === 'Locally systemic' }">Locally systemic</span>
                  <span class="mobility-pill" :class="{ active: detailProduct?.mobility === 'Systemic' }">Systemic</span>
                </div>
              </section>

              <section class="detail-section usage-section">
                <h3 class="detail-section-title">Use information</h3>
                <div class="detail-rows">
                  <div class="detail-row"><span>Rate</span><strong>{{ detailProduct?.rate ?? 'Not provided' }}</strong></div>
                  <div class="detail-row"><span>Rainfast period</span><strong>{{ detailProduct?.rainfast ?? 'Not provided' }}</strong></div>
                  <div class="detail-row"><span>Application interval</span><strong>{{ detailProduct?.interval ?? 'Not provided' }}</strong></div>
                  <div class="detail-row"><span>Application window</span><strong>{{ proposal?.window ? `${proposal.window.start} to ${proposal.window.end}` : 'Not provided' }}</strong></div>
                  <div class="detail-row"><span>Next assessment</span><strong>{{ proposal?.next_assessment ?? 'Not provided' }}</strong></div>
                </div>
              </section>
            </div>

            <aside class="product-detail-aside" aria-label="Eligibility and product actions">
              <section class="detail-section eligibility-card">
                <h3 class="detail-section-title">Eligibility checks</h3>
                <div class="eligibility-row">
                  <span>Label and registration</span>
                  <span class="badge rejected">Unverified</span>
                </div>
                <div class="eligibility-row">
                  <span>Application constraints</span>
                  <span class="badge proposed">Pending</span>
                </div>
                <div class="eligibility-row">
                  <span>FRAC history</span>
                  <span class="badge" :class="detailProduct?.eligibility === 'Eligible in prototype data' ? 'selected' : 'rejected'">
                    {{ detailProduct ? (detailProduct.eligibility === 'Eligible in prototype data' ? 'Sample check passed' : 'Excluded') : 'Not assessed' }}
                  </span>
                </div>
              </section>

              <div v-if="detailProduct" class="detail-actions">
                <p class="sample-note">{{ prototypeStore.data.label }}</p>
                <p v-if="!proposal" class="sample-note">Confirmations stay local to this prototype preview; they do not update a proposal or schedule.</p>
                <button type="button" class="journey-cta sample-confirm" :class="{ 'insist-button': detailProduct.eligibility !== 'Eligible in prototype data' }" @click="confirmSampleProduct">
                  {{ detailProduct.eligibility === 'Eligible in prototype data' ? 'Confirm sample selection' : 'Insist on excluded option' }}
                </button>
                <p v-if="isConfirmed(detailProduct.id)" class="confirmed-message" role="status">This product is in your sample selection.</p>
              </div>
              <p v-else class="sample-note">Verify the registered label and consult an agricultural specialist before making treatment decisions.</p>
            </aside>
          </div>
          <ul v-if="proposal?.constraints?.length" class="constraints">
            <li v-for="constraint in proposal.constraints" :key="constraint">{{ constraint }}</li>
          </ul>
        </template>
        <div v-else class="empty"><p>No product details are available because this cycle returned no treatment proposal.</p></div>
      </section>
      <div class="nav">
        <button type="button" @click="page = 2">Back to options</button>
        <button v-if="proposal" class="primary" type="button" @click="page = 4">Continue to decision</button>
      </div>
    </template>

    <template v-else-if="page === 4">
      <section class="decision-page">
        <template v-if="prototypeStore.enabled && confirmedProducts.length">
          <div class="heading-row">
            <div>
              <span class="eyebrow">Prototype preview</span>
              <h2>Your decision</h2>
            </div>
            <span class="badge proposed">Not a scheduler decision</span>
          </div>
          <div class="decision-layout">
            <div class="decision-main">
              <div class="decision-details-grid">
                <section class="detail-section decision-selection">
                  <p class="section-kicker">Selected products · sample only</p>
                  <div v-for="product in confirmedProducts" :key="product.id" class="decision-product">
                    <div>
                      <strong>{{ product.name }}</strong>
                      <span>FRAC {{ product.frac_code }} · {{ product.mobility }}</span>
                    </div>
                    <span class="badge" :class="product.eligibility === 'Eligible in prototype data' ? 'selected' : 'rejected'">
                      {{ product.eligibility === 'Eligible in prototype data' ? 'Sample eligible' : 'Excluded' }}
                    </span>
                    <p v-if="product.eligibility !== 'Eligible in prototype data'" class="decision-product-warning">{{ product.resistance_note }} Not recommended.</p>
                  </div>
                  <p class="sample-note">Compatibility, label eligibility, rates, and timing are not verified. These selections are not an application recommendation.</p>
                </section>
                <section class="detail-section decision-recommendation">
                  <p class="section-kicker">Recommended action · sample</p>
                  <div class="action-chips">
                    <span class="action-chip preventive" :class="{ active: prototypeStore.data?.recommended_action?.preventive }">Preventive</span>
                    <span class="action-chip mechanical" :class="{ active: prototypeStore.data?.recommended_action?.mechanical }">Mechanical</span>
                    <span class="action-chip treatment" :class="{ active: prototypeStore.data?.recommended_action?.treatment }">Treatment</span>
                    <span class="action-chip monitor" :class="{ active: prototypeStore.data?.recommended_action?.monitor }">Monitor</span>
                    <span class="action-chip provisional">{{ prototypeStore.data?.recommended_action?.provisional_label ?? 'Provisional' }}</span>
                  </div>
                  <div class="detail-rows">
                    <div class="detail-row"><span>Apply</span><strong>Not provided</strong></div>
                    <div class="detail-row"><span>Reassess</span><strong>{{ week }}</strong></div>
                  </div>
                </section>
              </div>
              <section class="detail-section decision-why">
                <p class="section-kicker">Why</p>
                <p>{{ prototypeStore.data?.recommended_action?.summary ?? 'No sample rationale is available.' }}</p>
              </section>
            </div>
            <aside class="detail-section decision-choice">
              <p class="section-kicker">Your decision</p>
              <div v-if="sampleDecision" class="decision-saved" role="status">
                <strong>{{ sampleDecision === 'approved' ? 'Sample preview approved' : 'Sample preview rejected' }}</strong>
                <span>This is a local prototype choice only. It does not update the scheduler or create a treatment schedule.</span>
              </div>
              <div v-else class="decision-actions">
                <button type="button" class="reject" @click="decideSample('rejected')">Reject</button>
                <button type="button" class="primary" @click="decideSample('approved')">Approve sample preview</button>
              </div>
              <p class="decision-disclaimer">Verify all findings and registered product labels with an agricultural specialist before making treatment decisions.</p>
            </aside>
          </div>
        </template>
        <template v-else>
          <div class="heading-row"><h2>Your decision</h2><span class="badge" :class="status">{{ status }}</span></div>
          <div v-if="proposal" class="decision-layout">
            <div class="decision-main">
              <div class="decision-details-grid">
                <section class="detail-section decision-recommendation">
                  <p class="section-kicker">Proposed treatment</p>
                  <h3>{{ selectedProduct?.name ?? treatment?.name ?? 'Treatment details unavailable' }}</h3>
                  <div class="detail-rows">
                    <div class="detail-row"><span>Line</span><strong>{{ line }}</strong></div>
                    <div class="detail-row"><span>Assessment week</span><strong>{{ week }}</strong></div>
                    <div v-if="proposal.window" class="detail-row"><span>Apply</span><strong>{{ proposal.window.start }} to {{ proposal.window.end }}</strong></div>
                  </div>
                </section>
                <section class="detail-section decision-why">
                  <p class="section-kicker">Why</p>
                  <p>{{ proposal.reason }}</p>
                </section>
              </div>
              <p v-if="proposal.decision?.note" class="hint">Saved note: {{ proposal.decision.note }}</p>
            </div>
            <aside class="detail-section decision-choice">
              <p class="section-kicker">Your decision</p>
              <template v-if="status === 'proposed'">
                <label class="note-label" for="decision-note">Decision note (optional)</label>
                <textarea id="decision-note" v-model="note" rows="3" placeholder="Add a note for this decision"></textarea>
                <p v-if="proposalStore.error" class="error" role="alert">{{ proposalStore.error }}</p>
                <div class="decision-actions">
                  <button type="button" class="reject" :disabled="proposalStore.busy" @click="decide('rejected')">Reject</button>
                  <button type="button" class="primary" :disabled="proposalStore.busy" @click="decide('approved')">Approve</button>
                </div>
              </template>
              <p v-else class="hint">This proposal has already been {{ status }}. Its decision cannot be changed here.</p>
              <p class="decision-disclaimer">Verify registered product labels and treatment details with an agricultural specialist before acting.</p>
            </aside>
          </div>
          <div v-else class="empty">
            <h3>No treatment decision is available</h3>
            <p>The scheduler did not return a proposal. Review the scheduler outcome before making treatment decisions.</p>
          </div>
        </template>
      </section>
      <div class="nav">
        <button type="button" @click="page = 3">Back to product details</button>
        <button v-if="sampleDecision" class="primary" type="button" @click="page = 5">View decision status</button>
        <button v-else-if="proposal && status !== 'proposed'" class="primary" type="button" @click="page = 5">View schedule status</button>
      </div>
    </template>

    <template v-else>
      <section class="schedule-page" aria-live="polite">
        <template v-if="sampleDecision">
          <div class="schedule-status-banner prototype-status">
            <span class="schedule-icon" aria-hidden="true">!</span>
            <div><strong>{{ sampleDecision === 'approved' ? 'Sample decision approved' : 'Sample decision rejected' }}</strong><span>Prototype preview only · No treatment schedule was created</span></div>
          </div>
          <div class="schedule-layout">
            <div class="schedule-main">
              <section class="detail-section schedule-overview">
                <p class="section-kicker">Prototype selection · {{ week }}</p>
                <h2>{{ confirmedProducts.map((product) => product.name).join(' · ') || 'No sample products selected' }}</h2>
                <div class="detail-rows">
                  <div class="detail-row"><span>Line</span><strong>{{ line }}</strong></div>
                  <div class="detail-row"><span>Decision</span><strong>{{ sampleDecision === 'approved' ? 'Sample approved' : 'Sample rejected' }}</strong></div>
                  <div class="detail-row"><span>Schedule</span><strong>Not generated</strong></div>
                </div>
              </section>
              <section class="detail-section schedule-timeline">
                <div class="schedule-section-heading"><h2>Schedule timeline</h2><span class="badge muted">No steps generated</span></div>
                <div class="timeline-empty"><span aria-hidden="true">i</span><p>This prototype-only decision does not approve or create a real treatment schedule. Application timing and follow-up steps are unavailable.</p></div>
              </section>
            </div>
            <aside class="detail-section schedule-aside">
              <p class="section-kicker">Prototype status</p>
              <p>Selections and decisions stay in this preview and are not sent to the scheduler.</p>
              <button type="button" class="journey-cta" @click="page = 4">Review your decision</button>
            </aside>
          </div>
        </template>
        <template v-else>
          <div class="schedule-status-banner" :class="status">
            <span class="schedule-icon" :class="status === 'approved' || status === 'applied' ? 'approved' : status === 'proposed' ? 'waiting' : 'review'" aria-hidden="true">
              {{ status === 'approved' || status === 'applied' ? '✓' : status === 'proposed' ? '…' : '!' }}
            </span>
            <div>
              <strong>{{ status === 'proposed' ? 'Proposed — awaiting your decision' : status === 'approved' ? 'Approved — apply during the treatment window' : status === 'applied' ? 'Treatment application recorded' : status === 'rejected' ? 'Proposal rejected — human review required' : cycle.phase === 'review' ? 'Human review required' : 'No treatment schedule was generated' }}</strong>
              <span>Line {{ line }} · {{ week }}</span>
            </div>
          </div>
          <div class="schedule-layout">
            <div class="schedule-main">
              <section v-if="proposal" class="detail-section schedule-overview">
                <p class="section-kicker">Treatment proposal</p>
                <h2>{{ treatment?.name ?? 'Proposed treatment' }}</h2>
                <p class="schedule-subtitle" v-if="proposal.window">Apply {{ proposal.window.start }} to {{ proposal.window.end }}<span v-if="proposal.next_assessment"> · next assessment {{ proposal.next_assessment }}</span></p>
                <p class="schedule-reason">{{ proposal.reason }}</p>
                <div class="schedule-actions">
                  <button v-if="status === 'proposed'" type="button" class="reject" @click="page = 4">Reject</button>
                  <button v-if="status === 'proposed'" type="button" class="journey-cta" @click="page = 4">Review and decide</button>
                  <RouterLink v-else-if="status === 'approved' || status === 'applied'" class="journey-cta link-button" :to="`/treatment/${encodeURIComponent(line)}/${encodeURIComponent(week)}`">Open full treatment schedule</RouterLink>
                </div>
                <p v-if="status === 'applied'" class="hint">Applied on {{ proposalStore.appliedOn }}.</p>
                <p v-if="proposalStore.cycle?.outcome_reason && status === 'rejected'" class="hint">Reason: {{ proposalStore.cycle.outcome_reason }}</p>
              </section>
              <section class="detail-section schedule-timeline">
                <div class="schedule-section-heading"><h2>{{ proposal && (status === 'approved' || status === 'applied') ? 'Treatment timeline' : 'Schedule timeline' }}</h2><span class="badge muted">{{ proposal && (status === 'approved' || status === 'applied') ? '0 / 2 done' : 'No approved steps' }}</span></div>
                <div class="timeline-empty"><span aria-hidden="true">i</span><p>{{ proposal && (status === 'approved' || status === 'applied') ? 'Open the full treatment schedule to view application and reassessment steps.' : proposal && status === 'proposed' ? 'A schedule will be available after the proposal is approved.' : proposal && status === 'rejected' ? 'This proposal was rejected. No treatment schedule was approved.' : cycle.phase === 'review' ? 'The scheduler requires human review; no treatment schedule is available.' : 'The scheduler recommends continued monitoring for this line-week.' }}</p></div>
              </section>
            </div>
            <aside class="detail-section schedule-aside">
              <p class="section-kicker">Schedule summary</p>
              <div class="detail-rows">
                <div class="detail-row"><span>Status</span><strong>{{ status === 'proposed' ? 'Awaiting decision' : status }}</strong></div>
                <div class="detail-row"><span>Line</span><strong>{{ line }}</strong></div>
                <div class="detail-row"><span>Assessment week</span><strong>{{ week }}</strong></div>
                <div v-if="proposal?.window" class="detail-row"><span>Application window</span><strong>{{ proposal.window.start }} – {{ proposal.window.end }}</strong></div>
              </div>
              <p class="schedule-disclaimer">Verify all treatment details and registered product labels with an agricultural specialist.</p>
            </aside>
          </div>
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
.journey-page-header { display: flex; justify-content: space-between; align-items: center; gap: 16px; }
.journey-page-header h1 { margin: 0; color: var(--forest); font: 800 1.4rem var(--font-display); }
.journey-page-header p { margin: 2px 0 0; color: var(--ink-soft); font-size: .82rem; }
.journey-status { padding: 10px 14px; border-radius: 12px; background: #d6efe6; color: #0b5d4a; font-size: .85rem; font-weight: 800; }
.journey-status.approved { background: #d3efd9; color: #0b5a1f; }
.journey-status.rejected { background: #fbdada; color: #9b1c1c; }
.journey-status.proposed { background: #d6efe6; color: #0b5d4a; }
.cycle-card { display: grid; gap: 12px; }
.cycle-card h2 { margin-bottom: 0; }
.cycle-card .cycle-description { margin: 0; }
.journey-steps { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 8px; list-style: none; margin: 0 0 6px; padding: 0; }
.journey-steps li { position: relative; min-width: 0; display: grid; justify-items: center; gap: 5px; text-align: center; color: var(--ink-soft); }
.journey-steps li:not(:last-child)::after { position: absolute; z-index: 0; top: 14px; left: calc(50% + 17px); right: calc(-50% + 17px); height: 3px; background: #cbd2cb; content: ""; }
.journey-steps li.done:not(:last-child)::after { background: #117a2a; }
.journey-steps li span { display: grid; place-items: center; width: 30px; height: 30px; border: 1px solid var(--line); border-radius: 50%; background: var(--card); font-weight: 800; }
.journey-steps li span { position: relative; z-index: 1; }
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
.combo-option, .excluded-list, .confirmed-list { display: grid; gap: 12px; }
.combo-option, .excluded-list { padding: 16px; border: 1px solid #cbd2cb; border-radius: 16px; background: #fff; }
.combo-option { border: 2px solid #117a2a; }
.excluded-list { border: 1.5px solid #d6455a; }
.combo-heading, .excluded-heading { display: flex; justify-content: space-between; align-items: start; gap: 12px; }
.combo-heading h3, .excluded-heading h3, .confirmed-list h3 { margin: 3px 0 0; color: var(--ink); font-size: 1rem; }
.combo-heading p { margin-top: 4px; color: var(--ink-soft); font-size: .79rem !important; }
.combo-warning, .excluded-heading p, .confirmed-list > p { color: var(--ink-soft); font-size: .82rem !important; line-height: 1.45; }
.combo-warning { max-width: 68ch; padding-left: 11px; border-left: 3px solid var(--warn); color: var(--ink-soft); }
.combination-products { display: grid; }
.product-option, .excluded-option { position: relative; display: flex; width: 100%; min-width: 0; align-items: center; gap: 12px; padding: 11px 0; border: 0; border-top: 1px solid #e5e7e5; border-radius: 0; color: var(--ink); text-align: left; transition: background .15s, box-shadow .15s, transform .15s; }
.product-option { background: transparent; }
.product-option:hover { background: #f5faf6; transform: none; }
.product-option.chosen { background: #f5faf6; box-shadow: inset 3px 0 var(--forest); padding-left: 8px; }
.product-copy, .excluded-copy { display: grid; min-width: 0; gap: 3px; }
.product-name { display: block; color: var(--ink); font-size: .95rem; font-weight: 800; line-height: 1.35; }
.product-description, .product-meta { display: block; color: var(--ink-soft); font-size: .79rem; line-height: 1.4; }
.product-action { display: grid; flex: 0 0 auto; justify-items: end; gap: 4px; margin-left: auto; color: var(--ink-soft); font-size: .78rem; font-weight: 600; white-space: nowrap; }
.product-action b { margin-left: 3px; font-size: 1rem; }
.product-link, .text-action { color: #6b7280; font-size: .8rem; font-weight: 800; text-decoration: underline; text-underline-offset: 3px; }
.text-action { border: 0; background: transparent; padding: 3px 6px; }
.product-option:hover .product-link, .excluded-option:hover .product-link, .text-action:hover { color: #374151; }
.options-continue { display: flex; justify-content: space-between; align-items: center; gap: 16px; padding-top: 12px; border-top: 1px solid var(--line); }
.options-continue p { color: var(--ink-soft); font-size: .84rem; }
.options-continue .journey-cta { flex: 0 0 auto; }
.selection-state { color: var(--forest); font-size: .68rem; font-weight: 800; text-transform: uppercase; }
.excluded-products { display: grid; }
.excluded-option { min-height: 58px; padding: 10px 0; background: transparent; }
.excluded-option:hover { background: #fff8f8; transform: none; }
.excluded-mark { display: grid; flex: 0 0 23px; width: 23px; height: 23px; place-items: center; border-radius: 50%; background: #fbe4e4; color: #962626; font-size: .78rem; font-weight: 900; }
.excluded-option .product-name { font-size: .88rem; }
.excluded-option .product-meta { font-size: .75rem; }
.excluded-option .product-action { color: #8d3434; }
.frac-label { display: inline-block; padding: 3px 8px; border-radius: 999px; background: #e5e7eb; color: #374151; font-size: .68rem; font-weight: 800; white-space: nowrap; }
.product-price { display: inline-block; padding: 3px 8px; border-radius: 999px; background: #e5e7eb; color: #374151; font-size: .68rem; font-weight: 800; white-space: nowrap; }
.selection-state.insisted { color: #8d3434; }
.confirmed-list { padding: 16px; border: 1px solid #cbd2cb; border-radius: 16px; background: #fff; }
.confirmed-list h3 span { display: inline-grid; place-items: center; min-width: 23px; height: 23px; margin-left: 4px; padding: 0 5px; border-radius: 999px; background: var(--tint); color: var(--forest); font-size: .78rem; }
.confirmed-list ul { display: grid; gap: 6px; }
.confirmed-list li { display: flex; justify-content: space-between; align-items: center; gap: 10px; padding: 8px 0; border-top: 1px solid var(--line); }
.confirmed-list li small { color: var(--danger); }
.confirmed-list li button { border: 0; background: transparent; color: var(--forest); font-weight: 800; text-decoration: underline; }
.fungicide-page { display: grid; gap: 16px; }
.fungicide-page > .heading-row h2 { margin: 0; color: var(--forest); font: 800 17px var(--font-display); }
.fungicide-layout { display: grid; grid-template-columns: minmax(0, 1fr) minmax(280px, 340px); gap: 20px; align-items: start; }
.catalog-main, .fungicide-sidebar { display: grid; align-content: start; gap: 14px; min-width: 0; }
.fungicide-sidebar { position: sticky; top: 16px; }
.catalog-list { display: grid; gap: 10px; }
.recommended-action { display: grid; gap: 10px; margin: 0; padding: 16px; border: 1px solid #cbd2cb; border-radius: 16px; background: #fff; }
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
.sample-disclaimer { margin: 0; padding: 10px 12px; border-radius: 10px; background: #e5e7eb; color: #374151; font-size: .82rem; font-weight: 700; }
.product-meta { display: flex; flex-wrap: wrap; align-items: center; gap: 5px 7px; color: var(--ink-soft); font-size: .82rem !important; }
.excluded { padding: 12px; border-radius: 10px; background: var(--beige); font-size: .85rem; }
.excluded summary { cursor: pointer; font-weight: 700; }
.excluded ul { padding-left: 20px; color: var(--ink-soft); line-height: 1.6; }
.option h3, .product-title h3, .decision-card h3 { margin: 5px 0; color: var(--ink); font-size: 1.05rem; }
.option p { margin-bottom: 0; }
.eyebrow { color: var(--ink-soft); font-size: .75rem; font-weight: 800; letter-spacing: .05em; text-transform: uppercase; }
.hint, .reason { color: var(--ink-soft); }
.empty { padding: 20px; border: 1px dashed var(--line); border-radius: 12px; color: var(--ink-soft); }
.empty h3 { color: var(--ink); }
.product-detail-page { display: grid; gap: 16px; }
.product-page-heading { padding-bottom: 12px; border-bottom: 1px solid var(--line); }
.product-page-heading h2 { margin: 3px 0 0; }
.product-detail-layout { display: grid; grid-template-columns: minmax(0, 1fr) minmax(260px, 320px); gap: 20px; align-items: start; }
.product-detail-main, .product-detail-aside { display: grid; gap: 16px; min-width: 0; }
.detail-section { padding: 16px; border: 1px solid #cbd2cb; border-radius: 16px; background: #fff; }
.product-identity { padding: 18px; }
.product-name-row { display: flex; justify-content: space-between; align-items: center; gap: 12px; }
.product-name-row h3 { margin: 0; color: var(--ink); font-size: 1.35rem; line-height: 1.3; }
.badge.muted { flex: 0 0 auto; background: #e5e7eb; color: #374151; }
.product-category { margin: 5px 0 8px; color: var(--ink-soft); font-size: .84rem !important; }
.product-category span { padding: 0 3px; }
.detail-rows { display: grid; }
.detail-row { display: flex; justify-content: space-between; align-items: center; gap: 14px; min-height: 42px; padding: 9px 0; border-top: 1px solid #e5e7e5; font-size: .87rem; }
.detail-row span { color: var(--ink-soft); }
.detail-row strong { color: var(--ink); font-weight: 700; text-align: right; overflow-wrap: anywhere; }
.detail-section-title { margin: 0 0 8px; color: var(--forest); font-size: 1rem; }
.resistance-card { border-color: #e5b923; background: #fdebca; }
.resistance-card.is-excluded { border-color: #e8b8b8; background: #fff0f0; }
.section-kicker { margin-bottom: 5px; color: #6b4000; font-size: .74rem !important; font-weight: 800; letter-spacing: .04em; text-transform: uppercase; }
.resistance-card.is-excluded .section-kicker, .resistance-card.is-excluded > p:last-child { color: #7a1515; }
.resistance-card > p:last-child, .proposal-reason { color: #4b2e00; font-size: .88rem !important; line-height: 1.55; }
.mobility-label { margin: 14px 0 8px; color: var(--ink-soft); font-size: .8rem !important; font-weight: 700; }
.mobility-pills { display: flex; flex-wrap: wrap; gap: 8px; }
.mobility-pill { display: inline-flex; min-height: 34px; align-items: center; padding: 0 13px; border: 1px solid #9ca3af; border-radius: 999px; background: #fff; color: #374151; font-size: .8rem; font-weight: 700; }
.mobility-pill.active { border-color: var(--forest); background: var(--forest); color: #fff; }
.usage-section .detail-row { min-height: 38px; }
.eligibility-card .detail-section-title { margin-bottom: 10px; }
.eligibility-row { display: flex; justify-content: space-between; align-items: center; gap: 8px; min-height: 44px; padding: 8px 0; border-top: 1px solid #e5e7e5; font-size: .8rem; }
.eligibility-row > span:first-child { color: var(--ink-soft); }
.eligibility-row .badge { flex: 0 0 auto; padding: 4px 8px; font-size: .66rem; }
.detail-actions { display: grid; gap: 10px; }
.sample-note { color: var(--ink-soft); font-size: .8rem !important; line-height: 1.5; }
.sample-confirm { width: 100%; }
.detail-actions .confirmed-message { margin: 0; }
.product-detail-page .constraints { margin: 0; padding: 10px 12px 10px 30px; border-radius: 12px; background: var(--beige); color: var(--ink-soft); font-size: .84rem; }
.constraints { padding-left: 20px; }
.disclaimer { padding: 12px; border-radius: 10px; background: var(--beige); color: var(--ink-soft); font-size: .82rem; line-height: 1.45; }
.confirmed-message { color: var(--forest); font-size: .85rem !important; font-weight: 800; }
.note-label { display: block; margin: 14px 0 6px; font-size: .85rem; font-weight: 700; }
textarea { display: block; width: 100%; padding: 10px 12px; border: 1px solid var(--line); border-radius: var(--radius-sm); font: inherit; resize: vertical; }
.decision-actions { display: flex; justify-content: flex-end; gap: 10px; margin-top: 16px; }
.decision-actions button { min-width: 120px; min-height: 42px; padding: 8px 14px; border: 1px solid var(--line); border-radius: var(--radius-sm); background: #fff; color: var(--ink); font: 700 14px var(--font-body); transition: background .15s, box-shadow .15s, transform .15s; }
.reject { border-color: var(--danger) !important; background: #fff !important; color: var(--danger) !important; }
.decision-actions .reject:hover:not(:disabled) { background: #fff5f5 !important; box-shadow: 0 4px 10px rgba(180, 35, 24, .12); transform: translateY(-1px); }
.decision-page { display: grid; gap: 16px; }
.decision-layout { display: grid; grid-template-columns: minmax(0, 1fr) minmax(260px, 320px); gap: 20px; align-items: start; }
.decision-main { display: grid; gap: 14px; min-width: 0; }
.decision-details-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; align-items: start; }
.decision-recommendation .detail-rows { margin-top: 12px; }
.decision-selection { display: grid; gap: 10px; }
.decision-product { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 4px 12px; align-items: center; padding: 10px 0; border-top: 1px solid #e5e7e5; }
.decision-product > div { display: grid; gap: 3px; min-width: 0; }
.decision-product > div strong { overflow-wrap: anywhere; }
.decision-product > div span { color: var(--ink-soft); font-size: .8rem; }
.decision-product > .badge { font-size: .67rem; }
.decision-product-warning { grid-column: 1 / -1; color: var(--danger); font-size: .8rem !important; }
.decision-why p:last-child { color: var(--ink-soft); font-size: .88rem; }
.decision-choice { display: grid; gap: 12px; }
.decision-choice .decision-actions { margin: 0; }
.decision-choice .decision-actions button { flex: 1; }
.decision-choice .decision-actions .primary { border: 1px solid var(--forest); background: var(--forest); color: #fff; }
.decision-choice .decision-actions .primary:hover:not(:disabled) { background: var(--forest-deep); box-shadow: 0 4px 12px rgba(6, 85, 44, .2); transform: translateY(-1px); }
.decision-disclaimer { color: var(--ink-soft); font-size: .78rem !important; line-height: 1.5; }
.decision-saved { display: grid; gap: 6px; padding: 12px; border-radius: 12px; background: var(--tint); color: var(--forest-deep); }
.decision-saved span { font-size: .82rem; line-height: 1.45; }
.error { color: var(--danger); }
.outcome { color: var(--ink-soft); }
.schedule-page { display: grid; gap: 16px; }
.schedule-status-banner { display: flex; align-items: center; gap: 12px; padding: 16px 18px; border-radius: 16px; background: #d6efe6; color: #0b5d4a; }
.schedule-status-banner.approved, .schedule-status-banner.applied { background: #d3efd9; color: #0b5a1f; }
.schedule-status-banner.rejected, .schedule-status-banner.review { background: #fbdada; color: #9b1c1c; }
.schedule-status-banner.proposed { background: #d6efe6; color: #0b5d4a; }
.schedule-status-banner.prototype-status { background: #fdebc8; color: #6b4000; }
.schedule-status-banner > div { display: grid; gap: 3px; }
.schedule-status-banner strong { font-size: .95rem; }
.schedule-status-banner > div > span { font-size: .8rem; }
.schedule-layout { display: grid; grid-template-columns: minmax(0, 1fr) minmax(280px, 360px); gap: 20px; align-items: start; }
.schedule-main { display: grid; gap: 16px; min-width: 0; }
.schedule-overview h2 { margin: 0 0 8px; color: var(--forest); font: 800 1.15rem var(--font-display); overflow-wrap: anywhere; }
.schedule-subtitle, .schedule-reason { color: var(--ink-soft); font-size: .88rem !important; line-height: 1.5; }
.schedule-subtitle { margin: 0 0 10px; }
.schedule-reason { margin: 0; }
.schedule-actions { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 16px; }
.schedule-actions .reject { min-height: 44px; padding: 0 18px; border-radius: var(--radius-sm); font: 800 14px var(--font-body); }
.schedule-section-heading { display: flex; justify-content: space-between; align-items: center; gap: 12px; }
.schedule-section-heading h2 { margin: 0; color: var(--forest); font: 800 1.05rem var(--font-display); }
.timeline-empty { display: flex; align-items: flex-start; gap: 12px; margin-top: 14px; padding: 12px; border-radius: 12px; background: #f3f4f3; color: var(--ink-soft); }
.timeline-empty > span { display: grid; flex: 0 0 24px; width: 24px; height: 24px; place-items: center; border-radius: 50%; background: #e5e7eb; color: #374151; font-size: .78rem; font-weight: 800; }
.timeline-empty p { margin: 0; font-size: .84rem; line-height: 1.5; }
.schedule-aside { display: grid; gap: 8px; }
.schedule-aside > p { color: var(--ink-soft); font-size: .84rem; line-height: 1.5; }
.schedule-aside .schedule-disclaimer { margin: 8px 0 0; padding-top: 12px; border-top: 1px solid var(--line); font-size: .77rem; }
.schedule-icon { display: grid; flex: 0 0 40px; place-items: center; width: 40px; height: 40px; border-radius: 50%; font-weight: 800; font-size: 1.15rem; }
.schedule-icon.waiting { background: var(--warn-tint); color: var(--warn); }
.schedule-icon.approved { background: var(--tint); color: var(--forest); }
.schedule-icon.review { background: #fbdada; color: var(--danger); }
.link-button { display: inline-flex; align-items: center; min-height: 42px; padding: 0 16px; border-radius: var(--radius-sm); background: var(--forest); color: #fff; font-weight: 800; text-decoration: none; }
.journey :is(button, a):focus-visible { outline: 3px solid #e59a0f; outline-offset: 3px; }
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
  .journey-steps { grid-template-columns: repeat(5, minmax(0, 1fr)); row-gap: 12px; }
  .fungicide-layout { grid-template-columns: minmax(0, 1fr); }
  .fungicide-sidebar { position: static; }
  .product-detail-layout { grid-template-columns: minmax(0, 1fr); }
  .decision-layout { grid-template-columns: minmax(0, 1fr); }
  .decision-details-grid { grid-template-columns: minmax(0, 1fr); }
  .schedule-layout { grid-template-columns: minmax(0, 1fr); }
}
@media (max-width: 520px) {
  .heading-row, .option { flex-direction: column; }
  .combination-products { grid-template-columns: minmax(0, 1fr); }
  .product-option { align-items: flex-start; }
  .excluded-option { align-items: center; }
  .combo-heading, .excluded-heading { align-items: flex-start; }
  .options-continue { align-items: stretch; flex-direction: column; }
  .catalog-main { order: 0; }
  .fungicide-sidebar { order: 1; }
  .journey-cta { width: 100%; }
  .journey-page-header { align-items: flex-start; }
  .journey-page-header h1 { font-size: 1.2rem; }
  .product-name-row { align-items: flex-start; flex-direction: column; }
  .detail-row { align-items: flex-start; flex-direction: column; gap: 3px; }
  .detail-row strong { text-align: left; }
  .eligibility-row { align-items: flex-start; }
  .decision-product { grid-template-columns: minmax(0, 1fr); }
  .decision-choice .decision-actions { flex-direction: column; }
  .decision-actions { flex-direction: column; }
  .decision-actions button { width: 100%; min-height: 42px; }
  .schedule-status-banner { align-items: flex-start; }
  .schedule-section-heading { align-items: flex-start; flex-direction: column; }
  .schedule-actions { flex-direction: column; }
  .schedule-actions > * { width: 100%; justify-content: center; }
}
</style>
