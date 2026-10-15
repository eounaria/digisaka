<script setup>
defineProps({ title: { type: String, required: true } });
</script>

<template>
  <header class="a-head"><h1>{{ title }}</h1></header>
  <div class="a-card box">
    <p class="a-note" role="status">Not available yet. This screen needs the workflow service to list workflows and their facts, which it cannot do today.</p>
    <p class="a-muted">Submit and review documents under Document Extractions.</p>
  </div>
</template>

<style scoped>
.box { padding: 20px; display: grid; gap: 12px; }
</style>
