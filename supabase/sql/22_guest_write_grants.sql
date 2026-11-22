-- ZankoSwap: take every write permission away from visitors without an account.
-- The live security check found that guests (role "anon") still had TRUNCATE
-- on most tables, and full INSERT/UPDATE/DELETE on seller_ratings and
-- ad_prices (tables made after file 17, which got Supabase's default grants).
-- Row-level security already blocked these writes, so nothing was open, but
-- the permissions should not exist at all.
-- Run in Supabase Dashboard -> SQL Editor. Safe to run more than once.

revoke insert, update, delete, truncate on all tables in schema public from anon;
revoke truncate on all tables in schema public from authenticated;

-- Tables created later must not get these permissions either.
alter default privileges for role postgres in schema public
  revoke insert, update, delete, truncate on tables from anon;
alter default privileges for role postgres in schema public
  revoke truncate on tables from authenticated;

-- Should return no rows.
select table_name, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and (
    (grantee = 'anon' and privilege_type in ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE'))
    or (grantee = 'authenticated' and privilege_type = 'TRUNCATE')
  );
