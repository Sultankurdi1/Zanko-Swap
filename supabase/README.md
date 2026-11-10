# ZankoSwap database

All SQL is run by hand in Supabase Dashboard → SQL Editor. Nothing here runs automatically.

## `sql/` — database changes, in order

Each file was run once, in the numbered order. To rebuild the database from scratch, run them in the same order. Later files override earlier ones: for example, `17_policy_reset_all_tables.sql` replaces every table policy, so the policies in files 01–16 are history only.

| File | What it does |
| --- | --- |
| 01–09 | Original tables: profiles, listings, places, research, exam papers, ads, chats, devices |
| 10–12 | Security hardening: admin role, hidden contact details, chat id rules, push limits |
| 13 | In-app account deletion |
| 14 | Blocked words in chat, names, listings and places |
| 15 | Image link rules, content reports, auto-hide after 3 reports |
| 16 | Storage policy reset |
| 17 | Full table policy reset (the current rules) |
| 18 | Admin panel access, seller ratings, app error reports |

New changes go in a new file with the next number.

## `scripts/` — one-off tools

| File | When to run |
| --- | --- |
| `make_owner_admin.sql` | Give the owner account the admin role |
| `reset_test_data.sql` | Once, right before launch: deletes all test content and every account except the owner's. Empty the storage buckets first. |

## `functions/` — Edge Functions

Deployed by pasting each `index.ts` into Supabase Dashboard → Edge Functions.

| Function | Secrets it needs |
| --- | --- |
| `send-chat-notification` | `FIREBASE_SERVICE_ACCOUNT_JSON` |
| `send-new-place-notification` | `FIREBASE_SERVICE_ACCOUNT_JSON` |
| `moderate-upload` | `SIGHTENGINE_API_USER`, `SIGHTENGINE_API_SECRET` |

Do not create policies by hand in the dashboard; add them to a new numbered file instead.
