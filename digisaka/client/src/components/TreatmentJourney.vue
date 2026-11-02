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
                  <span class="eyebrow">Featured sample · prototype only</span>
                  <h3>Two products to explore</h3>
                </div>
                <span class="badge selected">Sample pick</span>
              </div>
              <p class="combo-warning">These are two separate sample options grouped for the UI preview. Compatibility has not been assessed; this is not an instruction to mix or apply them.</p>
              <div class="combination-products">
                <button v-for="(product, index) in eligibleProducts" :key="product.id" type="button" class="product-option" :class="{ chosen: isConfirmed(product.id) }" :aria-label="`View details for ${product.name}`" @click="showProductDetails(product.id)">
                  <span class="product-number">0{{ index + 1 }}</span>
                  <span class="product-copy">
                    <span class="eyebrow">{{ product.group }}</span>
                    <span class="product-name">{{ product.name }}</span>
                    <span class="product-description">{{ product.efficacy }}</span>
                    <span class="product-meta">FRAC {{ product.frac_code }} · {{ product.mobility }}</span>
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
                  <h3>Excluded from the sample</h3>
                  <p>Not recommended. Select an item to inspect the reason and details.</p>
                </div>
                <span class="badge rejected">{{ excludedProducts.length }} excluded</span>
              </div>
              <div class="excluded-products">
                <button v-for="product in excludedProducts" :key="product.id" type="button" class="excluded-option" :aria-label="`View excluded product details for ${product.name}`" @click="showProductDetails(product.id)">
                  <span class="excluded-mark" aria-hidden="true">!</span>
                  <span class="excluded-copy">
                    <span class="product-name">{{ product.name }}</span>
                    <span class="product-meta">FRAC {{ product.frac_code }} · {{ product.resistance_note }}</span>
                  </span>
                  <span class="product-action">
                    <span v-if="isConfirmed(product.id)" class="selection-state insisted">Insisted</span>
                    <span class="product-link" aria-hidden="true">View details <b>→</b></span>
                  </span>
                </button>
              </div>
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
      <section class="card decision-card">
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
              <section class="detail-section decision-recommendation">
                <p class="section-kicker">Recommended action · sample</p>
                <div class="action-chips">
                  <span class="action-chip preventive" :class="{ active: prototypeStore.data?.recommended_action?.preventive }">Preventive</span>
                  <span class="action-chip mechanical" :class="{ active: prototypeStore.data?.recommended_action?.mechanical }">Mechanical</span>
                  <span class="action-chip provisional">{{ prototypeStore.data?.recommended_action?.provisional_label ?? 'Provisional' }}</span>
                </div>
                <div class="detail-rows">
                  <div class="detail-row"><span>Apply</span><strong>Not provided</strong></div>
                  <div class="detail-row"><span>Reassess</span><strong>{{ week }}</strong></div>
                </div>
              </section>
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
        </template>
      </section>
      <div class="nav">
        <button type="button" @click="page = 3">Back to product details</button>
        <button v-if="sampleDecision" class="primary" type="button" @click="page = 5">View decision status</button>
        <button v-else-if="proposal && status !== 'proposed'" class="primary" type="button" @click="page = 5">View schedule status</button>
      </div>
    </template>

    <template v-else>
      <section class="card schedule-card" aria-live="polite">
        <template v-if="sampleDecision">
          <span class="schedule-icon" :class="sampleDecision === 'approved' ? 'approved' : 'review'">{{ sampleDecision === 'approved' ? '✓' : '!' }}</span>
          <h2>{{ sampleDecision === 'approved' ? 'Sample decision approved' : 'Sample decision rejected' }}</h2>
          <p>{{ confirmedProducts.map((product) => product.name).join(' · ') }} · Line {{ line }} · {{ week }}</p>
          <p>This prototype-only decision does not approve or create a real treatment schedule.</p>
          <button type="button" @click="page = 4">Review your decision</button>
        </template>
        <template v-else-if="proposal && status === 'proposed'">
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
.combo-option, .excluded-list, .confirmed-list { display: grid; gap: 12px; }
.combo-option { padding: 4px 0 16px; }
.excluded-list { padding-top: 16px; border-top: 1px solid var(--line); }
.combo-heading, .excluded-heading { display: flex; justify-content: space-between; align-items: start; gap: 12px; }
.combo-heading h3, .excluded-heading h3, .confirmed-list h3 { margin: 3px 0 0; color: var(--ink); font-size: 1rem; }
.combo-warning, .excluded-heading p, .confirmed-list > p { color: var(--ink-soft); font-size: .82rem !important; line-height: 1.45; }
.combo-warning { max-width: 68ch; padding-left: 11px; border-left: 3px solid var(--warn); }
.combination-products { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px; }
.product-option, .excluded-option { position: relative; display: flex; width: 100%; min-width: 0; align-items: center; gap: 12px; padding: 15px; border: 0; border-radius: 12px; color: var(--ink); text-align: left; transition: background .15s, box-shadow .15s, transform .15s; }
.product-option { background: #f0f6f1; }
.product-option:hover { background: #e5f1e7; box-shadow: 0 5px 14px rgba(16, 64, 37, .1); transform: translateY(-1px); }
.product-option.chosen { background: #e0efe2; box-shadow: inset 3px 0 var(--forest); }
.product-number { display: grid; flex: 0 0 32px; width: 32px; height: 32px; place-items: center; border-radius: 50%; background: #fff; color: var(--forest); font-size: .72rem; font-weight: 900; }
.product-copy, .excluded-copy { display: grid; min-width: 0; gap: 3px; }
.product-name { display: block; color: var(--ink); font-size: .95rem; font-weight: 800; line-height: 1.35; }
.product-description, .product-meta { display: block; color: var(--ink-soft); font-size: .79rem; line-height: 1.4; }
.product-action { display: grid; flex: 0 0 auto; justify-items: end; gap: 4px; margin-left: auto; color: var(--forest); font-size: .76rem; font-weight: 800; white-space: nowrap; }
.product-action b { margin-left: 3px; font-size: 1rem; }
.product-link, .text-action { color: var(--forest); font-size: .8rem; font-weight: 800; text-decoration: underline; text-underline-offset: 3px; }
.text-action { border: 0; background: transparent; padding: 3px 6px; }
.product-option:hover .product-link, .excluded-option:hover .product-link, .text-action:hover { color: var(--forest-deep); }
.options-continue { display: flex; justify-content: space-between; align-items: center; gap: 16px; padding-top: 12px; border-top: 1px solid var(--line); }
.options-continue p { color: var(--ink-soft); font-size: .84rem; }
.options-continue .journey-cta { flex: 0 0 auto; }
.selection-state { color: var(--forest); font-size: .68rem; font-weight: 800; text-transform: uppercase; }
.excluded-products { display: grid; gap: 2px; }
.excluded-option { min-height: 58px; padding: 10px 12px; border-radius: 8px; background: transparent; }
.excluded-option:hover { background: #fff1f1; transform: none; }
.excluded-mark { display: grid; flex: 0 0 23px; width: 23px; height: 23px; place-items: center; border-radius: 50%; background: #fbe4e4; color: #962626; font-size: .78rem; font-weight: 900; }
.excluded-option .product-name { font-size: .88rem; }
.excluded-option .product-meta { font-size: .75rem; }
.excluded-option .product-action { color: #8d3434; }
.selection-state.insisted { color: #8d3434; }
.confirmed-list { padding: 14px; border-radius: 12px; background: #f6fbf7; }
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
.decision-actions button { min-width: 120px; }
.reject { background: #fff; border: 1px solid var(--danger); color: var(--danger); }
.decision-layout { display: grid; grid-template-columns: minmax(0, 1fr) minmax(260px, 320px); gap: 20px; align-items: start; }
.decision-main { display: grid; gap: 14px; min-width: 0; }
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
.decision-disclaimer { color: var(--ink-soft); font-size: .78rem !important; line-height: 1.5; }
.decision-saved { display: grid; gap: 6px; padding: 12px; border-radius: 12px; background: var(--tint); color: var(--forest-deep); }
.decision-saved span { font-size: .82rem; line-height: 1.45; }
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
  .product-detail-layout { grid-template-columns: minmax(0, 1fr); }
  .decision-layout { grid-template-columns: minmax(0, 1fr); }
}
@media (max-width: 520px) {
  .heading-row, .option { flex-direction: column; }
  .combination-products { grid-template-columns: minmax(0, 1fr); }
  .product-option { align-items: flex-start; }
  .excluded-option { align-items: center; }
  .combo-heading, .excluded-heading { align-items: flex-start; }
  .options-continue { align-items: stretch; flex-direction: column; }
  .journey-cta { width: 100%; }
  .product-name-row { align-items: flex-start; flex-direction: column; }
  .detail-row { align-items: flex-start; flex-direction: column; gap: 3px; }
  .detail-row strong { text-align: left; }
  .eligibility-row { align-items: flex-start; }
  .decision-product { grid-template-columns: minmax(0, 1fr); }
  .decision-choice .decision-actions { flex-direction: column; }
  .decision-actions { flex-direction: column; }
  .decision-actions button { width: 100%; min-height: 42px; }
}
</style>
