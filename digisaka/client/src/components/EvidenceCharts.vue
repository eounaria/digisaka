<script setup>
import { computed, watch, onBeforeUnmount } from 'vue';
import { useEvidenceStore } from '../stores/evidence.js';
import { verdictText, visibleWeeks } from '../helpers/evidence.js';
import WeekCharts from './WeekCharts.vue';

// What the rules looked at for one cycle: the last weeks of YLS/YLI and rainfall, with the verdicts.
const props = defineProps({ cycleId: { type: String, default: '' } });
const store = useEvidenceStore();
const load = () => (props.cycleId ? store.load(props.cycleId) : store.reset());
watch(() => props.cycleId, load, { immediate: true });
onBeforeUnmount(() => store.reset());
const ev = computed(() => (store.phase === 'ready' ? store.evidence : null));
const weeks = computed(() => (ev.value ? visibleWeeks(ev.value) : []));
</script>

<template>
  <section v-if="store.phase === 'loading' || store.phase === 'error' || ev" class="evidence" aria-label="Evidence">
    <h3>What the system looked at <small>(last 3 weeks and the weeks compared)</small></h3>
    <p v-if="store.phase === 'loading'" class="hint">Loading the evidence…</p>
    <p v-else-if="store.phase === 'error'" class="err">{{ store.error }} <button class="mark" type="button" @click="load">Try again</button></p>
    <template v-else-if="ev && weeks.length">
      <div class="chips">
        <span class="chip" :class="String(ev.disease.worsening)">Disease getting worse: {{ verdictText(ev.disease.worsening) }}</span>
        <span class="chip" :class="String(ev.rainfall.favourable)">Rainfall favours spread: {{ verdictText(ev.rainfall.favourable) }}</span>
      </div>
      <WeekCharts :weeks="weeks" :disease="ev.disease" :rainfall="ev.rainfall" />
    </template>
  </section>
</template>

<style scoped>
.evidence { background: var(--card); border: 1px solid var(--line); border-radius: var(--radius-md); padding: 16px; margin-top: 14px; box-shadow: var(--shadow); }
h3 { margin: 0 0 10px; font-size: 1rem; }
h3 small { font-weight: 400; color: var(--ink-soft); }
.chips { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 10px; }
.chip { font-size: .85rem; padding: 4px 10px; border-radius: 999px; background: var(--tint); color: var(--forest-deep); }
.chip.true { background: var(--warn-tint); color: var(--warn); }
.chip.not_computable { background: var(--beige); color: var(--ink-soft); }
.hint { color: var(--ink-soft); }
.err { color: var(--danger); }
</style>
