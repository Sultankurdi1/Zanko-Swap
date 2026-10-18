# ZankoSwap

ZankoSwap is a Flutter marketplace/community app using **Supabase only** for authentication, database, storage, and realtime features. Firebase is not required.

## Supabase configuration

The project URL is already configured for the ZankoSwap Supabase project. Pass the current Supabase **Publishable key** at build/run time:

```powershell
flutter clean
flutter pub get
flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Do not use a `service_role` key in the Flutter app. If a publishable key was rotated, create/copy the current one from Supabase Dashboard and use that current key.

## Database and storage

Run `supabase/zankoswap_setup.sql` in the Supabase SQL Editor. It creates/updates the required tables, RLS policies, and storage buckets.

Required buckets include `listing-images` and `profile-images`.

## Authentication

Login and registration use Supabase Auth. If email confirmation is enabled in Supabase, a new user must confirm their email before signing in.

## Firebase status

Firebase packages, initialization, Google Services configuration, Firestore configuration, and Firebase Storage configuration have been removed from the app.
