
const navMap = {home:'nav-home', history:'nav-history', scan:'nav-scan', profile:'nav-profile'};

function go(name){
  document.querySelectorAll('.screen').forEach(s=>s.classList.remove('active'));
  const targetScreen = document.getElementById('screen-'+name) || document.getElementById('screen-home');
  targetScreen.classList.add('active');
  targetScreen.scrollTop = 0;
  document.querySelectorAll('.navitem, .sidebar-link').forEach(n=>n.classList.remove('active'));

  const navId = navMap[name] || navMap[
    ['preview','processing','validation','final','treatmenthistory','bulk-processing','bulk-summary','bulk-actions','bulk-schedule-review','bulk-schedule-confirmed'].includes(name) ? 'scan' : 'home'
  ];
  if(navId) document.getElementById(navId).classList.add('active');

  if(name === 'scan') resetBulkFlow();
  if(name === 'history') renderBulkRecentScanned();
  if(name === 'scheduled-treatments') renderScheduledTreatments();
  if(name === 'home') updateDashboardOverview();
}

/* ================================================================
   ADMIN WEB — opens the Admin dashboard (design from file 1) as a
   full-window workspace; "Switch to User Web" returns to the app.
   ================================================================ */
let currentUseCase = 'black-sigatoka';

function startProcessing(){
  go('processing');
  const steps = document.querySelectorAll('#proc-steps .proc-step');
  steps.forEach((s,i)=>{
    s.classList.remove('done','active');
    s.querySelector('.mark').textContent = i===0 ? '✓' : '○';
  });
  steps[0].classList.add('done');
  steps[1].classList.add('active'); steps[1].querySelector('.mark').textContent='●';

  let i = 1;
  const timer = setInterval(()=>{
    steps[i].classList.remove('active');
    steps[i].classList.add('done');
    steps[i].querySelector('.mark').textContent = '✓';
    i++;
    if(i < steps.length){
      steps[i].classList.add('active');
      steps[i].querySelector('.mark').textContent = '●';
    } else {
      clearInterval(timer);
      setTimeout(()=>go('validation'), 500);
    }
  }, 650);
}

/* ---------- Leaf Validation demo toggle ---------- */
let leafValid = true;
function toggleValidationDemo(){
  leafValid = !leafValid;
  const box = document.getElementById('validation-result');
  const btn = document.getElementById('validation-btn');
  const hint = document.getElementById('validation-hint');
  if(leafValid){
    box.className = 'validation-result good';
    box.innerHTML = '<div class="vr-icon">✓</div><div class="vr-text"><h4>Banana Leaf Detected</h4><p>Image quality is good. Ready to check for Black Sigatoka symptoms.</p></div>';
    btn.className = 'btn btn-primary';
    btn.textContent = 'Continue to Assessment →';
    btn.setAttribute('onclick', "go('final')");
    hint.textContent = 'Show example: image not recognized';
  } else {
    box.className = 'validation-result bad';
    box.innerHTML = '<div class="vr-icon">!</div><div class="vr-text"><h4>Image Not Recognized</h4><p>We couldn\u2019t confirm this is a banana leaf. Please scan or upload a clear photo of a banana leaf.</p></div>';
    btn.className = 'btn btn-warn';
    btn.textContent = 'Scan Again';
    btn.setAttribute('onclick', "go('scan')");
    hint.textContent = 'Show example: banana leaf detected';
  }
}

/* ---------- Multi-leaf bulk capture & assessment ---------- */
/* Bulk Assessment = a named session (Plant + Date + Bulk ID) containing multiple INDIVIDUAL
   leaf assessments. Every leaf must first pass Black Sigatoka validation before it receives
   a stage — invalid leaves are routed to "Unvalidated / Review Required" and never staged.
   Validated leaves keep their own status/stage/action — the batch is never collapsed into a
   single "overall stage". See STAGE_META for the per-stage rules that drive this. */
const MOCK_LEAF_SEQUENCE = [
  {stage:0}, {stage:1}, {stage:2}, {stage:3},
  {stage:0}, {stage:1}, {stage:4}, {invalid:true}
]; // mirrors the spec's worked example exactly: Leaf01 Healthy, 02 Stage1, 03 Stage2, 04 Stage3,
   // 05 Healthy, 06 Stage1, 07 Stage4, 08 Unvalidated — repeats every 8 leaves.

const STAGE_META = {
  0: { emoji:'🟢', color:'var(--leaf)',   tag:'Healthy',   label:'Healthy / Stage 0',
       desc:'No significant symptoms',
       recommendedAction:'No treatment — Continue routine monitoring',
       groupLabel:'Healthy', treatmentEligible:false },
  1: { emoji:'🟡', color:'var(--banana)', tag:'Suspected', label:'Suspected Stage 1',
       desc:'Early suspected symptoms',
       recommendedAction:'Early-stage treatment schedule available — requires user review',
       groupLabel:'Early Treatment Consideration', treatmentEligible:true },
  2: { emoji:'🟠', color:'var(--warn)',   tag:'Suspected', label:'Suspected Stage 2',
       desc:'Developing symptoms',
       recommendedAction:'Developing-stage treatment schedule available — requires user review',
       groupLabel:'Developing Treatment Consideration', treatmentEligible:true },
  3: { emoji:'🟠', color:'var(--warn)',   tag:'Suspected', label:'Suspected Stage 3',
       desc:'Progressing symptoms',
       recommendedAction:'Treatment window may be considered — requires user review',
       groupLabel:'Treatment Consideration', treatmentEligible:true },
  4: { emoji:'🔴', color:'var(--danger)', tag:'Suspected', label:'Suspected Stage 4 (Advanced)',
       desc:'Advanced symptoms',
       recommendedAction:'Priority treatment-window consideration — requires user review',
       groupLabel:'Priority Treatment Consideration', treatmentEligible:true }
};
const STAGE_CONFIDENCE = { 0:'95.0%', 1:'94.7%', 2:'91.2%', 3:'88.5%', 4:'96.3%' };
const UNVALIDATED_META = {
  emoji:'⚪', color:'var(--tile-grey-ink)', label:'Unvalidated / Review Required',
  reason:'The observed characteristics are insufficient or inconsistent with Black Sigatoka.',
  recommendedAction:'Do not proceed to treatment. Capture another image or perform further inspection.'
};
// Suggested treatment windows, computed relative to the fixed prototype "today" (Aug 19, 2026).
const TREATMENT_WINDOWS = { 1:'August 20–22, 2026', 2:'August 21–24, 2026', 3:'August 21–23, 2026', 4:'August 20–22, 2026' };

/* ---------- Bulk session identity (Plant Name + Assessment Date + Bulk ID) ---------- */
const BULK_PLANT_NAMES = ['Banana Plant #001','Banana Plant #002','Banana Plant #003','Banana Plant #004','Banana Plant #005','Banana Plant #006'];
const BULK_ASSESSMENT_DATE = 'August 19, 2026'; // fixed "today" for this prototype
let bulkSessionCounter = 0;
let currentBulkId = '';
let currentBulkPlant = '';

function startNewBulkSession(){
  bulkSessionCounter++;
  currentBulkId = 'BA-2026-0819-' + String(bulkSessionCounter).padStart(3,'0');
  currentBulkPlant = BULK_PLANT_NAMES[(bulkSessionCounter - 1) % BULK_PLANT_NAMES.length];
  document.querySelectorAll('.bulk-id-value').forEach(el => el.textContent = currentBulkId);
  document.querySelectorAll('.bulk-plant-value').forEach(el => el.textContent = currentBulkPlant);
  document.querySelectorAll('.bulk-date-value').forEach(el => el.textContent = BULK_ASSESSMENT_DATE);
}

function setBulkStatus(text){
  document.querySelectorAll('.bulk-status-value').forEach(el => el.textContent = text);
}

/* ---------- Bulk assessment agent pipeline trace (spec section 15) ---------- */
const BULK_PIPELINE_STEPS = [
  'Bulk Created', 'Leaf Images Collected', 'Black Sigatoka Validation',
  'Individual Stage Assessment', 'Stage Groups Organized', 'Human Verification',
  'Treatment Recommendation', 'Schedule Review', 'Confirm & Schedule'
];
function renderBulkPipeline(containerId, activeIndex){
  const el = document.getElementById(containerId);
  if(!el) return;
  const rows = BULK_PIPELINE_STEPS.map((label, i) => {
    const cls = i < activeIndex ? 'done' : (i === activeIndex ? 'active' : 'pending');
    const icon = i < activeIndex ? '✓' : (i === activeIndex ? '→' : '○');
    const suffix = (i === 0 && currentBulkId) ? ' — ' + currentBulkId : '';
    return '<div class="pipeline-step ' + cls + '"><span class="ps-icon">' + icon + '</span><span class="ps-label">' + label + suffix + '</span></div>';
  }).join('');
  el.innerHTML = '<div class="pipeline-title">BULK ASSESSMENT AGENT</div>' + rows;
}

let bulkLeaves = []; // { id, valid, stage|null, status, confidence, recommendedAction, treatmentEligible }
let bulkIdCounter = 0;
let bulkTreatmentGroups = []; // { stage, leafNums, window } — built when entering schedule review

function resetBulkFlow(){
  bulkLeaves = [];
  bulkIdCounter = 0;
  startNewBulkSession();
  setBulkStatus('Validation Pending');
  renderBulkThumbs();
}

function addMockLeaf(){
  const entry = MOCK_LEAF_SEQUENCE[bulkLeaves.length % MOCK_LEAF_SEQUENCE.length];
  bulkIdCounter++;
  if(entry.invalid){
    bulkLeaves.push({
      id: bulkIdCounter,
      valid: false,
      stage: null,
      status: 'Unvalidated',
      confidence: null,
      recommendedAction: UNVALIDATED_META.recommendedAction,
      treatmentEligible: false,
      // Human-verification fields: aiGroupKey freezes what the AI originally decided so a
      // reviewer's override can still be shown against it; verified is only ever set by a
      // person, either confirming the AI's group or moving the leaf to a different one.
      aiGroupKey: 'invalid',
      verified: false,
      reassigned: false
    });
  } else {
    const stage = entry.stage;
    const meta = STAGE_META[stage];
    bulkLeaves.push({
      id: bulkIdCounter,
      valid: true,
      stage: stage,
      status: stage === 0 ? 'Healthy' : 'Suspected',
      confidence: STAGE_CONFIDENCE[stage],
      recommendedAction: meta.recommendedAction,
      treatmentEligible: meta.treatmentEligible,
      aiGroupKey: stage,
      verified: false,
      reassigned: false
    });
  }
  renderBulkThumbs();
}

