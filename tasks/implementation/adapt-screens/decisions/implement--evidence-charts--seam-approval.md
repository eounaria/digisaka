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

## Addendum: last three weeks visible when choosing a line

User asked that the last 3 weeks of line data be visible when choosing a line to scan, as well as on the treatment screen. All questions minor or standard; recommendations followed.

1. No cycle exists before a scan, so the evidence route cannot serve the picker. Added one additive scheduler route, `GET /lines/{line_id}/weeks/{week}/history` (AI_NeSy_Framework `17e551a`): the last three weekly values up to the picked week, within the year, missing weeks all null. Standard.
2. The picker shows the same line and bar charts as the treatment screen (shared `WeekCharts` component), without verdicts or compared-week highlights, which only exist for a cycle. The user asked why it was a table; there was no reason beyond keeping the first cut small. Minor.
3. The evidence charts now show the last 3 weeks plus any earlier week the rules compared, so each caption can be checked against the chart. Minor.
