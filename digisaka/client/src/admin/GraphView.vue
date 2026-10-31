
<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { useAuthStore } from '../stores/auth.js'
import { useUseCaseStore } from '../stores/useCase.js'

const auth = useAuthStore()
const uc = useUseCaseStore()

const containerRef = ref(null)
const mounting = ref(true)
const mountError = ref(null)

let reactRoot = null
let React = null
let ReactodiaGraph = null
let active = true
let refreshVersion = 0

function renderGraph() {
  if (!reactRoot || !React || !ReactodiaGraph) return

  reactRoot.render(
    React.createElement(ReactodiaGraph, {
      key: `${uc.slug}:${refreshVersion}`,
      useCaseSlug: uc.slug,
      token: auth.token,
    })
  )
}

async function mountReactComponent() {
  if (!containerRef.value || reactRoot) return

  mounting.value = true
  mountError.value = null

  try {
    const reactModule = await import('react')
    const ReactDOM = await import('react-dom/client')
    const graphModule = await import('./ReactodiaGraph.jsx')

    if (!active || !containerRef.value) return

    React = reactModule.default
    ReactodiaGraph = graphModule.ReactodiaGraph

    reactRoot = ReactDOM.createRoot(containerRef.value)
    renderGraph()
  } catch (err) {
    if (!active) return

    console.error('Failed to mount Reactodia:', err)
    mountError.value = err.message || 'Failed to load graph'
  } finally {
    if (active) mounting.value = false
  }
}

function reloadGraph() {
  refreshVersion += 1

  if (reactRoot) {
    renderGraph()
  } else {
    mountReactComponent()
  }
}

// Update the graph when the selected use case or token changes
watch(
  () => [uc.slug, auth.token],
  () => {
    if (reactRoot) {
      refreshVersion += 1
      renderGraph()
    }
  }
)

onMounted(() => {
  active = true
  mountReactComponent()
})

onUnmounted(() => {
  active = false

  if (reactRoot) {
    reactRoot.unmount()
    reactRoot = null
  }
})
</script>

<template>
  <div class="graph-view">
    <div class="graph-header">
      <h1>Knowledge Graph</h1>

      <div class="graph-controls">
        <span
          v-if="uc.current"
          class="use-case-badge"
        >
          {{ uc.current.label }}
        </span>

        <button
          class="btn-refresh"
          :disabled="mounting"
          title="Reload graph"
          @click="reloadGraph"
        >
          <svg
            viewBox="0 0 24 24"
            width="16"
            height="16"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
          >
            <path d="M23 4v6h-6" />
            <path d="M1 20v-6h6" />
            <path
              d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"
            />
          </svg>
        </button>
      </div>
    </div>

    <div class="graph-container">
      <!-- Only React controls this element -->
      <div
        ref="containerRef"
        class="react-mount"
      ></div>

      <div v-if="mounting" class="status-overlay">
        <p>Initializing knowledge graph...</p>
      </div>

      <div v-if="mountError" class="status-overlay">
        <p>{{ mountError }}</p>
        <button class="btn-retry" @click="reloadGraph">
          Try Again
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.graph-view {
  display: flex;
  flex-direction: column;
  height: 100%;
  min-height: 600px;
  background: var(--bg, #fafafa);
}

.graph-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 0 16px;
  border-bottom: 1px solid var(--line, #e5e5e5);
  flex-shrink: 0;
}

.graph-header h1 {
  margin: 0;
  font: 700 22px var(--font-display, system-ui);
  color: var(--forest, #087E42);
}

.graph-controls {
  display: flex;
  align-items: center;
  gap: 12px;
}

.use-case-badge {
  padding: 4px 10px;
  border-radius: 999px;
  background: var(--tint, #e8f5ee);
  color: var(--forest, #087E42);
  font: 600 12px var(--font-body, system-ui);
  text-transform: capitalize;
}

.btn-refresh {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border: 1px solid var(--line, #e5e5e5);
  border-radius: 10px;
  background: #fff;
  color: var(--forest, #087E42);
  cursor: pointer;
}

.btn-refresh:hover:not(:disabled) {
  background: var(--tint, #e8f5ee);
}

.btn-refresh:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.graph-container {
  position: relative;
  flex: 1;
  min-height: 500px;
  border: 1px solid var(--line, #e5e5e5);
  border-radius: 12px;
  background: #fff;
  overflow: hidden;
}

.react-mount {
  width: 100%;
  height: 100%;
  min-height: 500px;
}

.status-overlay {
  position: absolute;
  inset: 0;
  z-index: 20;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 24px;
  background: #fff;
  text-align: center;
  color: #6b7280;
}

.btn-retry {
  padding: 10px 20px;
  border: 1px solid #087E42;
  border-radius: 8px;
  background: #087E42;
  color: #fff;
  font: 600 14px system-ui;
  cursor: pointer;
}


/* Ensure Reactodia fills the graph container */
.react-mount {
  width: 100%;
  height: 100%;
  min-height: 500px;
}

/* Fix Reactodia's zero-height canvas */
.react-mount :deep(.reactodia-canvas) {
  height: 100% !important;
  min-height: 500px !important;
}

/* Fix Reactodia's zero-height pane */
.react-mount :deep(.reactodia-paper__pane) {
  height: 100% !important;
  min-height: 500px !important;
}

</style>
