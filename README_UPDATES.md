# ZankoSwap update setup

## Supabase SQL

Run `supabase/content_and_privacy_migration.sql` in the Supabase SQL Editor after the existing setup file. It creates the `research` and `examPapers` tables that fix `PGRST205`, adds vendor daily updates, and restricts chats and messages to their two participants through Row Level Security.

## Google Sign-In

Enable Google under Supabase Authentication → Providers, add the Android OAuth client ID and SHA-1/SHA-256 fingerprints in Google Cloud/Firebase, and keep the Android package identifier unchanged. The app now exposes a Continue with Google button and exchanges the Google ID token with Supabase Auth.

## Profile photos

The profile editor accepts JPG, JPEG, and PNG images, resizes/compresses picked images, and rejects files over 2 MB before upload.

## Chat privacy

Chat rows and messages are protected by participant-only RLS policies. The client uses a deterministic per-listing conversation ID and never exposes chat rows publicly. True cryptographic end-to-end encryption would additionally require a key exchange and encrypted message payload migration; the included database policy prevents unauthorized reads/writes at the Supabase layer.
