<script setup>
import { onMounted } from 'vue';
import { useNotificationsStore } from '../stores/notifications.js';
import PageHeader from '../components/PageHeader.vue';

const notes = useNotificationsStore();
const ago = (iso) => {
  const m = Math.round((Date.now() - new Date(iso)) / 60000);
  return m < 1 ? 'Just now' : m < 60 ? `${m}m ago` : m < 1440 ? `${Math.round(m / 60)}h ago` : `${Math.round(m / 1440)}d ago`;
};
// Keep unread markers visible on arrival, then clear the bell.
const unreadOnOpen = new Set();
onMounted(async () => {
  await notes.refresh();
  notes.items.filter((n) => !n.read).forEach((n) => unreadOnOpen.add(n.id));
  notes.markAllRead();
});
</script>

<template>
  <div class="page narrow">
    <PageHeader title="Notifications" subtitle="Treatment reminders and updates for your farm." />
    <p v-if="!notes.items.length" class="empty">No notifications yet. Treatment reminders will show up here.</p>
    <ul>
      <li v-for="n in notes.items" :key="n.id" :class="{ fresh: unreadOnOpen.has(n.id) }">
        <span class="ic">{{ unreadOnOpen.has(n.id) ? '🟡' : '🔔' }}</span>
        <div><p>{{ n.body ? `${n.title}. ${n.body}` : n.title }}</p><small>{{ ago(n.createdAt) }}</small></div>
      </li>
    </ul>
  </div>
</template>

<style scoped>
.narrow { max-width: 760px; }
ul { display: grid; gap: 10px; }
li { display: flex; gap: 14px; padding: 16px; border: 1px solid var(--line); border-radius: var(--radius-md); background: var(--card); }
li.fresh { border-color: rgba(10, 159, 85, .4); background: var(--tint); }
.ic { font-size: 20px; line-height: 1.4; }
p { font-weight: 700; } small { color: var(--ink-soft); }
.empty { padding: 40px 0; text-align: center; color: var(--ink-soft); font-weight: 700; }
</style>
