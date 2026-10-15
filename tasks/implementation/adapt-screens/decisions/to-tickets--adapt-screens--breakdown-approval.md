# Decision record: to-tickets breakdown approval, adapting the original screens

Developer audit only. Nothing else may link here.

## Preface

Source: the rough plan and grill-with-docs decisions for the adapt-screens slice (branch `qa-web/adapt-screens`), after the user deferred the Dashboard, Notifications and Settings. No wayfinder map exists because the grilling found no fog. Rules in force: minor and standard questions follow the recommendation; only destructive or breaking decisions halt for the user. The user was not asked anything this round.

## Decisions

| # | Question | Rank | Decision |
|---|---|---|---|
| 1 | Is the granularity right? | standard | Six tickets along the user journey: sign-in and shell; scan up to verification; scan from grouping to the cycle; history, list and stages; treatment detail; removal and exit gate. About one more than the cost estimate given to the user, because removal and the live run are their own ticket. |
| 2 | Blocking edges? | standard | 01 to 02; 03 and 04 each need 02 and are independent; 05 needs both; 06 needs 05. 04 depends on 02 because the line store arrives with the scan screen. |
| 3 | Where do the QA screens get removed? | standard | In 06, not 01. Until then they stay unrouted so the tree builds while the old stores take over their logic. |
| 4 | Where does the greyed-out handling live? | minor | In the ticket of the screen it appears on, not in a separate ticket. |
| 5 | Review point for the scan layout? | standard | Ticket 02 ends with the user seeing the screen before 03, since no web design exists to follow. This is a gate in the ticket, not a halt in this round. |
| 6 | Prefactoring? | minor | None. |
| 7 | Paths and code in tickets? | minor | Kept out. |
| 8 | Location and numbering? | minor | `tasks/implementation/adapt-screens/issues/NN-<slug>.md`, README with dependency table. |

## Halts

None.
