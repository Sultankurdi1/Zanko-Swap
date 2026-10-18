-- Align the ad table with the snake_case fields used by Flutter.
-- Run in Supabase SQL Editor after zankoswap_setup.sql and
-- production_security_and_schema.sql (which defines public.is_admin()).

alter table public.ad_campaigns add column if not exists subtitle text not null default '';
alter table public.ad_campaigns add column if not exists advertiser text not null default '';
alter table public.ad_campaigns add column if not exists image_url text not null default '';
alter table public.ad_campaigns add column if not exists receipt_url text not null default '';
alter table public.ad_campaigns add column if not exists target_url text not null default '';
alter table public.ad_campaigns add column if not exists target_route text not null default '';
alter table public.ad_campaigns add column if not exists category text not null default 'home';
alter table public.ad_campaigns add column if not exists badge_text text not null default 'SPONSORED';
alter table public.ad_campaigns add column if not exists budget_iqd integer not null default 0;
alter table public.ad_campaigns add column if not exists days integer not null default 7;
alter table public.ad_campaigns add column if not exists created_at timestamptz not null default now();
alter table public.ad_campaigns add column if not exists end_date timestamptz;
alter table public.ad_campaigns add column if not exists is_active boolean not null default false;
alter table public.ad_campaigns add column if not exists views_count integer not null default 0;
alter table public.ad_campaigns add column if not exists clicks_count integer not null default 0;

-- Preserve data from the earlier camelCase table when upgrading an existing app.
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='ad_campaigns' and column_name='imageUrl') then
    execute 'update public.ad_campaigns set image_url = "imageUrl" where image_url = ''''';
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='ad_campaigns' and column_name='targetUrl') then
    execute 'update public.ad_campaigns set target_url = "targetUrl" where target_url = ''''';
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='ad_campaigns' and column_name='targetRoute') then
    execute 'update public.ad_campaigns set target_route = "targetRoute" where target_route = ''''';
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='ad_campaigns' and column_name='receiptUrl') then
    execute 'update public.ad_campaigns set receipt_url = "receiptUrl" where receipt_url = ''''';
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='ad_campaigns' and column_name='badgeText') then
    execute 'update public.ad_campaigns set badge_text = "badgeText" where badge_text = ''SPONSORED''';
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='ad_campaigns' and column_name='budgetIQD') then
    execute 'update public.ad_campaigns set budget_iqd = "budgetIQD" where budget_iqd = 0';
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='ad_campaigns' and column_name='createdAt') then
    execute 'update public.ad_campaigns set created_at = "createdAt" where created_at = now()';
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='ad_campaigns' and column_name='isActive') then
    execute 'update public.ad_campaigns set is_active = "isActive" where is_active = false';
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='ad_campaigns' and column_name='viewsCount') then
    execute 'update public.ad_campaigns set views_count = "viewsCount" where views_count = 0';
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='ad_campaigns' and column_name='clicksCount') then
    execute 'update public.ad_campaigns set clicks_count = "clicksCount" where clicks_count = 0';
  end if;
end $$;

update public.ad_campaigns
set end_date = coalesce(end_date, created_at + make_interval(days => greatest(days, 1))),
    is_active = is_active or status in ('approved', 'active');

alter table public.ad_campaigns alter column end_date set default (now() + interval '7 days');

drop policy if exists "ads approved read" on public.ad_campaigns;
drop policy if exists "ads public active read" on public.ad_campaigns;
create policy "ads public active read" on public.ad_campaigns
for select to anon, authenticated
using (
  public.is_admin()
  or (status in ('approved', 'active') and is_active = true and end_date > now())
);

drop policy if exists "ads auth insert" on public.ad_campaigns;
create policy "ads authenticated insert" on public.ad_campaigns
for insert to authenticated with check (true);

drop policy if exists "ads admin update" on public.ad_campaigns;
create policy "ads admin update" on public.ad_campaigns
for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "ads admin delete" on public.ad_campaigns;
create policy "ads admin delete" on public.ad_campaigns
for delete to authenticated using (public.is_admin());
