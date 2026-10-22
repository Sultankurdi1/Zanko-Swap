-- Run this migration in the Supabase SQL Editor to enable message deletion
-- and remove conversations after 24 hours without activity.

alter table public.chats add column if not exists "lastSenderId" uuid references auth.users(id) on delete set null;
alter table public.chats add column if not exists "isRead" boolean not null default true;
alter table public.chats add column if not exists "lastMessageAt" timestamptz;
alter table public.chats add column if not exists "hiddenForBuyer" boolean not null default false;
alter table public.chats add column if not exists "hiddenForSeller" boolean not null default false;
update public.chats
set "lastMessageAt" = coalesce("lastMessageAt", "updatedAt", now());

-- Collapse the old per-listing conversations into one conversation per pair.
-- Preserve all messages and keep the most recently active chat's preview.
with normalized as (
  select
    c.*,
    least(c."buyerId"::text, c."sellerId"::text) as low_id,
    greatest(c."buyerId"::text, c."sellerId"::text) as high_id,
    coalesce(c."lastMessageAt", c."updatedAt", now()) as activity_at
  from public.chats c
), latest as (
  select distinct on (low_id, high_id) *
  from normalized
  order by low_id, high_id, activity_at desc
), visibility as (
  select
    low_id,
    high_id,
    bool_or(case when "buyerId"::text = low_id then "hiddenForBuyer" else "hiddenForSeller" end) as hidden_low,
    bool_or(case when "buyerId"::text = high_id then "hiddenForBuyer" else "hiddenForSeller" end) as hidden_high
  from normalized
  group by low_id, high_id
)
insert into public.chats (
  id, "buyerId", "sellerId", "listingId", "lastMessage", "lastMessageAt",
  "updatedAt", "lastSenderId", "isRead", "hiddenForBuyer", "hiddenForSeller"
)
select
  latest.low_id || '_' || latest.high_id,
  latest.low_id::uuid,
  latest.high_id::uuid,
  latest."listingId",
  latest."lastMessage",
  latest."lastMessageAt",
  latest."updatedAt",
  latest."lastSenderId",
  latest."isRead",
  visibility.hidden_low,
  visibility.hidden_high
from latest
join visibility using (low_id, high_id)
on conflict (id) do update set
  "buyerId" = excluded."buyerId",
  "sellerId" = excluded."sellerId",
  "listingId" = excluded."listingId",
  "lastMessage" = excluded."lastMessage",
  "lastMessageAt" = excluded."lastMessageAt",
  "updatedAt" = excluded."updatedAt",
  "lastSenderId" = excluded."lastSenderId",
  "isRead" = excluded."isRead",
  "hiddenForBuyer" = excluded."hiddenForBuyer",
  "hiddenForSeller" = excluded."hiddenForSeller";

update public.messages m
set "chatId" = least(c."buyerId"::text, c."sellerId"::text) || '_' || greatest(c."buyerId"::text, c."sellerId"::text)
from public.chats c
where m."chatId" = c.id
  and c.id <> least(c."buyerId"::text, c."sellerId"::text) || '_' || greatest(c."buyerId"::text, c."sellerId"::text);

delete from public.chats c
where c.id <> least(c."buyerId"::text, c."sellerId"::text) || '_' || greatest(c."buyerId"::text, c."sellerId"::text);

drop policy if exists "messages_sender_delete" on public.messages;
create policy "messages_sender_delete"
on public.messages for delete to authenticated
using (auth.uid() = "senderId");

-- Chat deletion is per participant. The row and messages remain available to
-- the other participant, while the existing 24-hour cleanup removes inactive
-- conversations for both participants.
drop policy if exists "chats_participant_delete" on public.chats;
create policy "chats_participant_delete"
on public.chats for delete to authenticated
using (auth.uid() = "buyerId" or auth.uid() = "sellerId");

-- Keep inbox badges and conversation previews current through Supabase Realtime.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'messages'
    ) then
      alter publication supabase_realtime add table public.messages;
    end if;
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'chats'
    ) then
      alter publication supabase_realtime add table public.chats;
    end if;
  end if;
end $$;

-- Supabase projects commonly provide pg_cron. The rest of the migration still
-- works if it is unavailable; in that case schedule this DELETE in the
-- Supabase dashboard using a daily database job.
do $$
begin
  create extension if not exists pg_cron;
exception when others then
  raise notice 'pg_cron is unavailable; schedule the cleanup query manually.';
end $$;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    execute $sql$
      select cron.unschedule(jobid)
      from cron.job
      where jobname = 'zankoswap-expire-inactive-chats'
    $sql$;
    perform cron.schedule(
      'zankoswap-expire-inactive-chats',
      '0 * * * *',
      $job$delete from public.chats where coalesce("lastMessageAt", "updatedAt") < now() - interval '24 hours'$job$
    );
  end if;
exception when others then
  raise notice 'Could not schedule chat cleanup; schedule the DELETE query manually.';
end $$;
