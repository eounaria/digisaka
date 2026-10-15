# Decision record: grill-with-docs, Docker for the web frontend

Developer audit only. Nothing else may link here.

## Preface

Slice 4 containerizes the digisaka web app so the full demo runs from a short series of commands. It comes before the live `L04` `2026-W24` run of slice 3. The web app is a Vue 3 and Vite client plus an Express and SQLite server (`digisaka/digisaka/`). Vite proxies `/api/v1/scheduler` to the scheduler on `127.0.0.1:8001` and `/api` to the Express server on `localhost:3000`; the QA screens sit behind the Express cookie login. The backend (QA on 8000, scheduler on 8001, Claude proxy on 9111, MLX embedder on 9200) runs as host processes per the AI_NeSy runbook and has no CORS. The repo has no Dockerfile or compose file today. Rules in force: minor and standard questions follow the recommendation; only destructive or breaking decisions halt for the user. The branch-base question was put to the user.

Facts checked: the QA route guard needs the Express login first (`client/src/router.js`); `package.json` needs Node 22 and `better-sqlite3`, a native module; `client/dist` and `data/` are gitignored; Docker Desktop is installed but `docker` is not on the agent shell's PATH, so implement must find the CLI before verifying anything.

## Decisions

| # | Question | Rank | Decision |
|---|---|---|---|
| 1 | Branch base for the Docker work? | breaking (asked) | New local branch `docker/web-frontend` off `integration/qa-web`. Slice 3 stays untouched. Not merged, not pushed. |
| 2 | Containerize the backend too? | standard | No. Frontend only. The Claude proxy and MLX embedder need the host, and QA needs local CV checkpoints. The backend keeps the AI_NeSy runbook's commands. |
| 3 | Which processes run in containers? | standard | Two services: `api` (Express and SQLite, port 3000) and `web` (Vite dev server, port 5173). The shell login needs `api`; the scheduler proxy lives in Vite. |
| 4 | Dev server or production build served statically? | standard | Vite dev server. The scheduler proxy exists only there, and the backend has no CORS, so a static build would need a new reverse proxy. Production images are out of scope. |
| 5 | How does the container reach the scheduler? | standard | `host.docker.internal:8001`, set through an environment variable read by `vite.config.js`, defaulting to `http://127.0.0.1:8001` so a non-Docker run is unchanged. `api` is reached as `http://api:3000` the same way. |
| 6 | Does the backend need to change for that? | standard | Not expected: Docker Desktop for Mac should reach host-loopback services. Unverified until the live step. If it fails, a backend bind change would be breaking and would halt for the user. |
| 7 | Where do Supabase values and secrets live? | standard | In the gitignored `client/.env.local` and `.env`, passed in at run time, never baked into an image or committed. Matches slice 3 decision 13. |
| 8 | Hot reload and dependencies? | minor | Bind-mount the client source; keep `node_modules` in a named volume so host and container binaries never mix. |
| 9 | Database and seeding? | standard | SQLite file in a named volume; seeding is a one-off `docker compose run` command listed in the series. |
| 10 | Base image and ports? | minor | `node:22-bookworm-slim` (glibc, so `better-sqlite3` installs without a toolchain fight). Ports published on `127.0.0.1` only. |
| 11 | Wrapper script or Makefile? | minor | No. The series is plain `docker compose` commands in the digisaka README, with the backend commands named by path to the AI_NeSy runbook rather than copied. |
| 12 | New glossary terms or an ADR? | minor | None. The choice is easy to reverse and adds no domain terms. |
| 13 | Wayfinder map? | standard | None. Every open question is settled above and the work fits one branch. Go to to-tickets. |
| 14 | Does the slice include the live `L04` run? | standard | No. The exit gate stops at the proxy reaching the scheduler; the live run follows as its own step. |

## Halts

Decision 1 was put to the user, who chose the new branch off `integration/qa-web`. No other halt.
