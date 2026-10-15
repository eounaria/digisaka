# implement: evidence charts, seam approval

Developer audit record. Context: the treatment screen and the scan Results step state "the disease is getting worse and rainfall favours its spread" with no visible evidence. The backend route `GET /cycles/{id}/evidence` is built (AI_NeSy_Framework, `056cb3c`). This slice adds the frontend: an evidence store, two plain-SVG charts and their mounting.

## Seams tested

- **Evidence store** (`stores/evidence.test.js`), on a stubbed `fetch`: loads the route, `unknown_evidence` maps to phase `none` (not an error), other failures show a readable message, a stale answer is ignored, reset drops a pending answer. Decided without asking (standard): matches the cycle and proposal stores.
- **Caption and geometry helper** (`helpers/evidence.test.js`): captions are built from the data in plain words, `null` weeks stay gaps in the line path and are listed as missing, axis top rounds to a round number. Decided without asking (standard): logic kept pure so it is testable without a DOM.
- **Not unit-tested:** the SVG component itself (no component-test setup in this client); covered by the build and the live check below. Decided without asking (minor).

## Design choices (all minor or standard, followed the recommendation)

- No chart library; hand-built SVG with the existing CSS variables, `role="img"` with a text summary, and a collapsible numbers table.
- The disease axis always runs so that worsening goes down (follows `worsening_direction`). `yli` is a lighter line labelled as context.
- Mounted on the treatment screen under the proposal card, and on the scan Results step when the cycle phase is proposal, monitoring or review.

## Still open

Live check needs the user's restarted scheduler and a closed cycle with a trend stage.
