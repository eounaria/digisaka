<script setup>
import { ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import { api } from '../api.js';
import { useUseCaseStore } from '../stores/useCase.js';
import GraphCanvas from './GraphCanvas.vue';
import { qs, useLoader } from './util.js';

const uc = useUseCaseStore(), router = useRouter();
const g = ref(null);
const { loading, error, run } = useLoader(() => api.get(`/api/admin/graph?${qs({ useCase: uc.slug })}`));
async function load() { const r = await run(); if (r) g.value = r; }
watch(() => uc.slug, load, { immediate: true });
</script>

<template>
  <header class="a-head"><h1>Knowledge Graph</h1><p>{{ uc.current.label }} graph · confirmed relationships only.</p></header>
  <p v-if="error" class="a-note err" role="alert">{{ error }}</p>
  <div v-if="g" class="shell">
    <div class="canvas">
      <GraphCanvas v-if="g.edges.length" :nodes="g.nodes" :edges="g.edges" :label="`${uc.current.label} knowledge graph`" />
      <div v-else class="a-card a-empty">
        <p>Nothing has been confirmed for {{ uc.current.label }} yet.</p>
        <button type="button" class="a-btn primary" @click="router.push('/admin/processing')">Review relationships</button>
      </div>
      <p v-if="g.truncated" class="a-muted cap">Showing the 150 most recently confirmed relationships.</p>
    </div>
    <aside>
      <div class="box"><div class="h"><span>Entities</span><span>{{ loading ? '…' : 'Live' }}</span></div><b>{{ g.stats.entities.toLocaleString() }}</b><small>distinct nodes</small></div>
      <div class="box"><div class="h"><span>Relationships</span></div><b>{{ g.stats.relationships.toLocaleString() }}</b><small>confirmed triples</small></div>
      <div class="box"><div class="h"><span>Class distribution</span></div>
        <div v-if="g.classes.length" class="badges"><span v-for="c in g.classes" :key="c.name" class="badge"><i :style="{ background: c.color }"></i>{{ c.name }} {{ c.pct }}%</span></div>
        <small v-else>No classes yet.</small>
      </div>
    </aside>
  </div>
</template>

<style scoped>
.shell { display: grid; grid-template-columns: 1fr 280px; gap: 18px; align-items: start; }
.cap { margin-top: 8px; font-size: 13.5px; }
aside { display: grid; gap: 14px; }
.box { padding: 16px 18px; border: 1px solid var(--line); border-radius: var(--radius-md); background: #fff; box-shadow: var(--shadow); }
.h { display: flex; justify-content: space-between; font-weight: 800; font-size: 14px; color: var(--ink-soft); }
.box b { display: block; margin: 6px 0 0; font: 800 32px/1.1 var(--font-display); color: var(--forest); }
.box small { color: var(--ink-soft); }
.badges { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 10px; }
.badge { display: inline-flex; align-items: center; gap: 7px; padding: 5px 11px; border-radius: 999px; background: var(--tint); font-weight: 800; font-size: 13px; color: var(--forest); }
.badge i { width: 10px; height: 10px; border-radius: 50%; }
@media (max-width: 1000px) { .shell { grid-template-columns: 1fr; } }
</style>