function removeMockLeaf(id){
  bulkLeaves = bulkLeaves.filter(l => l.id !== id);
  renderBulkThumbs();
}

function renderBulkThumbs(){
  const wrap = document.getElementById('bulk-thumbs');
  const label = document.getElementById('bulk-count-label');
  const clearLink = document.getElementById('bulk-clear-link');
  const assessBtn = document.getElementById('bulk-assess-btn');
  if(!wrap) return;

  label.textContent = bulkLeaves.length + (bulkLeaves.length === 1 ? ' leaf selected' : ' leaves selected');
  clearLink.style.display = bulkLeaves.length ? '' : 'none';
  assessBtn.disabled = bulkLeaves.length === 0;
  assessBtn.textContent = bulkLeaves.length ? 'Assess All Leaves (' + bulkLeaves.length + ')' : 'Assess All Leaves';

  const thumbsHtml = bulkLeaves.map((l, i) =>
    '<div class="bulk-thumb" onclick="openLeafPhoto(' + i + ', false)">' + (l.valid ? '🍃' : '⚠️')
    + '<span class="bt-remove" onclick="event.stopPropagation(); removeMockLeaf(' + l.id + ')">×</span>'
    + '<span class="bt-tag" style="background:' + (l.valid ? 'var(--forest)' : 'var(--tile-grey-ink)') + ';">Leaf ' + (i + 1) + '</span>'
    + '</div>'
  ).join('');
  wrap.innerHTML = thumbsHtml + '<div class="bulk-thumb add-tile" onclick="addMockLeaf()">＋</div>';
}
resetBulkFlow();

/* ---------- Leaf photo viewer ----------
   A tappable, larger view of a leaf's captured image — reuses the same leaf-photo mockup as
   the scan/validation screens. On the capture screen (revealDiagnosis=false) it shows only
   the plain photo, since staging hasn't happened yet in the flow. On the verification rows
   (revealDiagnosis=true) it also color-marks the symptoms matching the leaf's current group,
   so a reviewer can actually look at the leaf before confirming or reassigning it. */
const STAGE_LEAF_MARKS = {
  0: [],
  1: [ {cx:70,cy:72,rx:5,ry:3,fill:'var(--banana)',opacity:.85},
       {cx:104,cy:150,rx:4,ry:2.4,fill:'var(--banana)',opacity:.75} ],
  2: [ {cx:64,cy:75,rx:7,ry:4,fill:'var(--warn)',opacity:.85},
       {cx:112,cy:128,rx:6.5,ry:4,fill:'var(--warn)',opacity:.8},
       {cx:76,cy:160,rx:5,ry:3,fill:'var(--warn)',opacity:.7} ],
  3: [ {cx:60,cy:70,rx:10,ry:6,fill:'var(--warn)',opacity:.9},
       {cx:113,cy:126,rx:11,ry:7,fill:'#b5451f',opacity:.88},
       {cx:64,cy:156,rx:8,ry:5,fill:'var(--warn)',opacity:.8},
       {cx:100,cy:182,rx:6,ry:4,fill:'var(--warn)',opacity:.75} ],
  4: [ {cx:70,cy:80,rx:16,ry:10,fill:'var(--danger)',opacity:.92},
       {cx:116,cy:135,rx:18,ry:12,fill:'#4a0e0e',opacity:.92},
       {cx:68,cy:167,rx:14,ry:9,fill:'var(--danger)',opacity:.88},
       {cx:106,cy:196,rx:10,ry:6,fill:'#4a0e0e',opacity:.85} ]
};

function buildLeafPhotoSvg(l, revealDiagnosis){
  const showMarks = revealDiagnosis && l.valid;
  const marks = showMarks ? (STAGE_LEAF_MARKS[l.stage] || []) : [];
  const unclear = revealDiagnosis && !l.valid;
  const spotsHtml = marks.map(m => '<ellipse cx="' + m.cx + '" cy="' + m.cy + '" rx="' + m.rx + '" ry="' + m.ry + '" fill="' + m.fill + '" opacity="' + m.opacity + '"/>').join('');
  return '<svg viewBox="0 0 180 220" xmlns="http://www.w3.org/2000/svg"' + (unclear ? ' style="filter:grayscale(.5); opacity:.7;"' : '') + '>'
    + '<path d="M90 10 C 30 40, 15 110, 90 210 C 165 110, 150 40, 90 10 Z" fill="#3f7350" stroke="#c9e6b0" stroke-width="2"/>'
    + '<path d="M90 20 L90 200 M90 60 L55 90 M90 60 L125 90 M90 110 L55 140 M90 110 L125 140" stroke="#c9e6b0" stroke-width="1.4" fill="none"/>'
    + spotsHtml
    + (unclear ? '<text x="90" y="115" text-anchor="middle" font-size="34" fill="#fff">?</text>' : '')
    + '</svg>';
}

function openLeafPhoto(leafIndex, revealDiagnosis){
  const l = bulkLeaves[leafIndex];
  if(!l) return;
  document.getElementById('leaf-photo-title').textContent = 'Leaf ' + String(leafIndex + 1).padStart(2,'0');
  document.getElementById('leaf-photo-svg-wrap').innerHTML = buildLeafPhotoSvg(l, revealDiagnosis);
  const metaEl = document.getElementById('leaf-photo-meta');
  if(revealDiagnosis){
    const currentKey = l.valid ? l.stage : 'invalid';
    const meta = groupMetaFor(currentKey);
    let metaHtml = '<b>' + meta.label + '</b>' + (l.confidence ? ' · ' + l.confidence + ' AI confidence' : '');
    if(l.reassigned){
      metaHtml += '<br>✎ Reviewer-reassigned' + (l.aiGroupKey !== currentKey ? ' · AI originally suggested ' + groupMetaFor(l.aiGroupKey).label : '');
    }
    metaEl.innerHTML = metaHtml;
  } else {
    metaEl.innerHTML = l.valid ? 'Captured leaf image. Symptom staging will be shown after assessment.' : 'Captured leaf image.';
  }
  document.getElementById('leaf-photo-overlay').classList.add('active');
}

function closeLeafPhoto(){
  document.getElementById('leaf-photo-overlay').classList.remove('active');
}

/* ---------- Agentic assessment trace ----------
   Simulates the multi-step reasoning an assessment agent performs per leaf:
   image QA -> symptom/stage classification -> treatment-eligibility check -> routing.
   Each leaf's outcome is already computed (see addMockLeaf/STAGE_META) — this trace
   is the visible, step-by-step "showing of work" behind that per-leaf result, so the
   simulation never implies a single verdict is applied across the whole batch. */
function startBulkAssessment(){
  if(bulkLeaves.length === 0) return;
  go('bulk-processing');
  setBulkStatus('Validating…');
  renderBulkPipeline('bulk-pipeline-processing', 2);
  const total = bulkLeaves.length;
  document.getElementById('bulk-proc-title').textContent = 'Validating & Assessing ' + total + (total===1?' Leaf...':' Leaves...');

  const traceEl = document.getElementById('bulk-agent-trace');
  traceEl.innerHTML = '';

  // Build the full step queue up front, one group of lines per leaf. Every leaf runs
  // Black Sigatoka Validation FIRST — only a validated leaf proceeds to stage assessment.
  const queue = [];
  let validCount = 0, invalidCount = 0;
  bulkLeaves.forEach((l, i) => {
    const n = i + 1;
    const tag = 'Leaf ' + String(n).padStart(2,'0') + '/' + total;
    queue.push({ cls:'at-agent',  text:'🤖 Agent → ' + tag + ' — Black Sigatoka Validation' });
    queue.push({ cls:'at-substep', text:'1. checking image quality…' });
    queue.push({ cls:'at-result', text:'→ image is usable, leaf clearly visible' });
    queue.push({ cls:'at-substep', text:'2. verifying leaf type…' });
    queue.push({ cls:'at-result', text:'→ banana leaf detected' });
    queue.push({ cls:'at-substep', text:'3. checking disease relevance…' });

    if(l.valid){
      validCount++;
      const meta = STAGE_META[l.stage];
      queue.push({ cls:'at-result', text:'→ visual characteristics consistent with Black Sigatoka' });
      queue.push({ cls:'at-done', text:'✓ 4. Valid for Black Sigatoka assessment' });
      queue.push({ cls:'at-substep', text:'analyzing symptoms & classifying stage…' });
      queue.push({ cls:'at-result', text:'→ ' + meta.label + ' (confidence ' + l.confidence + ')' });
      queue.push({ cls:'at-substep', text:'checking treatment eligibility…' });
      queue.push({ cls:(l.treatmentEligible ? 'at-result at-eligible' : 'at-result'),
                   text: l.treatmentEligible ? '→ eligible — flag for treatment-window review' : '→ not eligible — ' + meta.groupLabel.toLowerCase() + ' only' });
      queue.push({ cls:'at-done', text:'✓ ' + tag + ' complete — routed to: ' + meta.label });
    } else {
      invalidCount++;
      queue.push({ cls:'at-result at-warn', text:'→ characteristics insufficient / inconsistent with Black Sigatoka' });
      queue.push({ cls:'at-done at-warn', text:'⚠ 4. NOT valid for Black Sigatoka assessment' });
      queue.push({ cls:'at-done at-warn', text:'⚠ ' + tag + ' — routed to: Unvalidated / Review Required (no stage assigned)' });
    }
  });
  queue.push({ cls:'at-final', text:'🧾 Compiling bulk summary — ' + validCount + ' validated / ' + invalidCount + ' unvalidated of ' + total + '. No shared stage or verdict applied across the bulk.' });

  let qi = 0;
  const timer = setInterval(()=>{
    if(qi >= queue.length){
      clearInterval(timer);
      setTimeout(()=>{
        setBulkStatus('Validated — Grouped by Stage');
        renderBulkSummary(); go('bulk-summary');
      }, 450);
      return;
    }
    const step = queue[qi];
    const line = document.createElement('span');
    line.className = 'at-line ' + step.cls;
    line.textContent = step.text;
    traceEl.appendChild(line);
    traceEl.scrollTop = traceEl.scrollHeight;
    qi++;
  }, 130);
}

