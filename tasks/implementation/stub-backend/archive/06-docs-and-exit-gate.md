# 06: Documentation and exit gate

**What to build:** Describe the stub where a new developer looks: a README section "Run it on the stub" (the command, the sample users, the scenarios per line, document title and image name, reset, how to switch back and the `docker compose restart web` rule), and a CLAUDE.md update (commands, the stub's place beside the real backends, the rule that it is standalone and its shapes come from the client). Then run the exit gate.

**Blocked by:** 04, 05

**Status:** done

- [ ] With no host services, each sample user signs in and every Practitioner screen and the Document Extractions flow can be driven, including each named scenario.
- [ ] The admin screens that use the Express API open for the Technical User.
- [ ] `npm test`, `npm --prefix client test` (including the contract tests) and the stub unit tests pass.
- [ ] Switching back to the real backend with plain `docker compose up` works unchanged.
- [ ] The README and CLAUDE.md state that the stub can drift from the real services and that the manual run against the real backend remains the acceptance gate.
