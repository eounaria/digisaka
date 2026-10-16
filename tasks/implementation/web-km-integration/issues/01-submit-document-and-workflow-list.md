# 01: Submit a document and keep a list of my workflows

**What to build:** The admin console's Document Extractions screen is replaced. A Technical User submits a document: a pasted or chosen plain-text file, or a PDF, with a title. The workflow is created and appears in a list on the screen with its title, id, state and time. The list is remembered in this browser for the signed-in user, and any workflow can also be opened by pasting its id, since the API cannot list workflows. A Practitioner-only user does not see the screen. Validation errors from the API (size limits, unusable PDF, bad text) show the API's own message.

**Blocked by:** None (can start immediately)

**Status:** built; exercised live by the seed run

- [ ] Submitting text creates a workflow and adds it to the list; submitting a PDF does the same.
- [ ] Reloading the page keeps the list for the same user and does not show it to another user.
- [ ] Opening a workflow by id works, and an unknown id shows the API's message.
- [ ] The old document upload, extract, edit and delete actions are gone from this screen.
- [ ] A user without the Technical User role cannot reach the screen.
- [ ] Unit tests cover the store (create, remember, open by id) with a fake client.