function renderBulkSummary(){
  captureCurrentBulkAssessment();
  document.getElementById('bulk-summary-count').textContent = bulkLeaves.length;
  renderBulkPipeline('bulk-pipeline-summary', 5);

  // Group key: stage 0–4 for validated leaves, 'invalid' for unvalidated leaves.
  const counts = {};
  bulkLeaves.forEach(l => { const key = l.valid ? l.stage : 'invalid'; counts[key] = (counts[key] || 0) + 1; });
  const groupCount = Object.keys(counts).length;

  // The Bulk ID represents the assessment session/plant group, NOT a single disease stage —
  // never collapse a mixed batch down to "worst stage = bulk stage".
  const noteWrap = document.getElementById('bulk-multigroup-note-wrap');
  noteWrap.innerHTML = groupCount > 1
    ? '<div class="bulk-multigroup-note">📊 Bulk contains multiple Black Sigatoka assessment groups — see breakdown below.</div>'
    : '';

  // Edge case: every leaf validated healthy — no grouping/treatment content needed.
  const allHealthy = bulkLeaves.length > 0 && bulkLeaves.every(l => l.valid && l.stage === 0);
  document.getElementById('bulk-allhealthy-banner-wrap').innerHTML = allHealthy
    ? '<div class="bulk-allhealthy-banner"><div class="icon">🟢</div>'
      + '<div class="txt"><h5>All scanned leaves appear healthy.</h5>'
      + '<p>No treatment is recommended. Continue routine monitoring.</p></div></div>'
    : '';

  const stageKeys = Object.keys(counts).filter(k => k !== 'invalid').sort((a,b)=>Number(a)-Number(b));

  // Human verification: track how many leaves a reviewer has confirmed or reassigned.
  const verifiedCount = bulkLeaves.filter(l => l.verified).length;
  const allVerified = bulkLeaves.length > 0 && verifiedCount === bulkLeaves.length;
  const verifyBannerEl = document.getElementById('verify-progress-banner');
  if(verifyBannerEl){
    verifyBannerEl.innerHTML = bulkLeaves.length === 0 ? '' :
      '<div class="verify-banner' + (allVerified ? ' all-done' : '') + '">'
      + '<div class="vb-icon">' + (allVerified ? '✅' : '🧑\u200d🌾') + '</div>'
      + '<div class="vb-text"><h5>Human Verification' + (allVerified ? ' Complete' : ' Required') + '</h5>'
      + '<p>' + (allVerified
          ? 'Every leaf\'s stage group has been confirmed or reassigned by a reviewer.'
          : 'Check each leaf below. Confirm the AI\'s stage, or use "Move to…" if it belongs in a different group.') + '</p></div>'
      + '<div class="vb-progress">' + verifiedCount + '/' + bulkLeaves.length + '</div>'
      + '</div>';
  }

  let rowsHtml = stageKeys.map(stageKey => {
    const stage = Number(stageKey);
    const meta = STAGE_META[stage];
    const nums = [];
    bulkLeaves.forEach((l,i) => { if(l.valid && l.stage === stage) nums.push(i+1); });
    return '<div class="bulk-action-group' + (meta.treatmentEligible ? ' tc-group' : '') + '">'
      + '<div class="bag-head"><span class="emoji">' + meta.emoji + '</span><h5>' + (stage === 0 ? meta.groupLabel : meta.label) + '</h5>'
      + '<span class="bag-count">' + nums.length + (nums.length === 1 ? ' leaf' : ' leaves') + '</span></div>'
      + '<div class="bag-action">' + meta.recommendedAction + '</div>'
      + renderLeafVerifyRows(nums)
      + '</div>';
  }).join('');
  if(counts['invalid']){
    const nums = [];
    bulkLeaves.forEach((l,i) => { if(!l.valid) nums.push(i+1); });
    rowsHtml += '<div class="bulk-action-group unvalidated-group">'
      + '<div class="bag-head"><span class="emoji">' + UNVALIDATED_META.emoji + '</span><h5>' + UNVALIDATED_META.label + '</h5>'
      + '<span class="bag-count">' + nums.length + (nums.length === 1 ? ' leaf' : ' leaves') + '</span></div>'
      + '<div class="bag-action">' + UNVALIDATED_META.recommendedAction + '</div>'
      + renderLeafVerifyRows(nums)
      + '</div>';
  }
  document.getElementById('bulk-summary-rows').innerHTML = rowsHtml;

  const continueBtn = document.getElementById('bulk-continue-btn');
  if(continueBtn) continueBtn.disabled = !allVerified;

  // Treatment Consideration: ONLY validated leaves whose stage allows treatment-window review (3 & 4).
  const eligible = bulkLeaves.filter(l => l.treatmentEligible);
  const tcSection = document.getElementById('bulk-treatment-section');
  if(eligible.length === 0){
    tcSection.innerHTML = '';
  } else {
    const leafRows = eligible.map(l => {
      const i = bulkLeaves.indexOf(l);
      const meta = STAGE_META[l.stage];
      return '<div class="tc-leaf-row"><span class="emoji">' + meta.emoji + '</span>'
        + '<span class="lab">Leaf ' + String(i + 1).padStart(2,'0') + ' — ' + meta.label + '</span></div>';
    }).join('');
    tcSection.innerHTML = '<div class="tc-section-title">🔶 Treatment Consideration — '
      + eligible.length + (eligible.length === 1 ? ' leaf requires' : ' leaves require') + ' treatment-window review</div>'
      + leafRows;
  }

  // Populate the grouped Treatment Recommendation screen from these same individual results.
  renderBulkActions();
}

/* ---------- Group metadata lookup, keyed the same way as bulkLeaves' grouping key
   (stage 0–4 for validated leaves, 'invalid' for unvalidated leaves). Shared by the
   group cards and by the "Move to…" dropdown so both always offer the same set. ---------- */
function groupMetaFor(key){
  return key === 'invalid'
    ? { emoji: UNVALIDATED_META.emoji, label: UNVALIDATED_META.label, action: UNVALIDATED_META.recommendedAction }
    : { emoji: STAGE_META[key].emoji, label: key === 0 ? STAGE_META[0].groupLabel : STAGE_META[key].label, action: STAGE_META[key].recommendedAction };
}
const ALL_GROUP_KEYS = [0,1,2,3,4,'invalid'];

/* A human reviewer moving a leaf to a different group — this is the "2nd verification" /
   human touch that can override the AI's stage assignment. Recomputes every derived field
   (status/confidence/recommendedAction/treatmentEligible) so the leaf behaves exactly as if
   it had been assessed at the new group from the start; nothing downstream needs to know
   the value was reassigned rather than AI-assigned. */
function moveLeafStage(leafIndex, targetValue){
  if(targetValue === '') return;
  const l = bulkLeaves[leafIndex];
  if(!l) return;
  const targetKey = targetValue === 'invalid' ? 'invalid' : Number(targetValue);
  const currentKey = l.valid ? l.stage : 'invalid';
  if(targetKey === currentKey){ l.verified = true; renderBulkSummary(); return; }

  if(targetKey === 'invalid'){
    l.valid = false;
    l.stage = null;
    l.status = 'Unvalidated';
    l.confidence = null;
    l.recommendedAction = UNVALIDATED_META.recommendedAction;
    l.treatmentEligible = false;
  } else {
    const meta = STAGE_META[targetKey];
    l.valid = true;
    l.stage = targetKey;
    l.status = targetKey === 0 ? 'Healthy' : 'Suspected';
    l.confidence = STAGE_CONFIDENCE[targetKey];
    l.recommendedAction = meta.recommendedAction;
    l.treatmentEligible = meta.treatmentEligible;
  }
  l.reassigned = true;
  l.verified = true;
  renderBulkSummary();
}

/* Reviewer confirms the AI's group was correct for this leaf — no group change, just marks
   it as human-checked. */
function confirmLeafStage(leafIndex){
  const l = bulkLeaves[leafIndex];
  if(!l) return;
  l.verified = true;
  renderBulkSummary();
}

function buildMoveOptionsHtml(currentKey){
  return '<option value="">Move to…</option>' + ALL_GROUP_KEYS
    .filter(k => k !== currentKey)
    .map(k => '<option value="' + k + '">' + groupMetaFor(k).label + '</option>')
    .join('');
}

/* Renders the individual, per-leaf verification rows inside a group card: each leaf can be
   confirmed as-is, or reassigned to any other stage group via the dropdown — that reassignment
   is the human override the AI grouping is checked against. */
function renderLeafVerifyRows(nums){
  return '<div class="leaf-verify-list">' + nums.map(n => {
    const i = n - 1;
    const l = bulkLeaves[i];
    const currentKey = l.valid ? l.stage : 'invalid';
    const rowCls = 'leaf-verify-row' + (l.verified ? ' lvr-verified' : '') + (l.reassigned ? ' lvr-reassigned' : '');
    const confText = l.reassigned
      ? '<span class="lvr-conf lvr-reassigned-tag">✎ Reviewer-reassigned' + (l.aiGroupKey !== currentKey ? ' · AI suggested ' + groupMetaFor(l.aiGroupKey).label : '') + '</span>'
      : '<span class="lvr-conf">' + (l.confidence ? 'AI confidence: ' + l.confidence : 'No confidence score (unvalidated)') + '</span>';
    return '<div class="' + rowCls + '">'
      + '<div class="lvr-main lvr-clickable" onclick="openLeafPhoto(' + i + ', true)"><span class="lvr-num">📷 Leaf ' + String(n).padStart(2,'0') + '</span>' + confText + '</div>'
      + '<div class="lvr-actions">'
      + '<button class="lvr-confirm' + (l.verified && !l.reassigned ? ' confirmed' : '') + '" onclick="confirmLeafStage(' + i + ')">' + (l.verified && !l.reassigned ? '✓ Confirmed' : 'Confirm') + '</button>'
      + '<select class="lvr-move" onchange="moveLeafStage(' + i + ', this.value)">' + buildMoveOptionsHtml(currentKey) + '</select>'
      + '</div></div>';
  }).join('') + '</div>';
}

/* ---------- Recommended Actions (grouped-second view) ----------
   Read-only recap: human verification (confirm / move-to-group) happens earlier, on the Bulk
   Summary screen. By the time a bulk reaches this screen every leaf's stage already reflects
   whatever a reviewer confirmed or reassigned there — this screen just presents the resulting
   groups and their recommended actions. */
