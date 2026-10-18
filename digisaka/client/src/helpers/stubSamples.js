// Sample leaf images for running the web app on the stub (docker-compose.stub.yml sets VITE_STUB_SAMPLES).
// The stub picks its canned answer from the image name, so each sample is named after a scenario.
// The bytes are a 1x1 PNG: the stub only needs a non-empty payload.
const PNG = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

export const SAMPLE_SCENARIOS = {
  stage2: 'Stage 2 leaf',
  healthy: 'Healthy leaf',
  rescan: 'Rescan needed',
  referral: 'Referral',
  not_leaf: 'Not a leaf',
  unavailable: 'QA unavailable',
};
const DEFAULT_SET = ['stage2', 'stage2', 'healthy'];
export const RETAKE_SAMPLE = 'stage2'; // a retake of a rescan leaf must be a normal leaf, not another rescan

export const samplesEnabled = () => import.meta.env.VITE_STUB_SAMPLES === '1';

let counter = 0;
export function sampleFile(scenario) {
  if (!(scenario in SAMPLE_SCENARIOS)) throw new Error(`Unknown sample scenario: ${scenario}`);
  const bytes = Uint8Array.from(atob(PNG), (c) => c.charCodeAt(0));
  const n = String(++counter).padStart(2, '0');
  return new File([bytes], `${scenario}-leaf-${n}.png`, { type: 'image/png' });
}

export const defaultSamples = () => DEFAULT_SET.map(sampleFile);

// Adds the default samples to an empty queue for the selected line-week; never touches a queue that already has leaves.
export function addDefaultSamples(scan, enabled = samplesEnabled()) {
  if (enabled && scan.line && !scan.leaves.length) scan.addFiles(defaultSamples());
}
