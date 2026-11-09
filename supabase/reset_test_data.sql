-- ZankoSwap: remove all test data before launch.
-- Deletes every listing, place, place update, research, exam paper, ad,
-- chat, message, report, block and saved item, all user-suggested
-- institutions still waiting for review, and every account except the
-- owner's. The real institution directory and the owner's account stay.
--
-- BEFORE running: empty the storage buckets in Supabase Dashboard -> Storage
-- (listing-images, profile-images, service-images, ad-receipts).
-- Run in Supabase Dashboard -> SQL Editor. This cannot be undone.

do $$
declare
  owner_email constant text := 'tahasulaiman135@gmail.com';
  owner_id uuid;
  tbl text;
begin
  select id into owner_id from auth.users where lower(email) = owner_email;
  if owner_id is null then
    raise exception 'Owner account % not found. Nothing was deleted.', owner_email;
  end if;

  foreach tbl in array array[
    'messages', 'chats', 'chat_notifications_sent', 'content_reports',
    'user_reports', 'user_blocks', 'service_updates', 'place_broadcasts',
    'services', 'listings', 'research', 'exam_papers', 'ad_campaigns',
    'saved_items', 'favorites'
  ] loop
    if to_regclass('public.' || tbl) is not null then
      execute format('truncate table public.%I restart identity cascade', tbl);
    end if;
  end loop;

  delete from public.institutions where active = false;

  if to_regclass('public.user_devices') is not null then
    delete from public.user_devices where user_id <> owner_id;
  end if;

  delete from public.profiles where id <> owner_id;
  delete from auth.users where id <> owner_id;
end $$;

select 'accounts' as item, count(*) as remaining from auth.users
union all select 'listings', count(*) from public.listings
union all select 'places', count(*) from public.services
union all select 'research', count(*) from public.research
union all select 'exam papers', count(*) from public.exam_papers
union all select 'ads', count(*) from public.ad_campaigns
union all select 'chats', count(*) from public.chats
union all select 'messages', count(*) from public.messages
union all select 'institutions', count(*) from public.institutions;
