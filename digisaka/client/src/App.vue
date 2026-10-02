<script setup>
import { RouterView } from 'vue-router';
</script>

<template>
  <RouterView v-slot="{ Component, route }">
    <Transition name="fade" mode="out-in"><component :is="Component" :key="route.matched[0]?.path" /></Transition>
  </RouterView>
</template>
