# Decision record: implement seam approval, Docker for the web frontend

Developer audit only. Nothing else may link here.

## Preface

Ticket 01 of slice 4 (branch `docker/web-frontend`). Rules in force: minor and standard questions follow the recommendation; only destructive or breaking decisions halt for the user. The user was not asked anything this round.

## Decisions

| # | Question | Rank | Decision |
|---|---|---|---|
| 1 | Which seams get unit tests? | standard | One: the dev proxy target resolution (environment in, API and scheduler targets out), with local defaults, environment override and empty-as-unset. It is the only logic this slice adds. |
| 2 | Test the Dockerfile and compose file? | standard | No unit tests. They are checked by running them: build, seed, start, login through the web port, persistence across restart, host edit visible in the served module. |
| 3 | Where does the module live? | minor | Beside `vite.config.js`, with the test included explicitly in the Vitest include list, since the config file cannot import the Vue source tree. |
| 4 | Build tools in the image? | standard | Install python3, make and g++: `better-sqlite3` fell back to compiling (no prebuilt binary for this Node on arm64). Alternative of pinning another Node was not taken. |
| 5 | API container command? | minor | Plain `node server/index.js`. The package's `dev` script uses `--watch` with `--env-file-if-exists`, which crashes when `.env` is absent; compose passes `.env` in anyway. Server hot reload is not part of the ticket. |
| 6 | Server tests on the host fail to load (root dependencies not installed there). | minor | Not fixed; predates the slice. Run in the container instead, 12 of 12 pass. |

## Halts

None.
