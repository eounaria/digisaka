<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth.js';
import { useLinesStore, dashboardSummary } from '../stores/lines.js';
import { today } from '../helpers/today.js';
import Icon from '../components/Icon.vue';

const router = useRouter();
const auth = useAuthStore();
const lines = useLinesStore();
const spin = ref(false);

const name = computed(() => {
  const w = auth.email.split('@')[0].split(/[._-]/)[0];
  return w ? w[0].toUpperCase() + w.slice(1) : '';
});

const initials = computed(() => {
  const parts = auth.email.split('@')[0].split(/[._-]/);
  return parts.map(p => p[0]?.toUpperCase() || '').slice(0, 2).join('');
});

const greeting = computed(() => `Good ${getTimeOfDay()}, ${name.value || 'User'}`);

function getTimeOfDay() {
  const h = new Date().getHours();
  if (h < 12) return 'Morning';
  if (h < 18) return 'Afternoon';
  return 'Evening';
}

const date = computed(() => {
  const d = new Date();
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return `${days[d.getDay()]}, ${months[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;
});

const time = computed(() => {
  const d = new Date();
  const h = d.getHours();
  const m = String(d.getMinutes()).padStart(2, '0');
  return `${(h % 12) || 12}:${m} ${h < 12 ? 'AM' : 'PM'}`;
});

const sum = computed(() => dashboardSummary(lines.statuses));
const STATUS = { proposed: 'Awaiting Decision', approved: 'Approved', rejected: 'Rejected', applied: 'Applied' };

const lastRefresh = ref(Date.now());
const updatedText = computed(() => {
  const mins = Math.floor((Date.now() - lastRefresh.value) / 60000);
  if (mins < 1) return 'just now';
  return `${mins} ${mins === 1 ? 'minute' : 'minutes'} ago`;
});

async function refresh() {
  spin.value = true;
  lastRefresh.value = Date.now();
  await lines.load();
  setTimeout(() => (spin.value = false), 500);
}

onMounted(() => {
  lines.load();
  setInterval(() => {
    // Force reactivity update for time/greeting
    time.value; // no-op to trigger reactivity
  }, 30000);
});

const open = (r) => router.push(`/treatment/${encodeURIComponent(r.lineId)}/${encodeURIComponent(r.week)}`);
</script>

<template>
  <div class="page">
    <!-- Greeting -->
    <h2 class="greeting">{{ greeting }}</h2>

    <!-- Hero Section -->
    <section class="hero" aria-label="Welcome">
      <div class="clock">
        <div class="time">{{ time }}</div>
        <div class="date">{{ date }}</div>
        <button class="refresh" type="button" @click="refresh">
          <Icon :name="spin ? 'refresh' : 'refresh'" :size="16" :class="{ spin }" />
          Refresh
        </button>
      </div>
      <div>
        <h2>Welcome back to <em>Digisaka</em></h2>
        <p>Monitor banana crop health and review Black Sigatoka scans, proposals and treatments across your lines.</p>
        <p class="updated">Last updated: <b>{{ updatedText }}</b></p>
      </div>
    </section>

    <!-- Shortcut Cards -->
    <section class="cards" aria-label="Shortcuts">
      <button class="card" type="button" @click="router.push('/scan')">
        <div class="tile">
          <Icon name="scan" :size="22" />
        </div>
        <div class="txt">
          <b>Disease Detection</b>
          <span>Scan banana leaves for Black Sigatoka</span>
        </div>
        <svg class="chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M9 6l6 6-6 6"/>
        </svg>
      </button>
      <button class="card" type="button" @click="router.push('/history')">
        <div class="tile">
          <Icon name="history" :size="22" />
        </div>
        <div class="txt">
          <b>Diagnosis History</b>
          <span>Review each line's weeks and proposals</span>
        </div>
        <svg class="chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M9 6l6 6-6 6"/>
        </svg>
      </button>
      <button class="card" type="button" @click="router.push('/schedule')">
        <div class="tile gold">
          <Icon name="calendar" :size="22" />
        </div>
        <div class="txt">
          <b>Smart Schedule</b>
          <span>Plan and track treatment</span>
        </div>
        <svg class="chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M9 6l6 6-6 6"/>
        </svg>
      </button>
    </section>

    <!-- Farm Overview Stats -->
    <div class="section-head">
      <h3>Farm Overview</h3>
      <a href="#" @click.prevent="router.push('/history')">View history →</a>
    </div>
    <section class="stats" aria-label="Farm overview">
      <div class="stat">
        <b>{{ sum.leavesScanned }}</b>
        <span>Leaves Scanned</span>
      </div>
      <div class="stat">
        <b>{{ sum.weeksAssessed }}</b>
        <span>Line-weeks Assessed</span>
      </div>
      <div class="stat">
        <b>{{ sum.awaitingDecision }}</b>
        <span>Awaiting Decision</span>
      </div>
    </section>

    <!-- Note about counts -->
    <p class="note" v-if="sum.lines > 0">
      Counts cover closed weeks across {{ sum.lines }} {{ sum.lines === 1 ? 'line' : 'lines' }}.
      <template v-if="sum.humanReview">
        {{ sum.humanReview }} {{ sum.humanReview === 1 ? 'line needs' : 'lines need' }} human review.
      </template>
    </p>

    <!-- Recent Proposals -->
    <section class="proposals" aria-label="Recent proposals">
      <h3>Recent proposals</h3>
      <div v-if="lines.loaded && !sum.recent.length" class="empty">
        No proposals yet. Scan a line and close its week to see one here.
        <button type="button" @click="router.push('/scan')">Start a scan</button>
      </div>
      <div v-else-if="sum.recent.length" class="proposal-list">
        <button
          v-for="r in sum.recent"
          :key="r.lineId + r.week"
          class="proposal"
          type="button"
          @click="open(r)"
        >
          <div class="grow">
            <b>Line {{ r.lineId }}</b>
            <span>{{ r.week }}</span>
          </div>
          <span class="badge" :class="r.status === 'proposed' ? 'warn' : 'ok'">
            {{ STATUS[r.status] ?? r.status }}
          </span>
        </button>
      </div>
    </section>
  </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap');

.page {
  font-family: 'Roboto', system-ui, -apple-system, 'Segoe UI', sans-serif;
}

/* Page spacing */
.page > section + section { margin-top: 20px; }
.page > div + section { margin-top: 28px; }
.page > p + section { margin-top: 28px; }

/* Greeting */
.greeting {
  margin: 0 0 16px 4px;
  font-size: 24px;
  font-weight: 700;
  color: var(--forest);
}

/* Hero */
.hero {
  background: var(--forest);
  color: #fff;
  border-radius: 24px;
  padding: 40px 58px;
  display: flex;
  align-items: center;
  gap: 100px;
  min-height: 196px;
}
.clock { flex: none; }
.time { font-size: 48px; font-weight: 700; line-height: 1.1; letter-spacing: -0.5px; }
.hero .date { font-size: 16px; margin: 8px 0 14px; color: rgba(255, 255, 255, 0.8); }
.refresh {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 38px;
  padding: 0 25px;
  border: 0;
  border-radius: 6px;
  background: #fff;
  color: var(--ink);
  font-size: 14px;
  font-weight: 500;
}
.refresh:hover { background: var(--beige); }
.refresh .spin { animation: turn .5s linear; }
@keyframes turn { to { transform: rotate(360deg); } }
.hero h2 { margin: 0 0 8px; font-size: 30px; font-weight: 700; }
.hero h2 em { font-style: normal; color: var(--banana); }
.hero p { margin: 0 0 14px; font-size: 16px; line-height: 1.4; color: rgba(255, 255, 255, 0.9); }
.updated { margin: 0; font-size: 14px; color: rgba(255, 255, 255, 0.7); }
.updated b { font-weight: 700; }

/* Cards */
.cards { display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px; }
.card {
  display: flex;
  align-items: center;
  gap: 16px;
  background: #fff;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 1px 4px rgba(16, 24, 40, .08);
  border: none;
  cursor: pointer;
  transition: box-shadow .15s, transform .15s;
}
.card:hover { box-shadow: 0 4px 12px rgba(16, 24, 40, .12); transform: translateY(-1px); }
.card:focus-visible { outline: 3px solid var(--leaf); outline-offset: 2px; }
.tile { width: 48px; height: 48px; border-radius: 12px; display: grid; place-items: center; background: var(--tint); color: var(--forest); }
.tile.gold { background: #fff4d6; color: #d97706; }
.tile :deep(svg) { width: 22px; height: 22px; }
.txt { flex: 1; min-width: 0; }
.txt b { display: block; font-size: 16px; font-weight: 700; color: var(--ink); }
.txt span { display: block; font-size: 12px; color: var(--ink-soft); margin-top: 4px; }
.chev { width: 20px; height: 20px; color: #9ca3af; flex: none; }

/* Section head */
.section-head { display: flex; align-items: baseline; justify-content: space-between; margin: 28px 0 14px; }
.section-head h3 { margin: 0; font-size: 18px; font-weight: 700; color: var(--forest); }
.section-head a { font-size: 14px; font-weight: 500; color: var(--forest); margin-right: 8px; }
.section-head a:hover { text-decoration: underline; }

/* Stats */
.stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px; }
.stat {
  background: #fff;
  border-radius: 12px;
  height: 126px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  box-shadow: 0 1px 4px rgba(16, 24, 40, .08);
}
.stat b { font-size: 30px; font-weight: 700; line-height: 1.2; color: var(--forest); }
.stat span { font-size: 14px; color: var(--ink-soft); margin-top: 4px; font-weight: 700; }

/* Note */
.note { margin-top: 10px; color: var(--ink-soft); font-size: 14px; }

/* Proposals */
.proposals { margin-top: 38px; }
.proposals h3 { margin: 0 0 14px; font-size: 18px; font-weight: 700; color: var(--forest); }
.proposal-list {
  overflow: hidden;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 1px 4px rgba(16, 24, 40, .08);
}
.proposal {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: transparent;
  padding: 24px;
  border: none;
  border-bottom: 1px solid var(--line);
  cursor: pointer;
  width: 100%;
  text-align: left;
  transition: background-color .15s;
}
.proposal:last-child { border-bottom: none; }
.proposal:hover { background: var(--tint); }
.proposal:focus-visible { outline: 3px solid var(--leaf); outline-offset: 2px; }
.grow { flex: 1; min-width: 0; display: grid; gap: 4px; }
.grow b { font-size: 16px; font-weight: 700; color: var(--ink); }
.grow span { font-size: 14px; color: var(--ink-soft); }
.badge { padding: 12px 23px; border-radius: 999px; font-size: 14px; font-weight: 700; white-space: nowrap; }
.badge.warn { background: #f3d9db; color: #a8222b; }
.badge.ok { background: var(--tint); color: var(--forest); }

/* Empty state */
.empty { padding: 26px; border: 1.5px dashed var(--line); border-radius: 12px; background: var(--card); text-align: center; color: var(--ink-soft); }
.empty button { display: block; margin: 14px auto 0; padding: 11px 22px; border: 0; border-radius: 14px; background: var(--forest); color: #fff; font: 800 15px var(--font-display); }

/* Responsive */
@media (max-width: 1100px) {
  .hero { gap: 40px; padding: 32px; flex-wrap: wrap; }
  .cards, .stats { grid-template-columns: 1fr; }
  .greeting { font-size: 22px; }
}
@media (max-width: 900px) {
  .hero { flex-direction: column; gap: 16px; padding: 24px; text-align: center; }
  .clock { text-align: center; }
  .time { font-size: 36px; }
  .hero h2 { font-size: 24px; }
  .cards, .stats { gap: 16px; }
  .proposal { flex-direction: column; align-items: flex-start; gap: 14px; }
  .badge { width: 100%; text-align: center; }
}
</style>