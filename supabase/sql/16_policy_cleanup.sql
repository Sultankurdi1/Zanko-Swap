-- ZankoSwap policy cleanup.
-- Some tables and storage rules were created by hand in the dashboard and
-- allowed people without an account to write. This file removes every policy
-- on those places (whatever its name) and recreates only what the app needs.
-- Run in Supabase Dashboard -> SQL Editor. Safe to run more than once.
-- The last query lists every remaining policy so it can be checked.

-- 0) Two test rows created while checking these holes.
delete from public.research where "authorId" = '00000000-0000-0000-0000-00000000dead';
delete from public.exam_papers where "authorId" = '00000000-0000-0000-0000-00000000dead';

-- 1) Visitors without an account may read, never write.
revoke insert, update, delete on all tables in schema public from anon;

-- 2) Drop every policy on the affected tables and on storage.
do $$
declare
  policy record;
begin
  for policy in
    select schemaname, tablename, policyname from pg_policies
    where (schemaname = 'storage' and tablename = 'objects')
       or (schemaname = 'public' and tablename in ('research', 'exam_papers', 'profiles'))
  loop
    execute format('drop policy if exists %I on %I.%I', policy.policyname, policy.schemaname, policy.tablename);
  end loop;
end $$;

-- 3) Profiles: signed-in users see names and photos (email and phone stay
--    hidden by column grants); each person writes only their own row.
alter table public.profiles enable row level security;
create policy "profiles_read_authenticated" on public.profiles
for select to authenticated using (true);
create policy "profiles_insert_own" on public.profiles
for insert to authenticated with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles
for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- 4) Research and exam papers: everyone reads; only the signed-in author writes.
alter table public.research enable row level security;
create policy "research_public_read" on public.research
for select to public using (true);
create policy "research_insert_own" on public.research
for insert to authenticated with check (auth.uid() = "authorId");
create policy "research_update_own" on public.research
for update to authenticated
using (auth.uid() = "authorId" or public.is_admin())
with check (auth.uid() = "authorId" or public.is_admin());
create policy "research_delete_own" on public.research
for delete to authenticated using (auth.uid() = "authorId" or public.is_admin());

alter table public.exam_papers enable row level security;
create policy "exam_papers_public_read" on public.exam_papers
for select to public using (true);
create policy "exam_papers_insert_own" on public.exam_papers
for insert to authenticated with check (auth.uid() = "authorId");
create policy "exam_papers_update_own" on public.exam_papers
for update to authenticated
using (auth.uid() = "authorId" or public.is_admin())
with check (auth.uid() = "authorId" or public.is_admin());
create policy "exam_papers_delete_own" on public.exam_papers
for delete to authenticated using (auth.uid() = "authorId" or public.is_admin());

-- 5) Storage. Public image buckets: files are viewable by their public URL;
--    uploads go only through the moderate-upload Edge Function; owners can
--    list and delete their own folder.
create policy "public_images_read_own_folder" on storage.objects
for select to authenticated
using (
  bucket_id in ('listing-images', 'profile-images', 'service-images')
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "public_images_delete_own_folder" on storage.objects
for delete to authenticated
using (
  bucket_id in ('listing-images', 'profile-images', 'service-images')
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Private ad receipts: only the uploader and admins.
create policy "ad_receipts_insert_own" on storage.objects
for insert to authenticated
with check (bucket_id = 'ad-receipts' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "ad_receipts_read_own_or_admin" on storage.objects
for select to authenticated
using (
  bucket_id = 'ad-receipts'
  and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin())
);

create policy "ad_receipts_update_own" on storage.objects
for update to authenticated
using (bucket_id = 'ad-receipts' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'ad-receipts' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "ad_receipts_delete_own" on storage.objects
for delete to authenticated
using (bucket_id = 'ad-receipts' and (storage.foldername(name))[1] = auth.uid()::text);

select schemaname, tablename, policyname, cmd, roles::text as roles,
       coalesce(qual, '') as using_rule, coalesce(with_check, '') as check_rule
from pg_policies
where schemaname in ('public', 'storage')
order by schemaname, tablename, cmd, policyname;
