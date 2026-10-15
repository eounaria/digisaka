<script setup>
import { ref, onMounted } from 'vue';
import PageHeader from '../components/PageHeader.vue';
import { scheduler, signOut } from '../scheduler/session.js';
import { messageFor } from '../scheduler/client.js';
import { useRouter } from 'vue-router';

const router = useRouter();
const lines = ref(null), error = ref('');

async function load() {
  error.value = '';
  try { const r = await scheduler.listLines(); lines.value = Array.isArray(r) ? r : []; }
  catch (e) { error.value = messageFor(e); }
}
function leave() { signOut(); router.push('/qa/sign-in'); }
onMounted(load);
</script>

<template>
  <PageHeader title="QA scheduler" subtitle="Signed in as a Practitioner.">
    <button @click="leave">Sign out</button>
  </PageHeader>
  <div class="err" role="alert">{{ error }}</div>
  <p v-if="!lines && !error">Loading lines...</p>
  <p v-else-if="lines">Scheduler reachable: {{ lines.length }} lines.</p>
</template>
