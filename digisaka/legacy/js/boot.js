/* Connects the legacy screens to the backend and, when embedded, to the Vue shell. */
(async function boot() {
  let user;
  try { ({ user } = await api.get('/api/auth/me')); }
  catch { location.href = '/login'; return; }
  window.DS_USER = user;
  window.DS_FIRST_NAME = user.name.split(/\s+/)[0].toUpperCase();

  const setText = (sel, text) => { const el = document.querySelector(sel); if (el) el.textContent = text; };
  setText('#header-avatar-btn', user.initials);
  setText('#screen-profile .avatar', user.initials);
  setText('#screen-profile .pname', user.name);
  if (user.location) setText('#screen-profile .pfarm', user.location);

  window.updateDashboardOverview = async function () {
    try {
      const d = await api.get('/api/dashboard');
      document.getElementById('dash-leaves').textContent = d.leavesScanned;
      document.getElementById('dash-bulks').textContent = d.bulksAssessed;
      document.getElementById('dash-treatment').textContent = d.leavesNeedingTreatment;
    } catch { /* keep the last shown values */ }
  };

  const captureLocal = window.captureCurrentBulkAssessment;
  window.captureCurrentBulkAssessment = function () {
    captureLocal();
    const snap = recentBulkAssessments.find((b) => b.bulkId === currentBulkId);
    if (!snap) return;
    api.put('/api/bulks/' + encodeURIComponent(snap.bulkId), snap).then(() => updateDashboardOverview()).catch((e) => console.error('Could not save bulk', e));
  };

  // The prototype only kept confirmed schedules in memory, so nothing reached the Vue Treatment Schedule
  // screens. Save each confirmation to the server (bulk first, since a schedule needs its bulk).
  const recordLocal = window.recordConfirmedBulkSchedule;
  window.recordConfirmedBulkSchedule = function () {
    recordLocal();
    const entry = confirmedBulks.find((b) => b.bulkId === currentBulkId);
    if (!entry) return;
    const snap = recentBulkAssessments.find((b) => b.bulkId === currentBulkId);
    const code = encodeURIComponent(entry.bulkId);
    window.__scheduleSaving = (snap ? api.put('/api/bulks/' + code, snap) : Promise.resolve())
      .then(() => api.put('/api/schedules/' + code, { groups: entry.groups }))
      .then(async () => {
        confirmedBulks = (await api.get('/api/schedules')).schedules;   // pick up server-side labels
        parent.postMessage({ type: 'schedule-saved' }, location.origin);
      });
    window.__scheduleSaving.catch((e) => console.error('Could not save treatment schedule', e));
  };

  try {
    const { bulks } = await api.get('/api/bulks?limit=8');
    recentBulkAssessments = bulks;
    const highest = bulks.map((b) => Number((b.bulkId.match(/(\d+)$/) || [])[1]) || 0).reduce((a, b) => Math.max(a, b), 0);
    bulkSessionCounter = Math.max(bulkSessionCounter, highest);
  } catch (e) { console.error(e); }
  updateDashboardOverview();

  // Was only ever populated live from the in-session scan flow; load it so the schedule list and
  // calendar work correctly on a fresh page load too, and so deep links from the Vue shell can match.
  try { confirmedBulks = (await api.get('/api/schedules')).schedules; } catch (e) { console.error(e); }

  const q = new URLSearchParams(location.search);

  // Deep link from the Vue bulk-stages list: open the calendar already set to the right bulk/stage.
  // The calendar itself still shows the prototype's fixed demo dates regardless of which stage this is.
  if (q.get('bulk')) {
    const idx = confirmedBulks.findIndex((b) => b.bulkId === q.get('bulk'));
    if (idx !== -1) {
      selectedBulkIndex = idx;
      const stageNum = Number(q.get('stage'));
      const g = confirmedBulks[idx].groups.find((gr) => gr.stage === stageNum) || confirmedBulks[idx].groups[0];
      if (g) { currentStage = g.stage; renderStage(); renderTreatmentSchedule(); }
    }
  }

  /* Embedded inside the Vue shell: drop the legacy chrome and hand top-level navigation to the shell. */
  if (q.get('embed')) {
    const st = document.createElement('style');
    st.textContent = '.sidebar,.app-header{display:none!important}body{background:transparent!important}.app-content{padding-bottom:0!important}';
    document.head.appendChild(st);
    const own = q.get('screen');
    const SHELL = ['home', 'profile', 'notifications'];
    const TOP = ['scan', 'history', 'scheduled-treatments'];
    const goInner = window.go;
    window.go = function (name) {
      if (SHELL.includes(name) || (TOP.includes(name) && name !== own)) parent.postMessage({ type: 'go', screen: name }, location.origin);
      else goInner(name);
    };
    // Tapping a stage card on "Schedule Confirmed" opens that stage in the shell's Treatment Schedule
    // (real saved data, persistent checkboxes) instead of the prototype's fixed demo screen.
    window.goToScheduleFromConfirmation = async function (_bulkIndex, groupIndex) {
      const g = bulkTreatmentGroups[groupIndex];
      if (!g) return;
      try { await window.__scheduleSaving; }
      catch { alert('The treatment schedule could not be saved. Please check your connection and confirm it again.'); return; }
      parent.postMessage({ type: 'open-schedule', bulkId: currentBulkId, stage: g.stage }, location.origin);
    };
    addEventListener('message', (e) => {
      if (e.origin !== location.origin || e.data?.type !== 'useCase') return;
      const sel = document.getElementById('global-usecase-select');
      if (sel && sel.value !== e.data.slug) { sel.value = e.data.slug; sel.dispatchEvent(new Event('change')); }
    });
    goInner(own || 'home');
  } else if (q.get('screen')) go(q.get('screen'));
})();
