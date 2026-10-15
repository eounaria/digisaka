<script setup>
import { computed, onMounted } from 'vue';
import { useFactReviewStore, PAGE } from '../stores/factReview.js';
import { useWorkflowRunStore } from '../stores/workflowRun.js';
import { useAuthStore } from '../stores/auth.js';
import Pill from './Pill.vue';
import { fmtDateTime } from './util.js';

const props = defineProps({ workflowId: { type: String, required: true } });
const STAGE = 'extraction_review';
const store = useFactReviewStore(), run = useWorkflowRunStore(), auth = useAuthStore();
const FILTERS = [['pending', 'Needing review'], ['accepted', 'Accepted'], ['rejected', 'Rejected'], ['unresolved', 'Unresolved'], ['', 'All']];
onMounted(() => store.load(props.workflowId, { disposition: 'pending' }));

const pages = computed(() => Math.max(1, Math.ceil(store.total / PAGE)));
const page = computed(() => Math.floor(store.offset / PAGE) + 1);
const tone = (d) => (d === 'accepted' ? 'good' : d === 'rejected' ? 'bad' : d === 'pending' ? 'warn' : 'neutral');
const triple = (t) => [t?.subject, t?.predicate, t?.object].map((x) => x ?? '—').join('  →  ');
const restored = (r) => (r ? ['subject', 'relation', 'object'].map((k) => `${k} ${r[`${k}_restored`] ? 'restored' : 'not restored'}`).join(', ') : '—');
const claim = (f) => (!f.claimed_by ? '' : f.claimed_by === auth.userId ? 'mine' : 'other');
const until = (s) => (s ? fmtDateTime(s.replace('T', ' ').replace(/(\.\d+)?(Z|\+00:00)$/, '')) : '');

async function decide(f, decision) {
  if (await store.review(f.id, decision, STAGE)) await run.recheck(props.workflowId);
}
</script>

<template>
  <section class="a-card box" aria-label="Fact review">
    <div class="top">
      <h2>Review extracted facts</h2>
      <label>Show
        <select class="a-select" :value="store.disposition" @change="store.load(workflowId, { disposition: $event.target.value })">
          <option v-for="[v, l] in FILTERS" :key="v" :value="v">{{ l }}</option>
        </select>
      </label>
    </div>

    <p v-if="store.error" class="a-note err" role="alert">{{ store.error }}</p>
    <p v-if="store.notice" class="a-note" role="status">{{ store.notice }}</p>
    <p v-if="store.loading" class="a-muted">Loading facts…</p>
    <p v-else-if="!store.facts.length && !store.error" class="a-muted">No facts here.</p>

    <ul class="list">
      <li v-for="f in store.facts" :key="f.id" class="fact">
        <div class="row">
          <strong class="triple">{{ triple(f.extracted_triple) }}</strong>
          <Pill :tone="tone(f.disposition)">{{ f.disposition }}</Pill>
        </div>
        <blockquote>{{ f.source_excerpt }}</blockquote>
        <p class="meta">
          GraphJudge: {{ f.graphjudge_result ?? '—' }} · Restoration: {{ restored(f.restoration_status) }}
          <template v-if="claim(f) === 'mine'"> · <strong>Claimed by you</strong> until {{ until(f.claim_expires_at) }}</template>
          <template v-else-if="claim(f) === 'other'"> · Claimed by a colleague until {{ until(f.claim_expires_at) }}</template>
        </p>
        <div class="a-actions">
          <button type="button" class="a-btn" :disabled="store.busy || claim(f) === 'mine'" @click="store.claim(f.id)">Claim</button>
          <button type="button" class="a-btn" :disabled="store.busy || claim(f) !== 'mine'" @click="store.release(f.id)">Release</button>
          <button type="button" class="a-btn primary" :disabled="store.busy || f.disposition !== 'pending'" @click="decide(f, 'accept')">Accept</button>
          <button type="button" class="a-btn danger" :disabled="store.busy || f.disposition !== 'pending'" @click="decide(f, 'reject')">Reject</button>
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
.pager { display: flex; justify-content: space-between; align-items: center; gap: 12px; }
</style>
