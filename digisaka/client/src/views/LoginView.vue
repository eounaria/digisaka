<script setup>
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth.js';

const router = useRouter(), auth = useAuthStore();
const register = ref(false), busy = ref(false), error = ref('');
const f = ref({ name: '', email: '', password: '', location: '' });
const title = computed(() => (register.value ? 'Create your account' : 'Sign in'));

async function submit() {
  busy.value = true; error.value = '';
  try {
    const { name, email, password, location } = f.value;
    await auth.submit(register.value ? 'register' : 'login', register.value ? { name, email: email.trim(), password, location } : { email: email.trim(), password });
    router.push('/');
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
        <h1>{{ title }}</h1>
        <p class="sub">{{ register ? 'Set up your farm profile to start scanning.' : 'Use the account for your farm.' }}</p>
        <template v-if="register"><label for="name">Full name</label><input id="name" v-model="f.name" autocomplete="name"></template>
        <label for="email">Email</label><input id="email" v-model="f.email" type="email" autocomplete="email" required>
        <label for="password">Password</label><input id="password" v-model="f.password" type="password" :autocomplete="register ? 'new-password' : 'current-password'" required>
        <template v-if="register"><label for="location">Farm location</label><input id="location" v-model="f.location" placeholder="Barangay, town, province"></template>
        <div class="err" role="alert">{{ error }}</div>
        <button class="primary" :disabled="busy" type="submit">{{ register ? 'Create account' : 'Sign in' }}</button>
        <button class="link" type="button" @click="register = !register; error = ''">{{ register ? 'I already have an account' : 'Create an account' }}</button>
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
button.link { background: none; border: 0; color: var(--forest); font: 700 15px var(--font-body); cursor: pointer; margin-top: 18px; text-decoration: underline; }
.err { color: var(--danger); font-weight: 700; font-size: 14px; margin-top: 14px; min-height: 1.3em; }
@media (max-width: 760px) { .login-page { grid-template-columns: 1fr; } .brand-side { padding: 24px; gap: 24px; } .brand-side h2 { font-size: 24px; } }
</style>
