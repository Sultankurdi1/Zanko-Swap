-- ZankoSwap security hardening, part 2.
-- Run once in Supabase Dashboard -> SQL Editor, after security_hardening_migration.sql.

-- 1) Private bucket for ad payment receipts: only the uploader and admins can read.
insert into storage.buckets (id, name, public)
values ('ad-receipts', 'ad-receipts', false)
on conflict (id) do update set public = false;

drop policy if exists "ad_receipts_insert_own" on storage.objects;
create policy "ad_receipts_insert_own" on storage.objects
for insert to authenticated
with check (bucket_id = 'ad-receipts' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "ad_receipts_read_own_or_admin" on storage.objects;
create policy "ad_receipts_read_own_or_admin" on storage.objects
for select to authenticated
using (
  bucket_id = 'ad-receipts'
  and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin())
);

drop policy if exists "ad_receipts_update_own" on storage.objects;
create policy "ad_receipts_update_own" on storage.objects
for update to authenticated
using (bucket_id = 'ad-receipts' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'ad-receipts' and (storage.foldername(name))[1] = auth.uid()::text);

-- 2) Public image buckets: files stay viewable by their public URL, but nobody
--    can list or browse other users' folders through the API.
drop policy if exists "listing_images_read" on storage.objects;
drop policy if exists "profile_images_read" on storage.objects;
drop policy if exists "service_images_read" on storage.objects;
drop policy if exists "service_images_public_read" on storage.objects;

drop policy if exists "public_images_read_own_folder" on storage.objects;
create policy "public_images_read_own_folder" on storage.objects
for select to authenticated
using (
  bucket_id in ('listing-images', 'profile-images', 'service-images')
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "service_images_update_own" on storage.objects;
create policy "service_images_update_own" on storage.objects
for update to authenticated
using (bucket_id = 'service-images' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'service-images' and (storage.foldername(name))[1] = auth.uid()::text);

-- 3) Upload limits: images only, max 10 MB.
update storage.buckets
set file_size_limit = 10485760,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
where id in ('listing-images', 'profile-images', 'service-images', 'ad-receipts');
