import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    proxy: {
      // QA screens talk to the scheduler directly; this rule must stay ahead of '/api'.
      '/api/v1/scheduler': 'http://127.0.0.1:8001',
      '/api': 'http://localhost:3000',
      '/legacy': 'http://localhost:3000',
    },
  },
  build: { outDir: 'dist', emptyOutDir: true },
  test: { include: ['src/**/*.test.js'] },
});
