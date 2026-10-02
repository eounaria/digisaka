import { defineStore } from 'pinia';
import { api } from '../api.js';
import { useAuthStore } from './auth.js';

export const useUseCaseStore = defineStore('useCase', {
  state: () => ({ cases: [], slug: 'black-sigatoka' }),
  getters: { current: (s) => s.cases.find((c) => c.slug === s.slug) ?? s.cases[0] ?? { label: '', crop: '', disease: '', icon: '' } },
  actions: {
    async load() {
      if (this.cases.length) return;
      this.cases = (await api.get('/api/me/use-cases')).useCases;
      this.slug = useAuthStore().user?.useCase || this.slug;
    },
    async select(slug) { this.slug = slug; await api.put('/api/me/preferences', { useCase: slug }).catch(() => {}); },
  },
});
