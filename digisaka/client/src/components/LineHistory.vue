<script setup>
import { watch, onBeforeUnmount } from 'vue';
import { useLineHistoryStore } from '../stores/lineHistory.js';
import WeekCharts from './WeekCharts.vue';

// The last three weekly values of a line, so the practitioner sees the trend while choosing what to scan.
const props = defineProps({ line: { type: String, default: '' }, week: { type: String, default: '' } });
const store = useLineHistoryStore();
const load = () => store.load(props.line, props.week);
watch(() => [props.line, props.week], load, { immediate: true });
onBeforeUnmount(() => store.load('', ''));
</script>

<template>
  <section v-if="store.phase !== 'idle'" class="history" aria-label="Recent weeks for this line">
    <h3>Line {{ store.lineId }}: last 3 weeks</h3>
    <p v-if="store.phase === 'loading'" class="hint">Loading…</p>
    <p v-else-if="store.phase === 'error'" class="err">{{ store.error }} <button class="mark" type="button" @click="load">Try again</button></p>
    <WeekCharts v-else :weeks="store.weeks" />
  </section>
</template>

<style scoped>
.history { margin-top: 12px; }
h3 { margin: 0 0 6px; font-size: .95rem; }
svg { max-width: 420px; }
.hint { color: var(--ink-soft); font-size: .8rem; margin: 6px 0 0; }
.err { color: var(--danger); }
</style>
