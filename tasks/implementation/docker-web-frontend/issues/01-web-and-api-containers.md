# 01: Web app and API up in containers

**What to build:** A developer with Docker running and the app's env files in place starts the stack with compose and opens the web app in the browser. The Express API and the Vite dev server each run in a container, the seeded demo accounts can sign in to the shell, and the QA sign-in screen loads. Editing a client source file on the host updates the browser without rebuilding. Running the app outside Docker behaves exactly as before.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] One compose command builds and starts two services, the API and the web dev server, with ports published on the host's loopback only.
- [ ] The dev server's proxy targets for the API and the scheduler are read from environment variables and default to today's values, so a non-Docker run is unchanged. In compose the API target is the API service.
- [ ] A one-off compose command seeds the demo accounts into a database held in a named volume; the database survives a stop and start of the stack.
- [ ] A seeded demo account signs in to the shell through the containerized stack, and the QA sign-in screen loads.
- [ ] Client source edits on the host reach the browser through hot reload, and dependencies installed in the container are kept apart from any host install.
- [ ] No secret or env file content is baked into an image or committed; env files stay gitignored and are passed in at run time.
- [ ] The existing client unit suite and the server tests still pass outside Docker.
- [ ] The Docker CLI is located and used for the verification run; the verification is recorded in the ticket.
