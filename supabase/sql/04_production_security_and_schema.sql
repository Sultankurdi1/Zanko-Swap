-- ZankoSwap production schema/RLS patch
-- Run after the base schema + content_and_privacy_migration.sql.
-- This migration is idempotent and preserves the app's existing camelCase columns.

create extension if not exists pgcrypto;

-- Roles used by the UI and RLS. Admins are still authenticated users; the
-- trusted role is stored in app_metadata by a server-side/admin workflow.
alter table public.profiles add column if not exists role text not null default 'user';

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
  or coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin';
$$;

-- Public browsing for guest mode.
drop policy if exists "institutions_public_read" on public.institutions;
create policy "institutions_public_read" on public.institutions for select to public using (active = true);

drop policy if exists "listings_read" on public.listings;
drop policy if exists "listings_public_read" on public.listings;
create policy "listings_public_read" on public.listings
for select to public using (status = 'active');

drop policy if exists "services_read_active" on public.services;
drop policy if exists "services_public_read" on public.services;
create policy "services_public_read" on public.services
for select to public using (active = true);

drop policy if exists "research_public_read" on public.research;
create policy "research_public_read" on public.research
for select to public using (true);

drop policy if exists "exam_papers_public_read" on public.exam_papers;
create policy "exam_papers_public_read" on public.exam_papers
for select to public using (true);

-- Service contact/navigation metadata.
alter table public.services add column if not exists phone text not null default '';
alter table public.services add column if not exists "menuUrl" text not null default '';
alter table public.services add column if not exists "copyPrice" text not null default '';
alter table public.services add column if not exists latitude double precision;
alter table public.services add column if not exists longitude double precision;

-- Ownership-based writes + admin moderation.
drop policy if exists "listings_update_own" on public.listings;
create policy "listings_update_own" on public.listings
for update to authenticated
using (auth.uid() = "sellerId" or public.is_admin())
with check (auth.uid() = "sellerId" or public.is_admin());

drop policy if exists "listings_delete_own" on public.listings;
create policy "listings_delete_own" on public.listings
for delete to authenticated
using (auth.uid() = "sellerId" or public.is_admin());

drop policy if exists "services_update_own" on public.services;
create policy "services_update_own" on public.services
for update to authenticated
using (auth.uid() = "ownerId" or public.is_admin())
with check (auth.uid() = "ownerId" or public.is_admin());

drop policy if exists "services_delete_own" on public.services;
create policy "services_delete_own" on public.services
for delete to authenticated
using (auth.uid() = "ownerId" or public.is_admin());

drop policy if exists "research_update_own" on public.research;
create policy "research_update_own" on public.research
for update to authenticated
using (auth.uid() = "authorId" or public.is_admin())
with check (auth.uid() = "authorId" or public.is_admin());

drop policy if exists "research_delete_own" on public.research;
create policy "research_delete_own" on public.research
for delete to authenticated
using (auth.uid() = "authorId" or public.is_admin());

drop policy if exists "exam_papers_update_own" on public.exam_papers;
create policy "exam_papers_update_own" on public.exam_papers
for update to authenticated
using (auth.uid() = "authorId" or public.is_admin())
with check (auth.uid() = "authorId" or public.is_admin());

drop policy if exists "exam_papers_delete_own" on public.exam_papers;
create policy "exam_papers_delete_own" on public.exam_papers
for delete to authenticated
using (auth.uid() = "authorId" or public.is_admin());

-- Canonical content columns. Flutter writes these exact names.
alter table public.research add column if not exists stage text not null default '';
alter table public.research add column if not exists file_url text not null default '';
do $$ begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='research' and column_name='stage' and data_type <> 'text') then
    alter table public.research alter column stage type text using stage::text;
  end if;
end $$;
alter table public.research add column if not exists "authorId" uuid;
alter table public.research add column if not exists "createdAt" timestamptz not null default now();

alter table public.exam_papers add column if not exists images text[] not null default '{}';
alter table public.exam_papers add column if not exists "authorId" uuid;
alter table public.exam_papers add column if not exists "createdAt" timestamptz not null default now();

-- Optional compatibility conversion from snake_case columns when older tables exist.
do $$ begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='research' and column_name='author_id') then
    update public.research set "authorId" = author_id where "authorId" is null;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='research' and column_name='created_at') then
    update public.research set "createdAt" = created_at where "createdAt" is null;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='exam_papers' and column_name='author_id') then
    update public.exam_papers set "authorId" = author_id where "authorId" is null;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='exam_papers' and column_name='created_at') then
    update public.exam_papers set "createdAt" = created_at where "createdAt" is null;
  end if;
end $$;

-- Make the three service categories explicit without changing old data.
update public.services set type = 'copy' where lower(type) in ('copy shop','copyshop','stationery','stationary','کۆپی','پەراوگە');
update public.services set type = 'restaurant' where lower(type) in ('restaurant','restaurants','خواردنگە','چێشتخانە');
update public.services set type = 'cafe' where lower(type) in ('cafe','cafes','کافێ');


-- Storage buckets used by the Flutter upload services.
insert into storage.buckets (id, name, public) values ('listing-images', 'listing-images', true) on conflict (id) do update set public = true;
insert into storage.buckets (id, name, public) values ('service-images', 'service-images', true) on conflict (id) do update set public = true;
insert into storage.buckets (id, name, public) values ('profile-images', 'profile-images', true) on conflict (id) do update set public = true;

alter table storage.objects enable row level security;
drop policy if exists "service_images_public_read" on storage.objects;
create policy "service_images_public_read" on storage.objects for select to public using (bucket_id = 'service-images');
drop policy if exists "service_images_insert_own" on storage.objects;
create policy "service_images_insert_own" on storage.objects for insert to authenticated with check (bucket_id = 'service-images' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "service_images_delete_own" on storage.objects;
create policy "service_images_delete_own" on storage.objects for delete to authenticated using (bucket_id = 'service-images' and (storage.foldername(name))[1] = auth.uid()::text);

-- Realtime is useful for instant UI updates after deletes/inserts.
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='listings') then alter publication supabase_realtime add table public.listings; end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='services') then alter publication supabase_realtime add table public.services; end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='research') then alter publication supabase_realtime add table public.research; end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='exam_papers') then alter publication supabase_realtime add table public.exam_papers; end if;
exception when undefined_object then null;
end $$;
