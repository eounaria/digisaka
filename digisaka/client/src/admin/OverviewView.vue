<script setup>
import { ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import { api } from '../api.js';
import { useUseCaseStore } from '../stores/useCase.js';
import { qs, useLoader, compact, ago, ACTION, ACTION_ICON } from './util.js';

const uc = useUseCaseStore(), router = useRouter();
const data = ref(null), syncedAt = ref(null);
const { loading, error, run } = useLoader(() => api.get(`/api/admin/overview?${qs({ useCase: uc.slug })}`));
async function load() { const r = await run(); if (r) { data.value = r; syncedAt.value = new Date(); } }
watch(() => uc.slug, load, { immediate: true });

const k = () => data.value.kpis;
const cards = () => [
  { label: 'Knowledge entities', value: compact(k().entities), foot: k().entities ? 'In confirmed relationships' : 'Nothing confirmed yet', icon: '◎', tone: 'green' },
  { label: 'Relationships', value: compact(k().relationships), foot: k().avgConfidence == null ? 'None confirmed yet' : `${k().avgConfidence}% average confidence`, icon: '↗', tone: 'teal' },
  { label: 'Documents', value: compact(k().documents), foot: `${k().awaitingExtraction} awaiting extraction`, icon: '▤', tone: 'yellow' },
  { label: 'Images labeled', value: k().images ? `${k().imagesLabeledPct}%` : '—', foot: `${compact(k().images)} ${k().images === 1 ? 'asset' : 'assets'} in scope`, icon: '✓', tone: 'purple' },
];
const when = (d) => syncedAt.value && d;
</script>

<template>
  <div class="head">
    <div><h1>Operations dashboard</h1><p>Use-case health and knowledge pipeline overview for <strong>{{ uc.current.label }}</strong>.</p></div>
    <button type="button" class="synced" @click="load">{{ loading ? 'Refreshing…' : `Updated ${syncedAt?.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }) ?? ''} · Refresh` }}</button>
  </div>
  <p v-if="error" class="a-note err" role="alert">{{ error }}</p>

  <section v-if="!data && loading" class="kpis" aria-hidden="true"><article v-for="i in 4" :key="i" class="kpi"><span class="skel" style="height: 14px; width: 60%"></span><span class="skel" style="height: 34px; width: 40%; margin: 14px 0 8px"></span><span class="skel" style="height: 12px; width: 70%"></span></article></section>

  <template v-if="data">
    <section class="kpis">
      <article v-for="c in cards()" :key="c.label" class="kpi">
        <div class="top"><span>{{ c.label }}</span><i :class="c.tone">{{ c.icon }}</i></div>
        <b>{{ c.value }}</b><small>{{ c.foot }}</small>
      </article>
    </section>

    <section class="panel">
      <div class="panel-head"><h3>Pipeline health</h3><a href="#" @click.prevent="router.push('/admin/processing')">View processing</a></div>
      <div v-for="p in data.pipeline" :key="p.name" class="bar-row">
        <span class="name">{{ p.name }}</span>
        <div class="bar" role="progressbar" :aria-valuenow="p.pct" aria-valuemin="0" aria-valuemax="100" :aria-label="p.name" :title="p.note"><span :style="{ width: p.pct + '%' }"></span></div>
        <b>{{ p.pct }}%</b>
      </div>
    </section>

    <section class="bottom">
      <article class="scope">
        <div>
          <h3>Selected use case</h3>
          <p>{{ data.scope.pendingReview ? `${uc.current.label}: ${data.scope.pendingReview} relationship${data.scope.pendingReview === 1 ? '' : 's'} waiting for review.` : `${uc.current.label}: nothing is waiting for review.` }}</p>
        </div>
        <div class="scope-stats">
          <div><b>{{ data.scope.classes }}</b><span>Ontology classes</span></div>
          <div><b>{{ data.scope.relations }}</b><span>Relation types</span></div>
          <div><b>{{ data.scope.pendingReview }}</b><span>Pending review</span></div>
        </div>
      </article>
      <article class="panel">
        <div class="panel-head"><h3>Latest activity</h3><a href="#" @click.prevent="router.push('/admin/history')">History</a></div>
        <ul v-if="data.activity.length">
          <li v-for="a in data.activity" :key="a.id">
            <i class="ico">{{ ACTION_ICON[a.action] ?? '◎' }}</i>
            <div><b>{{ ACTION[a.action] ?? a.action }} · {{ a.objectType.toLowerCase() }}</b><small>{{ a.objectLabel }} · {{ a.actor }}</small></div>
            <span>{{ when(ago(a.createdAt)) }}</span>
          </li>
        </ul>
        <p v-else class="a-empty">No activity yet. Upload a document to get started.</p>
      </article>
    </section>
  </template>
</template>

<style scoped>
.head { display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; margin-bottom: 20px; }
h1 { font: 800 30px/1.2 var(--font-display); color: var(--forest); }
.head p { margin-top: 4px; color: var(--ink-soft); }
.synced { padding: 9px 14px; border: 1px solid var(--line); border-radius: 12px; background: #fff; font-size: 13.5px; font-weight: 800; color: var(--ink-soft); white-space: nowrap; }
.synced:hover { background: var(--tint); }
.kpis { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; }
.kpi { padding: 18px; border: 1px solid var(--line); border-radius: var(--radius-md); background: #fff; box-shadow: var(--shadow); }
.kpi .top { display: flex; justify-content: space-between; align-items: center; font-weight: 800; font-size: 14px; color: var(--ink-soft); }
.kpi i { display: grid; place-items: center; width: 32px; height: 32px; border-radius: 10px; font-style: normal; color: #fff; }
.green { background: var(--forest); } .teal { background: var(--teal); } .yellow { background: var(--banana); color: #5B4300 !important; } .purple { background: var(--stat-purple); }
.kpi b { display: block; margin: 10px 0 2px; font: 800 34px/1.1 var(--font-display); color: var(--forest); }
.kpi small { color: var(--ink-soft); }
.panel { margin-top: 16px; padding: 22px; border: 1px solid var(--line); border-radius: var(--radius-lg); background: #fff; box-shadow: var(--shadow); }
.panel-head { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 14px; }
h3 { font: 800 18px var(--font-display); color: var(--forest); }
.panel-head a { font-weight: 800; font-size: 14px; color: var(--teal); }
.bar-row { display: grid; grid-template-columns: 150px 1fr 48px; align-items: center; gap: 16px; padding: 7px 0; }
.name { font-weight: 800; color: var(--ink-soft); }
.bar { height: 10px; border-radius: 999px; background: #EAF0EC; overflow: hidden; }
.bar span { display: block; height: 100%; border-radius: inherit; background: linear-gradient(90deg, var(--leaf), var(--teal)); }
.bar-row b { text-align: right; color: var(--forest); }
.bottom { display: grid; grid-template-columns: 1.15fr 1fr; gap: 16px; margin-top: 16px; }
.bottom .panel { margin-top: 0; }
.scope { display: flex; flex-direction: column; justify-content: space-between; gap: 20px; padding: 22px; border-radius: var(--radius-lg); color: #fff; background: linear-gradient(140deg, #0A8A49, var(--forest-deep)); }
.scope h3 { color: #fff; } .scope p { margin-top: 6px; color: rgba(255, 255, 255, .85); }
.scope-stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }
.scope-stats div { padding: 14px; border-radius: 14px; background: rgba(255, 255, 255, .12); }
.scope-stats b { display: block; font: 800 24px var(--font-display); } .scope-stats span { font-size: 13px; color: rgba(255, 255, 255, .8); }
li { display: flex; align-items: center; gap: 14px; padding: 12px 0; border-top: 1px solid var(--line); }
li:first-child { border-top: 0; }
.ico { display: grid; place-items: center; flex: none; width: 34px; height: 34px; border-radius: 10px; background: var(--tint); color: var(--forest); font-style: normal; font-weight: 800; }
li div { flex: 1; display: grid; min-width: 0; } li b { font-size: 15px; } li small { color: var(--ink-soft); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; } li > span { font-weight: 800; color: var(--forest); }
@media (max-width: 1100px) { .kpis { grid-template-columns: repeat(2, 1fr); } .bottom { grid-template-columns: 1fr; } }
@media (max-width: 600px) { .kpis { grid-template-columns: 1fr; } .bar-row { grid-template-columns: 1fr 44px; } .bar-row .bar { grid-column: 1 / -1; grid-row: 2; } .synced { display: none; } }
</style>
