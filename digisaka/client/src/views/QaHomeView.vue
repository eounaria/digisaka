<script setup>
import { ref, onMounted } from 'vue';
import { useRouter, RouterLink } from 'vue-router';
import PageHeader from '../components/PageHeader.vue';
import { scheduler, signOut } from '../scheduler/session.js';
import { messageFor } from '../scheduler/client.js';
import { isoWeekOf } from '../scheduler/week.js';

const router = useRouter();
const lines = ref(null), error = ref('');
const status = ref({});
const week = isoWeekOf(new Date());

function statusText(s) {
  if (!s) return '';
  if (s.human_review_required) return 'Human review required';
  const c = s.latest_cycle;
  return c ? `Last cycle ${c.week}: ${c.status}` : 'No cycles yet';
}

async function load() {
  error.value = '';
  try {
    const r = await scheduler.listLines();
    lines.value = r.lines ?? [];
    await Promise.all(lines.value.map(async (id) => {
      try { status.value[id] = await scheduler.getLine(id); } catch { /* status stays blank */ }
    }));
  } catch (e) { error.value = messageFor(e); }
}
function leave() { signOut(); router.push('/qa/sign-in'); }
onMounted(load);
</script>

<template>
  <PageHeader title="QA scheduler" subtitle="Pick a line to scan its leaves for a week.">
    <button @click="leave">Sign out</button>
  </PageHeader>
  <div class="err" role="alert">{{ error }}</div>
  <p v-if="!lines && !error">Loading lines...</p>
  <ul v-else-if="lines" class="lines">
    <li v-for="id in lines" :key="id">
      <RouterLink :to="{ path: `/qa/lines/${id}`, query: { week } }"><strong>{{ id }}</strong></RouterLink>
      <span class="st">{{ statusText(status[id]) }}</span>
    </li>
  </ul>
</template>

<style scoped>
.lines { list-style: none; padding: 0; display: grid; gap: 8px; max-width: 520px; }
.lines li { display: flex; justify-content: space-between; gap: 12px; padding: 12px 16px; background: var(--card); border: 1px solid var(--line); border-radius: var(--radius-md); box-shadow: var(--shadow); }
.st { color: var(--ink-soft); }
</style>
