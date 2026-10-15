// Groups verified leaves the way the mobile result screen does: by QA's stage label, with healthy and
// unvalidated (not a leaf, referral) listed apart.
export function groupLeaves(leaves) {
  const stages = new Map(), healthy = [], unvalidated = [];
  for (const leaf of leaves) {
    if (leaf.outcome === 'healthy') healthy.push(leaf);
    else if (leaf.outcome === 'treatment_result') {
      const label = leaf.stage || 'Stage not given';
      if (!stages.has(label)) stages.set(label, []);
      stages.get(label).push(leaf);
    } else unvalidated.push(leaf);
  }
  return { stages: [...stages].map(([label, items]) => ({ label, leaves: items })).sort((a, b) => a.label.localeCompare(b.label)), healthy, unvalidated };
}
