-- Run this migration in the Supabase SQL Editor to enable message deletion
-- and remove conversations after 24 hours without activity.

alter table public.chats add column if not exists "lastSenderId" uuid references auth.users(id) on delete set null;
alter table public.chats add column if not exists "isRead" boolean not null default true;
alter table public.chats add column if not exists "lastMessageAt" timestamptz;
update public.chats
set "lastMessageAt" = coalesce("lastMessageAt", "updatedAt", now());

drop policy if exists "messages_sender_delete" on public.messages;
create policy "messages_sender_delete"
on public.messages for delete to authenticated
using (auth.uid() = "senderId");

-- Allow either participant to remove a conversation from both inboxes.
-- The messages table references chats with ON DELETE CASCADE.
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
