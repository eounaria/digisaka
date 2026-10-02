
(function(){
  function ensureGlobalSwitcher(){
    const headerRight=document.querySelector('.app-header-right');
    if(!headerRight || document.getElementById('global-usecase-wrap')) return;
    const wrap=document.createElement('div');
    wrap.id='global-usecase-wrap';
    wrap.className='global-usecase-wrap';
    wrap.innerHTML=`<span class="global-usecase-label">USE CASE</span>
      <select id="global-usecase-select" class="global-usecase-select" aria-label="Global Use Case">
        <option value="black-sigatoka">🍌 Black Sigatoka</option>
        <option value="rice">🌾 Rice</option>
        <option value="corn">🌽 Corn</option>
      </select>`;
    headerRight.insertBefore(wrap,headerRight.firstChild);
    const sel=wrap.querySelector('select');
    sel.value=currentUseCase;
    sel.addEventListener('change',()=>setGlobalUseCase(sel.value));
  }

  function setGlobalUseCase(id){
    if(!GLOBAL_USE_CASES[id]) return;
    currentUseCase=id;
    const wrap=document.getElementById('global-usecase-wrap');
    const select=document.getElementById('global-usecase-select');
    if(select) select.value=id;
    if(wrap){
      wrap.classList.add('switching');
      setTimeout(()=>wrap.classList.remove('switching'),450);
    }
    updateGlobalContextUI();
    updateUserContext();
    showContextNotice();
  }

  function showContextNotice(){
    let notice=document.getElementById('global-usecase-notice');
    if(!notice){
      notice=document.createElement('div');
      notice.id='global-usecase-notice';
      notice.className='global-usecase-context';
      document.querySelector('.app-header').appendChild(notice);
    }
    const c=GLOBAL_USE_CASES[currentUseCase];
    notice.textContent=`Use case switched to ${c.label}. All relevant modules now use this context.`;
    notice.classList.add('show');
    clearTimeout(window.__ucNoticeTimer);
    window.__ucNoticeTimer=setTimeout(()=>notice.classList.remove('show'),2600);
  }

  function updateGlobalContextUI(){
    const c=GLOBAL_USE_CASES[currentUseCase];
    document.querySelectorAll('[data-usecase-label]').forEach(el=>el.textContent=c.label);
    const selector=document.getElementById('global-usecase-select');
    if(selector) selector.value=currentUseCase;
    const dot=document.getElementById('header-leaf-dot');
    if(dot) dot.textContent=c.icon;
  }

  window.setUseCase=setGlobalUseCase;

  function updateUserContext(){
    const c=GLOBAL_USE_CASES[currentUseCase];
    const set=(id,text)=>{const el=document.getElementById(id);if(el)el.textContent=text;};
    set('hero-greeting-eyebrow','GOOD EVENING, JUAN');
    const hero=document.querySelector('#screen-home .home-hero-copy p');
    if(hero) hero.textContent=`Monitor ${c.crop.toLowerCase()} crop health and review ${c.disease} knowledge in the ${c.label} workspace.`;
    const scanSub=document.querySelector('#screen-scan .page-sub');
    if(scanSub) scanSub.textContent=`Scan or select ${c.crop.toLowerCase()} images to check for signs related to ${c.disease}.`;
    const upload=document.querySelector('#leaf-upload-zone h3');
    if(upload) upload.textContent=`Upload a ${c.crop.toLowerCase()} photo`;
    const validationSub=document.querySelector('#screen-validation .page-sub');
    if(validationSub) validationSub.textContent=`Is this a ${c.crop.toLowerCase()} leaf or crop image?`;
    const finalTitle=document.getElementById('final-assessment');
    if(finalTitle && currentUseCase!=='black-sigatoka') finalTitle.textContent=`Assessment: Possible ${c.disease}`;
    const conditionRows=document.querySelectorAll('#screen-final .review-row .val');
    if(conditionRows.length && currentUseCase!=='black-sigatoka') conditionRows[0].textContent=c.disease;
    const schedule=document.getElementById('schedule-stage-heading');
    if(schedule && currentUseCase!=='black-sigatoka') schedule.textContent=c.disease;
  }

  // Patch go so the global context is refreshed after navigation without changing routing.
  const originalGo=window.go;
  window.go=function(name){
    originalGo(name);
    updateGlobalContextUI();
  };

  ensureGlobalSwitcher();
  updateGlobalContextUI();
  updateUserContext();
})();
