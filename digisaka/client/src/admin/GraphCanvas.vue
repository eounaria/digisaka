<script setup>
import { computed } from 'vue';
import { layoutGraph } from './graphLayout.js';

// nodes: [{ id, label, caption?, color, degree? }]   edges: [{ from, to, label }]
const props = defineProps({ nodes: Array, edges: Array, labelEdges: Boolean, label: { type: String, default: 'Graph' } });
const W = 800, H = 480;
const edgeText = computed(() => props.labelEdges || props.edges.length <= 14);   // few edges: print each relationship name
const pos = computed(() => layoutGraph(props.nodes, props.edges, W, H));
const radius = (n) => (props.labelEdges ? 36 : 12 + Math.min(n.degree ?? 1, 8) * 2.2);
const short = (s, n = props.labelEdges ? 16 : 20) => (s.length > n ? s.slice(0, n - 1) + '…' : s);
const lines = computed(() => props.edges.filter((e) => e.from !== e.to && pos.value[e.from] && pos.value[e.to]).map((e, i) => {
  const a = pos.value[e.from], b = pos.value[e.to];
  const fa = props.nodes.find((n) => n.id === e.from), fb = props.nodes.find((n) => n.id === e.to);
  const dx = b.x - a.x, dy = b.y - a.y, d = Math.hypot(dx, dy) || 1, ux = dx / d, uy = dy / d;
  const ra = radius(fa), rb = radius(fb) + 4;
  return { key: i, x1: a.x + ux * ra, y1: a.y + uy * ra, x2: b.x - ux * rb, y2: b.y - uy * rb, label: e.label, mx: (a.x + b.x) / 2, my: (a.y + b.y) / 2 - 5 };
}));
</script>

<template>
  <svg :viewBox="`0 0 ${W} ${H}`" role="img" :aria-label="label" class="graph">
    <defs><marker id="arrow" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 z" fill="#9aa5c8" /></marker></defs>
    <g v-for="l in lines" :key="l.key">
      <line :x1="l.x1" :y1="l.y1" :x2="l.x2" :y2="l.y2" class="edge" marker-end="url(#arrow)"><title>{{ l.label }}</title></line>
      <text v-if="edgeText" :x="l.mx" :y="l.my" class="elabel">{{ l.label }}</text>
    </g>
    <g v-for="n in nodes" :key="n.id" v-show="pos[n.id]">
      <circle :cx="pos[n.id]?.x" :cy="pos[n.id]?.y" :r="radius(n)" :fill="n.color" class="node"><title>{{ n.label }}{{ n.caption ? ` (${n.caption})` : '' }}</title></circle>
      <text v-if="labelEdges" :x="pos[n.id]?.x" :y="(pos[n.id]?.y ?? 0) + 4" class="inside">{{ short(n.label) }}</text>
      <template v-else>
        <text :x="pos[n.id]?.x" :y="(pos[n.id]?.y ?? 0) + radius(n) + 13" class="below">{{ short(n.label) }}</text>
      </template>
    </g>
  </svg>
</template>

<style scoped>
.graph { display: block; width: 100%; height: auto; border-radius: var(--radius-md); background: radial-gradient(circle at 30% 20%, #1c2150, #0f1233); }
.edge { stroke: #7f8bbd; stroke-width: 1.3; opacity: .8; }
.node { stroke: rgba(255, 255, 255, .55); stroke-width: 2; }
.elabel { fill: #b9c1e6; font: 600 11px var(--font-body); text-anchor: middle; paint-order: stroke; stroke: #0f1233; stroke-width: 3px; }
.inside { fill: #fff; font: 800 11.5px var(--font-body); text-anchor: middle; }
.below { fill: #dfe4ff; font: 700 11px var(--font-body); text-anchor: middle; paint-order: stroke; stroke: #0f1233; stroke-width: 3px; }
</style>
