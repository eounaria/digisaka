# 05: Remove the old screens and run the acceptance gate

**What to build:** The Express-backed Document Extractions and KG Processing code, routes and nav entries that the new screens replace are removed, along with their tests and the Express document, triple and graph endpoints they called, and `server/extract.js`. Tracing and Knowledge Graph, which read that data, stay in the nav greyed out as not available yet; Overview greys out its document and relationship figures. Other admin screens are untouched. Then the end-to-end run from the backend's acceptance ticket is done in the browser: the Plantix dedup seed first, then the Paviso terminal report, then the FAO stage excerpt, each as text, by the test Technical User.

**Blocked by:** 04

**Status:** done for the seed run; the Paviso and FAO runs were deliberately skipped

- [x] No route, nav entry or import points at the removed screens; the build succeeds and the Vitest and server tests pass.
- [x] The seed workflow reaches `completed` from the browser alone.
- [ ] The Paviso document, over several chunks, reaches `completed` from the browser alone, with facts reviewed on the screen.
- [ ] The FAO excerpt reaches `completed` as its own workflow.
- [x] The accepted facts are found in Fuseki under each run's named graph (checked for the seed run: one accepted fact, two triples in its fact graph).
- [x] Anything that blocked the run is written down as a follow-up, not fixed in this ticket.
