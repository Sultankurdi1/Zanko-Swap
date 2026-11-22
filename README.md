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

## Website (installable web app)

The same Flutter app runs as a website at `zankoswap.pages.dev` (Cloudflare
Pages). On a phone, people open it and add it to the home screen: Android shows
an install button, iPhone users follow the Share → Add to Home Screen hint.

- Build: `flutter build web --release` → `build/web`.
- `.github/workflows/web-deploy.yml` publishes on every push to `main` that
  touches the app. It needs the GitHub secrets `CLOUDFLARE_API_TOKEN` (Pages
  edit permission) and `CLOUDFLARE_ACCOUNT_ID`, and a Pages project named
  `zankoswap`.
- `web/sw.js` makes the site installable and shows a Kurdish offline page;
  `web/flutter_bootstrap.js` keeps Flutter's old self-removing service worker
  from replacing it. The install hint lives in `web/index.html`.
- Picked photos are uploaded as bytes (`XFile`), and previews use
  `PickedImage` (`lib/core/widgets/picked_image.dart`), so uploads work on the
  web too.
- Web-only differences: no push notifications, no Google sign-in (email and
  password instead), PDF "download" opens the file in the browser, and paid ads
  are shown on the website even on iPhones (it is not the App Store).
