/*
 * A small force-directed layout so graphs of any size get readable positions with no extra library.
 * Deterministic: the same nodes and edges always land in the same place.
 */
export function layoutGraph(nodes, edges, w = 800, h = 480, padX = 96, padY = 56) {
  const n = nodes.length;
  if (!n) return {};
  const index = new Map(nodes.map((nd, i) => [nd.id, i]));
  const pos = nodes.map((_, i) => {
    const a = (i / n) * Math.PI * 2, r = Math.min(w, h) / 2.8;
    return { x: w / 2 + Math.cos(a) * r * (1 + 0.05 * Math.sin(i * 7)), y: h / 2 + Math.sin(a) * r * 0.8, dx: 0, dy: 0 };
  });
  const pairs = edges.map((e) => [index.get(e.from), index.get(e.to)]).filter(([a, b]) => a != null && b != null && a !== b);
  const k = Math.min(Math.sqrt((w * h) / n) * 0.75, 150);   // small graphs stay compact instead of flying to the corners
  const rounds = n > 150 ? 120 : 280;
  for (let it = 0; it < rounds; it++) {
    const t = 1 - it / rounds;
    for (const p of pos) { p.dx = (w / 2 - p.x) * 0.012; p.dy = (h / 2 - p.y) * 0.012; }   // gentle pull to the middle
    for (let i = 0; i < n; i++) for (let j = i + 1; j < n; j++) {
      let dx = pos[i].x - pos[j].x, dy = pos[i].y - pos[j].y;
      const d = Math.hypot(dx, dy) || 0.01, f = (k * k) / d / d;
      dx *= f; dy *= f;
      pos[i].dx += dx; pos[i].dy += dy; pos[j].dx -= dx; pos[j].dy -= dy;
    }
    for (const [a, b] of pairs) {
      const dx = pos[a].x - pos[b].x, dy = pos[a].y - pos[b].y, d = Math.hypot(dx, dy) || 0.01, f = d / k;
      pos[a].dx -= dx * f * 0.5; pos[a].dy -= dy * f * 0.5; pos[b].dx += dx * f * 0.5; pos[b].dy += dy * f * 0.5;
    }
    for (const p of pos) {
      const d = Math.hypot(p.dx, p.dy) || 0.01, m = Math.min(d, 40 * t + 2);
      p.x = Math.min(w - padX, Math.max(padX, p.x + (p.dx / d) * m));
      p.y = Math.min(h - padY - 10, Math.max(padY, p.y + (p.dy / d) * m));
    }
  }
  return Object.fromEntries(nodes.map((nd, i) => [nd.id, { x: pos[i].x, y: pos[i].y }]));
}
