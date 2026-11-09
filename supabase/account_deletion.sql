-- ZankoSwap in-app account deletion (required by Google Play and the App Store).
-- Run once in Supabase Dashboard -> SQL Editor, after security_hardening_v3.sql.
-- Safe to run more than once.

drop policy if exists "ad_receipts_delete_own" on storage.objects;
create policy "ad_receipts_delete_own" on storage.objects
for delete to authenticated
using (bucket_id = 'ad-receipts' and (storage.foldername(name))[1] = auth.uid()::text);

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not signed in';
  end if;

  if to_regclass('public.messages') is not null then
    delete from public.messages where "senderId" = uid;
  end if;
  if to_regclass('public.chats') is not null then
    delete from public.chats where "buyerId" = uid or "sellerId" = uid;
  end if;
  if to_regclass('public.favorites') is not null then
    delete from public.favorites where "userId" = uid;
  end if;
  if to_regclass('public.service_updates') is not null then
    delete from public.service_updates where "ownerId" = uid;
  end if;
  if to_regclass('public.services') is not null then
    delete from public.services where "ownerId" = uid;
  end if;
  if to_regclass('public.listings') is not null then
    delete from public.listings where "sellerId" = uid;
  end if;
  if to_regclass('public.research') is not null then
    delete from public.research where "authorId" = uid;
  end if;
  if to_regclass('public.exam_papers') is not null then
    delete from public.exam_papers where "authorId" = uid;
  end if;
  if to_regclass('public.user_devices') is not null then
    delete from public.user_devices where user_id = uid;
  end if;
  if to_regclass('public.user_blocks') is not null then
    delete from public.user_blocks where blocker_id = uid or blocked_id = uid;
  end if;
  if to_regclass('public.place_broadcasts') is not null then
    delete from public.place_broadcasts where owner_id = uid;
  end if;
  delete from public.profiles where id = uid;
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
