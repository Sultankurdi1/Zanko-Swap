-- Store FCM registration tokens without exposing other users' devices.
create table if not exists public.user_devices (
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, fcm_token)
);

alter table public.user_devices enable row level security;
grant select, insert, update, delete on public.user_devices to authenticated;

drop policy if exists "users_manage_own_fcm_devices" on public.user_devices;
create policy "users_manage_own_fcm_devices"
on public.user_devices
for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
