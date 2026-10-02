<script setup>
// Placeholder cards shown while a list loads, shaped like the real cards so nothing jumps.
defineProps({ rows: { type: Number, default: 3 } });
</script>
<template>
  <div aria-hidden="true">
    <div v-for="i in rows" :key="i" class="skel-card"><span class="skel"></span><div><span class="skel" style="height: 14px; width: 45%"></span><span class="skel" style="height: 12px; width: 70%"></span></div></div>
  </div>
</template>
