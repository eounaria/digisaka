# Digisaka AI

Black Sigatoka detection for banana farms, plus an admin knowledge console.
Vue 3 frontend, Express + SQLite backend.

## Run it (retired Express shell)
> Describes the earlier Express-cookie shell with demo logins that no longer exist. Do not follow it; use "Run it in Docker" below.

```bash
npm install
npm run build     # installs and builds the Vue app into client/dist
npm run seed      # sample farmers and demo knowledge (no accounts)
npm start         # http://localhost:3000
```

**Developing the frontend** (hot reload): run `npm run dev` in one terminal and `npm run dev:client`
in another, then open http://localhost:5173. Vite forwards `/api` and `/legacy` to the server.

`npm test` runs the API tests. Copy `.env.example` to `.env` to configure; `JWT_SECRET` is required in production.

## Run it in Docker
Runs the web app (Express API and Vite dev server) in containers. Needs Docker Desktop only; no local Node.
The AI_NeSy backend stays on the host. The Claude proxy and the MLX embedder need your Claude login and Apple
silicon, and QA needs local CV checkpoints, so they are not containerized.

1. **Start the backend on the host.** Follow "Start order" in `AI_NeSy_Framework/scripts/scheduler_acceptance/RUNBOOK.md`
   (Claude proxy, MLX embedder, QA on 8000, scheduler on 8001). The scheduler on `127.0.0.1:8001` is what the web
   container calls, through `host.docker.internal`; no backend change is needed.
2. **Create the env file** (gitignored). One file feeds both the `api` service (token check) and the client (sign-in):
   ```bash
   cp client/.env.example client/.env.local   # set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY
   ```
   Optionally `cp .env.example .env` for other settings.
3. **Start the web stack and seed it:**
   ```bash
   docker compose up -d --build
   docker compose run --rm api npm run seed     # first run only; seeds sample farmers and demo knowledge, no accounts
   ```
4. **Open http://localhost:5173** and sign in with an AI_NeSy Supabase account. There are no Digisaka-only logins.

   | Account | Credentials (variable names in `AI_NeSy_Framework/.env.dev`) | Gets |
   |---|---|---|
   | Practitioner | `SUPABASE_TEST_PRACTITIONER_*` | Scan, History, Schedule and Treatment screens |
   | Technical User | `SUPABASE_TEST_TECHNICAL_USER_*` | The same screens, plus the admin console |

   The browser sends the Supabase token to the Express admin API, which asks Supabase who it belongs to and admits only
   Technical User roles (Administrator, Domain Expert, Plant Pathologist). A Technical User is recorded in the local
   `users` table on their first admin request.

Stop with `docker compose down`. `docker compose down -v` also wipes the database and the installed dependencies;
run it (then `up --build`) after changing a `package.json`, because the dependency volumes outlive the image.

Limits: dev server only (no production image), the backend is not containerized, and client edits hot reload but
server edits need `docker compose restart api`. Known limits: knowledge maintenance (the admin console) is not integrated with AI_NeSy and still uses its own SQLite data; the admin Users screen lists local sample farmers, not AI_NeSy accounts. Without a running scheduler, the scan, history and schedule screens fail with a generic "Something went wrong" message (the dev proxy answers 502).

## Layout
```
client/                 Vue 3 + Vite + Vue Router + Pinia
  src/router.js          routes and the auth/admin guards
  src/stores/             auth, farm (lines), scan, cycle, lines, proposal, useCase (admin)
  src/components/         AppLayout (sidebar, header, phone tab bar), Icon, PageHeader
  src/views/              Login, Scan, History, ScheduleList, ScheduleLine, TreatmentDetail
  src/admin/              admin console: layout + the nine admin screens, Modal, Pill, GraphCanvas, util.js
  src/styles/             tokens.css (design tokens) + base.css; every component styles itself
                          (admin.css holds the shared `a-` building blocks for the admin screens)
legacy/                  the original prototype code, served at /legacy for screens not yet ported
server/                  Express API: auth, dashboard, bulks, use-case preferences, admin (routes/admin*.js)
  extract.js              rule-based relationship extractor (swap in an LLM here)
  ontology-defaults.js    starting classes/relations/folders created for every use case
```

## What's built
- **Backend:** SQLite-backed auth (register/login/logout, JWT cookie session), a dashboard endpoint
  (leaves scanned, bulks assessed, leaves needing treatment), bulk assessment storage, and per-user
  use-case preference (Black Sigatoka / Rice / Corn).
- **Frontend:** sign in / register, the app shell (sidebar, header, phone tab bar, use-case switcher,
  notification bell), the dashboard, Diagnosis History, the full Treatment Schedule flow (list →
  bulk's stages → a stage's real treatment-step detail with a live status workflow and a calendar),
  Notifications, and the whole admin console (see below) — all in Vue with their own styling, no
  dependency on the prototype's CSS.
- **Still on the prototype code:** the scan → assess → schedule flow and settings detail, shown inside
  the Vue shell through `LegacyFrame` with the same login session and API. It talks to the shell over
  `postMessage` (see the embed block in `legacy/js/boot.js`). The prototype's old admin overlay (markup,
  `admin.js`, `adm-` CSS, role switch) has been removed from `legacy/`; only the scan flow still uses it.

**Connecting to the API (auth, every endpoint, request and response shapes, curl examples): see [API.md](API.md).**

