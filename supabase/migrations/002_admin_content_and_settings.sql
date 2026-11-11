-- Aluetoo Admin: extensions non destructives
-- Aucune table existante n'est supprimée. Sauvegarde recommandée avant toute migration.

alter table public.user_controls
  add column if not exists banned_reason text;

create or replace function public.aluetoo_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

revoke all on function public.aluetoo_is_admin() from public;
grant execute on function public.aluetoo_is_admin() to authenticated;

create table if not exists public.aluetoo_announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 140),
  body text not null check (char_length(body) between 1 and 10000),
  is_published boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.aluetoo_notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 140),
  message text not null check (char_length(message) between 1 and 4000),
  target_user_id uuid references auth.users(id) on delete cascade,
  is_published boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.aluetoo_events (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 140),
  description text not null default '',
  starts_at timestamptz not null,
  ends_at timestamptz,
  location text,
  is_published boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint aluetoo_events_dates_check check (ends_at is null or ends_at >= starts_at)
);

create table if not exists public.aluetoo_settings (
  key text primary key check (char_length(key) between 1 and 80),
  value jsonb not null default '{}'::jsonb,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);

alter table public.aluetoo_announcements enable row level security;
alter table public.aluetoo_notifications enable row level security;
alter table public.aluetoo_events enable row level security;
alter table public.aluetoo_settings enable row level security;

drop policy if exists "aluetoo announcements public read" on public.aluetoo_announcements;
create policy "aluetoo announcements public read"
on public.aluetoo_announcements for select
to anon, authenticated
using (is_published = true);

drop policy if exists "aluetoo announcements admin all" on public.aluetoo_announcements;
create policy "aluetoo announcements admin all"
on public.aluetoo_announcements for all
to authenticated
using (public.aluetoo_is_admin())
with check (public.aluetoo_is_admin());

drop policy if exists "aluetoo notifications recipient read" on public.aluetoo_notifications;
create policy "aluetoo notifications recipient read"
on public.aluetoo_notifications for select
to authenticated
using (is_published = true and (target_user_id is null or target_user_id = auth.uid()));

drop policy if exists "aluetoo notifications admin all" on public.aluetoo_notifications;
create policy "aluetoo notifications admin all"
on public.aluetoo_notifications for all
to authenticated
using (public.aluetoo_is_admin())
with check (public.aluetoo_is_admin());

drop policy if exists "aluetoo events public read" on public.aluetoo_events;
create policy "aluetoo events public read"
on public.aluetoo_events for select
to anon, authenticated
using (is_published = true);

drop policy if exists "aluetoo events admin all" on public.aluetoo_events;
create policy "aluetoo events admin all"
on public.aluetoo_events for all
to authenticated
using (public.aluetoo_is_admin())
with check (public.aluetoo_is_admin());

drop policy if exists "aluetoo settings admin all" on public.aluetoo_settings;
create policy "aluetoo settings admin all"
on public.aluetoo_settings for all
to authenticated
using (public.aluetoo_is_admin())
with check (public.aluetoo_is_admin());

grant select on public.aluetoo_announcements, public.aluetoo_events to anon, authenticated;
grant select on public.aluetoo_notifications to authenticated;
grant select, insert, update, delete on public.aluetoo_announcements,
  public.aluetoo_notifications, public.aluetoo_events, public.aluetoo_settings to authenticated;
