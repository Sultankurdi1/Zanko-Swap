-- ZankoSwap: ad prices the admin can change from the app.
-- Run in Supabase Dashboard -> SQL Editor. Safe to run more than once.

create table if not exists public.ad_prices (
  placement text primary key,
  price_per_week_iqd integer not null check (price_per_week_iqd between 250 and 100000000),
  updated_at timestamptz not null default now()
);

insert into public.ad_prices (placement, price_per_week_iqd)
values ('home', 15000), ('course', 5000)
on conflict (placement) do nothing;

alter table public.ad_prices enable row level security;
grant select on public.ad_prices to anon, authenticated;
grant insert, update on public.ad_prices to authenticated;

drop policy if exists "ad_prices_read_all" on public.ad_prices;
create policy "ad_prices_read_all" on public.ad_prices
for select to anon, authenticated using (true);

drop policy if exists "ad_prices_admin_insert" on public.ad_prices;
create policy "ad_prices_admin_insert" on public.ad_prices
for insert to authenticated with check (public.is_admin());

drop policy if exists "ad_prices_admin_update" on public.ad_prices;
create policy "ad_prices_admin_update" on public.ad_prices
for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- The amount to pay is always worked out on the server from the current price,
-- so it cannot be changed from a modified app.
create or replace function public.set_ad_budget()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  weekly integer;
begin
  if new.days is null or new.days not in (7, 14, 30) then
    new.days := 7;
  end if;
  select price_per_week_iqd into weekly from public.ad_prices where placement = new.placement;
  if weekly is null then
    raise exception 'unknown_ad_placement' using errcode = 'P0001';
  end if;
  new.budget_iqd := weekly * greatest(new.days / 7, 1);
  return new;
end;
$$;

drop trigger if exists set_ad_budget on public.ad_campaigns;
create trigger set_ad_budget
before insert on public.ad_campaigns
for each row execute function public.set_ad_budget();

select placement, price_per_week_iqd from public.ad_prices order by placement;
