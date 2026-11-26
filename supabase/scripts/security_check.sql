-- ZankoSwap: read-only security check of the LIVE database.
-- Changes nothing. Run in Supabase Dashboard -> SQL Editor; every row it
-- returns is a problem to fix (no rows = all good).

-- 1) Tables anyone can reach without row-level security.
select 'RLS is OFF' as problem, c.relname as item
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity

union all
-- 2) Policies that let everybody do everything (often added by hand).
select 'Wide-open policy', tablename || ': ' || policyname
from pg_policies
where schemaname in ('public', 'storage')
  and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
  and (coalesce(qual, '') = 'true' or coalesce(with_check, '') = 'true')
  and not (tablename = 'institutions' and policyname = 'institutions_insert_authenticated')

union all
-- 3) Visitors without an account must never write.
select 'Guests can write', table_name || ' (' || privilege_type || ')'
from information_schema.role_table_grants
where table_schema = 'public' and grantee = 'anon'
  and privilege_type in ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')

union all
-- 4) Email and phone must stay hidden from other users.
select 'Email/phone visible to others', column_name
from information_schema.column_privileges
where table_schema = 'public' and table_name = 'profiles'
  and grantee in ('anon', 'authenticated') and privilege_type = 'SELECT'
  and column_name in ('email', 'phone', 'role')

union all
-- 5) Who is admin (should be only the owner).
select 'Admin account (check it is yours)', coalesce(u.email, p.id::text)
from public.profiles p left join auth.users u on u.id = p.id
where p.role = 'admin'

union all
-- 6) Private buckets must stay private.
select 'Bucket should be private', id
from storage.buckets
where id in ('ad-receipts', 'student-ids') and public = true;
