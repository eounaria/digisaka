import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import { proxyTargets } from './vite.proxy.js';

const targets = proxyTargets(process.env);

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    // Bind-mounted sources do not always raise file events inside a container.
    watch: process.env.VITE_USE_POLLING ? { usePolling: true } : undefined,
    proxy: {
      // QA screens talk to the scheduler directly; this rule must stay ahead of '/api'.
      '/api/v1/scheduler': targets.scheduler,
      // Knowledge Maintenance talks to the main API directly.
      '/api/v1/knowledge-maintenance': targets.km,
      '/api': targets.api,
      '/legacy': targets.api,
    },
  },
  build: { outDir: 'dist', emptyOutDir: true },
  test: { include: ['src/**/*.test.js', 'vite.proxy.test.js'] },
  // Reactodia layout worker - use native worker format
  worker: {
    format: 'es'
  },
  optimizeDeps: {
    include: ['@reactodia/workspace', 'n3']
  }
});
