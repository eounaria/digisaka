<script setup>
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth.js';
import PageHeader from '../components/PageHeader.vue';

const router = useRouter(), auth = useAuthStore();
const GROUPS = [
  { label: 'Account', rows: [{ ic: '👤', text: 'User Information' }, { ic: '🌱', text: 'Farm Information' }] },
  { label: 'Preferences', rows: [{ ic: '🔔', text: 'Notifications', value: 'On' }, { ic: '🌐', text: 'Language', value: 'English' }] },
  { label: 'Support', rows: [{ ic: 'ℹ️', text: 'About Digisaka' }, { ic: '❓', text: 'Help & Support' }] },
];
async function signOut() { await auth.logout(); router.push('/login'); }
</script>

<template>
  <div v-if="auth.user" class="page narrow">
    <PageHeader title="My Profile" />
    <section class="head">
      <div class="avatar">{{ auth.user.initials }}</div>
      <h2>{{ auth.user.name }}</h2>
      <p>{{ auth.user.location || auth.user.email }}</p>
    </section>
    <section v-for="g in GROUPS" :key="g.label" class="group">
      <h3>{{ g.label }}</h3>
      <div v-for="r in g.rows" :key="r.text" class="row"><span class="ic">{{ r.ic }}</span><span class="t">{{ r.text }}</span><span class="v">{{ r.value }} ›</span></div>
    </section>
    <section class="group"><button class="row out" type="button" @click="signOut"><span class="ic">🚪</span><span class="t">Sign out</span><span class="v">›</span></button></section>
  </div>
</template>

<style scoped>
.narrow { max-width: 760px; }
.head { display: grid; justify-items: center; gap: 4px; padding: 26px; border-radius: 22px; background: linear-gradient(135deg, #9AD9AE, #EFE7D6); }
.avatar { display: grid; place-items: center; width: 66px; height: 66px; border-radius: 50%; background: var(--forest); color: #fff; font: 800 24px var(--font-display); }
.head h2 { font: 800 19px var(--font-display); color: var(--forest); } .head p { color: var(--ink-soft); }
.group { margin-top: 22px; display: grid; gap: 8px; }
.group h3 { padding-left: 4px; font: 800 12px var(--font-display); letter-spacing: .08em; text-transform: uppercase; color: var(--ink-soft); }
.row { display: flex; align-items: center; gap: 14px; width: 100%; padding: 14px 16px; border: 0; border-radius: var(--radius-sm); background: var(--card); box-shadow: var(--shadow); text-align: left; }
.ic { display: grid; place-items: center; width: 34px; height: 34px; border-radius: 10px; background: var(--beige); }
.t { flex: 1; font-weight: 800; } .v { color: var(--ink-soft); font-weight: 700; }
button.row:hover { background: var(--tint); }
</style>
