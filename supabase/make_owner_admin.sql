-- ZankoSwap: make the owner's account an admin.
-- Sets the role both in the sign-in token (app_metadata, read by the app)
-- and in public.profiles (read by the database rules through is_admin()).
-- Run in Supabase Dashboard -> SQL Editor, then sign out and back in on the
-- phone so the app picks up the new role.

do $$
declare
  owner_email constant text := 'tahasulaiman135@gmail.com';
  owner_id uuid;
begin
  select id into owner_id from auth.users where lower(email) = owner_email;
  if owner_id is null then
    raise exception 'Account % not found. Sign up in the app first.', owner_email;
  end if;

  update auth.users
  set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role": "admin"}'::jsonb
  where id = owner_id;

  insert into public.profiles (id, email, role)
  values (owner_id, owner_email, 'admin')
  on conflict (id) do update set role = 'admin';
end $$;

select u.email,
       u.raw_app_meta_data ->> 'role' as app_role,
       p.role as profile_role
from auth.users u
left join public.profiles p on p.id = u.id
where p.role = 'admin' or u.raw_app_meta_data ->> 'role' = 'admin';
