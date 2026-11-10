-- ============================================================
-- Fix: show real name + avatar of the other user in chats
-- Run this entire file once in Supabase Dashboard -> SQL Editor.
-- ============================================================

-- 1) Every signed-in user may READ all profiles (needed to show
--    the other person's name and avatar in the inbox / chat).
--    Writing stays limited to your own row.
drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles own select" on public.profiles;
create policy "profiles_read_authenticated"
on public.profiles for select
to authenticated
using (true);

-- 2) Make sure every new user automatically gets a profile row
--    created from the signup metadata (displayName / photoUrl).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, "displayName", "photoUrl")
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'displayName',
             new.raw_user_meta_data->>'display_name',
             new.raw_user_meta_data->>'full_name',
             new.raw_user_meta_data->>'name',
             split_part(coalesce(new.email, ''), '@', 1),
             'Student'),
    coalesce(new.raw_user_meta_data->>'photoUrl',
             new.raw_user_meta_data->>'picture',
             new.raw_user_meta_data->>'avatar_url')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- 3) Backfill: create profile rows for users that already exist
--    (e.g. signed up before this fix, Google sign-in users).
insert into public.profiles (id, email, "displayName", "photoUrl")
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data->>'displayName',
           u.raw_user_meta_data->>'display_name',
           u.raw_user_meta_data->>'full_name',
           u.raw_user_meta_data->>'name',
           split_part(coalesce(u.email, ''), '@', 1),
           'Student'),
  coalesce(u.raw_user_meta_data->>'photoUrl',
           u.raw_user_meta_data->>'picture',
           u.raw_user_meta_data->>'avatar_url')
from auth.users u
on conflict (id) do update
  set "displayName" = coalesce(nullif(public.profiles."displayName", ''),
                               excluded."displayName"),
      email = coalesce(nullif(public.profiles.email, ''), excluded.email),
      "photoUrl" = coalesce(public.profiles."photoUrl", excluded."photoUrl");

-- 4) Also refresh name/photo for Google users whose metadata holds
--    'name' / 'picture' but whose profile row is still empty/default.
update public.profiles p
set "displayName" = u.raw_user_meta_data->>'name',
    "photoUrl" = coalesce(p."photoUrl", u.raw_user_meta_data->>'picture')
from auth.users u
where p.id = u.id
  and (p."displayName" is null or p."displayName" in ('', 'Student', 'قوتابی'))
  and coalesce(u.raw_user_meta_data->>'name', '') <> '';