function renderBulkActions(){
  const wrap = document.getElementById('bulk-actions-list');
  if(!wrap) return;
  renderBulkPipeline('bulk-pipeline-actions', 6);

  const scheduleBtn = document.getElementById('bulk-schedule-btn');

  if(bulkLeaves.length === 0){
    wrap.innerHTML = '<div class="bulk-action-empty">No leaves have been assessed yet.</div>';
    if(scheduleBtn) scheduleBtn.disabled = true;
    return;
  }

  // Group key: stage 0–4 for validated leaves, 'invalid' for unvalidated leaves.
  const byStage = {};
  bulkLeaves.forEach((l, i) => {
    const key = l.valid ? l.stage : 'invalid';
    (byStage[key] = byStage[key] || []).push(i + 1);
  });

  const leafListHtml = (nums) => '<div class="bag-leaflist">Leaf ' + nums.map(n => {
    const l = bulkLeaves[n - 1];
    return String(n).padStart(2,'0') + (l.reassigned ? ' (reviewer-reassigned)' : '');
  }).join(', ') + '</div>';

  let html = '';
  if(byStage[0]){
    const meta = STAGE_META[0];
    const nums = byStage[0];
    html += '<div class="bulk-action-group">'
      + '<div class="bag-head"><span class="emoji">' + meta.emoji + '</span><h5>' + meta.groupLabel + '</h5>'
      + '<span class="bag-count">' + nums.length + (nums.length === 1 ? ' leaf' : ' leaves') + '</span></div>'
      + '<div class="bag-action">' + meta.recommendedAction + '</div>'
      + leafListHtml(nums)
      + '</div>';
  }

  // Every validated stage (1–4) keeps its own subgroup card. All disease stages have a stage-specific treatment schedule.
  [1,2,3,4].forEach(stage => {
    if(!byStage[stage]) return;
    const meta = STAGE_META[stage];
    const nums = byStage[stage];
    html += '<div class="bulk-action-group' + (meta.treatmentEligible ? ' tc-group' : '') + '">'
      + '<div class="bag-head"><span class="emoji">' + meta.emoji + '</span><h5>' + meta.label + '</h5>'
      + '<span class="bag-count">' + nums.length + (nums.length === 1 ? ' leaf' : ' leaves') + '</span></div>'
      + '<div class="bag-action">' + meta.recommendedAction + '</div>'
      + leafListHtml(nums)
      + '</div>';
  });

  // Unvalidated / Review Required — never a treatment group.
  if(byStage['invalid']){
    const nums = byStage['invalid'];
    html += '<div class="bulk-action-group unvalidated-group">'
      + '<div class="bag-head"><span class="emoji">' + UNVALIDATED_META.emoji + '</span><h5>' + UNVALIDATED_META.label + '</h5>'
      + '<span class="bag-count">' + nums.length + (nums.length === 1 ? ' leaf' : ' leaves') + '</span></div>'
      + '<div class="bag-action">' + UNVALIDATED_META.recommendedAction + '</div>'
      + leafListHtml(nums)
      + '</div>';
  }

  const hasEligible = [1,2,3,4].some(s => byStage[s]);
  if(!hasEligible){
    html += '<div class="bulk-action-empty">No leaves currently require treatment-window review.</div>';
  }

  wrap.innerHTML = html;
  if(scheduleBtn) scheduleBtn.disabled = !hasEligible;
}

/* User deliberately opens the existing single-stage treatment confirmation flow for ONE
   eligible stage-group at a time. Nothing here schedules treatment automatically — the
   farmer still confirms treatment history and the window itself on the following screens.
   (Kept for the single-leaf flow; the bulk workflow below uses its own group-based review.) */
function reviewTreatmentForStage(stage){
  setStage(stage);
  resetTreatmentHistoryScreen();
  go('treatmenthistory');
}

/* ---------- Bulk Treatment Schedule (group-based, gated by explicit confirmation) ----------
   Stages 1–4 each receive their own stage-specific treatment schedule. Healthy and
   Unvalidated leaves are excluded. The system schedules eligible disease stages automatically. */
function goToBulkScheduleReview(){
  buildBulkTreatmentGroups();
  confirmBulkSchedule();
}

function renderBulkScheduleReview(){
  document.getElementById('bsr-bulk-id').textContent = currentBulkId;
  document.getElementById('bsr-plant').textContent = currentBulkPlant;
  const wrap = document.getElementById('bsr-groups');
  if(bulkTreatmentGroups.length === 0){
    wrap.innerHTML = '<div class="bsr-empty">No stage groups are currently eligible for treatment scheduling.</div>';
    return;
  }
  wrap.innerHTML = bulkTreatmentGroups.map(g => {
    const meta = STAGE_META[g.stage];
    return '<div class="bsr-group-row">'
      + '<span class="emoji">' + meta.emoji + '</span>'
      + '<div class="bsr-group-text">'
      + '<span class="lab">' + meta.label + ' — ' + g.leafNums.length + (g.leafNums.length === 1 ? ' leaf' : ' leaves') + '</span>'
      + '<span class="sub">Leaf ' + g.leafNums.map(n => String(n).padStart(2,'0')).join(', ') + '</span>'
      + '<span class="win">Suggested treatment window: ' + g.window + '</span>'
      + '</div></div>';
  }).join('');
}

function cancelBulkSchedule(){
  setBulkStatus('Validated — Grouped by Stage');
  go('bulk-actions');
}

function confirmBulkSchedule(){
  setBulkStatus('Scheduled');
  recordConfirmedBulkSchedule();
  renderBulkScheduleConfirmed();
  renderBulkPipeline('bulk-pipeline-confirmed', 9);
  go('bulk-schedule-confirmed');
}

function renderBulkScheduleConfirmed(){
  document.getElementById('bsc-bulk-id').textContent = currentBulkId;
  document.getElementById('bsc-plant').textContent = currentBulkPlant;
  const justConfirmedBulkIndex = confirmedBulks.length - 1;
  const wrap = document.getElementById('bsc-groups');
  wrap.innerHTML = bulkTreatmentGroups.map((g, gi) => {
    const meta = STAGE_META[g.stage];
    const heading = (g.stage === 4 ? 'PRIORITY — ' : '') + 'Black Sigatoka Treatment';
    return '<div class="bsc-event-card" onclick="goToScheduleFromConfirmation(' + justConfirmedBulkIndex + ',' + gi + ')">'
      + '<div class="bsc-event-head"><span class="emoji">' + meta.emoji + '</span><h5>' + heading + '</h5><span class="bsc-chev">›</span></div>'
      + '<div class="bsc-row"><span class="lab">Plant</span><span class="val">' + currentBulkPlant + '</span></div>'
      + '<div class="bsc-row"><span class="lab">Bulk ID</span><span class="val">' + currentBulkId + '</span></div>'
      + '<div class="bsc-row"><span class="lab">Group</span><span class="val">' + meta.label + '</span></div>'
      + '<div class="bsc-row"><span class="lab">Affected Leaves</span><span class="val">Leaf ' + g.leafNums.map(n => String(n).padStart(2,'0')).join(', ') + '</span></div>'
      + '<div class="bsc-row"><span class="lab">Treatment Window</span><span class="val">' + g.window + '</span></div>'
      + '<div class="bsc-row"><span class="lab">Status</span><span class="val bsc-status">✅ Scheduled</span></div>'
      + '<div class="bsc-tap-hint">Tap to view treatment schedule →</div>'
      + '</div>';
  }).join('');
}

/* Tapping a calendar-event card on the confirmation screen jumps straight into
   that stage-group's Smart Schedule treatment view, same destination as the
   Scheduled Treatments → Bulk → Stage drill-down. */
function goToScheduleFromConfirmation(bulkIndex, stageIndex){
  selectedBulkIndex = bulkIndex;
  selectedStageIndex = stageIndex;
  const b = confirmedBulks[bulkIndex];
  const g = b && b.groups ? b.groups[stageIndex] : null;
  if(g){
    currentStage = g.stage;
    renderStage();
    renderTreatmentSchedule();
  }
  go('treatment');
}

/* ---------- Predicted Black Sigatoka stage (dynamic) ---------- */
const STAGE_DATA = {
  1: {
    title: "Suspected Black Sigatoka — Stage 1",
    assessment: "Suspected: Early Stage Black Sigatoka",
    description: "This assessment suggests possible early-stage symptoms. Small streaks are just beginning to appear on the leaf surface.",
    commonSymptoms: ["Light reddish-brown streaks","Faint yellow halo forming","No significant leaf damage yet"],
    confidence: "94.7%",
    nextStep: "Symptoms suggest possible early-stage progression. A treatment window may be considered for review, pending your confirmation.",
    stepAssessment: "Suspected early-stage Black Sigatoka detected. Small streaks are just beginning to appear on the leaf surface.",
    stepTreatment: "Symptoms suggest early-stage progression — a treatment window may be considered for review.",
    stepApplication: "Monitor the affected plant and inspect nearby leaves for similar symptoms while the suggested treatment window is reviewed.",
    stepFollowup: "Any treatment remains subject to your confirmation and applicable agricultural guidance."
  },
  2: {
    title: "Suspected Black Sigatoka — Stage 2",
    assessment: "Suspected: Stage 2 Black Sigatoka",
    description: "This assessment suggests possible stage 2 symptoms. Streaks appear to elongate and darken, with the surrounding yellow area growing.",
    commonSymptoms: ["Elongated dark brown streaks","Widening yellow halo","Multiple visible lesions"],
    confidence: "91.2%",
    nextStep: "Symptoms suggest possible progression. A treatment window may be considered for review, pending your confirmation.",
    stepAssessment: "Suspected Stage 2 Black Sigatoka detected. Streaks appear to elongate and darken, with the surrounding yellow area growing.",
    stepTreatment: "Symptoms are progressing — a treatment window may be considered for review.",
    stepApplication: "Continue monitoring the plant while the suggested treatment window is reviewed.",
    stepFollowup: "Any treatment remains subject to your confirmation and applicable agricultural guidance."
  },
  3: {
    title: "Suspected Black Sigatoka — Stage 3",
    assessment: "Suspected: Stage 3 Black Sigatoka",
    description: "This assessment suggests possible stage 3 symptoms. Lesions appear to darken and merge, often with a wet-looking border.",
    commonSymptoms: ["Dark brown to black lesions","Wet-looking lesion borders","Merging spots across the leaf"],
    confidence: "88.5%",
    nextStep: "Symptoms suggest possible progression. Consider closer monitoring and review whether a treatment window should be scheduled, pending your confirmation.",
    stepAssessment: "Suspected Stage 3 Black Sigatoka detected. Lesions appear to darken and merge, often with a wet-looking border.",
    stepTreatment: "Symptoms are progressing — a treatment window may be considered for review.",
    stepApplication: "Closer monitoring is advised while the suggested treatment window is reviewed.",
    stepFollowup: "Any treatment remains subject to your confirmation and applicable agricultural guidance."
  },
  4: {
    title: "Suspected Black Sigatoka — Stage 4",
    assessment: "Suspected: Stage 4 (Advanced) Black Sigatoka",
    description: "This assessment suggests possible advanced-stage symptoms. Large sections of the leaf appear to have died off, which may reduce the plant's ability to photosynthesize.",
    commonSymptoms: ["Extensive leaf necrosis","Black lesions with yellow ring","Leaf appears scorched or dried"],
    confidence: "96.3%",
    nextStep: "Symptoms suggest possible advanced progression. A priority monitoring and treatment-window schedule can be suggested for your review and confirmation.",
    stepAssessment: "Suspected Stage 4 (Advanced) Black Sigatoka detected. Large sections of the leaf appear to have died off.",
    stepTreatment: "Symptoms suggest possible advanced progression — a priority treatment window is suggested for review.",
    stepApplication: "Prioritize inspection of the plant and surrounding leaves without delay.",
    stepFollowup: "A priority monitoring and treatment-window schedule can be suggested for your review and confirmation."
  }
};

