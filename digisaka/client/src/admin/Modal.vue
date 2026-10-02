<script setup>
import { ref, onMounted, onBeforeUnmount, nextTick } from 'vue';
const props = defineProps({ title: String, width: { type: String, default: '520px' } });
const emit = defineEmits(['close']);
const box = ref(null), leaving = ref(false);
// Play the exit animation first, then let the parent remove the dialog.
function close() { if (leaving.value) return; leaving.value = true; setTimeout(() => emit('close'), 160); }
let opener;
const onKey = (e) => {
  if (e.key === 'Escape') return close();
  if (e.key !== 'Tab') return;   // keep focus inside the dialog
  const f = [...box.value.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')].filter((x) => !x.disabled && x.offsetParent !== null);
  if (!f.length) return;
  const first = f[0], last = f[f.length - 1];
  if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
  else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
};
onMounted(async () => {
  opener = document.activeElement;
  document.addEventListener('keydown', onKey);
  await nextTick();
  (box.value.querySelector('input, select, textarea') ?? box.value.querySelector('button')).focus();
});
onBeforeUnmount(() => { document.removeEventListener('keydown', onKey); opener?.focus?.(); });
</script>

<template>
  <div class="veil" :class="{ out: leaving }" @mousedown.self="close">
    <div ref="box" class="dialog" role="dialog" aria-modal="true" :aria-label="props.title" :style="{ maxWidth: width }">
      <header><h2>{{ title }}</h2><button type="button" class="x" aria-label="Close" @click="close">&times;</button></header>
      <div class="body"><slot /></div>
      <footer v-if="$slots.footer"><slot name="footer" /></footer>
    </div>
  </div>
</template>

<style scoped>
.veil { animation: veil-in .2s var(--ease) both; position: fixed; inset: 0; z-index: 50; display: grid; place-items: center; padding: 20px; background: rgba(11, 36, 22, .45); }
.dialog { animation: dialog-in .28s var(--ease) both; display: flex; flex-direction: column; width: 100%; max-height: calc(100dvh - 40px); border-radius: var(--radius-lg); background: #fff; box-shadow: 0 24px 60px rgba(0, 0, 0, .25); }
header { display: flex; justify-content: space-between; align-items: center; gap: 12px; padding: 18px 22px; border-bottom: 1px solid var(--line); }
h2 { font: 800 19px var(--font-display); color: var(--forest); }
.x { width: 34px; height: 34px; border: 0; border-radius: 50%; background: var(--tint); font-size: 22px; line-height: 1; color: var(--forest); }
.body { padding: 20px 22px; overflow-y: auto; }
footer { display: flex; justify-content: flex-end; flex-wrap: wrap; gap: 10px; padding: 14px 22px; border-top: 1px solid var(--line); }
@keyframes veil-in { from { opacity: 0; } }
@keyframes dialog-in { from { opacity: 0; transform: translateY(14px) scale(.97); } }
.veil.out { opacity: 0; transition: opacity .16s var(--ease-in); }
.veil.out .dialog { transform: translateY(8px) scale(.98); opacity: .6; transition: transform .16s var(--ease-in), opacity .16s var(--ease-in); }
.x:hover { background: var(--leaf-soft); }
</style>
