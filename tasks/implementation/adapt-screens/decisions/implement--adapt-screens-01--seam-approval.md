# implement: adapt-screens ticket 01, seam approval

Context: ticket 01 (Supabase sign-in in the original login, auth store, route guard, trimmed shell). Seams were stated in chat during the earlier session and are recorded here afterwards. Minor and standard questions followed the recommendation.

- Seam: the auth store (Supabase password grant with a fake `fetch`, role reading from the token, sign-out) and the route guard (role-based redirects). Standard; approved.
- No component tests for the login view or the shell. Minor; approved.
