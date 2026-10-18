# ZankoSwap — Production Build Notes

This archive is based on the supplied ZankoSwap project and keeps the existing Supabase architecture while adding the requested production features.

## Run

```powershell
flutter clean
flutter pub get
flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

The project already has the Supabase URL configured through `SUPABASE_URL`; you can override it with another `--dart-define` if required.

## Supabase SQL

Run these in order in the Supabase SQL Editor:

1. `supabase/schema.sql`
2. `supabase/content_and_privacy_migration.sql`
3. `supabase/production_security_and_schema.sql`

The final migration provides guest/public reads, owner-only writes, admin moderation, service contact/navigation columns, canonical `exam_papers` and `research` fields, and realtime publication entries.

## Implemented

- Email **or phone** Supabase Auth with the existing guest/public browsing flow.
- Ownership checks in the UI plus RLS enforcement in SQL; admins can moderate content.
- Exams: multi-image upload, scientific/literary branch, year and subject filtering, edit/delete, favorites, full-screen pinch/zoom gallery.
- Research: academic path, `authorId`, `stage`, `createdAt`, `file_url`, edit/delete, favorites, PDF viewer and local document download.
- Saved/Favorites for listings/books, exams and research using persistent local storage.
- Restaurants, cafes and stationeries have dedicated drawer routes and locked add forms.
- Google Maps and WhatsApp external launch actions on service cards/details.
- Optional service phone, menu URL, copy-price, latitude and longitude fields.
- Modern colorful home category cards and compact 4-column publication grid.
- Kurdish/Arabic strings for the newly added user-facing actions and dialogs.
- Loading skeletons, empty states and retry states for the main async screens.

## Important

The Supabase publishable key must be supplied at runtime. Do not replace it with a service-role key. The service-role key must never be shipped inside a Flutter client application.
