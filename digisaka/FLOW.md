# How Digisaka Works: The Flow

Digisaka has two sides that share one server and one database: the **farmer app**, where leaves are scanned and treatment is scheduled, and the **admin console**, where the knowledge behind the system is managed.

## Farmer flow

**1. Sign in.** The farmer logs in and the server sets a session cookie. They pick a use case (Black Sigatoka, Rice or Corn) in the header, and the choice is saved to their account.

**2. Scan.** Disease Detection opens the original scan screen inside the Vue app. The farmer captures a leaf image and taps "Use This Image". The screen processes it and returns a result for that leaf: a disease stage from 1 to 4, healthy, or not validated.

**3. Build a bulk.** Leaves are grouped into a *bulk*: one assessment session for one plant, with a bulk ID. When the farmer opens the bulk summary, the app saves the bulk and all its leaves to the server (`PUT /api/bulks/:code`). This is why the Dashboard counts and Diagnosis History update.

**4. Confirm and schedule.** Pressing "Confirm & Schedule" groups the leaves that need treatment by stage. Healthy and unvalidated leaves are left out. Each group gets three suggested steps: Treatment, a Follow-up five days later, and a Re-assessment ten days later. Every step starts as "Suggested" and is never assumed applied.

**5. Save.** The app then saves the bulk again and the schedule to the server (`PUT /api/schedules/:code`). The first save for a bulk also creates a "Treatment scheduled" notification. This save was the fix for schedules not appearing after a scan.

**6. Review.** The Vue screens read from the server:
- **Treatment Schedule** lists bulks, then each bulk's stages, then the steps for one stage. The farmer can update a step's status there.
- **Diagnosis History** lists past bulks. "View Bulk" opens that bulk's stages, or shows "No schedule yet".
- **Notifications** shows the alert and the unread count.

One limit: the dates in generated steps still come from the prototype's fixed demo calendar (August and September), not from today's date.

## Admin flow

Admins work per use case, chosen in the header.

1. **Upload** a text document (.txt, .md, .csv or .json) in Document Extractions.
2. **Extract.** A rule-based extractor finds relationships such as "Black Sigatoka caused by Pseudocercospora fijiensis". Each starts as *extracted*, and low-confidence ones are flagged for correction.
3. **Review** in KG Processing. Admins edit (*corrected*), confirm, reject or restore each relationship, or confirm all at once.
4. **Publish.** Only *confirmed* relationships appear in the Knowledge Graph. Pending ones show in the Temporary Graph.
5. **Maintain.** Ontologies define the allowed classes and relationship types. Datasets & Images holds training images in folders. Tracing follows one document from upload to graph. History logs every change, and Overview summarises it all.

## How they connect

Both sides call the same Express API. Farmers can only reach their own data, and admin routes require the admin role. At present the admin knowledge graph does not feed the farmer's scan results, so the two flows run side by side.
