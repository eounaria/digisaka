
/* ===== Admin Web (design from file 1) ===== */
(function(){

      const useCaseSelect = document.getElementById('adm-useCaseSelect');
      const usecaseBanner = document.getElementById('adm-usecaseBanner');
      const ontologyUseCaseLabel = document.getElementById('adm-ontologyUseCaseLabel');
      const folderTree = document.getElementById('adm-folderTree');
      const assetGrid = document.getElementById('adm-assetGrid');
      const activeFolderLabel = document.getElementById('adm-activeFolderLabel');
      const imgCount = document.getElementById('adm-imgCount');
      const labeledCount = document.getElementById('adm-labeledCount');
      const statusCount = document.getElementById('adm-statusCount');
      const folderCount = document.getElementById('adm-folderCount');
      const processingUploadBtn = document.getElementById('adm-processingUploadBtn');
      const processingUploadInput = document.getElementById('adm-processingUploadInput');

      if (processingUploadBtn && processingUploadInput) {
        processingUploadBtn.addEventListener('click', () => processingUploadInput.click());
        processingUploadInput.addEventListener('change', () => {
          const file = processingUploadInput.files[0];
          if (!file) return;
          processingUploadBtn.lastChild.textContent = ` ${file.name}`;
          processingUploadBtn.title = `Selected: ${file.name}`;
        });
      }

      const treeData = {
        'Black Sigatoka': [
          { name: 'Healthy', count: 42 },
          { name: 'Early Stage', count: 62 },
          { name: 'Moderate Stage', count: 81 },
          { name: 'Advanced Stage', count: 63 }
        ],
        'Rice': [
          { name: 'Healthy', count: 39 },
          { name: 'Early Stage', count: 58 },
          { name: 'Moderate Stage', count: 76 },
          { name: 'Advanced Stage', count: 53 }
        ],
        'Corn': [
          { name: 'Healthy', count: 45 },
          { name: 'Early Stage', count: 48 },
          { name: 'Moderate Stage', count: 67 },
          { name: 'Advanced Stage', count: 61 }
        ]
      };

      const assetMap = {
        'Black Sigatoka': [
          ['Healthy leaf #01', 'Healthy', '2.1k labels'],
          ['Early lesion A5', 'Early Stage', '1.7k labels'],
          ['Moderate patch B8', 'Moderate Stage', '2.3k labels'],
          ['Advanced blight Z2', 'Advanced Stage', '1.4k labels'],
          ['Field scan 204', 'Healthy', '1.8k labels'],
          ['Canopy stage 6', 'Early Stage', '1.5k labels'],
          ['Deterioration T9', 'Moderate Stage', '2.0k labels'],
          ['Late wilt group', 'Advanced Stage', '1.2k labels']
        ],
        'Rice': [
          ['Rice leaf 110', 'Healthy', '1.9k labels'],
          ['Rice yellowing 4', 'Early Stage', '1.6k labels'],
          ['Stress pattern C2', 'Moderate Stage', '2.2k labels'],
          ['Late rice stress', 'Advanced Stage', '1.3k labels'],
          ['Field image 09', 'Healthy', '1.7k labels'],
          ['Growth phase 3', 'Early Stage', '1.8k labels'],
          ['Severe blight D1', 'Moderate Stage', '2.4k labels'],
          ['Chlorosis cluster', 'Advanced Stage', '1.1k labels']
        ],
        'Corn': [
          ['Corn canopy 01', 'Healthy', '2.0k labels'],
          ['Silk lesion A2', 'Early Stage', '1.5k labels'],
          ['Rust zone B6', 'Moderate Stage', '2.1k labels'],
          ['Advanced stress C9', 'Advanced Stage', '1.6k labels'],
          ['Leaf edge panel', 'Healthy', '1.9k labels'],
          ['Emerging symptom', 'Early Stage', '1.7k labels'],
          ['Severe foliar strip', 'Moderate Stage', '2.0k labels'],
          ['Late corn stress', 'Advanced Stage', '1.4k labels']
        ]
      };

      function renderFolderTree() {
        const selected = useCaseSelect.value;
        const folders = treeData[selected];
        folderTree.innerHTML = `
          <div class="adm-tree-node adm-active">
            <span>${selected}</span>
            <span class="adm-count">${folders.reduce((sum, item) => sum + item.count, 0)}</span>
          </div>
          <div class="adm-tree-sub">
            ${folders.map((folder) => `
              <div class="adm-tree-node" data-folder="${folder.name}">
                <span>${folder.name}</span>
                <span class="adm-count">${folder.count}</span>
              </div>
            `).join('')}
          </div>
        `;

        const nodes = folderTree.querySelectorAll('.adm-tree-node[data-folder]');
        nodes.forEach((node) => {
          node.addEventListener('click', () => {
            nodes.forEach((n) => n.classList.remove('adm-active'));
            node.classList.add('adm-active');
            activeFolderLabel.textContent = `${selected} / ${node.dataset.folder}`;
            const folderAsset = assetMap[selected];
            const items = folderAsset.filter((item) => item[1] === node.dataset.folder);
            renderAssets(items.length ? items : folderAsset.slice(0, 8));
          });
        });

        if (nodes[0]) {
          nodes[0].click();
        }
      }

      function renderAssets(items) {
        const selected = useCaseSelect.value;
        const total = items.length;
        imgCount.textContent = total * 28;
        labeledCount.textContent = Math.round(total * 22);
        statusCount.textContent = `${Math.max(72, 81 + total)}%`;
        folderCount.textContent = `${treeData[selected].length + 4}`;

        assetGrid.innerHTML = items.map(([name, label, meta], index) => `
          <div class="adm-asset-card">
            <div class="adm-thumb">🧬</div>
            <div class="adm-asset-name">${name}</div>
            <div class="adm-asset-meta">${label} • ${meta}</div>
            <div class="adm-asset-actions">
              <button class="adm-mini-btn">View</button>
              <button class="adm-mini-btn">Move</button>
            </div>
          </div>
        `).join('');
      }

      useCaseSelect.addEventListener('change', () => {
        const selected = useCaseSelect.value;
        usecaseBanner.textContent = `Active use case: ${selected}`;
        const overviewUseCase = document.getElementById('adm-overviewUseCase');
        const scopeDescription = document.getElementById('adm-scopeDescription');
        if (overviewUseCase) overviewUseCase.textContent = selected;
        if (scopeDescription) scopeDescription.textContent = `${selected} knowledge operations are within expected health thresholds.`;
        if (ontologyUseCaseLabel) ontologyUseCaseLabel.textContent = selected;
        buildOntologyGraph(selected);
        buildKnowledgeGraph(selected);
        renderFolderTree();
      });

      document.querySelectorAll('.adm-nav-item').forEach((button) => {
        button.addEventListener('click', () => {
          document.querySelectorAll('.adm-nav-item').forEach((item) => item.classList.remove('adm-active'));
          button.classList.add('adm-active');
          document.querySelectorAll('.adm-screen').forEach((item) => item.classList.remove('adm-active'));
          const target = button.dataset.screen;
          const targetScreen = document.getElementById(`adm-screen-${target}`);
          if (targetScreen) targetScreen.classList.add('adm-active');
        });
      });

      document.querySelectorAll('.adm-tab').forEach((tab) => {
        tab.addEventListener('click', () => {
          document.querySelectorAll('.adm-tab').forEach((t) => t.classList.remove('adm-active'));
          tab.classList.add('adm-active');
        });
      });

      function buildNetwork(elId, nodeCount = 42, scale = 1) {
        const el = document.getElementById(elId);
        if (!el) return;
        const nodes = [];
        for (let i = 0; i < nodeCount; i++) {
          const angle = (i / nodeCount) * Math.PI * 2;
          const radius = 60 + Math.random() * 170;
          const x = 50 + Math.cos(angle) * radius * 0.55 * scale + (Math.random() * 12 - 6);
          const y = 50 + Math.sin(angle) * radius * 0.42 * scale + (Math.random() * 12 - 6);
          nodes.push({ x, y, s: 10 + Math.random() * 18 });
        }

        const edges = [];
        for (let i = 0; i < nodes.length; i++) {
          for (let j = i + 1; j < nodes.length; j++) {
            if (Math.random() < 0.06) {
              edges.push([nodes[i], nodes[j]]);
            }
          }
        }

        const edgeHtml = edges.map(([a, b]) => {
          const dx = b.x - a.x;
          const dy = b.y - a.y;
          const length = Math.hypot(dx, dy);
          const angle = Math.atan2(dy, dx) * 180 / Math.PI;
          const left = a.x;
          const top = a.y;
          return `<div class="adm-edge" style="left:${left}%; top:${top}%; width:${length}%; transform: rotate(${angle}deg);"></div>`;
        }).join('');

        const nodeHtml = nodes.map((node, idx) => `
          <div class="adm-node" style="left:${node.x}%; top:${node.y}%; width:${node.s}px; height:${node.s}px;"></div>
        `).join('');
        el.innerHTML = edgeHtml + nodeHtml;
      }

      function buildOntologyGraph(useCase) {
        const el = document.getElementById('adm-ontologyNetwork');
        if (!el) return;

        const graphData = {
          'Black Sigatoka': {
            disease: 'Black Sigatoka',
            crop: 'Banana',
            symptom: 'Leaf streak',
            pathogen: 'Pseudocercospora',
            stage: 'Advanced stage',
            environment: 'High humidity',
            treatment: 'Fungicide plan'
          },
          Rice: {
            disease: 'Rice blast',
            crop: 'Rice',
            symptom: 'Leaf lesion',
            pathogen: 'Magnaporthe',
            stage: 'Early stage',
            environment: 'Wet season',
            treatment: 'Field treatment'
          },
          Corn: {
            disease: 'Corn rust',
            crop: 'Corn',
            symptom: 'Rust spots',
            pathogen: 'Puccinia',
            stage: 'Moderate stage',
            environment: 'Warm weather',
            treatment: 'Crop protection'
          }
        }[useCase];

        const nodes = [
          { id: 'crop', x: 106, y: 88, r: 47, color: '#2e3192', label: graphData.crop, caption: 'Crop' },
          { id: 'disease', x: 394, y: 88, r: 51, color: '#ef6a16', label: graphData.disease, caption: 'Disease' },
          { id: 'pathogen', x: 670, y: 88, r: 48, color: '#48d20d', label: graphData.pathogen, caption: 'Pathogen' },
          { id: 'symptom', x: 176, y: 270, r: 49, color: '#d51bd8', label: graphData.symptom, caption: 'Symptom' },
          { id: 'stage', x: 470, y: 270, r: 53, color: '#8520e1', label: graphData.stage, caption: 'Disease Stage' },
          { id: 'environment', x: 716, y: 260, r: 46, color: '#293394', label: graphData.environment, caption: 'Environment' },
          { id: 'treatment', x: 365, y: 350, r: 45, color: '#e9c318', label: graphData.treatment, caption: 'Treatment' }
        ];
        const byId = Object.fromEntries(nodes.map((node) => [node.id, node]));
        const relations = [
          ['crop', 'disease', 'affected by'],
          ['disease', 'pathogen', 'caused by'],
          ['disease', 'symptom', 'shows'],
          ['symptom', 'stage', 'indicates'],
          ['stage', 'environment', 'influenced by'],
          ['disease', 'treatment', 'managed with'],
          ['treatment', 'crop', 'protects'],
          ['crop', 'symptom', 'observed in']
        ];

        const line = (fromId, toId, label) => {
          const from = byId[fromId];
          const to = byId[toId];
          const dx = to.x - from.x;
          const dy = to.y - from.y;
          const distance = Math.hypot(dx, dy);
          const ux = dx / distance;
          const uy = dy / distance;
          const x1 = from.x + ux * from.r;
          const y1 = from.y + uy * from.r;
          const x2 = to.x - ux * to.r;
          const y2 = to.y - uy * to.r;
          const mx = (x1 + x2) / 2;
          const my = (y1 + y2) / 2 - 8;
          return `<line class="adm-relation" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}"></line><text class="adm-relation-label" x="${mx}" y="${my}">${label}</text>`;
        };

        const nodeMarkup = nodes.map((node) => `
          <g>
            <circle class="adm-graph-node" cx="${node.x}" cy="${node.y}" r="${node.r}" fill="${node.color}"></circle>
            <text class="adm-graph-node-label" x="${node.x}" y="${node.y - 3}">${node.label}</text>
            <text class="adm-graph-caption" x="${node.x}" y="${node.y + node.r + 16}">${node.caption}</text>
          </g>
        `).join('');

        el.innerHTML = `
          <svg class="adm-ontology-graph-svg" viewBox="0 0 800 420" role="img" aria-label="${useCase} ontology relationship graph">
            <defs>
              <marker id="ontologyArrow" markerWidth="9" markerHeight="9" refX="8" refY="4.5" orient="auto">
                <path d="M0,0 L9,4.5 L0,9 z" fill="#9ea7ff"></path>
              </marker>
            </defs>
            ${relations.map(([from, to, label]) => line(from, to, label)).join('')}
            ${nodeMarkup}
          </svg>
        `;
      }

      function buildKnowledgeGraph(useCase) {
        const el = document.getElementById('adm-network');
        if (!el) return;
        const graphData = {
          'Black Sigatoka': {
            disease: 'Black Sigatoka', crop: 'Banana', symptom: 'Leaf streak',
            pathogen: 'Pseudocercospora', region: 'Davao', stage: 'Advanced stage',
            treatment: 'Fungicide plan', source: 'Field report'
          },
          Rice: {
            disease: 'Rice blast', crop: 'Rice', symptom: 'Leaf lesion',
            pathogen: 'Magnaporthe', region: 'Nueva Ecija', stage: 'Early stage',
            treatment: 'Field treatment', source: 'Survey report'
          },
          Corn: {
            disease: 'Corn rust', crop: 'Corn', symptom: 'Rust spots',
            pathogen: 'Puccinia', region: 'Bukidnon', stage: 'Moderate stage',
            treatment: 'Crop protection', source: 'Farm log'
          }
        }[useCase];

        const scopeLabel = document.getElementById('adm-kgScopeLabel');
        if (scopeLabel) scopeLabel.textContent = `${useCase} graph`;
        const classLabels = [
          `${graphData.symptom} 42%`, `${graphData.region} 21%`,
          `${graphData.pathogen} 19%`, `${graphData.crop} 18%`
        ];
        ['adm-kgClassOne', 'adm-kgClassTwo', 'adm-kgClassThree', 'adm-kgClassFour'].forEach((id, index) => {
          const item = document.getElementById(id);
          if (item) item.textContent = classLabels[index];
        });

        const nodes = [
          { id: 'source', x: 86, y: 88, r: 40, color: '#2b378f', label: graphData.source, caption: 'Source' },
          { id: 'crop', x: 245, y: 88, r: 44, color: '#3948d1', label: graphData.crop, caption: 'Crop' },
          { id: 'disease', x: 430, y: 88, r: 52, color: '#e86d19', label: graphData.disease, caption: 'Disease' },
          { id: 'pathogen', x: 645, y: 88, r: 47, color: '#37bd25', label: graphData.pathogen, caption: 'Pathogen' },
          { id: 'symptom', x: 160, y: 270, r: 49, color: '#d725c9', label: graphData.symptom, caption: 'Symptom' },
          { id: 'stage', x: 395, y: 270, r: 50, color: '#7e29db', label: graphData.stage, caption: 'Disease Stage' },
          { id: 'region', x: 650, y: 270, r: 44, color: '#26388e', label: graphData.region, caption: 'Region' },
          { id: 'treatment', x: 510, y: 400, r: 45, color: '#e7c21b', label: graphData.treatment, caption: 'Treatment' }
        ];
        const byId = Object.fromEntries(nodes.map((node) => [node.id, node]));
        const relations = [
          ['source', 'crop', 'describes'],
          ['crop', 'disease', 'affected by'],
          ['disease', 'pathogen', 'caused by'],
          ['disease', 'symptom', 'shows'],
          ['symptom', 'stage', 'indicates'],
          ['disease', 'region', 'observed in'],
          ['disease', 'treatment', 'managed with'],
          ['treatment', 'crop', 'protects']
        ];
        const line = (fromId, toId, label) => {
          const from = byId[fromId];
          const to = byId[toId];
          const dx = to.x - from.x;
          const dy = to.y - from.y;
          const distance = Math.hypot(dx, dy);
          const ux = dx / distance;
          const uy = dy / distance;
          const x1 = from.x + ux * from.r;
          const y1 = from.y + uy * from.r;
          const x2 = to.x - ux * to.r;
          const y2 = to.y - uy * to.r;
          return `<line class="adm-relation" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}"></line><text class="adm-relation-label" x="${(x1 + x2) / 2}" y="${(y1 + y2) / 2 - 8}">${label}</text>`;
        };
        const nodeMarkup = nodes.map((node) => `
          <g>
            <circle class="adm-graph-node" cx="${node.x}" cy="${node.y}" r="${node.r}" fill="${node.color}"></circle>
            <text class="adm-graph-node-label" x="${node.x}" y="${node.y - 3}">${node.label}</text>
            <text class="adm-graph-caption" x="${node.x}" y="${node.y + node.r + 16}">${node.caption}</text>
          </g>
        `).join('');
        el.innerHTML = `
          <svg class="adm-ontology-graph-svg adm-kg-graph-svg" viewBox="0 0 760 470" role="img" aria-label="${useCase} knowledge graph">
            <defs>
              <marker id="ontologyArrow" markerWidth="9" markerHeight="9" refX="8" refY="4.5" orient="auto">
                <path d="M0,0 L9,4.5 L0,9 z" fill="#9ea7ff"></path>
              </marker>
            </defs>
            ${relations.map(([from, to, label]) => line(from, to, label)).join('')}
            ${nodeMarkup}
          </svg>
        `;
      }

      buildKnowledgeGraph(useCaseSelect.value);
      buildOntologyGraph(useCaseSelect.value);
      renderFolderTree();
    
})();
