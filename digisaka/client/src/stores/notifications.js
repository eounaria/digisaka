import { defineStore } from 'pinia';
import { api } from '../api.js';

export const useNotificationsStore = defineStore('notifications', {
  state: () => ({ items: [], unread: 0 }),
  actions: {
    async refresh() {
      try { Object.assign(this, await api.get('/api/notifications').then((d) => ({ items: d.notifications, unread: d.unread }))); } catch { /* keep last */ }
    },
    async markAllRead() {
      if (!this.unread) return;
      await api.post('/api/notifications/read-all').catch(() => {});
      this.unread = 0;
    },
  },
});
