-- ZankoSwap content moderation: block sexual, abusive and threatening words
-- in chat, profile names, listings and places, and stop chat item cards from
-- carrying images hosted outside the app.
-- Run once in Supabase Dashboard -> SQL Editor, after account_deletion.sql.
-- Safe to run more than once. Add more words later in Table Editor -> blocked_terms.

create or replace function public.moderation_tokens(input text)
returns text[]
language plpgsql
immutable
set search_path = public
as $$
declare
  s text := lower(coalesce(input, ''));
  parts text[];
  tok text;
  buf text := '';
  result text[] := '{}';
begin
  s := regexp_replace(s, '[​-‏‪-‮⁦-⁩﻿ـً-ٰٟ]', '', 'g');
  s := translate(s,
    'يىێكةەھأإآٱؤۆڵڕ01345@$ئ',
    'یییکهههااااوولرoieasas');
  s := regexp_replace(s, '(.)\1+', '\1', 'g');
  parts := regexp_split_to_array(s, '[\s\-_.,!?:;"''`()\[\]{}/\\|*+=~^&%#<>،؛؟«»…]+');
  foreach tok in array parts loop
    if tok = '' then
      continue;
    end if;
    if char_length(tok) = 1 then
      buf := buf || tok;
    else
      if char_length(buf) > 1 then
        result := result || buf;
      end if;
      buf := '';
      result := result || tok;
    end if;
  end loop;
  if char_length(buf) > 1 then
    result := result || buf;
  end if;
  return result;
end;
$$;

create table if not exists public.blocked_terms (
  term text primary key,
  match text not null default 'contains' check (match in ('contains', 'word', 'phrase')),
  normalized text not null default ''
);
alter table public.blocked_terms enable row level security;
revoke all on public.blocked_terms from anon, authenticated;

create or replace function public.blocked_terms_normalize()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.normalized := array_to_string(public.moderation_tokens(new.term), ' ');
  return new;
end;
$$;

drop trigger if exists blocked_terms_normalize on public.blocked_terms;
create trigger blocked_terms_normalize
before insert or update on public.blocked_terms
for each row execute function public.blocked_terms_normalize();

insert into public.blocked_terms (term, match) values
  ('sexy', 'contains'), ('sexual', 'contains'), ('fuck', 'contains'), ('porn', 'contains'), ('pussy', 'contains'),
  ('blowjob', 'contains'), ('handjob', 'contains'), ('horny', 'contains'), ('nude', 'contains'),
  ('boob', 'contains'), ('whore', 'contains'), ('slut', 'contains'), ('bitch', 'contains'),
  ('dildo', 'contains'), ('orgasm', 'contains'), ('masturbat', 'contains'), ('cunt', 'contains'),
  ('asshole', 'contains'), ('nigger', 'contains'), ('faggot', 'contains'), ('qahba', 'contains'),
  ('qehbe', 'contains'),
  ('sex', 'word'), ('dick', 'word'), ('cock', 'word'), ('tits', 'word'), ('rape', 'word'), ('rapist', 'word'),
  ('cum', 'word'), ('anal', 'word'), ('nsfw', 'word'), ('fag', 'word'),
  ('kir', 'word'), ('kos', 'word'), ('qun', 'word'),
  ('kill you', 'phrase'), ('i will kill', 'phrase'), ('rape you', 'phrase'),

  ('سێکس', 'contains'), ('سیکس', 'contains'), ('پۆرن', 'contains'), ('قەحبە', 'contains'),
  ('گاندن', 'contains'), ('بگێم', 'contains'), ('دەیگێم', 'contains'), ('دەتگێم', 'contains'),
  ('بیگێم', 'contains'), ('قونەدەر', 'contains'), ('بێناموس', 'contains'), ('بێشەرەف', 'contains'),
  ('سەگباب', 'contains'), ('دەتکوژم', 'contains'), ('بتکوژم', 'contains'), ('دەتسوتێنم', 'contains'),
  ('کیر', 'word'), ('کیرم', 'word'), ('کیرت', 'word'), ('کیری', 'word'), ('کیرە', 'word'),
  ('کوس', 'word'), ('کوسی', 'word'), ('کوست', 'word'), ('قوز', 'word'), ('قون', 'word'),
  ('قونت', 'word'), ('حیز', 'word'), ('حیزە', 'word'), ('زۆڵ', 'word'),
  ('سەرت دەبڕم', 'phrase'),

  ('سكس', 'contains'), ('منيوك', 'contains'), ('منيوج', 'contains'), ('متناك', 'contains'),
  ('شرموط', 'contains'), ('عاهر', 'contains'), ('قحبة', 'contains'), ('كحبة', 'contains'),
  ('كسمك', 'contains'), ('لوطي', 'contains'), ('اباحي', 'contains'), ('اقتلك', 'contains'),
  ('اكتلك', 'contains'), ('اذبحك', 'contains'), ('اغتصبك', 'contains'),
  ('نيك', 'word'), ('انيك', 'word'), ('انيكك', 'word'), ('انيجك', 'word'), ('نيجني', 'word'),
  ('ينيك', 'word'), ('نيكني', 'word'), ('زب', 'word'), ('زبي', 'word'), ('كس', 'word'),
  ('كسك', 'word'), ('طيز', 'word'), ('طيزك', 'word'), ('خول', 'word'),
  ('كس امك', 'phrase')