## Admin console
Every screen is scoped to the use case chosen in the header and is backed by real tables. The
prototype's versions were hardcoded demos (fixed counts, random graph positions), so these were
rebuilt rather than ported.

| Screen | What it does |
|---|---|
| Overview | Live KPIs, pipeline progress bars and latest activity computed from the data below |
| KG Processing | Relationships move **extracted → corrected → confirmed** (or rejected). Edit, confirm, reject, restore, add by hand, confirm all; a temporary graph shows what is pending |
| Document Extractions | Upload text documents, extract, re-extract, edit metadata, delete; status follows what happens to the document's relationships |
| Tracing | One document's activity log and its four pipeline steps (source → extraction → correction → knowledge graph) |
| History | Audit log of every admin change, searchable and filterable by action |
| Knowledge Graph | Confirmed relationships drawn as a graph, with entity/relationship counts and class distribution |
| Ontologies | Add, rename, recolour and delete classes and relationship types; the graph redraws from them |
| Datasets & Images | Nested folders, multi-image upload (PNG/JPEG/WebP/GIF, 8 MB each), search, validate, move (re-labels), delete |
| Users | Farmer list and CSV master-list import |

**Extraction is rule-based, not AI.** `server/extract.js` reads structured triples (JSON, CSV with
`subject,predicate,object` columns, `A | relation | B` lines) and plain sentences that use one of the
ontology's relationship labels ("Black Sigatoka is caused by Pseudocercospora fijiensis."). Sentence
matches get ~0.76–0.9 confidence and anything under 0.8 is flagged "Needs correction". It only reads
text files (.txt, .md, .csv, .json) — PDF and Word extraction is not implemented. To use a language model,
replace `extractTriples()` and keep its return shape.

**Image safety.** Uploads are checked by their bytes, not the header (SVG is refused), stored under
`data/uploads` (set `UPLOAD_DIR` to move it) with random names, and served only to signed-in admins.

**Not built:** per-admin permissions beyond the admin role, image annotation/bounding boxes, and
real-time sync between admins (reload to see another admin's changes).

**Treatment Schedule detail, rebuilt from real data, not ported.** The original prototype's calendar
screen (`screen-treatment`) displayed a single hardcoded demo (fixed August dates, one shared
oil/fungicide/monitor checklist) that never read from actual bulk data, even before this work — so
porting its markup as-is wasn't an option. Its underlying data *was* real, though: confirming a
schedule generates three genuine steps per stage (Treatment, Follow-up, Re-assessment) with computed
dates, stored in `treatment_groups`. `TreatmentDetailView.vue` is a new view built directly on that
real data: a status workflow per step (Suggested → Confirmed → Applied, with Unknown / Follow-up
Required as side states) that saves to `/api/schedules/:code`, and a small calendar that highlights
each step's actual date and recolors by its live status. Not carried over from the original: the
FRAC-rotation warning, the post-cycle outcome modal, and the required-photo-proof upload — those were
decorative flourishes not tied to real data either; revisit if the product still wants them.

**History → bulk:** "View Bulk" opens `/schedule/:bulkId` (that bulk's stages) when the bulk has a confirmed\
treatment schedule; bulks without one show "No schedule yet" and aren't clickable.\

**Bug fixed in an earlier pass:** embedding a legacy screen (`?embed=1&screen=...`) computed which
screen to show but never actually activated it, so every embedded screen — Disease Detection included
— was silently displaying the dashboard underneath. Fixed in `legacy/js/boot.js`, which also now
loads `confirmedBulks` from `/api/schedules` on boot (it was previously only populated live during an
in-session scan, so it was empty on every page reload).

## Porting a screen next
Build the Vue view, point its route at it in `router.js` in place of `LegacyFrame`, and delete the
matching legacy screen once nothing else depends on it. When the last one is ported, `legacy/` (and
its old CSS) can be deleted entirely.

## API (retired shell; only /api/health and /api/admin are mounted, /api/admin takes a Supabase bearer token and also serves GET /admin/use-cases)
| Method | Path | Notes |
|---|---|---|
| POST | /auth/register, /auth/login, /auth/logout | |
| GET | /auth/me | current user |
| GET | /me/use-cases | crop/disease workspaces |
| PUT | /me/preferences | remember the selected use case |
| GET | /dashboard | leaves scanned, bulks assessed, leaves needing treatment |
| GET | /bulks?limit= | recent bulks |
| PUT | /bulks/:code | creates or replaces a bulk and its leaves |
| GET/POST/PUT/DELETE | /admin/documents[/:id], POST /admin/documents/:id/extract, GET /admin/documents/:id/trace | admin only; all `/admin` routes need `?useCase=` |
| GET/POST/PUT, POST | /admin/triples[/:id], /admin/triples/:id/{confirm,reject,restore,unconfirm}, /admin/triples/confirm-pending | relationship workflow |
| GET | /admin/graph?scope=confirmed\|pending, /admin/overview, /admin/audit | |
| GET/POST/PUT/DELETE | /admin/ontology/classes[/:id], /admin/ontology/relations[/:id] | |
| GET/POST/PUT/DELETE | /admin/datasets/folders[/:id], /admin/datasets/images[/:id], GET .../images/:id/file | image upload is a raw body with `?name=&folderId=` |
| GET, POST | /admin/users, /admin/users/import | |
