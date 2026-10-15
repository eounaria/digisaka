# Digisaka API

How to connect to the Digisaka server and every endpoint it exposes. Everything lives under `/api` and speaks JSON, except image upload (raw bytes) and image download.

- [Connecting](#connecting)
- [Where it connects](#where-it-connects)
- [Conventions](#conventions)
- [Auth](#auth) · [Farmer endpoints](#farmer-endpoints) · [Admin endpoints](#admin-endpoints)
- [Quick start with curl](#quick-start-with-curl)
- [Limits and security notes](#limits-and-security-notes)

---

## Connecting

| | |
|---|---|
| Base URL (production) | the server that serves the built client, e.g. `https://your-host` — API at `/api` |
| Base URL (local) | `http://localhost:3000/api` (`PORT` in `.env`) |
| Dev client | Vite on `http://localhost:5173`, which proxies `/api` and `/legacy` to port 3000, so the browser sees one origin |
| Auth | HTTP-only session cookie `ds_session` (JWT, 7 days). No bearer tokens, no API keys |
| Format | `Content-Type: application/json` for bodies and responses |
| Health check | `GET /api/health` → `{ "ok": true }` (no sign-in needed) |

**Same-origin only.** No CORS headers are sent (see [Where it connects](#where-it-connects) for what to change). A browser app must be served from the same origin as the API (or sit behind a proxy like Vite's). Native or server-to-server clients just need to keep the cookie. To call the API from a different origin you would need to add the `cors` package with `credentials: true`, or move to token auth. Neither is built.

### From the Vue client

`client/src/api.js` is the one place that talks to the server:

```js
import { api } from './api.js';

const { bulks } = await api.get('/api/bulks?limit=10');
await api.post('/api/notifications/read-all');
await api.put('/api/me/preferences', { useCase: 'rice' });
await api.del('/api/admin/documents/12');
await api.upload('/api/admin/datasets/images?useCase=rice&name=leaf-1', fileInput.files[0]);   // raw body
```

It sends the cookie (`credentials: 'same-origin'`), throws an `Error` whose `message` is the server's `error` text (with `.status`), and on a `401` outside `/api/auth/*` signs the user out and returns to `/login`.

### From plain `fetch`

```js
const res = await fetch('/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password }),
  credentials: 'same-origin',
});
const data = await res.json();          // { user } or { error }
```

---

## Where it connects

One Express server owns the API **and** serves the website, so there is no API address to configure. The browser calls relative paths like `/api/bulks`, which always reach the server the page came from.

```
Browser ──► Express server (server/app.js, port 3000)
              ├─ /api/*     the API (this document)
              ├─ /legacy/*  the old scan screen (still a prototype)
              └─ everything else → the built Vue app (client/dist)
```

### The three places that make the connection

| File | What it does | Change it when |
|---|---|---|
| `server/app.js` | Mounts every route: `/api/auth`, `/api/dashboard`, `/api/bulks`, `/api/me`, `/api/schedules`, `/api/notifications`, `/api/admin`. Also serves `client/dist` and `/legacy` | you add a new API route group |
| `client/src/api.js` | The single helper all Vue code uses to call the API (`api.get/post/put/del/upload`). Paths are relative and the session cookie goes along automatically | you add a base URL, headers or global error handling |
| `client/vite.config.js` | **Development only:** the proxy that sends `/api` and `/legacy` from `localhost:5173` to `localhost:3000` | you change `PORT` in `.env` |

The old scan screen has its own copy of the helper in `legacy/js/api.js` (GET, POST and PUT only). It uses the same relative paths and the same cookie, so it needs no setup. It goes away once that screen is ported.

### Which Vue files call which part of the API

| Part of the app | Calls | Files |
|---|---|---|
| Sign in, session | `/api/auth/*` | `stores/auth.js` (the login page calls it through this store) |
| Dashboard | `/api/dashboard`, `/api/bulks?limit=3` | `stores/farm.js` |
| Use-case switcher | `/api/me/*` | `stores/useCase.js` |
| Diagnosis History | `/api/bulks`, `/api/schedules` | `views/HistoryView.vue` |
| Treatment Schedule (list, stages, detail) | `/api/schedules` (the detail view also saves with `PUT`) | `views/ScheduleListView.vue`, `BulkStagesView.vue`, `TreatmentDetailView.vue` |
| Notifications bell and page | `/api/notifications` | `stores/notifications.js` |
| Admin screens | `/api/admin/*` | everything in `client/src/admin/` |

### Running it

| Mode | Start | Open | How the API is reached |
|---|---|---|---|
| Production / single server | `npm run build`, then `npm start` | `http://localhost:3000` | same server, same origin |
| Development | `npm run dev` (API, port 3000) **and** `npm run dev:client` (Vue, port 5173) | `http://localhost:5173` | Vite proxy forwards `/api` to port 3000 |
| Scripts, curl, other tools | `npm start` | `http://localhost:3000/api/...` | direct; sign in first and keep the cookie (see [Quick start](#quick-start-with-curl)) |

### Pointing a separate frontend or app at the API

This is **not set up**. Today the website and API must share one address. If you host the frontend somewhere else (another domain, a mobile app, a different port in production), three things are needed:

1. **Server:** install `cors` in `server/app.js` with `origin` set to your frontend's address and `credentials: true`.
2. **Client:** add a base URL in `client/src/api.js`, for example `const BASE = import.meta.env.VITE_API_URL ?? ''`, put it in front of every `fetch` URL, and set `credentials: 'include'` instead of `'same-origin'`.
3. **Cookie:** cross-site cookies need `sameSite: 'none'` and HTTPS (change `cookieOpts` in `server/auth.js`), or switch to token auth. `SameSite=Lax` blocks the cookie across sites.

Until then, keep the API and website on the same domain, for example behind one reverse proxy that sends `/api` to the Node server.

---

## Conventions

- **Errors** are always `{ "error": "Human-readable message." }` with one of these statuses:

| Status | Meaning |
|---|---|
| 400 | Invalid input (message says what to fix) |
| 401 | Not signed in or session expired |
| 403 | Signed in but not an admin |
| 404 | Item not found. Unknown `/api/...` paths return `{ "error": "Not found." }` |
| 409 | Conflict: duplicate, wrong state for the action, or something still in use |
| 413 | Body too large (JSON over 2 MB, image over 8 MB) |
| 429 | Too many sign-in attempts |
| 500 | Server error (details are logged, not returned) |

- **Timestamps.** Notifications use ISO 8601 UTC (`2026-10-01T14:53:01Z`). Admin endpoints return SQLite UTC strings (`2026-10-01 14:53:01`); treat them as UTC.
- **Pagination** (`limit`, `offset`) returns `total` so you can page. Each endpoint's maximum is listed below.
- **Admin scope.** Every knowledge and dataset endpoint needs `useCase=<slug>` (query string, or in the JSON body for POST/PUT). Missing or unknown → `400 Choose a valid use case.` Seeded slugs: `black-sigatoka`, `rice`, `corn`.
- **IDs in paths** are integers, except bulk codes (`/bulks/:code`), which are strings you choose.

---

## Auth

### `POST /api/auth/register`
Create a farmer account and sign in (sets the cookie).

```json
{ "email": "ana@farm.ph", "name": "Ana Reyes", "password": "at-least-8-chars", "location": "Davao" }
```
`location` is optional. → **201** `{ "user": User }`. Errors: 400 (bad email, missing name, password under 8 characters), 409 (email already registered), 429.

### `POST /api/auth/login`
```json
{ "email": "ana@farm.ph", "password": "..." }
```
→ `{ "user": User }` and the cookie. 401 `Email or password is incorrect.` Rate limited (see below).

### `POST /api/auth/logout`
Clears the cookie → `{ "ok": true }`.

### `GET /api/auth/me`
Current user, or 401. The client calls this on load to restore a session → `{ "user": User }`.

**User**
```json
{ "id": 2, "email": "ana@farm.ph", "name": "Ana Reyes", "role": "farmer", "location": "Davao", "useCase": "black-sigatoka", "initials": "AR" }
```
`role` is `farmer` or `admin`.

---

## Farmer endpoints

All need a signed-in user and only ever return that user's own data.

### Dashboard
`GET /api/dashboard` → `{ "leavesScanned": 42, "bulksAssessed": 6, "leavesNeedingTreatment": 9 }`

### Use cases and preference
`GET /api/me/use-cases` → `{ "useCases": [{ "slug": "rice", "label": "Rice", "icon": "🌾", "crop": "Rice", "disease": "Rice Blast" }] }`

`PUT /api/me/preferences` body `{ "useCase": "rice" }` → `{ "ok": true, "useCase": "rice" }`. 400 for an unknown slug.

### Bulks (assessment sessions)

`GET /api/bulks?limit=8` (default 8, max 50), newest first:

```json
{ "bulks": [{
  "bulkId": "BLK-001", "plant": "Banana Plant A", "date": "2026-09-30", "leafCount": 3,
  "counts": { "1": 1, "2": 1, "3": 0, "4": 0 }, "status": "Assessment Complete",
  "leaves": [{ "id": 1, "valid": true, "stage": 2, "status": "Early", "confidence": "92%",
               "recommendedAction": "Apply fungicide", "treatmentEligible": true }]
}] }
```
`counts` tallies valid leaves by stage 1–4. `leaf.id` is the leaf's position in the bulk. Leaves saved with `valid: false` come back with `stage`, `status`, `confidence` and `recommendedAction` all `null`. `confidence` is a string, stored exactly as you send it.

`PUT /api/bulks/:code` creates the bulk, or replaces it and all its leaves if the code exists for this user.

```json
{ "plant": "Banana Plant A", "date": "2026-09-30", "status": "Assessment Complete",
  "leaves": [
    { "valid": true, "stage": 2, "status": "Early", "confidence": "92%", "recommendedAction": "Apply fungicide", "treatmentEligible": true },
    { "valid": false }
  ] }
```
`plant`, `date` and at least one leaf are required. Valid leaves need an integer `stage` 0–4; leaves are numbered by their order in the array. `status` defaults to `Assessment Complete`. → `{ "bulk": Bulk }`.

### Treatment schedules

`GET /api/schedules` lists bulks that have a confirmed schedule, oldest first:

```json
{ "schedules": [{ "displayLabel": "Bulk 1", "bulkId": "BLK-001", "plant": "Banana Plant A",
  "groups": [{ "stage": 2, "leafNums": [1, 4], "window": "Sep 30 – Oct 14", "schedule": [{ "status": "Confirmed" }] }] }] }
```
`displayLabel` is numbered by position (not stored).

`PUT /api/schedules/:code` confirms or replaces the schedule for a bulk saved earlier.

```json
{ "groups": [{ "stage": 2, "leafNums": [1, 4], "window": "Sep 30 – Oct 14",
               "schedule": [{ "status": "Suggested", "...": "any other step fields are stored as sent" }] }] }
```
Each group needs `stage` 1–4, `leafNums` (array), and `schedule` (array). Every step's `status` must be one of `Suggested`, `Confirmed`, `Applied`, `Unknown`, `Follow-up Required`. → `{ "ok": true, "groups": [...] }`. 404 if the bulk hasn't been saved with `PUT /api/bulks/:code` first. The first time a bulk gets a schedule, a "Treatment scheduled" notification is created. The original confirmation time of each stage is kept when you re-save.

### Notifications
`GET /api/notifications` (latest 50) → `{ "unread": 1, "notifications": [{ "id": 7, "title": "Treatment scheduled", "body": "...", "read": false, "createdAt": "2026-10-01T14:53:01Z" }] }`

`POST /api/notifications/read-all` → `{ "ok": true }`

---

## Admin endpoints

Everything under `/api/admin` needs `role: "admin"` (otherwise 403). Changes are written to the audit log, which the **History** screen reads.

### Overview and audit log

`GET /api/admin/overview?useCase=` → `{ kpis, pipeline, scope, activity }`
- `kpis`: `entities`, `relationships`, `avgConfidence` (percent or `null`), `documents`, `awaitingExtraction`, `images`, `imagesLabeledPct`
- `pipeline`: `[{ name, pct, note }]` for Extraction, Correction, Confirmation, Traceability, Image validation
- `scope`: `classes`, `relations`, `pendingReview`
- `activity`: the 5 latest audit entries

`GET /api/admin/audit?useCase=&q=&action=&limit=25&offset=0` (max 100) →
`{ "total", "entries": [{ id, actor, action, objectType, objectLabel, previous, newValue, status, detail, createdAt }], "actions": ["CONFIRM", ...] }`.
`q` searches actor, object and type. Entries with no use case (such as farmer imports) appear under every use case.

### Documents

| Method & path | Body / query | Returns |
|---|---|---|
| `GET /documents` | `useCase`, `q`, `status` (`Queued`/`Needs review`/`Extracted`/`Confirmed`), `limit` (≤200, default 100), `offset` | `{ total, documents, counts }` |
| `POST /documents` | `{ useCase, title?, docType?, source?, fileName?, content, extract? }` | **201** `{ document, extraction }` |
| `GET /documents/:id` | | `{ document (with content), triples }` |
| `PUT /documents/:id` | `{ title, docType, source }` | `{ document }` |
| `DELETE /documents/:id` | | `{ ok }` (also deletes its relationships) |
| `POST /documents/:id/extract` | | `{ found, added, document }` |
| `GET /documents/:id/trace` | | `{ document, lineage, events }` |

A **document** is `{ id, title, docType, source, fileName, sizeBytes, status, extractedAt, createdAt, updatedAt, relationships, entities, confidence }`. `counts` is `{ Queued, Extracted, "Needs review", Confirmed }` for the whole use case.

`content` is the file's text, read in the browser. Supported: plain text and Markdown (sentences using the ontology's relationship wording), CSV with `subject,predicate,object[,confidence]` columns, JSON arrays of triples, and `A | relation | B` lines. The JSON body is limited to 2 MB. `title` falls back to `fileName`. With `extract: true`, extraction runs immediately and `extraction` is `{ found, added }` (otherwise `null`). Relationships that already exist (even rejected ones) aren't added again.

`trace.lineage` is four steps (`Source document`, `Extraction`, `Correction`, `Knowledge graph`), each `{ title, time, detail, state: "done" | "pending" }`. `events` is the document's audit entries, newest first.

### Relationships (triples)

A relationship moves **extracted → corrected → confirmed**, or is **rejected**.

| Method & path | Body / query | Returns |
|---|---|---|
| `GET /triples` | `useCase`, `stage`, `q`, `limit` (≤100, default 25), `offset` | `{ total, triples, counts }` |
| `POST /triples` | `{ useCase, subject, predicate, object, subjectClass?, objectClass? }` | **201** `{ triple }` (starts as `corrected`, confidence 1) |
| `PUT /triples/:id` | `{ subject, predicate, object, subjectClass?, objectClass? }` | `{ triple }` (becomes `corrected`; 409 if rejected) |
| `POST /triples/:id/confirm` | | `{ triple }` from `extracted` or `corrected` |
| `POST /triples/:id/reject` | | `{ triple }` from `extracted` or `corrected` |
| `POST /triples/:id/restore` | | `{ triple }` from `rejected` (becomes `corrected`) |
| `POST /triples/:id/unconfirm` | | `{ triple }` from `confirmed` (becomes `corrected`) |
| `POST /triples/confirm-pending` | `{ useCase }` | `{ confirmed: n }` (409 if nothing is pending) |

A **triple** is `{ id, subject, subjectClass, predicate, object, objectClass, confidence, stage, documentId, documentTitle, documentType, reviewer, updatedAt }`. `counts` is `{ extracted, corrected, confirmed, rejected, queued, pendingTrace }`: `queued` counts documents not yet extracted, `pendingTrace` counts relationships with no source document. If `predicate` matches an ontology relationship name, its classes are filled in automatically. Taking an action from the wrong stage returns 409.

### Graph

`GET /graph?useCase=&scope=confirmed|pending` (default `confirmed`; `pending` = extracted + corrected)

```json
{ "nodes": [{ "id": "black sigatoka", "label": "Black Sigatoka", "caption": "Disease", "color": "#ef6a16", "degree": 4 }],
  "edges": [{ "from": "banana", "to": "black sigatoka", "label": "affected by" }],
  "truncated": false, "stats": { "entities": 6, "relationships": 5 },
  "classes": [{ "name": "Disease", "count": 1, "pct": 17, "color": "#ef6a16" }] }
```
At most 150 edges are returned (newest first); `stats` always counts everything.

### Ontology

| Method & path | Body | Returns |
|---|---|---|
| `GET /ontology?useCase=` | | `{ classes: [{ id, name, color, description, usage }], relations: [{ id, label, fromId, toId, fromName, toName }] }` |
| `POST /ontology/classes` | `{ useCase, name, color?, description? }` | **201** `{ id }` |
| `PUT /ontology/classes/:id` | `{ name?, color?, description? }` | `{ ok }` (renaming updates existing relationships) |
| `DELETE /ontology/classes/:id` | | `{ ok }` (409 while relationships use it; its links are removed with it) |
| `POST /ontology/relations` | `{ useCase, fromId, toId, label }` | **201** `{ id }` |
| `DELETE /ontology/relations/:id` | | `{ ok }` |

`color` is `#rrggbb`. Class names and relationship types are unique per use case, ignoring case (409 on duplicates). Every use case starts with 9 classes and 9 relationship types.

### Datasets and images

**Folders**

| Method & path | Body | Returns |
|---|---|---|
| `GET /datasets/folders?useCase=` | | `{ folders: [{ id, parentId, name, count }], total, unfiled }` |
| `POST /datasets/folders` | `{ useCase, name, parentId? }` | **201** `{ id }` |
| `PUT /datasets/folders/:id` | `{ name }` | `{ ok }` |
| `DELETE /datasets/folders/:id` | | `{ ok }` (409 unless empty) |

Names are unique among siblings, ignoring case. `count` is images directly in the folder.

**Images**

`GET /datasets/images?useCase=&folderId=&q=&status=&sort=&limit=24&offset=0`
- `folderId`: a folder id (includes everything nested under it), `unfiled`, or omit for all
- `status`: `Validated` or `Needs review` · `sort`: `newest` (default), `oldest`, `name` · `limit` max 100
- → `{ total, images: [{ id, name, mime, sizeBytes, label, status, folderId, folderName, createdAt }], metrics: { images, labeled, validationPct } }` (`metrics` covers the selected folder, ignoring search and status filters)

`POST /datasets/images?useCase=&folderId=&name=&label=`: **raw image bytes as the body**, with `Content-Type` set to `image/png`, `image/jpeg`, `image/webp` or `image/gif`. Up to 8 MB. The file's actual bytes are checked, so a wrong header or an SVG is refused with 400. `label` defaults to the folder's name. → **201** `{ image }`.

`PUT /datasets/images/:id` body any of `{ name, label, status, folderId }` → `{ image }`. `status` is `Validated` or `Needs review`; `folderId: null` unfiles. Moving to another folder also relabels the image with that folder's name unless you send `label` too.

`DELETE /datasets/images/:id` → `{ ok }` (the stored file is removed too).

`GET /datasets/images/:id/file` → the image itself (correct `Content-Type`, private cache). Works in an `<img src>` because the session cookie goes with it.

### Farmer accounts

`GET /api/admin/users?q=&limit=25&offset=0` (max 100) → `{ total, limit, offset, users: [{ id, lastName, firstName, middleName, email, contact, location, createdAt }] }`. `q` searches names, email and contact; only farmers are listed.

`POST /api/admin/users/import` body `{ "csv": "Last Name,First Name,Middle Name,Email,Contact\nReyes,Ana,,ana@farm.ph,0917..." }` → `{ "created": 12, "skipped": [{ "line": 4, "email": "x@y.ph", "reason": "Already registered" }] }`. Reasons are `Invalid email`, `Missing name` and `Already registered`; `line` is the CSV line number (header = line 1), and `email` is left out when the email itself was invalid.
The header must include Last Name, First Name and Email (Middle Name and Contact are optional; `Contact Number` is accepted). Maximum 5,000 farmers per import. Imported accounts get a random password they cannot use, so they can't sign in until an invite flow exists (not built).

---

## Quick start with curl

```bash
BASE=http://localhost:3000

# 1. Sign in and keep the cookie  (demo accounts come from `npm run seed`, password digisaka123)
curl -s -c jar.txt -H 'Content-Type: application/json' \
  -d '{"email":"admin@digisaka.test","password":"digisaka123"}' $BASE/api/auth/login

# 2. Call anything with the cookie
curl -s -b jar.txt "$BASE/api/admin/overview?useCase=black-sigatoka"

# 3. Upload a document and extract it straight away
curl -s -b jar.txt -H 'Content-Type: application/json' -d '{
  "useCase":"black-sigatoka","title":"Field notes","fileName":"notes.txt","extract":true,
  "content":"Black Sigatoka is caused by Pseudocercospora fijiensis.\nBanana | affected by | Black Sigatoka"
}' $BASE/api/admin/documents

# 4. Review and confirm
curl -s -b jar.txt "$BASE/api/admin/triples?useCase=black-sigatoka&stage=extracted"
curl -s -b jar.txt -X POST $BASE/api/admin/triples/1/confirm

# 5. Upload an image into a folder
curl -s -b jar.txt -H 'Content-Type: image/png' --data-binary @leaf.png \
  "$BASE/api/admin/datasets/images?useCase=black-sigatoka&folderId=2&name=leaf-1"
```

Demo logins after `npm run seed`: `juan@digisaka.test` (farmer) and `admin@digisaka.test` (admin), both with password `digisaka123`. Change or delete them before going live.

---

## Limits and security notes

- **Sign-in limit:** 20 register/login attempts per 15 minutes per client IP. The two demo emails are exempt when `NODE_ENV` isn't `production`.
- **Cookie:** `HttpOnly`, `SameSite=Lax`, `Secure` when `NODE_ENV=production` (serve over HTTPS there). Sessions last 7 days and can't be revoked individually; changing `JWT_SECRET` signs everyone out.
- **`JWT_SECRET`** must be set in production. Without it the server generates a temporary one and sessions reset on every restart.
- **CSRF:** the `SameSite=Lax` cookie blocks cross-site POST/PUT/DELETE in modern browsers. There are no CSRF tokens.
- **Content security policy is off** (`helmet` runs with CSP disabled) because the legacy scan screen uses inline handlers. Turn it on after that screen is ported.
- **Uploads** go to `UPLOAD_DIR` (default `data/uploads`) under random names, and are served only to signed-in admins.
- **Not built:** CORS for other origins, API keys or bearer tokens, per-admin permissions, password reset, and real-time updates (clients must refetch).

### Environment

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | `3000` | HTTP port |
| `DB_PATH` | `data/digisaka.db` | SQLite file (`:memory:` in tests) |
| `UPLOAD_DIR` | `data/uploads` beside the database | Where dataset images are stored |
| `JWT_SECRET` | random per start | Signs session cookies. **Required in production** |
| `NODE_ENV` | `development` | `production` turns on secure cookies and the sign-in limit for demo accounts |