on conflict (term) do update set match = excluded.match;

delete from public.blocked_terms where term = 'xxx';

update public.blocked_terms set normalized = array_to_string(public.moderation_tokens(term), ' ');

create or replace function public.contains_blocked_terms(input text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  tokens text[];
  spaced text;
begin
  if input is null or btrim(input) = '' then
    return false;
  end if;
  tokens := public.moderation_tokens(input);
  if coalesce(array_length(tokens, 1), 0) = 0 then
    return false;
  end if;
  spaced := ' ' || array_to_string(tokens, ' ') || ' ';
  return exists (
    select 1
    from public.blocked_terms t
    where t.normalized <> ''
      and (
        (t.match = 'word' and t.normalized = any (tokens))
        or (t.match = 'phrase' and position(' ' || t.normalized || ' ' in spaced) > 0)
        or (t.match = 'contains' and exists (
          select 1 from unnest(tokens) as tok where position(t.normalized in tok) > 0
        ))
      )
  );
end;
$$;
revoke all on function public.contains_blocked_terms(text) from public, anon, authenticated;

create or replace function public.enforce_clean_text()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  field text;
  value text;
begin
  if auth.uid() is null or public.is_admin() then
    return new;
  end if;
  foreach field in array tg_argv loop
    value := to_jsonb(new) ->> field;
    if tg_op = 'UPDATE' and value is not distinct from (to_jsonb(old) ->> field) then
      continue;
    end if;
    if public.contains_blocked_terms(value) then
      raise exception 'inappropriate_content' using errcode = 'P0001';
    end if;
  end loop;
  return new;
end;
$$;

create or replace function public.enforce_message_shape()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  card jsonb;
  image text;
begin
  if auth.uid() is null then
    return new;
  end if;
  if new.type not in ('text', 'item_card') then
    raise exception 'inappropriate_content' using errcode = 'P0001';
  end if;
  if new.type = 'item_card' then
    begin
      card := new.text::jsonb;
    exception when others then
      raise exception 'inappropriate_content' using errcode = 'P0001';
    end;
    image := coalesce(card ->> 'image', '');
    if image <> '' and image not like 'https://sbjkeyhihfypoieexfga.supabase.co/storage/v1/object/public/listing-images/%' then
      raise exception 'inappropriate_content' using errcode = 'P0001';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_message_shape on public.messages;
create trigger enforce_message_shape
before insert or update on public.messages
for each row execute function public.enforce_message_shape();

drop trigger if exists enforce_clean_text on public.messages;
create trigger enforce_clean_text
before insert or update on public.messages
for each row execute function public.enforce_clean_text('text');

drop trigger if exists enforce_clean_text on public.chats;
create trigger enforce_clean_text
before insert or update on public.chats
for each row execute function public.enforce_clean_text('lastMessage');

drop trigger if exists enforce_clean_text on public.profiles;
create trigger enforce_clean_text
before insert or update on public.profiles
for each row execute function public.enforce_clean_text('displayName');

drop trigger if exists enforce_clean_text on public.listings;
create trigger enforce_clean_text
before insert or update on public.listings
for each row execute function public.enforce_clean_text('title', 'description', 'sellerName');

drop trigger if exists enforce_clean_text on public.services;
create trigger enforce_clean_text
before insert or update on public.services
for each row execute function public.enforce_clean_text('name', 'offer', 'address');

drop trigger if exists enforce_clean_text on public.service_updates;
create trigger enforce_clean_text
before insert or update on public.service_updates
for each row execute function public.enforce_clean_text('title', 'body');
