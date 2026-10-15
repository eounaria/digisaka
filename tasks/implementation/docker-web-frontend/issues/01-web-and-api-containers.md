# 01: Web app and API up in containers

**What to build:** A developer with Docker running and the app's env files in place starts the stack with compose and opens the web app in the browser. The Express API and the Vite dev server each run in a container, the seeded demo accounts can sign in to the shell, and the QA sign-in screen loads. Editing a client source file on the host updates the browser without rebuilding. Running the app outside Docker behaves exactly as before.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] One compose command builds and starts two services, the API and the web dev server, with ports published on the host's loopback only.
- [x] The dev server's proxy targets for the API and the scheduler are read from environment variables and default to today's values, so a non-Docker run is unchanged. In compose the API target is the API service.
- [x] A one-off compose command seeds the demo accounts into a database held in a named volume; the database survives a stop and start of the stack.
- [x] A seeded demo account signs in to the shell through the containerized stack, and the QA sign-in screen loads.
- [x] Client source edits on the host reach the browser through hot reload, and dependencies installed in the container are kept apart from any host install.
- [x] No secret or env file content is baked into an image or committed; env files stay gitignored and are passed in at run time.
- [x] The existing client unit suite passes on the host (65 tests). The server tests pass in the `api` container (12 of 12); on the host they cannot load, because the root `node_modules` is not installed there, which predates this slice.
- [x] The Docker CLI is located and used for the verification run; the verification is recorded in the ticket.

Verified 2026-10-16 with Docker 29.8 on Docker Desktop for Mac: image builds; seed runs; both containers stay up; login as a seeded account through port 5173 returns 200; the QA sign-in route returns the shell; the database survives `down` and `up`; an edit on the host shows in the served module within seconds (a browser-side hot update was not observed, no browser attached). The image needs python3, make and g++ because `better-sqlite3` has no prebuilt binary for this Node on arm64.
