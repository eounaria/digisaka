<script setup>
import { ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { signIn } from '../scheduler/session.js';

const router = useRouter(), route = useRoute();
const email = ref(''), password = ref(''), busy = ref(false), error = ref('');

// Only same-site paths, never another sign-in page or an external address.
const safeNext = (n) => (typeof n === 'string' && /^\/(?!\/)/.test(n) && n !== '/sign-in' ? n : '/qa');

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
  <div class="sign-in">
    <h1>Digisaka sign-in</h1>
    <form class="form" novalidate @submit.prevent="submit">
      <p class="sub">Use your AI_NeSy account.</p>
      <label for="si-email">Email</label><input id="si-email" v-model="email" type="email" autocomplete="email" required>
      <label for="si-password">Password</label><input id="si-password" v-model="password" type="password" autocomplete="current-password" required>
      <div class="err" role="alert">{{ error }}</div>
      <button class="primary" :disabled="busy" type="submit">Sign in</button>
    </form>
  </div>
</template>

<style scoped>
.sign-in { max-width: 360px; margin: 12vh auto 0; padding: 0 var(--gutter, 16px); }
.form { display: grid; gap: 8px; }
</style>
