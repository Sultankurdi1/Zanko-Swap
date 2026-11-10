-- ZankoSwap security hardening.
-- Run once in Supabase Dashboard -> SQL Editor, after all other migrations.
-- Safe to run more than once.

-- 1) Users must not be able to promote themselves to admin.
alter table public.profiles add column if not exists role text not null default 'user';

create or replace function public.protect_profile_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return new;
  end if;
  if coalesce((auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'admin' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.role := 'user';
  elsif new.role is distinct from old.role then
    new.role := old.role;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_profile_role on public.profiles;
create trigger protect_profile_role
before insert or update on public.profiles
for each row execute function public.protect_profile_role();

-- 2) Other users may only see name + photo, never email or phone.
revoke select on public.profiles from anon, authenticated;
grant select (id, "displayName", "photoUrl", "updatedAt") on public.profiles to authenticated;

create or replace function public.get_my_profile()
returns table (id uuid, email text, "displayName" text, phone text, "photoUrl" text)
language sql
stable
security definer
set search_path = public
as $$
  select p.id, p.email, p."displayName", p.phone, p."photoUrl"
  from public.profiles p
  where p.id = auth.uid();
$$;
revoke all on function public.get_my_profile() from public, anon;
grant execute on function public.get_my_profile() to authenticated;

-- 3) Ads: users can only submit pending ads; only admins approve them.
drop policy if exists "ads auth insert" on public.ad_campaigns;
drop policy if exists "ads authenticated insert" on public.ad_campaigns;
create policy "ads authenticated insert" on public.ad_campaigns
for insert to authenticated
with check (
  public.is_admin()
  or (status = 'pending' and is_active = false and views_count = 0 and clicks_count = 0)
);

create or replace function public.increment_ad_click(ad_id text)
returns void
language sql
security definer
set search_path = public
as $$
  update public.ad_campaigns
  set clicks_count = clicks_count + 1
  where id::text = ad_id
    and status in ('approved', 'active')
    and is_active = true;
$$;
revoke all on function public.increment_ad_click(text) from public;
grant execute on function public.increment_ad_click(text) to anon, authenticated;

-- 4) Institutions: anyone signed in may suggest one, only admins may edit.
drop policy if exists "institutions_insert_authenticated" on public.institutions;
create policy "institutions_insert_authenticated" on public.institutions
for insert to authenticated with check (true);

drop policy if exists "institutions_update_authenticated" on public.institutions;
drop policy if exists "institutions_update_admin" on public.institutions;
create policy "institutions_update_admin" on public.institutions
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

-- 5) Chat: a participant may mark messages as read but never rewrite the
--    other person's messages, and chat participants cannot be swapped.
create or replace function public.protect_message_update()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is null then
    return new;
  end if;
  if new."senderId" is distinct from old."senderId"
     or new."chatId" is distinct from old."chatId"
     or new."createdAt" is distinct from old."createdAt" then
    raise exception 'not allowed';
  end if;
  if auth.uid() <> old."senderId"
     and (new.text is distinct from old.text or new.type is distinct from old.type) then
    raise exception 'not allowed';
  end if;
  return new;
end;
$$;

drop trigger if exists protect_message_update on public.messages;
create trigger protect_message_update
before update on public.messages
for each row execute function public.protect_message_update();

create or replace function public.protect_chat_update()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is null then
    return new;
  end if;
  if new.id is distinct from old.id
     or new."buyerId" is distinct from old."buyerId"
     or new."sellerId" is distinct from old."sellerId" then
    raise exception 'not allowed';
  end if;
  return new;
end;
$$;

drop trigger if exists protect_chat_update on public.chats;
create trigger protect_chat_update
before update on public.chats
for each row execute function public.protect_chat_update();