const SCHEDULE_DATA = {
  1: {
    ruleAnd: "Observed symptoms match early-stage pattern",
    rule: "Early-stage symptoms — treatment window suggested for consideration",
    output: "Suggested monitoring & treatment-window schedule",
    events: [
      {day:18, color:'green', type:'Monitor', desc:'Check the affected leaf and nearby leaves for any change.'},
      {day:19, color:'yellow', type:'Re-assessment', desc:'Follow-up visual check of the marked leaf area.'},
      {day:20, color:'blue', type:'Suggested Treatment', desc:'Treatment may be considered during this window, subject to your confirmation and applicable agricultural guidance.'},
      {day:22, color:'orange', type:'Follow-up', desc:'Compare current symptoms against this assessment.'}
    ]
  },
  2: {
    ruleAnd: "Observed symptoms match stage 2 pattern",
    rule: "Symptoms progressing — treatment window suggested for consideration",
    output: "Suggested monitoring & treatment-window schedule",
    events: [
      {day:18, color:'green', type:'Monitor', desc:'Check the affected leaf and nearby leaves for any change.'},
      {day:19, color:'yellow', type:'Re-assessment', desc:'Follow-up visual check of the marked leaf area.'},
      {day:21, color:'blue', type:'Suggested Treatment', desc:'Treatment may be considered during this window, subject to your confirmation and applicable agricultural guidance.'},
      {day:24, color:'orange', type:'Follow-up', desc:'Compare current symptoms against this assessment.'}
    ]
  },
  3: {
    ruleAnd: "Observed symptoms match stage 3 pattern",
    rule: "Symptoms progressing — treatment window suggested for consideration",
    output: "Suggested monitoring & treatment-window schedule",
    events: [
      {day:18, color:'green', type:'Monitor', desc:'Check the affected leaf and nearby leaves for any change.'},
      {day:19, color:'yellow', type:'Re-assessment', desc:'Follow-up visual check of the marked leaf area.'},
      {day:20, color:'blue', type:'Suggested Treatment', desc:'Treatment may be considered during this window, subject to your confirmation and applicable agricultural guidance.'},
      {day:21, color:'blue', type:'Suggested Treatment', desc:'Treatment may be considered during this window, subject to your confirmation and applicable agricultural guidance.'},
      {day:25, color:'orange', type:'Follow-up', desc:'Compare current symptoms against this assessment.'}
    ]
  },
  4: {
    ruleAnd: "Observed symptoms match stage 4 (advanced) pattern",
    rule: "Advanced symptoms — priority treatment window suggested for consideration",
    output: "Suggested priority monitoring & treatment-window schedule",
    events: [
      {day:18, color:'green', type:'Monitor', desc:'Check the affected leaf and nearby leaves for any change.'},
      {day:19, color:'blue', type:'Suggested Treatment', desc:'Advanced symptoms — treatment may be considered during this window, subject to your confirmation.'},
      {day:23, color:'red', type:'Further Review', desc:'Advanced, priority case — an in-person specialist review is strongly recommended.'},
      {day:26, color:'orange', type:'Follow-up', desc:'Compare current symptoms against this assessment.'}
    ]
  }
};

const COLOR_VARS = { green:'var(--leaf)', yellow:'var(--banana)', blue:'var(--teal)', orange:'var(--warn)', red:'var(--danger)' };
const DOT_EMOJI = { green:'🌿', yellow:'🔍', blue:'🧴', orange:'🍃', red:'🔥' };

/* Full visual treatment per activity type — used to render calendar cards,
   the Up Next card, and (via DOT_EMOJI) the activity list + next-action badge. */
const EVENT_META = {
  green:  { bg:'rgba(30,158,74,.12)',  border:'rgba(30,158,74,.35)',  text:'var(--forest)', icon:'🌿', label:'MONITOR',    critical:false },
  yellow: { bg:'rgba(255,201,60,.2)',  border:'rgba(255,201,60,.5)',  text:'#9C6B00',        icon:'🔍', label:'RE-ASSESS',  critical:false },
  blue:   { bg:'rgba(42,157,143,.14)', border:'rgba(42,157,143,.4)',  text:'var(--teal)',    icon:'🧴', label:'TREATMENT',  critical:false },
  orange: { bg:'rgba(231,111,81,.14)', border:'rgba(231,111,81,.42)', text:'var(--warn)',    icon:'🍃', label:'FOLLOW-UP',  critical:false },
  red:    { bg:'rgba(214,40,40,.12)',  border:'rgba(214,40,40,.5)',   text:'var(--danger)',  icon:'🔥', label:'REVIEW',     critical:true  }
};

/* Mock "today" — resolves to the real device date when it falls within the
   demo's August 2026 calendar, otherwise falls back to day 17 for the demo. */
function getTodayInfo(){
  const now = new Date();
  const isAug2026 = now.getFullYear() === 2026 && now.getMonth() === 7;
  const todayDay = isAug2026 ? now.getDate() : 17;
  return { now, todayDay };
}


let currentStage = 1;

function symptomPillsHtml(list){
  return list.map(s=>'<div class="symptom-pill"><span class="sq"></span>'+s+'</div>').join('');
}

const TIMELINE_META = {
  oil: { statusClass:'upcoming', dotIcon:'🟡' },
  fungicide: { statusClass:'scheduled', dotIcon:'🔵' },
  monitor: { statusClass:'monitor', dotIcon:'⚪' }
};
let timelineChecked = { oil:false, fungicide:false, monitor:false };
let finalTimelineChecked = { oil:false, fungicide:false, monitor:false };

function setStage(n){
  currentStage = n;
  timelineChecked = { oil:false, fungicide:false, monitor:false };
  finalTimelineChecked = { oil:false, fungicide:false, monitor:false };
  renderStage();
}

/* Opens the single-plant assessment detail (screen-final) for a given stage,
   used by the Assessment History list so each past entry reflects its own stage. */
function viewHistoryAssessment(stage){
  setStage(stage);
  go('final');
}


function updateDashboardOverview(){
  const leavesEl = document.getElementById('dash-leaves');
  const bulksEl = document.getElementById('dash-bulks');
  const treatmentEl = document.getElementById('dash-treatment');
  if(!leavesEl || !bulksEl || !treatmentEl) return;
  // Keep the polished demo values until real bulk records exist. Once the user
  // completes bulk assessments, update the overview from the actual in-session data.
  if(recentBulkAssessments && recentBulkAssessments.length){
    const totalLeaves = recentBulkAssessments.reduce((sum,b)=>sum+(Number(b.leafCount)||0),0);
    const totalTreatment = recentBulkAssessments.reduce((sum,b)=>{
      const c=b.counts||{};
      return sum + [1,2,3,4].reduce((n,stage)=>n+(Number(c[stage])||0),0);
    },0);
    leavesEl.textContent = totalLeaves;
    bulksEl.textContent = recentBulkAssessments.length;
    treatmentEl.textContent = totalTreatment;
  }
}

/* ---------- Bulk Recent Scanned history ---------- */
let recentBulkAssessments = [];
let selectedRecentBulkIndex = null;

function captureCurrentBulkAssessment(){
  if(!currentBulkId || !currentBulkPlant || !bulkLeaves.length) return;
  const counts = {1:0,2:0,3:0,4:0};
  bulkLeaves.forEach(l=>{ if(l.valid && counts[l.stage] !== undefined) counts[l.stage]++; });
  const snapshot = {
    bulkId: currentBulkId,
    plant: currentBulkPlant,
    date: BULK_ASSESSMENT_DATE,
    leafCount: bulkLeaves.length,
    counts: {...counts},
    status: 'Assessment Complete',
    leaves: JSON.parse(JSON.stringify(bulkLeaves))
  };
  const existing = recentBulkAssessments.findIndex(x=>x.bulkId === snapshot.bulkId);
  if(existing >= 0) recentBulkAssessments[existing] = snapshot;
  else recentBulkAssessments.unshift(snapshot);
  recentBulkAssessments = recentBulkAssessments.slice(0,8);
}

function buildBulkTreatmentGroups(){
  bulkTreatmentGroups = [];
  [4,3,2,1].forEach(stage => {
    const nums = [];
    bulkLeaves.forEach((l,i) => { if(l.valid && l.stage === stage) nums.push(i+1); });
    if(nums.length) bulkTreatmentGroups.push({ stage, leafNums: nums, window: TREATMENT_WINDOWS[stage] });
  });
}

function openRecentBulkAssessment(i){
  const b = recentBulkAssessments[i];
  if(!b) return;
  selectedRecentBulkIndex = i;
  currentBulkId = b.bulkId;
  currentBulkPlant = b.plant;
  bulkLeaves = JSON.parse(JSON.stringify(b.leaves));
  document.querySelectorAll('.bulk-id-value').forEach(el => el.textContent = currentBulkId);
  document.querySelectorAll('.bulk-plant-value').forEach(el => el.textContent = currentBulkPlant);
  document.querySelectorAll('.bulk-date-value').forEach(el => el.textContent = b.date);
  renderBulkThumbs();

  // View Bulk opens directly to the confirmed Bulk Treatment Schedule view.
  // Reuse an existing confirmed schedule for this Bulk ID when available; otherwise
  // build the stage groups and create the same calendar schedule used by the normal
  // Confirm & Schedule flow. This keeps the screenshot-style destination functional.
  buildBulkTreatmentGroups();
  if(bulkTreatmentGroups.length === 0){
    setBulkStatus(b.status);
    go('bulk-summary');
    return;
  }

  let existing = confirmedBulks.findIndex(x => x.bulkId === currentBulkId);
  if(existing < 0){
    setBulkStatus('Scheduled');
    recordConfirmedBulkSchedule();
  } else {
    setBulkStatus('Scheduled');
  }

  renderBulkScheduleConfirmed();
  renderBulkPipeline('bulk-pipeline-confirmed', 9);
  go('bulk-schedule-confirmed');
}

