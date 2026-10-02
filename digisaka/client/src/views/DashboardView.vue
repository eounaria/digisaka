<script setup>
import { computed, onMounted, onBeforeUnmount, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth.js';
import { useUseCaseStore } from '../stores/useCase.js';
import { useFarmStore } from '../stores/farm.js';
import Icon from '../components/Icon.vue';

const router = useRouter(), auth = useAuthStore(), uc = useUseCaseStore(), farm = useFarmStore();
const now = ref(new Date()), spin = ref(false);
let tick;

const greeting = computed(() => { const h = now.value.getHours(); return `${h < 12 ? 'GOOD MORNING' : h < 18 ? 'GOOD AFTERNOON' : 'GOOD EVENING'}, ${auth.firstName.toUpperCase()}`; });
const clock = computed(() => now.value.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }));
const date = computed(() => now.value.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric', year: 'numeric' }));
const needs = (b) => Object.values(b.counts).reduce((a, n) => a + n, 0);

async function refresh() { spin.value = true; await farm.refresh().catch(() => {}); setTimeout(() => (spin.value = false), 500); }
onMounted(() => { farm.refresh().catch(() => {}); tick = setInterval(() => (now.value = new Date()), 30000); });
onBeforeUnmount(() => clearInterval(tick));
</script>

<template>
  <div class="page">
    <section class="hero">
      <div class="hero-copy">
        <p class="eyebrow">{{ greeting }}</p>
        <h1>Welcome back to <em>Digisaka</em></h1>
        <p class="lead">Monitor {{ uc.current.crop.toLowerCase() }} crop health and review {{ uc.current.disease }} knowledge in the {{ uc.current.label }} workspace.</p>
        <p class="updated">Last updated: <b>just now</b></p>
      </div>
      <div class="hero-side">
        <div class="time">{{ clock }}</div>
        <div class="date">{{ date }}</div>
        <button class="refresh" :class="{ spin }" type="button" @click="refresh"><Icon name="refresh" :size="15" />Refresh</button>
      </div>
    </section>

    <section class="actions">
      <button class="action primary" type="button" @click="router.push('/scan')">
        <span class="tile dark"><Icon name="scan" /></span>
        <span class="txt"><b>Disease Detection</b><small>Scan {{ uc.current.crop.toLowerCase() }} leaves for {{ uc.current.disease }}</small></span><i>›</i>
      </button>
      <button class="action" type="button" @click="router.push('/history')">
        <span class="tile teal"><Icon name="history" /></span>
        <span class="txt"><b>Diagnosis History</b><small>Review past bulk assessments</small></span><i>›</i>
      </button>
      <button class="action" type="button" @click="router.push('/schedule')">
        <span class="tile yellow">🗓️</span>
        <span class="txt"><b>Smart Schedule</b><small>Plan and track treatment</small></span><i>›</i>
      </button>
    </section>

    <section>
      <div class="section-head"><h2>Farm Overview</h2><a href="#" @click.prevent="router.push('/history')">View Bulks →</a></div>
      <div class="stats">
        <div class="stat"><span class="chip blue"><Icon name="plus" :size="18" /></span><b>{{ farm.stats.leavesScanned }}</b><small>Leaves Scanned</small></div>
        <div class="stat"><span class="chip purple"><Icon name="history" :size="18" /></span><b>{{ farm.stats.bulksAssessed }}</b><small>Bulks Assessed</small></div>
        <div class="stat"><span class="chip orange"><Icon name="alert" :size="18" /></span><b>{{ farm.stats.leavesNeedingTreatment }}</b><small>Need Treatment</small></div>
      </div>
    </section>

    <section>
      <div class="section-head"><h2>Recent assessments</h2></div>
      <div v-if="!farm.recent.length" class="empty">
        No assessments yet. Scan a few leaves to see results here.
        <button type="button" @click="router.push('/scan')">Start a scan</button>
      </div>
      <button v-for="b in farm.recent" :key="b.bulkId" class="recent" type="button" @click="router.push('/history')">
        <span class="grow"><b>{{ b.plant }}</b><small>{{ b.bulkId }} · {{ b.date }} · {{ b.leafCount }} leaves</small></span>
        <span class="badge" :class="needs(b) ? 'warn' : 'ok'">{{ needs(b) ? needs(b) + ' need treatment' : 'All clear' }}</span>
      </button>
    </section>
  </div>
</template>

<style scoped>
.page > section + section { margin-top: 28px; }
.hero { position: relative; overflow: hidden; display: flex; justify-content: space-between; gap: 24px; padding: 30px; border-radius: 26px; color: #fff; background: linear-gradient(135deg, #0FA85B, var(--forest-deep)); }
.hero::after { content: ''; position: absolute; top: -70px; right: -50px; width: 240px; height: 240px; border-radius: 50%; background: rgba(255, 255, 255, .08); pointer-events: none; }
.eyebrow { font: 800 13px var(--font-display); letter-spacing: .12em; color: rgba(255, 255, 255, .78); }
h1 { margin: 8px 0; font: 800 30px/1.2 var(--font-display); }
h1 em { font-style: normal; color: var(--banana); }
.lead { max-width: 34em; color: rgba(255, 255, 255, .88); }
.updated { margin-top: 14px; font-size: 14px; color: rgba(255, 255, 255, .78); }
.hero-side { position: relative; z-index: 1; text-align: right; }
.time { font: 800 34px var(--font-display); }
.date { margin: 2px 0 14px; font-weight: 700; color: rgba(255, 255, 255, .78); }
.refresh { display: inline-flex; align-items: center; gap: 8px; padding: 9px 18px; border: 1px solid rgba(255, 255, 255, .3); border-radius: 999px; background: rgba(255, 255, 255, .14); color: #fff; font-weight: 800; }
.refresh:hover { background: rgba(255, 255, 255, .22); }
.refresh.spin :deep(svg) { animation: turn .5s linear; }
@keyframes turn { to { transform: rotate(360deg); } }
.actions { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-top: 20px; }
.action { display: flex; align-items: center; gap: 14px; min-height: 96px; padding: 16px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); text-align: left; box-shadow: var(--shadow); transition: border-color .15s, transform .15s; }
.action:hover { border-color: var(--leaf); transform: translateY(-1px); }
.action.primary { background: var(--tint); border-color: rgba(10, 159, 85, .35); }
.tile { display: grid; place-items: center; flex: none; width: 44px; height: 44px; border-radius: 14px; color: #fff; font-size: 20px; }
.tile.dark { background: var(--forest); } .tile.teal { background: var(--teal); } .tile.yellow { background: var(--banana); }
.txt { flex: 1; min-width: 0; display: grid; gap: 2px; }
.txt b { font: 800 16px var(--font-display); }
.txt small { color: var(--ink-soft); font-weight: 700; font-size: 14px; line-height: 1.35; }
.action i { font-style: normal; font-size: 22px; color: var(--ink-soft); }
.section-head { display: flex; align-items: baseline; justify-content: space-between; margin-bottom: 12px; }
.section-head h2 { font: 800 18px var(--font-display); color: var(--forest); }
.section-head a { font-weight: 800; font-size: 14px; color: var(--teal); }
.stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
.stat { display: grid; justify-items: center; gap: 4px; padding: 18px 12px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); box-shadow: var(--shadow); }
.stat b { font: 800 30px/1.1 var(--font-display); color: var(--forest); }
.stat small { font-weight: 800; color: var(--ink-soft); }
.chip { display: grid; place-items: center; width: 36px; height: 36px; border-radius: 11px; }
.chip.blue { background: #E8F0FE; color: var(--stat-blue); } .chip.purple { background: #F0EBFE; color: var(--stat-purple); } .chip.orange { background: #FFF1DC; color: var(--stat-orange); }
.empty { padding: 26px; border: 1.5px dashed var(--line); border-radius: var(--radius-md); background: var(--card); text-align: center; color: var(--ink-soft); }
.empty button { display: block; margin: 14px auto 0; padding: 11px 22px; border: 0; border-radius: 14px; background: var(--forest); color: #fff; font: 800 15px var(--font-display); }
.recent { display: flex; align-items: center; gap: 14px; width: 100%; margin-bottom: 10px; padding: 14px 16px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); text-align: left; }
.recent:hover { border-color: var(--leaf); }
.grow { flex: 1; min-width: 0; display: grid; }
.grow b { font: 700 16px var(--font-display); } .grow small { color: var(--ink-soft); }
.badge { padding: 5px 11px; border-radius: 999px; font: 800 13px var(--font-body); white-space: nowrap; }
.badge.ok { background: var(--tint); color: var(--forest); } .badge.warn { background: var(--warn-tint); color: #B4432A; }
@media (max-width: 900px) {
  .hero { flex-direction: column; gap: 14px; padding: 22px; }
  h1 { font-size: 26px; } .hero-side { text-align: left; } .time, .date { display: none; }
  .actions { grid-template-columns: 1fr; gap: 12px; }
  .stats { gap: 10px; } .stat b { font-size: 26px; }
}
</style>
