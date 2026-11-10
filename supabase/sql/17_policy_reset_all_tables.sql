-- ZankoSwap full table policy reset.
-- Hand-made dashboard policies such as "Allow all on messages for
-- authenticated" let any signed-in user read every chat and approve ads.
-- This removes EVERY policy on every table in the public schema and recreates
-- only the rules the app needs. Run after policy_cleanup.sql.
-- Run in Supabase Dashboard -> SQL Editor. Safe to run more than once.

do $$
declare
  policy record;
begin
  for policy in
    select tablename, policyname from pg_policies where schemaname = 'public'
  loop
    execute format('drop policy if exists %I on public.%I', policy.policyname, policy.tablename);
  end loop;
end $$;

revoke insert, update, delete on all tables in schema public from anon;

-- Profiles
create policy "profiles_read_authenticated" on public.profiles
for select to authenticated using (true);
create policy "profiles_insert_own" on public.profiles
for insert to authenticated with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles
for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Listings
create policy "listings_public_read" on public.listings
for select to public using (status = 'active' and moderation_hidden = false);
create policy "listings_owner_read" on public.listings
for select to authenticated using (auth.uid() = "sellerId" or public.is_admin());
create policy "listings_insert_own" on public.listings
for insert to authenticated with check (auth.uid() = "sellerId");
create policy "listings_update_own" on public.listings
for update to authenticated
using (auth.uid() = "sellerId" or public.is_admin())
with check (auth.uid() = "sellerId" or public.is_admin());
create policy "listings_delete_own" on public.listings
for delete to authenticated using (auth.uid() = "sellerId" or public.is_admin());

-- Places
create policy "services_public_read" on public.services
for select to public using (active = true and moderation_hidden = false);
create policy "services_owner_read" on public.services
for select to authenticated using (auth.uid() = "ownerId" or public.is_admin());
create policy "services_insert_own" on public.services
for insert to authenticated with check (auth.uid() = "ownerId");
create policy "services_update_own" on public.services
for update to authenticated
using (auth.uid() = "ownerId" or public.is_admin())
with check (auth.uid() = "ownerId" or public.is_admin());
create policy "services_delete_own" on public.services
for delete to authenticated using (auth.uid() = "ownerId" or public.is_admin());

-- Place updates
create policy "service_updates_public_read" on public.service_updates
for select to public using (true);
create policy "service_updates_insert_owner" on public.service_updates
for insert to authenticated
with check (
  auth.uid() = "ownerId"
  and exists (select 1 from public.services s where s.id = "serviceId" and s."ownerId" = auth.uid())
);
create policy "service_updates_update_owner" on public.service_updates
for update to authenticated
using (auth.uid() = "ownerId")
with check (
  auth.uid() = "ownerId"
  and exists (select 1 from public.services s where s.id = "serviceId" and s."ownerId" = auth.uid())
);
create policy "service_updates_delete_owner" on public.service_updates
for delete to authenticated using (auth.uid() = "ownerId" or public.is_admin());

-- Research and exam papers
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

-- Institutions (user suggestions are held for review by a trigger)
create policy "institutions_read_active" on public.institutions
for select to public using (active = true);
create policy "institutions_read_admin" on public.institutions
for select to authenticated using (public.is_admin());
create policy "institutions_insert_authenticated" on public.institutions
for insert to authenticated with check (true);
create policy "institutions_update_admin" on public.institutions
for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "institutions_delete_admin" on public.institutions
for delete to authenticated using (public.is_admin());

-- Ads: anyone sees running ads; users only submit pending ads; admins manage.
create policy "ads_public_active_read" on public.ad_campaigns
for select to anon, authenticated
using (
  public.is_admin()
  or (status in ('approved', 'active') and is_active = true and end_date > now())
);
create policy "ads_authenticated_insert" on public.ad_campaigns
for insert to authenticated
with check (
  public.is_admin()
  or (status = 'pending' and is_active = false and views_count = 0 and clicks_count = 0)
);
create policy "ads_admin_update" on public.ad_campaigns
for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "ads_admin_delete" on public.ad_campaigns
for delete to authenticated using (public.is_admin());

-- Chats: only the two participants.
create policy "chats_participants_read" on public.chats
for select to authenticated using (auth.uid() = "buyerId" or auth.uid() = "sellerId");
create policy "chats_participants_insert" on public.chats
for insert to authenticated with check (auth.uid() = "buyerId" or auth.uid() = "sellerId");
create policy "chats_participants_update" on public.chats
for update to authenticated
using (auth.uid() = "buyerId" or auth.uid() = "sellerId")
with check (auth.uid() = "buyerId" or auth.uid() = "sellerId");

-- Messages: only participants read; the sender writes; blocked pairs cannot write.
create policy "messages_participants_read" on public.messages
for select to authenticated
using (exists (
  select 1 from public.chats c
  where c.id = "chatId" and (auth.uid() = c."buyerId" or auth.uid() = c."sellerId")
));
create policy "messages_participants_insert" on public.messages
for insert to authenticated
with check (
  auth.uid() = "senderId"
  and exists (
    select 1 from public.chats c
    where c.id = "chatId"
      and (auth.uid() = c."buyerId" or auth.uid() = c."sellerId")
      and not public.chat_users_blocked(c."buyerId", c."sellerId")
  )
);
create policy "messages_participants_update" on public.messages
for update to authenticated
using (exists (
  select 1 from public.chats c
  where c.id = "chatId" and (auth.uid() = c."buyerId" or auth.uid() = c."sellerId")
))
with check (exists (
  select 1 from public.chats c
  where c.id = "chatId" and (auth.uid() = c."buyerId" or auth.uid() = c."sellerId")
));
create policy "messages_sender_delete" on public.messages
for delete to authenticated using (auth.uid() = "senderId");

-- Blocks and reports
create policy "user_blocks_read_own" on public.user_blocks
for select to authenticated using (auth.uid() = blocker_id);
create policy "user_blocks_create_own" on public.user_blocks
for insert to authenticated with check (auth.uid() = blocker_id and blocker_id <> blocked_id);
create policy "user_blocks_delete_own" on public.user_blocks
for delete to authenticated using (auth.uid() = blocker_id);

create policy "user_reports_create_own" on public.user_reports
for insert to authenticated with check (auth.uid() = reporter_id and reporter_id <> reported_user_id);

create policy "content_reports_create_own" on public.content_reports
for insert to authenticated with check (auth.uid() = reporter_id);

-- Devices and saved items
create policy "users_manage_own_fcm_devices" on public.user_devices
for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

do $$
begin
  if to_regclass('public.saved_items') is not null then
    execute 'create policy "saved_items_own" on public.saved_items for all to authenticated using (auth.uid() = "userId") with check (auth.uid() = "userId")';
  end if;
end $$;

select tablename, policyname, cmd, roles::text as roles
from pg_policies
where schemaname = 'public'
order by tablename, cmd, policyname;
