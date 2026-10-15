<script setup>
import { RouterLink, RouterView, useRouter } from 'vue-router';
import { sessionState, signOut } from '../scheduler/session.js';

const router = useRouter();
function leave() { signOut(); router.push('/sign-in'); }
</script>

<template>
  <header class="bar">
    <b class="brand">Digisaka</b>
    <nav>
      <RouterLink to="/qa" active-class="active">QA Scheduler</RouterLink>
      <RouterLink v-if="sessionState.technicalUser" to="/admin" active-class="active">Admin console</RouterLink>
    </nav>
    <span class="who">{{ sessionState.email }}</span>
    <button type="button" @click="leave">Sign out</button>
  </header>
  <main class="page"><RouterView /></main>
</template>

<style scoped>
.bar { display: flex; align-items: center; gap: 16px; padding: 12px var(--gutter, 16px); border-bottom: 1px solid var(--line, #ddd); flex-wrap: wrap; }
.brand { font: 800 18px var(--font-display, inherit); color: var(--forest, inherit); }
nav { display: flex; gap: 12px; flex: 1; }
nav a { text-decoration: none; font-weight: 700; color: var(--forest, inherit); }
nav a.active { text-decoration: underline; }
.who { font-size: 14px; opacity: .75; }
.page { padding: 20px var(--gutter, 16px) 40px; }
</style>
