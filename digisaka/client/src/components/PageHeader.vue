<script setup>
defineProps({ title: String, subtitle: String });
</script>
<template>
  <header class="page-header">
    <div><h1>{{ title }}</h1><p v-if="subtitle">{{ subtitle }}</p></div>
    <div class="actions"><slot /></div>
  </header>
</template>
<style scoped>
.page-header { display: flex; align-items: flex-end; justify-content: space-between; gap: 16px; margin-bottom: 20px; }
h1 { font: 800 28px/1.2 var(--font-display); color: var(--forest); }
p { color: var(--ink-soft); margin-top: 4px; }
.actions:empty { display: none; }
</style>