function renderBulkRecentScanned(){
  const wrap = document.getElementById('bulk-recent-scanned-list');
  if(!wrap) return;
  if(recentBulkAssessments.length === 0){
    wrap.innerHTML = '<div class="bulk-action-empty">No bulk assessments have been completed yet. Run a bulk assessment to see it here.</div>';
    return;
  }
  wrap.innerHTML = recentBulkAssessments.map((b,i)=>{
    const c=b.counts || {1:0,2:0,3:0,4:0};
    return '<div class="hist-card bulk-recent-card" onclick="openRecentBulkAssessment('+i+')">'
      + '<div class="thumb">📦</div>'
      + '<div class="hist-body">'
      + '<div class="date">'+b.date+'</div>'
      + '<div class="name">'+b.plant+'</div>'
      + '<div class="diag" style="color:var(--teal)">'+b.bulkId+'</div>'
      + '<div class="diag">'+b.leafCount+' leaves scanned</div>'
      + '<div class="diag" style="color:var(--ink-soft)">Stage 1: '+c[1]+' | Stage 2: '+c[2]+' | Stage 3: '+c[3]+' | Stage 4: '+c[4]+'</div>'
      + '</div>'
      + '<div class="hist-conf"><div class="pct" style="font-size:11px;">'+b.status+'</div><div class="view">View Bulk</div></div>'
      + '</div>';
  }).join('');
}

/* ---------- Assessment History filter chips (All / Healthy / Suspected) ---------- */
function filterAssessmentHistory(status){
  const scope = document.getElementById('screen-history');
  scope.querySelectorAll('.filter-row .filter-chip').forEach(chip=>{
    chip.classList.toggle('active', chip.dataset.filter === status);
  });
  let visibleCount = 0;
  scope.querySelectorAll('.hist-card').forEach(card=>{
    const match = status === 'all' || card.dataset.status === status;
    card.classList.toggle('hide', !match);
    if(match) visibleCount++;
  });
  const emptyNote = document.getElementById('hist-empty-note');
  if(emptyNote) emptyNote.classList.toggle('hide', visibleCount > 0);
}

function renderStage(){
  const data = STAGE_DATA[currentStage];
  document.getElementById('final-assessment').textContent = data.assessment;
  document.getElementById('final-stage-title').textContent = data.title;
  document.getElementById('final-stage-desc').textContent = data.description;
  document.getElementById('final-common-symptoms').innerHTML = symptomPillsHtml(data.commonSymptoms);
  document.getElementById('rec-step-assessment').textContent = data.stepAssessment;
  document.getElementById('review-stage').textContent = 'Stage ' + currentStage;
  renderFinalTimelineChecklist();
  document.querySelectorAll('#stage-demo-btns button').forEach(b=>{
    b.classList.toggle('active', Number(b.dataset.stage) === currentStage);
  });
}
renderStage();

/* ---------- Treatment History (farmer-reported, never assumed) ---------- */
let treatmentHistoryState = null; // 'APPLIED' | 'NOT_APPLIED' | 'UNKNOWN'
let lastTreatmentType = 'oil'; // 'oil' | 'fungicide' — only meaningful when treatmentHistoryState === 'APPLIED'
let treatmentHistoryFlow = 'single'; // 'single' (per-leaf schedule) | 'bulk' (bulk stage-group schedule)

function resetTreatmentHistoryScreen(){
  treatmentHistoryState = null;
  lastTreatmentType = 'oil';
  ['APPLIED','NOT_APPLIED','UNKNOWN'].forEach(s=>{
    const el = document.getElementById('th-btn-'+s);
    if(el) el.classList.remove('checked');
  });
  selectLastTreatmentType('oil');
  document.getElementById('th-applied-block').classList.add('hide');
  document.getElementById('th-unknown-note').classList.add('hide');
  document.getElementById('th-notapplied-note').classList.add('hide');
  document.getElementById('th-continue-wrap').classList.add('hide');
}

function selectTreatmentHistory(state){
  treatmentHistoryState = state;
  ['APPLIED','NOT_APPLIED','UNKNOWN'].forEach(s=>{
    const el = document.getElementById('th-btn-'+s);
    if(el) el.classList.toggle('checked', s === state);
  });
  document.getElementById('th-applied-block').classList.toggle('hide', state !== 'APPLIED');
  document.getElementById('th-unknown-note').classList.toggle('hide', state !== 'UNKNOWN');
  document.getElementById('th-notapplied-note').classList.toggle('hide', state !== 'NOT_APPLIED');
  document.getElementById('th-continue-wrap').classList.remove('hide');
}

function selectLastTreatmentType(type){
  lastTreatmentType = type;
  const select = document.getElementById('th-type-select');
  if(select) select.value = type;
}

/* Farmer confirms the suspected assessment -> ask treatment history before scheduling */
function confirmAssessment(){
  treatmentHistoryFlow = 'single';
  resetTreatmentHistoryScreen();
  go('treatmenthistory');
}

/* Bulk flow: a treatment schedule (for the eligible Stage 3/4 groups) is never created
   without first asking whether the plant has already been treated. */
function startBulkTreatmentHistory(){
  treatmentHistoryFlow = 'bulk';
  resetTreatmentHistoryScreen();
  go('treatmenthistory');
}

/* Close (X) button on Treatment History returns to wherever that flow started from. */
function closeTreatmentHistory(){
  go(treatmentHistoryFlow === 'bulk' ? 'bulk-actions' : 'final');
}

function proceedFromHistory(){
  if(treatmentHistoryFlow === 'bulk'){
    goToBulkScheduleReview();
    return;
  }
  timelineChecked = { oil:false, fungicide:false, monitor:false };
  renderTreatmentSchedule();
  go('treatment');
}

/* ---------- AI + Agricultural/Symbolic scheduling (rules run behind the scenes) ---------- */
/* If treatment history is UNKNOWN, never assume a previous treatment occurred: swap any
   suggested treatment window for a safer "Re-inspect Plant" action pending farmer confirmation.
   If a previous treatment WAS applied, rotate the suggested treatment type away from whatever
   the farmer says they last used (basic FRAC-rotation-style logic), so the schedule reflects it. */
function getScheduleEvents(){
  const sd = SCHEDULE_DATA[currentStage];
  return sd.events.map(ev=>{
    if(ev.type !== 'Suggested Treatment') return ev;
    if(treatmentHistoryState === 'UNKNOWN'){
      return { day:ev.day, color:'yellow', type:'Re-inspect Plant', desc:'Previous treatment history is unknown. Re-check the plant before proceeding with another treatment.' };
    }
    if(treatmentHistoryState === 'APPLIED'){
      const lastLabel = lastTreatmentType === 'oil' ? 'Oil' : 'Fungicide / Chemical';
      const nextLabel = lastTreatmentType === 'oil' ? 'Fungicide / Chemical' : 'Oil';
      return { day:ev.day, color:ev.color, type:'Suggested Treatment', desc:'Suggested: '+nextLabel+' application — rotating away from your last recorded treatment ('+lastLabel+'). Subject to your confirmation.' };
    }
    return ev;
  });
}


/* ---------- Photo proof of treatment (required before checking off Oil/Fungicide steps) ---------- */
let pendingProof = null; // { scope: 'timeline'|'final', key: 'oil'|'fungicide' }

const PROOF_LABELS = { oil:'Oil Application', fungicide:'Fungicide / Chemical' };

/* Intercepts the checkbox click: checking ON a treatment step opens the photo-proof
   modal instead of toggling directly; unchecking (or non-gated items) toggles as normal. */
function handleTreatmentCheckbox(event, scope, key){
  const checkbox = event.target;
  const stateObj = scope === 'timeline' ? timelineChecked : finalTimelineChecked;
  if(checkbox.checked && !stateObj[key]){
    checkbox.checked = false; // revert until proof is confirmed
    openProofModal(scope, key);
    return;
  }
  if(scope === 'timeline') toggleTimelineItem(key); else toggleFinalTimelineItem(key);
}

function openProofModal(scope, key){
  pendingProof = { scope, key };
  document.getElementById('proof-modal-sub').textContent =
    'Upload a photo showing the ' + PROOF_LABELS[key] + ' treatment was applied before marking this step as done.';
  document.getElementById('proof-file-input').value = '';
  document.getElementById('proof-preview-wrap').classList.add('hide');
  document.getElementById('proof-preview-img').src = '';
  document.getElementById('proof-upload-box').classList.remove('hide');
  document.getElementById('proof-upload-text').textContent = 'Tap to upload a photo';
  document.getElementById('proof-confirm-btn').disabled = true;
  document.getElementById('proof-overlay').classList.add('show');
}

function closeProofModal(){
  document.getElementById('proof-overlay').classList.remove('show');
  pendingProof = null;
}

function handleProofFileSelected(event){
  const file = event.target.files[0];
  if(!file) return;
  const reader = new FileReader();
  reader.onload = function(e){
    document.getElementById('proof-preview-img').src = e.target.result;
    document.getElementById('proof-preview-wrap').classList.remove('hide');
    document.getElementById('proof-preview-name').textContent = file.name;
    document.getElementById('proof-upload-text').textContent = 'Tap to change photo';
    document.getElementById('proof-confirm-btn').disabled = false;
  };
  reader.readAsDataURL(file);
}

function confirmProofUpload(){
  if(!pendingProof) return;
  const { scope, key } = pendingProof;
  if(scope === 'timeline') toggleTimelineItem(key); else toggleFinalTimelineItem(key);
  closeProofModal();
}

/* ---------- Detailed Timeline checklist (separate tracker from Suggested Activities) ---------- */
function toggleTimelineItem(key){
  timelineChecked[key] = !timelineChecked[key];
  renderTimelineChecklist();
  // Closing the loop: once the final reassessment step is checked off, ask the
  // farmer what actually happened instead of silently ending the cycle.
  if(key === 'monitor' && timelineChecked.monitor){
    openOutcomeModal();
  }
}

