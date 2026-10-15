<script setup>
import { computed, onMounted, ref } from 'vue';
import { useFactReviewStore, PAGE } from '../stores/factReview.js';
import { useWorkflowRunStore } from '../stores/workflowRun.js';
import { useAuthStore } from '../stores/auth.js';
import Pill from './Pill.vue';
import { fmtDateTime } from './util.js';

const props = defineProps({ workflowId: { type: String, required: true }, stage: { type: String, default: 'extraction_review' } });
const final = props.stage === 'final_review';
// A fact can be decided while it is pending (extraction review) or accepted (final review).
const DECIDABLE = final ? 'accepted' : 'pending';
const changed = ref(0);
const store = useFactReviewStore(), run = useWorkflowRunStore(), auth = useAuthStore();
const FILTERS = [['pending', 'Needing review'], ['accepted', 'Accepted'], ['rejected', 'Rejected'], ['unresolved', 'Unresolved'], ['', 'All']];
onMounted(async () => {
  store.load(props.workflowId, { disposition: DECIDABLE });
  if (final) changed.value = await store.countChanged(props.workflowId);
});

const pages = computed(() => Math.max(1, Math.ceil(store.total / PAGE)));
const page = computed(() => Math.floor(store.offset / PAGE) + 1);
const tone = (d) => (d === 'accepted' ? 'good' : d === 'rejected' ? 'bad' : d === 'pending' ? 'warn' : 'neutral');
const triple = (t) => [t?.subject, t?.predicate ?? t?.relation, t?.object].map((x) => x ?? '—').join('  →  ');
const problem = (v) => v?.message ?? (typeof v === 'string' ? v : JSON.stringify(v));
const ends = (r) => (r ? [['Subject', r.subject], ['Object', r.object]].filter(([, e]) => e) : []);
const restored = (r) => (r ? ['subject', 'relation', 'object'].map((k) => `${k} ${r[`${k}_restored`] ? 'restored' : 'not restored'}`).join(', ') : '—');
const claim = (f) => (!f.claimed_by ? '' : f.claimed_by === auth.userId ? 'mine' : 'other');
const until = (s) => (s ? fmtDateTime(s.replace('T', ' ').replace(/(\.\d+)?(Z|\+00:00)$/, '')) : '');

async function decide(f, decision) {
  if (await store.review(f.id, decision, props.stage)) await run.recheck(props.workflowId);
}
</script>

