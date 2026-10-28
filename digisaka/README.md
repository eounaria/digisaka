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

### Stop and restart
Run these from `digisaka/digisaka/`. The services are `api` (Express) and `web` (Vite).

```bash
docker compose ps                     # what is running
docker compose stop                   # stop both, keep containers and data
docker compose start                  # start them again
docker compose restart api            # after a server edit (Express routes, seed)
docker compose restart web            # after a change to client/vite.config.js (proxy targets such as KM_URL) or client/.env.local
docker compose up -d --build          # after a Dockerfile, package.json or docker-compose.yml change (including env such as KM_URL)
docker compose logs -f api web        # follow the logs
```

Without Docker (the retired local route), stop with Ctrl+C in each terminal and start again with
`npm run dev` (Express) and `npm run dev:client` (Vite).

Stop with `docker compose down`. `docker compose down -v` also wipes the database and the installed dependencies;
run it (then `up --build`) after changing a `package.json`, because the dependency volumes outlive the image.

Limits: dev server only (no production image), the backend is not containerized, and client edits hot reload but
server edits need `docker compose restart api`. Known limits: Document Extractions talks to the AI_NeSy Knowledge Maintenance API on port 8000 (the main API, through the `KM_URL` proxy), so that API and its workflow runner must be up; Tracing and Knowledge Graph are greyed out until the service can list workflows and facts, and the rest of the admin console (datasets, ontology, audit, users) still uses its own SQLite data; the admin Users screen lists local sample farmers, not AI_NeSy accounts. Without a running scheduler, the scan, history and schedule screens fail with a generic "Something went wrong" message (the dev proxy answers 502).

## Run it on the stub

The stub (`stub/`) is one Node server on port 9000 that stands in for Supabase sign-in, the scheduler and Knowledge Maintenance, so the whole app runs with no host services. It is standalone: its data is fixed in the repo and it needs nothing outside it.

Start the stack:

```bash
docker compose -f docker-compose.yml -f docker-compose.stub.yml up -d --build
```

Seed the sample farmers and demo knowledge (first run only):

```bash
docker compose run --rm api npm run seed
```

Restart the stub after editing it:

```bash
docker compose -f docker-compose.yml -f docker-compose.stub.yml restart stub
```

Stop the stack. Plain `docker compose stop` does not know the `stub` service, so pass both files:

```bash
docker compose -f docker-compose.yml -f docker-compose.stub.yml stop
```

Reset to the seed (workflows, scans, decisions):

```bash
curl -X POST 127.0.0.1:9000/__stub/reset
```

Use `127.0.0.1` for curl if a host Node process holds `[::]:3000`. To go back to the real backends:

```bash
docker compose up -d --build
```

After a proxy target change:

```bash
docker compose restart web
```

After a compose env change, run `up -d --build` again.

**Sign-in.** Any password works except `wrong` (which is refused).

| User | Roles | Lands on |
|---|---|---|
| `farmer@digisaka.test` | practitioner | the farmer app |
| `admin@digisaka.test` | administrator | `/admin` |
| `both@digisaka.test` | practitioner, domain_expert | the farmer app, with the admin console too |

**Scenarios are fixed data**, not switches:

