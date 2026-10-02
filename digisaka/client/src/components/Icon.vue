<script setup>
import { computed } from 'vue';
const PATHS = {
  home: '<path d="M3 11l9-8 9 8"/><path d="M5 10v10h14V10"/>',
  scan: '<path d="M4 8V6a2 2 0 012-2h2M4 16v2a2 2 0 002 2h2M20 8V6a2 2 0 00-2-2h-2M20 16v2a2 2 0 01-2 2h-2"/><circle cx="12" cy="12" r="3.4"/>',
  history: '<path d="M4 4h16v16H4z"/><path d="M8 9h8M8 13h8M8 17h5"/>',
  calendar: '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18M8 2v4M16 2v4"/>',
  user: '<circle cx="12" cy="8" r="3.4"/><path d="M5 20c1.5-4 5-5.5 7-5.5S17.5 16 19 20"/>',
  logout: '<path d="M9 4H5v16h4"/><path d="M16 8l4 4-4 4M20 12H9"/>',
  bell: '<path d="M6 10a6 6 0 1112 0c0 4 1.5 5.5 2 6H4c.5-.5 2-2 2-6z"/><path d="M10 20a2 2 0 004 0"/>',
  refresh: '<path d="M4 4v6h6M20 20v-6h-6"/><path d="M5.5 15a7 7 0 0012.9 2.5M18.5 9A7 7 0 005.6 6.5"/>',
  plus: '<path d="M12 4v16M4 12h16"/>',
  search: '<circle cx="11" cy="11" r="6.5"/><path d="M16 16l4.5 4.5"/>',
  upload: '<path d="M12 16V4m0 0L7.5 8.5M12 4l4.5 4.5"/><path d="M5 15v4a1 1 0 001 1h12a1 1 0 001-1v-4"/>',
  folder: '<path d="M3 7a2 2 0 012-2h4l2 2h8a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2z"/>',
  trash: '<path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13"/>',
  alert: '<path d="M12 9v4M12 17h.01"/><path d="M10.3 3.9L1.8 18a2 2 0 001.7 3h17a2 2 0 001.7-3L13.7 3.9a2 2 0 00-3.4 0z"/>',
};
const props = defineProps({ name: { type: String, required: true }, size: { type: [Number, String], default: 20 } });
const html = computed(() => PATHS[props.name] ?? '');
</script>
<template>
  <svg class="icon" viewBox="0 0 24 24" :width="size" :height="size" fill="none" stroke="currentColor" stroke-width="1.8"
       stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" v-html="html"></svg>
</template>
<style>.icon { flex: none; }</style>
