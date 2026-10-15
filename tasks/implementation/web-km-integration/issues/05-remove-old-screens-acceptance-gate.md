# 05: Remove the old screens and run the acceptance gate

**What to build:** The Express-backed Document Extractions and KG Processing code, routes and nav entries that the new screens replace are removed, along with their tests and the unused Express endpoints they called. The other admin screens are untouched. Then the end-to-end run from the backend's acceptance ticket is done in the browser: the Plantix dedup seed first, then the Paviso terminal report, then the FAO stage excerpt, each as text, by the test Technical User.

**Blocked by:** 04

**Status:** ready-for-agent

- [ ] No route, nav entry or import points at the removed screens; the build succeeds and the Vitest and server tests pass.
- [ ] The seed workflow reaches `completed` from the browser alone.
- [ ] The Paviso document, over several chunks, reaches `completed` from the browser alone, with facts reviewed on the screen.
- [ ] The FAO excerpt reaches `completed` as its own workflow.
- [ ] The accepted facts are found in Fuseki under each run's named graph.
- [ ] Anything that blocked the run is written down as a follow-up, not fixed in this ticket.
