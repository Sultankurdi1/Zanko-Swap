-- ZankoSwap: real place locations, research PDFs, listing prices and the 13+ age check.
-- Run in Supabase Dashboard -> SQL Editor. Safe to run more than once.

-- 1) Research: the columns the app saves, and the author is always the signed-in user.
alter table public.research add column if not exists "authorName" text not null default '';
alter table public.research add column if not exists description text not null default '';
alter table public.research add column if not exists "universityId" text not null default '';
alter table public.research add column if not exists "universityName" text not null default '';
alter table public.research add column if not exists "collegeId" text not null default '';
alter table public.research add column if not exists "departmentId" text not null default '';
alter table public.research alter column "authorId" set default auth.uid();

-- 2) Research PDF storage: public to read, PDF only, 20 MB each,
--    each person uploads only into their own folder, at most 50 files.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('research-files', 'research-files', true, 20971520, array['application/pdf'])
on conflict (id) do update
set public = true,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.my_research_file_count()
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::integer from storage.objects
  where bucket_id = 'research-files'
    and (storage.foldername(name))[1] = auth.uid()::text;
$$;
revoke all on function public.my_research_file_count() from public, anon;
grant execute on function public.my_research_file_count() to authenticated;

drop policy if exists "research_files_insert_own" on storage.objects;
create policy "research_files_insert_own" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'research-files'
  and (storage.foldername(name))[1] = auth.uid()::text
  and lower(storage.extension(name)) = 'pdf'
  and public.my_research_file_count() < 50
);

drop policy if exists "research_files_read_own_folder" on storage.objects;
create policy "research_files_read_own_folder" on storage.objects
for select to authenticated
using (bucket_id = 'research-files' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "research_files_delete_own" on storage.objects;
create policy "research_files_delete_own" on storage.objects
for delete to authenticated
using (
  bucket_id = 'research-files'
  and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin())
);

-- 3) Places must be pinned on the map when they are added.
create or replace function public.require_service_location()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.latitude is null or new.longitude is null
     or new.latitude not between -90 and 90
     or new.longitude not between -180 and 180 then
    raise exception 'location_required' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists require_service_location on public.services;
create trigger require_service_location
before insert on public.services
for each row execute function public.require_service_location();

-- 4) A listing "for a price" must have a real price.
create or replace function public.require_listing_price()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new."transactionType" = 'price' and coalesce(new."priceIQD", 0) <= 0 then
    raise exception 'price_required' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists require_listing_price on public.listings;
create trigger require_listing_price
before insert or update of "priceIQD", "transactionType" on public.listings
for each row execute function public.require_listing_price();

-- 5) Age check: one private row per account. Never shown to other people.
create table if not exists public.age_checks (
  user_id uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  birth_date date not null,
  created_at timestamptz not null default now()
);

alter table public.age_checks enable row level security;
revoke all on public.age_checks from anon;
grant select, insert, update on public.age_checks to authenticated;

drop policy if exists "age_checks_read_own" on public.age_checks;
create policy "age_checks_read_own" on public.age_checks
for select to authenticated using (user_id = auth.uid());

drop policy if exists "age_checks_insert_own" on public.age_checks;
create policy "age_checks_insert_own" on public.age_checks
for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "age_checks_update_own" on public.age_checks;
create policy "age_checks_update_own" on public.age_checks
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create or replace function public.enforce_minimum_age()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.birth_date < date '1900-01-01' or new.birth_date > current_date then
    raise exception 'invalid_birth_date' using errcode = 'P0001';
  end if;
  if new.birth_date > (current_date - interval '13 years')::date then
    raise exception 'too_young' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_minimum_age on public.age_checks;
create trigger enforce_minimum_age
before insert or update on public.age_checks
for each row execute function public.enforce_minimum_age();

select 'done' as result;
