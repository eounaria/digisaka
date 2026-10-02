<script setup>
defineProps({ tone: { type: String, default: 'neutral' } });
</script>
<template><span class="a-pill" :class="tone"><slot /></span></template>