- *Lines* (week 2026-W24): `L01` nothing recorded; `L02` an applied proposal; `L03` a proposal waiting for a decision; `L04` ready to scan (the default demo line, with a gap in last week's YLI reading); `L05` the rules could not decide, so human review with no evidence; `L06` closing its next week fails on the first try, then succeeds on retry.
- *Image names* decide the Scan answer: a name containing `healthy`, `not_leaf`, `referral`, `rescan` or `unavailable` gets that outcome; anything else is a stage 2 leaf. Closing a week takes a few seconds (the cycle runs on a timer).
- *Sample leaves*: the stub compose file sets `VITE_STUB_SAMPLES=1`, so the Scan screen fills an empty queue with two stage 2 leaves and one healthy leaf, shows a "Sample leaves" row with a button per scenario, and offers "Use sample" on a retake. No files need picking. The flag is unset on plain `docker compose up`, so the real-backend Scan screen is unchanged and the manual run against the real backend stays the acceptance gate. Changing it needs `docker compose up -d --build`.
- *Document titles* decide a Document Extractions path: containing `fail` ends in `failed` after a visible retry; `commit-fail` reaches `commit_failed`, and approving again retries it to `completed`; `slow` makes every state ten times longer; anything else is the happy path. Each workflow gets 30 facts, one of them claimed by a colleague. Extraction review shows only what extraction produced (the triple, excerpt, GraphJudge and restoration); the ontology check, correction, entity resolution and warnings appear from final approval on, as the pipeline produces them after extraction review. The facts are a mix that shows every block of the review panel across the two reviews (claiming takes it over; reviewing it without claiming is refused). A workflow moves to final approval once no fact is pending.

**It can drift.** The stub's shapes come from the client code and test fixtures, so a field the client never reads is a guess: the Knowledge Maintenance `workflow_type` value and 202 status codes, fact ids and `graphjudge_result` values, the shape of `retrying`, claim lifetimes (15 minutes), and the scheduler fields no store reads. The manual run against the real backends stays the acceptance gate.

Stub unit tests:

```bash
node --test "stub/*.test.js"
```

Client tests, including the contract tests in `client/src/stub-contract/` that drive the real Pinia stores against the in-process stub:

```bash
npm --prefix client test
```

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
| Overview | Image KPIs, ontology counts and latest activity. Entity, relationship and document figures are not available yet |
| Document Extractions | Submit a document to the Knowledge Maintenance workflow (port 8000), follow it, review extracted facts, approve the commit |
| Tracing | One document's activity log and its four pipeline steps (source → extraction → correction → knowledge graph) |
| History | Audit log of every admin change, searchable and filterable by action |
| Knowledge Graph | Confirmed relationships drawn as a graph, with entity/relationship counts and class distribution |
| Ontologies | Add, rename, recolour and delete classes and relationship types; the graph redraws from them |
| Datasets & Images | Nested folders, multi-image upload (PNG/JPEG/WebP/GIF, 8 MB each), search, validate, move (re-labels), delete |
| Users | Farmer list and CSV master-list import |

Tracing and Knowledge Graph are greyed out until the workflow service can list workflows and facts.

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
| GET | /admin/overview, /admin/audit | |
| GET/POST/PUT/DELETE | /admin/ontology/classes[/:id], /admin/ontology/relations[/:id] | |
| GET/POST/PUT/DELETE | /admin/datasets/folders[/:id], /admin/datasets/images[/:id], GET .../images/:id/file | image upload is a raw body with `?name=&folderId=` |
| GET, POST | /admin/users, /admin/users/import | |

## Toka AI Login Page Redesign (2026-10-29)

Complete visual redesign of the practitioner app login page (`/login` route) to match the Toka AI brand design specifications. The new design implements a pixel-accurate two-column desktop layout with a promotional left panel and centered login card on the right.

### Files Modified
| File | Purpose |
|------|---------|
| `client/src/views/LoginView.vue` | **Primary change** - Complete rewrite of the login page component with new two-column layout, Toka AI branding, gradient background, and responsive design |

### Layout Implementation

**Desktop (1440×948 reference):**
- Two-column CSS Grid layout: `39.31%` left panel / `60.69%` right panel
- Left panel: Full viewport height (`100vh` / `100dvh`), promotional content
- Right panel: Flexbox centered login card (max-width `483px`, padding `48px 72px`)
- No gap between panels, no unwanted margins or scrollbars at reference size

**Responsive Breakpoints:**
- **≥1440px**: Full reference design with proportional scaling
- **1024–1439px**: Two-column retained, card padding reduced
- **768–1023px**: Single column, left panel hidden, card centered with reduced padding
- **<768px**: Mobile-first single column, card full-width with comfortable margins
- **Height-based**: Promotional content hides at ≤800px, fully hidden at ≤700px

### Background Image and Gradient

**Image:** `blacksigatoka.png` (banana leaf with Black Sigatoka disease)
- Path: `../assets/blacksigatoka.png` (relative to LoginView.vue)
- `background-size: cover`, `background-position: center`

**Gradient Overlay (4 colors, 72% opacity, 180deg vertical):**
```css
linear-gradient(
  180deg,
  rgba(227, 255, 241, 0.72) 0%,    /* #E3FFF1 - mint green */
  rgba(27, 151, 90, 0.72) 33%,     /* #1B975A - emerald */
  rgba(5, 96, 52, 0.72) 66%,       /* #056034 - forest */
  rgba(18, 63, 41, 0.72) 100%      /* #123F29 - dark forest */
)
```
- Layered **over** the image (not behind it)
- Opacity applied per color stop, not to entire panel

### Logo and Branding

**Logo:** `bananaleaf1.png` (green banana leaf symbol)
- Path: `../assets/bananaleaf1.png`
- Container: `38×47px`, border `1px solid #007A48`, radius `2px`
- `object-fit: contain` preserves aspect ratio

**Brand Text:** "Toka AI"
- Font: Roboto 700, 24px, `#006D43`
- Gap: 10px from logo container

**Replaced:** All "DigiSaka" references → "Toka AI" on the login page

### Typography and Colors

| Element | Font | Size | Weight | Color |
|---------|------|------|--------|-------|
| Promo Heading | Roboto | 36px | 700 | `#8CFF91` |
| Promo Description | Roboto | 20px | 400 | `#F2F2F2` |
| Footer | Roboto | 16px | 400 | `#9AA5A4` |
| Login Heading | Roboto | 36px | 700 | `#1C1C1C` |
| Login Subtitle | Roboto | 18px | 400 | `#98A2B3` |
| Labels | Roboto | 16px | 400 | `#667085` |
| Inputs | Roboto | 14px | 400 | `#1C1C1C` |
| Placeholders | Roboto | 14px | 400 | `#98A2B3` |
| Remember Me | Roboto | 14px | 400 | `#111111` |
| Sign In Button | Roboto | 16px | 700 | `#FFFFFF` on `#006F47` |

**Input Styling:**
- Height: `45px` (desktop), `48px` (mobile)
- Border: `1px solid #1F2937`, radius `11px`
- Focus: `border-color: #006F47`
- Padding: `0 20px` (email), `0 52px 0 18px` (password for eye icon)

**Button Styling:**
- Height: `52px` (desktop), `48px` (mobile)
- Background: `#006F47`, hover `#005A3A`, active `#004D30`
- Radius: `10px`, no gradients/shadows
- Focus-visible: `3px solid #006F47` outline

**Checkbox:**
- `15×15px`, border `1px solid #111111`, radius `2px`
- Checked: background `#006F47`, white checkmark

### Form Functionality

**Preserved from original:**
- Supabase password grant authentication via `useAuthStore().signIn()`
- Route guard integration (`redirectFor`, `safeNext`, `landingFor`)
- Email/password validation (required fields, email type)
- Loading state (`busy` ref) with disabled inputs/button
- Error display via `error` ref
- `rememberMe` form field (added to form model)

**New implementations:**
- Password visibility toggle (eye icon, functional, accessible)
- ARIA attributes on toggle button (`aria-label`, `aria-pressed`)
- Keyboard support for checkbox (Space/Enter)
- Focus-visible states on all interactive elements
- Reduced motion support (`prefers-reduced-motion`)

### Responsive Design

**Breakpoints & Behavior:**
| Breakpoint | Left Panel | Right Panel | Card | Typography |
|------------|------------|-------------|------|------------|
| ≥1440px | Full promo | Centered 483px | 48px/72px | Reference sizes |
| 1024–1439px | Full promo | Centered | 40px/48px | Slightly reduced |
| 768–1023px | Hidden | Centered | 32px/24px | Heading 32px |
| <768px | Hidden | Full-width | 24px/20px | Heading 28px |

**Mobile Specific:**
- Input font-size `16px` prevents iOS zoom
- Touch targets ≥44px (button 48px, inputs 48px)
- Vertical scrolling enabled (`min-height: 100dvh`)
- Logo not shown on mobile (left panel hidden entirely)

**Height Adaptation:**
- `@media (max-height: 800px)`: Promo content repositions to bottom
- `@media (max-height: 700px)`: Promo content hidden, footer raised

### Verification Checklist

- [x] Two-column layout at 1440×948 matches reference proportions
- [x] Gradient uses exact 4 colors at 72% opacity over photograph
- [x] Logo uses `bananaleaf1.png` with correct border/radius
- [x] All text uses Roboto font family
- [x] Branding reads "Toka AI" (no "DigiSaka" on login page)
- [x] Login card centered in right panel with correct dimensions
- [x] Form measurements match reference (339px input width, 45px height, etc.)
- [x] Password visibility toggle works (eye open/closed icons)
- [x] Remember me checkbox functional with custom styling
- [x] Sign In button submits form, integrates with auth store
- [x] Existing authentication flow preserved (Supabase, route guards)
- [x] Responsive at 320px, 768px, 1024px, 1440px, 1920px
- [x] No horizontal overflow at any breakpoint
- [x] Vertical scrolling works on short screens
- [x] Images load from correct relative paths
- [x] Accessibility: labels, ARIA, focus-visible, reduced motion

### Build Status
- ✅ `npm run build` succeeds (1.20s)
- ✅ Assets processed correctly (`blacksigatoka-D1L-Y0yq.png` in dist)
- ✅ No TypeScript/ESLint errors
