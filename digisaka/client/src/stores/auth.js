import { defineStore } from 'pinia';
import { api } from '../api.js';

export const useAuthStore = defineStore('auth', {
  state: () => ({ user: null, checked: false }),
  getters: { isAdmin: (s) => s.user?.role === 'admin', firstName: (s) => s.user?.name.split(/\s+/)[0] ?? '' },
  actions: {
    async fetchMe() { try { this.user = (await api.get('/api/auth/me')).user; } catch { this.user = null; } this.checked = true; },
    async submit(mode, body) { this.user = (await api.post('/api/auth/' + mode, body)).user; },
    async logout() { await api.post('/api/auth/logout'); this.user = null; },
  },
});
