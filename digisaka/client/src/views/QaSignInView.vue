<script setup>
import { ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import PageHeader from '../components/PageHeader.vue';
import { signIn } from '../scheduler/session.js';

const router = useRouter(), route = useRoute();
const email = ref(''), password = ref(''), busy = ref(false), error = ref('');

const safeNext = (n) => (typeof n === 'string' && n !== '/qa/sign-in' && (n === '/qa' || n.startsWith('/qa/')) ? n : '/qa');

async function submit() {
  busy.value = true; error.value = '';
  try {
    await signIn(email.value, password.value);
    router.push(safeNext(route.query.next));
  } catch (e) { error.value = e.message; }
  finally { busy.value = false; }
}
</script>

<template>
  <PageHeader title="QA sign-in" />
  <form class="qa-form" novalidate @submit.prevent="submit">
    <p class="sub">Sign in with your Practitioner account to use the line-week screens.</p>
    <label for="qa-email">Email</label><input id="qa-email" v-model="email" type="email" autocomplete="email" required>
    <label for="qa-password">Password</label><input id="qa-password" v-model="password" type="password" autocomplete="current-password" required>
    <div class="err" role="alert">{{ error }}</div>
    <button class="primary" :disabled="busy" type="submit">Sign in</button>
  </form>
</template>

<style scoped>
.qa-form { max-width: 360px; display: grid; gap: 8px; }
</style>
