# Decision record: to-tickets, Knowledge Maintenance in the web app

Developer audit only. Nothing else may link here.

## Preface

Input is the rough plan for replacing the admin console's Express-backed Document Extractions and KG Processing screens with screens on the Knowledge Maintenance API. Rules in force: minor and standard questions follow the recommendation; destructive or breaking ones halt for the user. Facts checked: the KM routes expose create, get, retry, cancel, facts, review, claim, release and approve; there is no endpoint that lists workflows.

## Decisions

1. The plan assumed a workflow list screen, but the API cannot list workflows. Ranked standard. Self-decided: keep a per-user list of submitted workflows in the browser and allow opening any workflow by id; a backend list endpoint is left as a later ticket, since the plan allows no backend change.
2. Ticket granularity: five tickets (submit and list; status, retry and cancel; extraction review; final review and commit; removal and acceptance run), one per demoable step of the Technical User's path. Ranked standard. Self-decided as recommended: smaller splits would not be demoable, larger ones would not fit one context window.
3. Removal of the replaced Express-backed code is kept in the last ticket, not each ticket, so the old screens keep working until the new path is proven. Ranked standard. Self-decided.