/* ---------- Outcome check (prevents the cycle from ending with no resolution) ---------- */
function openOutcomeModal(){
  document.getElementById('outcome-modal-ask').style.display = '';
  document.getElementById('outcome-modal-result').style.display = 'none';
  document.getElementById('outcome-overlay').classList.add('show');
}
function closeOutcomeModal(){
  document.getElementById('outcome-overlay').classList.remove('show');
}
function submitOutcome(result){
  const badge = document.getElementById('sched-status-badge');
  const icon = document.getElementById('outcome-result-icon');
  const title = document.getElementById('outcome-result-title');
  const desc = document.getElementById('outcome-result-desc');
  const btn = document.getElementById('outcome-result-btn');

  if(result === 'improved'){
    icon.textContent = '✅';
    title.textContent = 'Cycle Complete';
    desc.textContent = "Nice work — the plant is looking healthy. We'll close this cycle and keep Plant #001 on routine monitoring.";
    badge.className = 'sched-status active';
    badge.textContent = '✅ Cycle Complete — Healthy';
    btn.textContent = 'Done';
    btn.onclick = closeOutcomeModal;
  } else {
    const worse = result === 'worse';
    icon.textContent = '⚠️';
    title.textContent = worse ? 'Symptoms Persisting' : 'No Improvement Yet';
    desc.textContent = worse
      ? "The full cycle didn't resolve it. We recommend a fresh scan to confirm current stage, and flagging this for an agricultural specialist."
      : "No change after the full cycle. A follow-up scan will help confirm whether a new treatment approach or specialist review is needed.";
    badge.className = 'sched-status attention';
    badge.textContent = '⚠️ Escalation Needed — Rescan Recommended';
    btn.textContent = 'Rescan Leaf';
    btn.onclick = function(){ closeOutcomeModal(); go('scan'); };
  }

  document.getElementById('outcome-modal-ask').style.display = 'none';
  document.getElementById('outcome-modal-result').style.display = '';
}

function renderTimelineChecklist(){
  let doneCount = 0;
  Object.keys(TIMELINE_META).forEach(key=>{
    const meta = TIMELINE_META[key];
    const isDone = timelineChecked[key];
    if(isDone) doneCount++;
    const item = document.getElementById('timeline-item-'+key);
    const dot = document.getElementById('timeline-dot-'+key);
    const checkbox = document.getElementById('timeline-checkbox-'+key);
    if(item) item.className = 'sched-item ' + (isDone ? 'done' : meta.statusClass);
    if(dot) dot.textContent = isDone ? '✓' : meta.dotIcon;
    if(checkbox) checkbox.checked = isDone;
  });
  const progEl = document.getElementById('timeline-progress');
  if(progEl) progEl.textContent = doneCount + ' / ' + Object.keys(TIMELINE_META).length + ' done';
  renderCalendar();
  renderUpNext();
}

/* ---------- Detailed Timeline preview on the Full Assessment screen (Recommended Next Step) ---------- */
function toggleFinalTimelineItem(key){
  finalTimelineChecked[key] = !finalTimelineChecked[key];
  renderFinalTimelineChecklist();
}

function renderFinalTimelineChecklist(){
  let doneCount = 0;
  Object.keys(TIMELINE_META).forEach(key=>{
    const meta = TIMELINE_META[key];
    const isDone = finalTimelineChecked[key];
    if(isDone) doneCount++;
    const item = document.getElementById('final-timeline-item-'+key);
    const dot = document.getElementById('final-timeline-dot-'+key);
    const checkbox = document.getElementById('final-timeline-checkbox-'+key);
    if(item) item.className = 'sched-item ' + (isDone ? 'done' : meta.statusClass);
    if(dot) dot.textContent = isDone ? '✓' : meta.dotIcon;
    if(checkbox) checkbox.checked = isDone;
  });
  const progEl = document.getElementById('final-timeline-progress');
  if(progEl) progEl.textContent = doneCount + ' / ' + Object.keys(TIMELINE_META).length + ' done';
}

/* ---------- Scheduled Treatments hierarchy: Smart Schedule -> Bulk -> Stage -> Schedule Details ----------
   Each confirmed bulk (see confirmBulkSchedule) is recorded here so the farmer can drill down into any
   past bulk's treatment-eligible stage groups (Stages 1–4 — see STAGE_META / goToBulkScheduleReview).
   The number of Bulks and Stages is never hard-coded; this list grows/shrinks with real confirmations. */
let confirmedBulks = [];     // { displayLabel, bulkId, plant, groups:[{stage,leafNums,window,schedule}] }
let confirmedBulkCounter = 0;
let selectedBulkIndex = null;
let selectedStageIndex = null;

// A schedule is never assumed applied just because it was generated — every entry starts
// "Suggested" and only changes if the farmer explicitly confirms/applies it elsewhere in the app.
const SCHEDULE_STATUS_META = {
  'Suggested':          { chip:'upcoming',  icon:'🟡' },
  'Confirmed':          { chip:'scheduled', icon:'🔵' },
  'Applied':            { chip:'completed', icon:'✅' },
  'Unknown':            { chip:'unknown',   icon:'❔' },
  'Follow-up Required': { chip:'attention', icon:'⚠️' }
};

function recordConfirmedBulkSchedule(){
  if(bulkTreatmentGroups.length === 0) return;
  confirmedBulkCounter++;
  const groups = bulkTreatmentGroups.map(g => {
    const startDay = parseInt((g.window.match(/\d+/) || ['20'])[0], 10);
    const raw = [
      { label:'Treatment',     offset:0,  desc:'Scheduled ' + STAGE_META[g.stage].label.toLowerCase() + ' treatment activity.' },
      { label:'Follow-up',     offset:5,  desc:'Check the condition after treatment.' },
      { label:'Re-assessment', offset:10, desc:'Perform another assessment to confirm progress.' }
    ];
    const schedule = raw.map(item => {
      let day = startDay + item.offset, month = 'August';
      if(day > 31){ day -= 31; month = 'September'; }
      return { label:item.label, day, month, desc:item.desc, status:'Suggested' };
    });
    return { stage:g.stage, leafNums:g.leafNums, window:g.window, schedule };
  });
  confirmedBulks.push({
    displayLabel: 'Bulk ' + confirmedBulkCounter,
    bulkId: currentBulkId,
    plant: currentBulkPlant,
    groups
  });
}

function renderScheduledTreatments(){
  const wrap = document.getElementById('scheduled-treatments-list');
  if(!wrap) return;
  if(confirmedBulks.length === 0){
    wrap.innerHTML = '<div class="bulk-action-empty">No treatments have been scheduled yet. Scan and confirm a bulk treatment schedule to see it here.</div>';
    return;
  }
  wrap.innerHTML = confirmedBulks.map((b, i) => {
    const n = b.groups.length;
    return '<div class="sched-hier-card" onclick="openBulkStages(' + i + ')">'
      + '<div class="shc-top"><span class="shc-icon">📦</span>'
      + '<div class="shc-text"><h5>' + b.displayLabel + '</h5><p>' + b.plant + ' · ' + b.bulkId + '</p></div>'
      + '<div class="shc-chev">›</div></div>'
      + '<div class="shc-sub">' + n + (n === 1 ? ' scheduled stage' : ' scheduled stages') + '</div>'
      + '</div>';
  }).join('');
}

function openBulkStages(i){
  selectedBulkIndex = i;
  const b = confirmedBulks[i];
  if(!b) return;
  document.getElementById('bulk-stages-title').textContent = b.displayLabel;
  document.getElementById('bulk-stages-sub').textContent = b.plant + ' · ' + b.bulkId;
  const wrap = document.getElementById('bulk-stages-list');
  wrap.innerHTML = b.groups.map((g, gi) => {
    const meta = STAGE_META[g.stage];
    return '<div class="sched-hier-card" onclick="openStageSchedule(' + gi + ')">'
      + '<div class="shc-top"><span class="shc-icon">' + meta.emoji + '</span>'
      + '<div class="shc-text"><h5>Stage ' + g.stage + '</h5><p>Treatment schedule available</p></div>'
      + '<div class="shc-chev">›</div></div>'
      + '</div>';
  }).join('');
  go('bulk-stages');
}

/* Selecting a Stage under a Bulk used to open an intermediate "Schedule Details" screen
   listing that stage's activities before letting the user open the full calendar. That
   screen has been removed — selecting a stage now goes straight to the Smart Schedule
   calendar, which already shows all confirmed activities. */
function openStageSchedule(gi){
  selectedStageIndex = gi;
  const b = confirmedBulks[selectedBulkIndex];
  const g = b && b.groups ? b.groups[gi] : null;
  if(g){
    currentStage = g.stage;
    renderStage();
    renderTreatmentSchedule();
  }
  go('treatment');
}

/* ---------- Smart Schedule calendar + Next Suggested Action ---------- */
/* The calendar now mirrors the Detailed Timeline (not the Suggested Activities list) */
const TIMELINE_CAL_META = {
  done:      { bg:'rgba(30,158,74,.12)',  border:'rgba(30,158,74,.35)',  text:'var(--forest)',        icon:'✓',  label:'DONE',       alert:null },
  oil:       { bg:'rgba(255,201,60,.2)',  border:'rgba(255,201,60,.5)',  text:'#9C6B00',               icon:'🟡', label:'OIL APPLICATION', alert:'pending' },
  fungicide: { bg:'rgba(42,157,143,.14)', border:'rgba(42,157,143,.4)',  text:'var(--teal)',           icon:'🔵', label:'FUNGICIDE',  alert:'pending' },
  monitor:   { bg:'var(--tile-grey)',     border:'var(--tile-grey-ink)', text:'var(--tile-grey-ink)',  icon:'⚪', label:'MONITOR',    alert:null },
  missed:    { bg:'rgba(214,40,40,.12)',  border:'rgba(214,40,40,.5)',   text:'var(--danger)',         icon:'🔥', label:'MISSED',     alert:'missed' }
};

function getTimelineCalendarEvents(){
  const { todayDay } = getTodayInfo();
  const raw = [
    { day:10, done:true, kind:'done', type:'Suspected Disease Logged', desc:'Suspected Black Sigatoka — Stage 1' },
    { day:15, done:timelineChecked.oil, kind:'oil', type:'Oil Application', desc:'Suggested oil application window.' },
    { day:29, done:timelineChecked.fungicide, kind:'fungicide', type:'Fungicide / Chemical', desc:'Suggested fungicide / chemical treatment window.' }
    // Monitoring/Reassessment (Sep 12) is outside this August grid, so it's left out
    // of calendar/Up Next day-number comparisons — it still lives in the Detailed Timeline.
  ];
  return raw.map(ev=>{
    let state;
    if(ev.done) state = 'done';
    else if(ev.day < todayDay) state = 'missed';
    else state = ev.kind;
    return { day:ev.day, state, type: state==='missed' ? ev.type+' — Missed' : ev.type, desc: state==='missed' ? 'This was scheduled for August '+ev.day+' and hasn\'t been marked done yet. Please complete it as soon as possible.' : ev.desc };
  });
}

const CAL_LAYOUT = [
  [null,null,null,null,null,15,16],
  [17,18,19,20,21,22,23],
  [24,25,26,27,28,29,30]
];

let nextAction = null;

