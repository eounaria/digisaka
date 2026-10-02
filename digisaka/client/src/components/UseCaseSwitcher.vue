<script setup>
import { useUseCaseStore } from '../stores/useCase.js';
const uc = useUseCaseStore();
</script>
<template>
  <label class="switcher">
    <span>Use case</span>
    <select aria-label="Use case" :value="uc.slug" @change="uc.select($event.target.value)">
      <option v-for="c in uc.cases" :key="c.slug" :value="c.slug">{{ c.icon }} {{ c.label }}</option>
    </select>
  </label>
</template>
<style scoped>
.switcher { display: flex; align-items: center; gap: 10px; padding: 0 12px 0 14px; height: 40px; border: 1px solid var(--line); border-radius: 999px; background: var(--tint); }
span { font: 800 11px var(--font-display); letter-spacing: .08em; text-transform: uppercase; color: var(--ink-soft); }
select { border: 0; background: transparent; font: 800 14px var(--font-display); color: var(--forest); cursor: pointer; padding-right: 4px; }
@media (max-width: 900px) { span { display: none; } .switcher { padding-left: 12px; } }
</style>
