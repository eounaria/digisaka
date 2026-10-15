# implement: single sign-in and shell, seams (supabase-only-auth ticket 02)

Context: ticket 02 of the Supabase-only accounts plan. Rank: standard, followed the recommendation without asking.

- Seam 1: reading email and roles from the access token (`scheduler/roles.js`), unit-tested with hand-built tokens. Display logic only.
- Seam 2: the admin API client (`api.js`), tested with a stubbed `fetch`: bearer header on get/post/upload, no header when signed out, 401 calls the unauthorized handler.
- Not unit-tested: Vue shell, router guard and sign-in view (thin wiring); covered by the build and the live run.
- Active use case: stored in `localStorage`, loaded from the admin API list; no server-side preference.