function renderCalendar(){
  const { todayDay } = getTodayInfo();
  const events = getTimelineCalendarEvents();
  const eventsByDay = {};
  events.forEach(ev=>{ eventsByDay[ev.day] = ev; }); // schedule never double-books a day

  const dows = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  let html = dows.map(d=>'<div class="cal-dow">'+d+'</div>').join('');
  CAL_LAYOUT.forEach(week=>{
    week.forEach(day=>{
      if(day === null){ html += '<div class="cal-day empty"></div>'; return; }
      const isToday = day === todayDay;
      const ev = eventsByDay[day];
      if(!ev){
        html += '<div class="cal-day'+(isToday?' today':'')+'">'+day+'</div>';
        return;
      }
      const meta = TIMELINE_CAL_META[ev.state];
      html += '<div class="cal-day has-event'+(meta.alert==='pending'?' pending':'')+(meta.alert==='missed'?' critical':'')+(isToday?' today':'')+'" '
        + 'style="background:'+meta.bg+'; border-color:'+meta.border+'; color:'+meta.text+';" title="'+ev.type+'">'
        + (meta.alert==='pending' ? '<span class="cd-badge">UPCOMING</span>' : '')
        + (meta.alert==='missed' ? '<span class="cd-badge">MISSED</span>' : '')
        + '<span class="cd-num">'+day+'</span>'
        + '<span class="cd-icon">'+meta.icon+'</span>'
        + '<span class="cd-lab">'+meta.label+'</span>'
        + '</div>';
    });
  });
  document.getElementById('cal-grid').innerHTML = html;
}

/* Up Next: the nearest scheduled activity from today, with a dynamically
   computed (never hard-coded) countdown. */
function renderUpNext(){
  const { todayDay } = getTodayInfo();
  const notDone = getTimelineCalendarEvents().filter(e => e.state !== 'done');
  const missed = notDone.filter(e => e.state === 'missed').sort((a,b)=>a.day-b.day);
  const pending = notDone.filter(e => e.state !== 'missed').sort((a,b)=>a.day-b.day);
  const upcoming = missed[0] || pending.find(e => e.day >= todayDay) || pending[0];
  const card = document.getElementById('upnext-card');
  if(!card) return;

  if(!upcoming){
    card.className = 'upnext-card';
    card.innerHTML = '<div class="upnext-icon" style="background:rgba(30,158,74,.12); color:var(--forest);">✅</div>'
      + '<div class="upnext-body"><div class="upnext-title">Up Next</div>'
      + '<div class="upnext-name">All caught up</div>'
      + '<div class="upnext-date">No further activities scheduled this month.</div></div>';
    return;
  }

  const meta = TIMELINE_CAL_META[upcoming.state];
  const daysLeft = upcoming.day - todayDay;
  let countdownText;
  if(upcoming.state === 'missed') countdownText = '🔥 ' + Math.abs(daysLeft) + (Math.abs(daysLeft) === 1 ? ' DAY OVERDUE' : ' DAYS OVERDUE');
  else if(daysLeft <= 0) countdownText = 'TODAY';
  else if(daysLeft === 1) countdownText = '1 DAY LEFT';
  else countdownText = daysLeft + ' DAYS LEFT';

  card.className = 'upnext-card' + (meta.alert==='pending' ? ' pending' : '') + (meta.alert==='missed' ? ' critical' : '');
  card.innerHTML = '<div class="upnext-icon" style="background:'+meta.bg+'; color:'+meta.text+';">'+meta.icon+'</div>'
    + '<div class="upnext-body">'
    + '<div class="upnext-title">Up Next</div>'
    + '<div class="upnext-name">'+upcoming.type+'</div>'
    + '<div class="upnext-date">Scheduled on August '+upcoming.day+', 2026</div>'
    + '<span class="upnext-countdown" style="background:'+meta.bg+'; color:'+meta.text+';">'+countdownText+'</span>'
    + '<div class="upnext-desc">'+upcoming.desc+'</div>'
    + '</div>';
}

function computeNextAction(){
  const events = getScheduleEvents();
  nextAction = events.find(e=>e.type==='Suggested Treatment') || events.find(e=>e.type==='Re-inspect Plant') || events[0] || null;
  if(!nextAction) return;
  const isTreatment = nextAction.type === 'Suggested Treatment';
  document.getElementById('next-action-badge').textContent = DOT_EMOJI[nextAction.color] + ' ' + nextAction.type.toUpperCase();
  document.getElementById('next-action-window-lab').textContent = isTreatment ? 'Suggested Window' : 'Suggested Date';
  document.getElementById('next-action-window-val').textContent = 'August ' + nextAction.day + ', 2026';
  const statusEl = document.getElementById('next-action-status');
  statusEl.className = 'status-chip ' + (isTreatment ? 'upcoming' : 'scheduled');
  statusEl.textContent = isTreatment ? '🟡 Suggested — Not Yet Confirmed' : '🔵 Suggested';
}

/* Reflect the farmer-reported last treatment in the Treatment Rotation strip */
function renderRotationStrip(){
  const title1 = document.getElementById('rotation-chip1-title');
  const stat1 = document.getElementById('rotation-chip1-stat');
  const dot1 = document.getElementById('rotation-chip1-dot');
  const title2 = document.getElementById('rotation-chip2-title');
  if(!title1 || !title2) return;
  if(treatmentHistoryState === 'APPLIED'){
    const lastLabel = lastTreatmentType === 'oil' ? 'Oil' : 'Fungicide';
    const nextLabel = lastTreatmentType === 'oil' ? 'Fungicide' : 'Oil';
    title1.textContent = lastLabel;
    stat1.textContent = 'Completed';
    dot1.textContent = '🟢';
    title2.textContent = nextLabel;
  } else if(treatmentHistoryState === 'NOT_APPLIED'){
    title1.textContent = 'None recorded';
    stat1.textContent = 'No prior treatment';
    dot1.textContent = '⚪';
    title2.textContent = 'Oil';
  } else if(treatmentHistoryState === 'UNKNOWN'){
    title1.textContent = 'Unknown';
    stat1.textContent = 'Not assumed';
    dot1.textContent = '❔';
    title2.textContent = 'Re-inspect first';
  }
}

function renderTreatmentSchedule(){
  const stageHeading = document.getElementById('schedule-stage-heading');
  const stageSub = document.getElementById('schedule-stage-sub');
  if(stageHeading) stageHeading.textContent = currentStage > 0 ? ('Black Sigatoka — Stage ' + currentStage) : 'Black Sigatoka';
  if(stageSub) stageSub.textContent = currentStage > 0 ? (STAGE_META[currentStage].groupLabel + ' · Stage-specific schedule') : 'Field A · 2.4 ha';
  renderCalendar();
  renderUpNext();
  renderTimelineChecklist();
  computeNextAction();
  renderRotationStrip();
  const badge = document.getElementById('sched-status-badge');
  badge.className = 'sched-status active';
  badge.textContent = '✅ Schedule Generated';
}
renderTreatmentSchedule();

/* ---------- Treatment Details: Suggested → Confirmed → Applied → Follow-up ---------- */
/* Each state is farmer-reported and explicit — the app never assumes a treatment
   was applied just because it reached its suggested date. */
function viewTreatmentDetail(){
  if(!nextAction) computeNextAction();
  const ev = nextAction;
  document.getElementById('detail-treatment-name').textContent = ev ? ev.type : 'Suggested Treatment';
  document.getElementById('detail-date').textContent = ev ? ('August ' + ev.day) : '—';
  const statusEl = document.getElementById('detail-status');
  statusEl.className = 'status-chip upcoming';
  statusEl.textContent = '🟡 Suggested';
  document.getElementById('detail-step-suggested').style.display = '';
  document.getElementById('detail-step-confirmed').style.display = 'none';
  document.getElementById('detail-step-applied').style.display = 'none';
  go('treatment-detail');
}

function confirmTreatmentDetail(){
  const statusEl = document.getElementById('detail-status');
  statusEl.className = 'status-chip scheduled';
  statusEl.textContent = '🔵 Confirmed by Farmer — Not Yet Applied';
  document.getElementById('detail-step-suggested').style.display = 'none';
  document.getElementById('detail-step-confirmed').style.display = '';
}

function markTreatmentApplied(){
  const statusEl = document.getElementById('detail-status');
  statusEl.className = 'status-chip completed';
  statusEl.textContent = '✅ Applied';
  document.getElementById('detail-step-confirmed').style.display = 'none';
  document.getElementById('detail-step-applied').style.display = '';
}

function markTreatmentUnknown(){
  const statusEl = document.getElementById('detail-status');
  statusEl.className = 'status-chip unknown';
  statusEl.textContent = '❔ Unknown — Not Assumed Applied';
  document.getElementById('detail-step-confirmed').style.display = 'none';
  document.getElementById('detail-step-applied').style.display = '';
}

/* ---------- desktop hero clock/date (visual only, no functional changes) ---------- */
function updateHeroDateTime(){
  const clockEl = document.getElementById('hero-clock');
  const dateEl = document.getElementById('hero-date');
  const eyebrowEl = document.getElementById('hero-greeting-eyebrow');
  if(!clockEl || !dateEl) return;
  const now = new Date();
  let h = now.getHours();
  const ampm = h >= 12 ? 'PM' : 'AM';
  h = h % 12; if(h === 0) h = 12;
  const mm = String(now.getMinutes()).padStart(2,'0');
  clockEl.textContent = h + ':' + mm + ' ' + ampm;
  dateEl.textContent = now.toLocaleDateString('en-US', { weekday:'long', month:'short', day:'numeric', year:'numeric' });
  if(eyebrowEl){
    const hr = now.getHours();
    const greet = hr < 12 ? 'GOOD MORNING' : (hr < 18 ? 'GOOD AFTERNOON' : 'GOOD EVENING');
    eyebrowEl.textContent = greet + ', JUAN';
  }
}
updateHeroDateTime();
setInterval(updateHeroDateTime, 30000);

/* ---------- leaf upload zone (visual upload flow → feeds the existing bulk leaf pipeline) ---------- */
function handleLeafFileSelected(event){
  const files = event.target.files;
  if(files && files.length){
    for(let i=0;i<files.length;i++){ addMockLeaf(); }
  }
  event.target.value = '';
}
function handleLeafDragOver(event){
  event.preventDefault();
  document.getElementById('leaf-upload-zone').classList.add('drag-over');
}
function handleLeafDragLeave(event){
  document.getElementById('leaf-upload-zone').classList.remove('drag-over');
}
function handleLeafDrop(event){
  event.preventDefault();
  document.getElementById('leaf-upload-zone').classList.remove('drag-over');
  const files = event.dataTransfer ? event.dataTransfer.files : null;
  if(files && files.length){
    for(let i=0;i<files.length;i++){ addMockLeaf(); }
  } else {
    addMockLeaf();
  }
}
