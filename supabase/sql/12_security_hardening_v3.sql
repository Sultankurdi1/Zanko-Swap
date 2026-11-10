-- ZankoSwap security hardening, part 3.
-- Run once in Supabase Dashboard -> SQL Editor, after security_hardening_v2.sql.
-- Safe to run more than once.

-- 1) Chat ids must be the sorted pair of participants. Without this, a user
--    could pre-create the chat id of two other people with themselves as a
--    participant and read every message those two send each other.
delete from public.chats c
where c.id <> least(c."buyerId"::text, c."sellerId"::text) || '_' || greatest(c."buyerId"::text, c."sellerId"::text);

alter table public.chats drop constraint if exists chats_id_matches_participants;
alter table public.chats add constraint chats_id_matches_participants
  check (id = least("buyerId"::text, "sellerId"::text) || '_' || greatest("buyerId"::text, "sellerId"::text));

-- Removing a chat for both people is not part of the app (it hides chats per
-- participant instead), so nobody may wipe the other person's history.
drop policy if exists "chats_participant_delete" on public.chats;

-- 2) Service updates may only be moved between services the caller owns.
drop policy if exists "service_updates_update_owner" on public.service_updates;
create policy "service_updates_update_owner" on public.service_updates
for update to authenticated
using (auth.uid() = "ownerId")
with check (
  auth.uid() = "ownerId"
  and exists (select 1 from public.services s where s.id = "serviceId" and s."ownerId" = auth.uid())
);

-- 3) Institutions suggested by regular users wait for admin review before
--    everyone sees them, so nobody can publish fake entries or phishing links.
create or replace function public.institutions_pending_for_users()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    new.active := false;
  end if;
  return new;
end;
$$;

drop trigger if exists institutions_pending_for_users on public.institutions;
create trigger institutions_pending_for_users
before insert on public.institutions
for each row execute function public.institutions_pending_for_users();

drop policy if exists "institutions authenticated read" on public.institutions;
drop policy if exists "institutions_read_admin" on public.institutions;
create policy "institutions_read_admin" on public.institutions
for select to authenticated using (public.is_admin());

-- 4) Leftover read policy that exposed sold/hidden listings to every user.
drop policy if exists "listings public read" on public.listings;

-- 5) Server-only bookkeeping for push notifications. RLS is on and there are
--    no policies, so only the Edge Functions (service role) can use them.
create table if not exists public.chat_notifications_sent (
  message_id text primary key,
  sent_at timestamptz not null default now()
);
alter table public.chat_notifications_sent enable row level security;
revoke all on public.chat_notifications_sent from anon, authenticated;

create table if not exists public.place_broadcasts (
  service_id text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  sent_at timestamptz not null default now()
);
create index if not exists place_broadcasts_owner_sent_idx on public.place_broadcasts (owner_id, sent_at desc);
alter table public.place_broadcasts enable row level security;
revoke all on public.place_broadcasts from anon, authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    execute $sql$
      select cron.unschedule(jobid)
      from cron.job
      where jobname = 'zankoswap-trim-chat-notifications'
    $sql$;
    perform cron.schedule(
      'zankoswap-trim-chat-notifications',
      '30 3 * * *',
      $job$delete from public.chat_notifications_sent where sent_at < now() - interval '2 days'$job$
    );
  end if;
exception when others then
  raise notice 'Could not schedule notification cleanup.';
end $$;
