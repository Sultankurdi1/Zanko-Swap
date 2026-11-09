-- ZankoSwap image safety and content reports.
-- Run once in Supabase Dashboard -> SQL Editor, after content_moderation.sql,
-- and only after the moderate-upload Edge Function is deployed with its
-- SIGHTENGINE_API_USER and SIGHTENGINE_API_SECRET secrets.
-- Safe to run more than once.

-- 1) Owners always see their own listings and places, including sold or hidden ones.
drop policy if exists "listings_owner_read" on public.listings;
create policy "listings_owner_read" on public.listings
for select to authenticated
using (auth.uid() = "sellerId" or public.is_admin());

drop policy if exists "services_owner_read" on public.services;
create policy "services_owner_read" on public.services
for select to authenticated
using (auth.uid() = "ownerId" or public.is_admin());

-- 2) Public images can only be added through the moderate-upload Edge Function,
--    which checks every picture for nudity before saving it.
drop policy if exists "listing_images_insert_own_folder" on storage.objects;
drop policy if exists "listing images upload" on storage.objects;
drop policy if exists "listing images update" on storage.objects;
drop policy if exists "profile_images_insert_own_folder" on storage.objects;
drop policy if exists "profile_images_update_own_folder" on storage.objects;
drop policy if exists "profile images upload" on storage.objects;
drop policy if exists "profile images update" on storage.objects;
drop policy if exists "service_images_insert_own_folder" on storage.objects;
drop policy if exists "service_images_insert_own" on storage.objects;
drop policy if exists "service_images_update_own" on storage.objects;

drop policy if exists "public_images_delete_own_folder" on storage.objects;
create policy "public_images_delete_own_folder" on storage.objects
for delete to authenticated
using (
  bucket_id in ('listing-images', 'profile-images', 'service-images')
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- 3) Image links saved in the database must point to this project's storage,
--    so nobody can show an outside picture through the API.
create or replace function public.enforce_image_urls()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  field text;
  value jsonb;
  item text;
  allowed_prefix constant text := 'https://sbjkeyhihfypoieexfga.supabase.co/storage/v1/object/public/';
begin
  if auth.uid() is null or public.is_admin() then
    return new;
  end if;
  foreach field in array tg_argv loop
    value := to_jsonb(new) -> field;
    if tg_op = 'UPDATE' and value is not distinct from (to_jsonb(old) -> field) then
      continue;
    end if;
    if value is null or jsonb_typeof(value) = 'null' then
      continue;
    end if;
    for item in
      select x from jsonb_array_elements_text(
        case when jsonb_typeof(value) = 'array' then value else jsonb_build_array(value) end
      ) as x
    loop
      if item <> ''
         and item not like allowed_prefix || '%'
         and item not like 'https://lh3.googleusercontent.com/%' then
        raise exception 'inappropriate_image' using errcode = 'P0001';
      end if;
    end loop;
  end loop;
  return new;
end;
$$;

drop trigger if exists enforce_image_urls on public.listings;
create trigger enforce_image_urls
before insert or update on public.listings
for each row execute function public.enforce_image_urls('images');

drop trigger if exists enforce_image_urls on public.profiles;
create trigger enforce_image_urls
before insert or update on public.profiles
for each row execute function public.enforce_image_urls('photoUrl');

drop trigger if exists enforce_image_urls on public.services;
create trigger enforce_image_urls
before insert or update on public.services
for each row execute function public.enforce_image_urls('imageUrl');

drop trigger if exists enforce_image_urls on public.service_updates;
create trigger enforce_image_urls
before insert or update on public.service_updates
for each row execute function public.enforce_image_urls('imageUrl');

drop trigger if exists enforce_image_urls on public.exam_papers;
create trigger enforce_image_urls
before insert or update on public.exam_papers
for each row execute function public.enforce_image_urls('images');

-- 4) Reported content is hidden automatically once 3 different people report it.
alter table public.listings add column if not exists moderation_hidden boolean not null default false;
alter table public.services add column if not exists moderation_hidden boolean not null default false;

create or replace function public.protect_moderation_hidden()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null
     or public.is_admin()
     or current_setting('zankoswap.auto_moderation', true) = 'on' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.moderation_hidden := false;
  else
    new.moderation_hidden := old.moderation_hidden;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_moderation_hidden on public.listings;
create trigger protect_moderation_hidden
before insert or update on public.listings
for each row execute function public.protect_moderation_hidden();

drop trigger if exists protect_moderation_hidden on public.services;
create trigger protect_moderation_hidden
before insert or update on public.services
for each row execute function public.protect_moderation_hidden();

drop policy if exists "listings_public_read" on public.listings;
create policy "listings_public_read" on public.listings
for select to public
using (status = 'active' and moderation_hidden = false);

drop policy if exists "services_public_read" on public.services;
create policy "services_public_read" on public.services
for select to public
using (active = true and moderation_hidden = false);

create table if not exists public.content_reports (
  id bigint generated by default as identity primary key,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  content_type text not null check (content_type in ('listing', 'service', 'service_update')),
  content_id text not null,
  reason text not null check (reason in ('sexual', 'harassment', 'spam', 'other')),
  created_at timestamptz not null default now(),
  constraint content_reports_once unique (reporter_id, content_type, content_id)
);
alter table public.content_reports enable row level security;
drop policy if exists "content_reports_create_own" on public.content_reports;
create policy "content_reports_create_own" on public.content_reports
for insert to authenticated
with check (auth.uid() = reporter_id);

create or replace function public.hide_reported_content()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  reporters integer;
begin
  select count(distinct reporter_id) into reporters
  from public.content_reports
  where content_type = new.content_type and content_id = new.content_id;

  if reporters >= 3 then
    perform set_config('zankoswap.auto_moderation', 'on', true);
    if new.content_type = 'listing' then
      update public.listings set moderation_hidden = true where id::text = new.content_id;
    elsif new.content_type = 'service' then
      update public.services set moderation_hidden = true where id::text = new.content_id;
    elsif new.content_type = 'service_update' then
      delete from public.service_updates where id::text = new.content_id;
    end if;
    perform set_config('zankoswap.auto_moderation', 'off', true);
  end if;
  return new;
end;
$$;

drop trigger if exists hide_reported_content on public.content_reports;
create trigger hide_reported_content
after insert on public.content_reports
for each row execute function public.hide_reported_content();
