import { defineStore } from 'pinia';
import { api } from '../api.js';

const KEY = 'digisaka.activeUseCase';
const remembered = () => { try { return localStorage.getItem(KEY); } catch { return null; } };
const remember = (slug) => { try { localStorage.setItem(KEY, slug); } catch { /* the choice just won't survive a reload */ } };

export const useUseCaseStore = defineStore('useCase', {
  state: () => ({ cases: [], slug: 'black-sigatoka' }),
  getters: { current: (s) => s.cases.find((c) => c.slug === s.slug) ?? s.cases[0] ?? { label: '', crop: '', disease: '', icon: '' } },
  actions: {
    async load() {
      if (this.cases.length) return;
      this.cases = (await api.get('/api/admin/use-cases')).useCases;
      const saved = remembered();
      this.slug = this.cases.some((c) => c.slug === saved) ? saved : this.cases[0]?.slug ?? this.slug;
    },
    select(slug) { this.slug = slug; remember(slug); },
  },
});
