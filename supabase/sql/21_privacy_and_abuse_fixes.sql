-- ZankoSwap: privacy and abuse fixes from the November 2026 security review.
-- Run in Supabase Dashboard -> SQL Editor. Safe to run more than once.

-- 1) "Who blocked whom" and "who chatted with whom" were answerable for ANY
--    two people by any signed-in user. Now a person can only ask about
--    themselves. The chat and rating rules always pass the caller's own id,
--    so they keep working.
create or replace function public.chat_users_blocked(user_a uuid, user_b uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() in (user_a, user_b)
    and exists (
      select 1 from public.user_blocks b
      where (b.blocker_id = user_a and b.blocked_id = user_b)
         or (b.blocker_id = user_b and b.blocked_id = user_a)
    );
$$;
revoke all on function public.chat_users_blocked(uuid, uuid) from public;
grant execute on function public.chat_users_blocked(uuid, uuid) to authenticated;

create or replace function public.have_chatted(user_a uuid, user_b uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() in (user_a, user_b)
    and exists (
      select 1 from public.chats c
      where (c."buyerId" = user_a and c."sellerId" = user_b)
         or (c."buyerId" = user_b and c."sellerId" = user_a)
    );
$$;
revoke all on function public.have_chatted(uuid, uuid) from public, anon;
grant execute on function public.have_chatted(uuid, uuid) to authenticated;

-- 2) Research and exam papers had no blocked-words check (listings, places,
--    names and chat already do).
drop trigger if exists enforce_clean_text on public.research;
create trigger enforce_clean_text
before insert or update on public.research
for each row execute function public.enforce_clean_text('title', 'description', 'authorName', 'linkOrContent');

drop trigger if exists enforce_clean_text on public.exam_papers;
create trigger enforce_clean_text
before insert or update on public.exam_papers
for each row execute function public.enforce_clean_text('subject', 'content', 'authorName');

-- 3) Research links: no javascript:, data: or other dangerous link types.
create or replace function public.enforce_safe_research_link()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  value text;
begin
  foreach value in array array[
    coalesce(to_jsonb(new) ->> 'linkOrContent', ''),
    coalesce(to_jsonb(new) ->> 'file_url', '')
  ] loop
    if btrim(value) ~* '^(javascript|data|vbscript|file|intent|blob)\s*:' then
      raise exception 'inappropriate_content' using errcode = 'P0001';
    end if;
  end loop;
  return new;
end;
$$;

drop trigger if exists enforce_safe_research_link on public.research;
create trigger enforce_safe_research_link
before insert or update on public.research
for each row execute function public.enforce_safe_research_link();

select 'done' as result;
