# Decision record: grill-with-docs, Knowledge Maintenance in the web app

Developer audit only. Nothing else may link here.

## Preface

The user asked to plan the web integration of the Knowledge Maintenance Workflow while also adapting existing screens. The project rules limit integration to the QA section until the prototype is done; the user's request widens that, so the widened scope is taken as their decision. Facts checked: the KM endpoints (create, get, retry, cancel, facts, review, claim, release, approve) are built in `src/ai_nesy/apps/api/routes/knowledge_maintenance*.py` and served on port 8000; the admin Extractions and Processing screens call the Express stub (`/api/admin/*`); ticket 36 in the backend repo fixes the acceptance documents and holds the runbook.

## Decisions

1. Replace the Express-backed Extractions and Processing screens, or keep them beside the KM ones? Ranked breaking (changes what screens do). Asked. Answer: replace them.
2. Does a test Technical User exist in Supabase with the role the KM API checks? Ranked minor. Asked. Answer: yes.
3. Which document is the acceptance run? Ranked minor. User pointed to the backend's KM implementation folder. Answer: ticket 36 decides it: the Paviso terminal report (7 chunks) as the acceptance document, the Plantix `yellow_and_black_sigatoka` record as the dedup seed committed first, and the FAO stage excerpt as a separate second run; all submitted as text entries.
4. Branch base: `qa-web/adapt-screens` rather than `staging`? Ranked standard. Asked. Answer: yes, based on `qa-web/adapt-screens`.
