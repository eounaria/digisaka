<script setup>
// Hosts a screen from the original prototype until it is ported to Vue. The frame hides the legacy
// chrome (embed=1) and shares this app's session cookie and API.
import { ref, computed, watch, onMounted } from 'vue';
import { useUseCaseStore } from '../stores/useCase.js';

const props = defineProps({ screen: String, extra: { type: Object, default: () => ({}) } });
const uc = useUseCaseStore();
const frame = ref(null), loaded = ref(false);
const src = computed(() => {
  const params = new URLSearchParams({ embed: '1', screen: props.screen, ...props.extra });
  return '/legacy/?' + params.toString();
});
const sendUseCase = () => frame.value?.contentWindow?.postMessage({ type: 'useCase', slug: uc.slug }, location.origin);
watch(() => uc.slug, sendUseCase);
onMounted(() => frame.value?.addEventListener('load', () => { loaded.value = true; sendUseCase(); }));
</script>

<template><iframe ref="frame" :key="src" class="frame" :class="{ loaded }" :src="src" title="Digisaka"></iframe></template>

<style scoped>
.frame { display: block; width: 100%; border: 0; background: transparent; opacity: 0; transition: opacity .3s var(--ease); height: calc(100dvh - var(--header-h) - var(--tabbar-h)); }
.frame.loaded { opacity: 1; }
</style>