<template>
  <section class="a-card box" aria-label="Fact review">
    <div class="top">
      <h2>{{ final ? 'Final review' : 'Review extracted facts' }}</h2>
      <label>Show
        <select class="a-select" :value="store.disposition" @change="store.load(workflowId, { disposition: $event.target.value })">
          <option v-for="[v, l] in FILTERS" :key="v" :value="v">{{ l }}</option>
        </select>
      </label>
    </div>

    <p v-if="changed" class="a-note" role="status">
      A check against the knowledge graph changed {{ changed }} accepted {{ changed === 1 ? 'fact' : 'facts' }} since you last reviewed. Decide {{ changed === 1 ? 'it' : 'them' }} again before approving.
    </p>
    <p v-if="store.error" class="a-note err" role="alert">{{ store.error }}</p>
    <p v-if="store.notice" class="a-note" role="status">{{ store.notice }}</p>
    <p v-if="store.loading" class="a-muted">Loading facts…</p>
    <p v-else-if="!store.facts.length && !store.error" class="a-muted">No facts here.</p>

    <ul class="list">
      <li v-for="f in store.facts" :key="f.id" class="fact">
        <div class="row">
          <strong class="triple">{{ triple(f.extracted_triple) }}</strong>
          <span class="pills">
            <Pill v-if="f.requires_action && final" tone="warn">Needs a new decision</Pill>
            <Pill :tone="tone(f.disposition)">{{ f.disposition }}</Pill>
          </span>
        </div>
        <blockquote>{{ f.source_excerpt }}</blockquote>
        <p class="meta">
          GraphJudge: {{ f.graphjudge_result ?? '—' }} · Restoration: {{ restored(f.restoration_status) }}
          <template v-if="claim(f) === 'mine'"> · <strong>Claimed by you</strong> until {{ until(f.claim_expires_at) }}</template>
          <template v-else-if="claim(f) === 'other'"> · Claimed by a colleague until {{ until(f.claim_expires_at) }}</template>
        </p>
        <div v-if="f.gate3 || f.mend || f.entity_resolution || f.entity_match_warnings?.length || f.entity_conflict_warnings?.length" class="detail">
          <p v-if="f.gate3" class="meta">
            Ontology check: <strong>{{ f.gate3.status === 'passed' ? 'passed' : 'violations' }}</strong>
          </p>
          <ul v-if="f.gate3?.violations?.length"><li v-for="(v, i) in f.gate3.violations" :key="i">{{ problem(v) }}</li></ul>
          <div v-if="f.mend?.iterations?.length" class="meta">
            <strong>{{ f.mend.altered ? 'Corrected automatically' : 'Correction tried, not resolved' }}</strong>
            <div v-for="it in f.mend.iterations" :key="it.iteration" class="diff">
              <span>Before: {{ triple(it.before) }}</span><span>After: {{ it.after ? triple(it.after) : '—' }}</span>
            </div>
          </div>
          <p v-for="[who, e] in ends(f.entity_resolution)" :key="who" class="meta">
            {{ who }}: {{ e.label ?? e.iri }} ({{ String(e.status).replace(/_/g, ' ') }}<template v-if="e.type">, {{ e.type }}</template>)
          </p>
          <p v-for="(w, i) in f.entity_match_warnings" :key="`m${i}`" class="warn">Possible match: {{ problem(w) }}</p>
          <p v-for="(w, i) in f.entity_conflict_warnings" :key="`c${i}`" class="warn">Conflict with the graph: {{ problem(w) }}</p>
        </div>
        <div class="a-actions">
          <button type="button" class="a-btn" :disabled="store.busy || claim(f) === 'mine'" @click="store.claim(f.id)">Claim</button>
          <button type="button" class="a-btn" :disabled="store.busy || claim(f) !== 'mine'" @click="store.release(f.id)">Release</button>
          <button type="button" class="a-btn primary" :disabled="store.busy || f.disposition !== DECIDABLE" @click="decide(f, 'accept')">Accept</button>
          <button type="button" class="a-btn danger" :disabled="store.busy || f.disposition !== DECIDABLE" @click="decide(f, 'reject')">Reject</button>
          <button type="button" class="a-btn" disabled title="Not available yet">Edit</button>
          <button type="button" class="a-btn" disabled title="Not available yet">Rework</button>
          <button type="button" class="a-btn" disabled title="Not available yet">Reinstate</button>
        </div>
      </li>
    </ul>

    <nav class="pager" aria-label="Pages">
      <button type="button" class="a-btn" :disabled="store.loading || store.offset === 0" @click="store.goTo(store.offset - PAGE)">Previous</button>
      <span class="a-muted">Page {{ page }} of {{ pages }} · {{ store.total }} facts</span>
      <button type="button" class="a-btn" :disabled="store.loading || store.offset + PAGE >= store.total" @click="store.goTo(store.offset + PAGE)">Next</button>
    </nav>
  </section>
</template>

<style scoped>
.box { padding: 20px; display: grid; gap: 16px; }
.top { display: flex; justify-content: space-between; align-items: center; gap: 12px; flex-wrap: wrap; }
.top h2 { margin: 0; }
.list { display: grid; gap: 12px; margin: 0; padding: 0; list-style: none; }
.fact { display: grid; gap: 8px; padding: 14px; border: 1px solid var(--line); border-radius: 14px; }
.row { display: flex; justify-content: space-between; gap: 12px; align-items: flex-start; }
.triple { overflow-wrap: anywhere; }
blockquote { margin: 0; padding-left: 12px; border-left: 3px solid var(--line); color: var(--ink-soft); }
.meta { margin: 0; color: var(--ink-soft); }
.pills { display: flex; gap: 6px; flex-wrap: wrap; justify-content: flex-end; }
.detail { display: grid; gap: 6px; padding: 10px 12px; border-radius: 10px; background: var(--bg); }
.detail p, .detail ul { margin: 0; }
.diff { display: grid; gap: 2px; margin-top: 4px; overflow-wrap: anywhere; }
.warn { color: #B4432A; }
.pager { display: flex; justify-content: space-between; align-items: center; gap: 12px; }
</style>
