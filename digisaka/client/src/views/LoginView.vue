<script setup>
import { ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useAuthStore } from '../stores/auth.js';
import { landingFor, safeNext } from '../routeGuard.js';

const router = useRouter(), route = useRoute(), auth = useAuthStore();
const busy = ref(false), error = ref('');
const f = ref({ email: '', password: '' });

async function submit() {
  busy.value = true; error.value = '';
  try {
    await auth.signIn(f.value.email, f.value.password);
    router.push(safeNext(route.query.next) ?? landingFor(auth));
  } catch (e) { error.value = e.message; }
  finally { busy.value = false; }
}
</script>

<template>
  <div class="login-page">
    <section class="brand-side">
      <div class="brand"><i>🍌</i>Digisaka</div>
      <div>
        <h2>Catch Black Sigatoka before it spreads</h2>
        <p>Scan banana leaves, assess them in bulk, and schedule treatment while it still works.</p>
      </div>
    </section>
    <section class="form-side">
      <form novalidate @submit.prevent="submit">
        <h1>Sign in</h1>
        <p class="sub">Use your Digisaka account.</p>
        <label for="email">Email</label><input id="email" v-model="f.email" type="email" autocomplete="email" required>
        <label for="password">Password</label><input id="password" v-model="f.password" type="password" autocomplete="current-password" required>
        <div class="err" role="alert">{{ error }}</div>
        <button class="primary" :disabled="busy" type="submit">Sign in</button>
        <button class="link" type="button" disabled title="Not available yet. Accounts come from Digisaka.">Create an account (not available yet)</button>
      </form>
    </section>
  </div>
</template>

<style scoped>
.login-page { font-family: var(--font-body); color: var(--ink); background: var(--bg); min-height: 100vh; display: grid; grid-template-columns: minmax(320px, 5fr) 7fr; }
.brand-side { background: linear-gradient(180deg, var(--forest), var(--forest-deep)); color: #fff; padding: 48px; display: flex; flex-direction: column; justify-content: space-between; }
.brand { display: flex; align-items: center; gap: 12px; font: 800 26px var(--font-display); }
.brand i { width: 40px; height: 40px; border-radius: 12px; background: rgba(255, 255, 255, .14); display: grid; place-items: center; font-style: normal; font-size: 22px; }
.brand-side h2 { font: 800 34px/1.2 var(--font-display); max-width: 14em; margin-bottom: 12px; }
.brand-side p { color: rgba(255, 255, 255, .72); font-size: 17px; max-width: 24em; }
.form-side { display: grid; place-items: center; padding: 32px; }
form { width: 100%; max-width: 400px; }
h1 { font: 800 28px var(--font-display); margin-bottom: 6px; }
.sub { color: var(--ink-soft); margin-bottom: 26px; }
label { display: block; font-weight: 700; font-size: 14px; margin: 16px 0 6px; }
input { width: 100%; padding: 13px 14px; border: 1.5px solid var(--line); border-radius: 12px; font: 600 16px var(--font-body); background: #fff; color: var(--ink); }
button.primary { width: 100%; margin-top: 24px; padding: 14px; border: 0; border-radius: 14px; background: var(--forest); color: #fff; font: 800 16px var(--font-display); cursor: pointer; }
button.primary:disabled { opacity: .6; cursor: wait; }
button.link:disabled { opacity: .45; cursor: not-allowed; text-decoration: none; }
button.link { background: none; border: 0; color: var(--forest); font: 700 15px var(--font-body); cursor: pointer; margin-top: 18px; text-decoration: underline; }
.err { color: var(--danger); font-weight: 700; font-size: 14px; margin-top: 14px; min-height: 1.3em; }
@media (max-width: 760px) { .login-page { grid-template-columns: 1fr; } .brand-side { padding: 24px; gap: 24px; } .brand-side h2 { font-size: 24px; } }
</style>
