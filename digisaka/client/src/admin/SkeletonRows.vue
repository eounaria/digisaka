<script setup>
// Placeholder table rows for the first load of an admin table.
defineProps({ cols: { type: Number, required: true }, rows: { type: Number, default: 5 } });
</script>
<template>
  <tr v-for="r in rows" :key="r" aria-hidden="true">
    <td v-for="c in cols" :key="c"><span class="skel" :style="{ height: '14px', width: (c === 1 ? 70 : 40 + ((r * 7 + c * 13) % 40)) + '%' }"></span></td>
  </tr>
</template>
