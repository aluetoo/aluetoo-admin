-- Aluetoo Admin - socle de base
-- Migration additive et idempotente : ne supprime aucune table ni aucun compte.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz not null default now()
);
alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists role text not null default 'user';
alter table public.profiles add column if not exists created_at timestamptz not null default now();

create table if not exists public.user_controls (
  user_id uuid primary key references auth.users(id) on delete cascade,
  bonus_messages integer not null default 0 check (bonus_messages >= 0),
  is_banned boolean not null default false,
  banned_reason text,
  updated_at timestamptz not null default now()
);
alter table public.user_controls add column if not exists bonus_messages integer not null default 0;
alter table public.user_controls add column if not exists is_banned boolean not null default false;
alter table public.user_controls add column if not exists banned_reason text;
alter table public.user_controls add column if not exists updated_at timestamptz not null default now();

create table if not exists public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  target_user_id uuid references auth.users(id) on delete set null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table public.admin_audit_log add column if not exists admin_user_id uuid references auth.users(id) on delete set null;
alter table public.admin_audit_log add column if not exists action text;
alter table public.admin_audit_log add column if not exists target_user_id uuid references auth.users(id) on delete set null;
alter table public.admin_audit_log add column if not exists details jsonb not null default '{}'::jsonb;
alter table public.admin_audit_log add column if not exists created_at timestamptz not null default now();

create or replace function public.aluetoo_is_admin()
returns boolean language sql stable security definer set search_path = public
as $$
  select exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin');
$$;
revoke all on function public.aluetoo_is_admin() from public;
grant execute on function public.aluetoo_is_admin() to authenticated;

create or replace function public.aluetoo_handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles(id,email,role)
  values(new.id,new.email,'user')
  on conflict(id) do update set email = excluded.email;
  insert into public.user_controls(user_id)
  values(new.id) on conflict(user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists aluetoo_auth_user_created on auth.users;
create trigger aluetoo_auth_user_created
after insert on auth.users
for each row execute procedure public.aluetoo_handle_new_user();

alter table public.profiles enable row level security;
alter table public.user_controls enable row level security;
alter table public.admin_audit_log enable row level security;

drop policy if exists "aluetoo profile self read" on public.profiles;
create policy "aluetoo profile self read" on public.profiles
for select to authenticated using (id = auth.uid());
drop policy if exists "aluetoo profile admin read" on public.profiles;
create policy "aluetoo profile admin read" on public.profiles
for select to authenticated using (public.aluetoo_is_admin());

drop policy if exists "aluetoo controls self read" on public.user_controls;
create policy "aluetoo controls self read" on public.user_controls
for select to authenticated using (user_id = auth.uid());
drop policy if exists "aluetoo controls admin all" on public.user_controls;
create policy "aluetoo controls admin all" on public.user_controls
for all to authenticated using (public.aluetoo_is_admin()) with check (public.aluetoo_is_admin());

drop policy if exists "aluetoo audit admin read" on public.admin_audit_log;
create policy "aluetoo audit admin read" on public.admin_audit_log
for select to authenticated using (public.aluetoo_is_admin());

grant select on public.profiles, public.user_controls, public.admin_audit_log to authenticated;

create or replace function public.aluetoo_admin_add_bonus(target_user_id uuid, amount integer default 5)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if not public.aluetoo_is_admin() then raise exception 'Accès administrateur requis'; end if;
  if amount is null or amount < 1 or amount > 1000 then raise exception 'Montant invalide'; end if;
  if not exists(select 1 from auth.users where id = target_user_id) then raise exception 'Utilisateur introuvable'; end if;
  insert into public.user_controls(user_id,bonus_messages,updated_at)
  values(target_user_id,amount,now())
  on conflict(user_id) do update set bonus_messages = public.user_controls.bonus_messages + excluded.bonus_messages, updated_at = now();
  insert into public.admin_audit_log(admin_user_id,action,target_user_id,details)
  values(auth.uid(),'bonus_messages_added',target_user_id,jsonb_build_object('amount',amount));
end;
$$;

create or replace function public.aluetoo_admin_set_ban(target_user_id uuid, should_ban boolean, reason text default '')
returns void language plpgsql security definer set search_path = public
as $$
begin
  if not public.aluetoo_is_admin() then raise exception 'Accès administrateur requis'; end if;
  if target_user_id = auth.uid() and should_ban then raise exception 'Tu ne peux pas bannir ton propre compte'; end if;
  if not exists(select 1 from auth.users where id = target_user_id) then raise exception 'Utilisateur introuvable'; end if;
  insert into public.user_controls(user_id,is_banned,banned_reason,updated_at)
  values(target_user_id,should_ban,nullif(left(coalesce(reason,''),500),''),now())
  on conflict(user_id) do update set is_banned = excluded.is_banned, banned_reason = excluded.banned_reason, updated_at = now();
  insert into public.admin_audit_log(admin_user_id,action,target_user_id,details)
  values(auth.uid(),case when should_ban then 'user_banned' else 'user_unbanned' end,target_user_id,jsonb_build_object('reason',coalesce(reason,'')));
end;
$$;

revoke all on function public.aluetoo_admin_add_bonus(uuid,integer) from public;
revoke all on function public.aluetoo_admin_set_ban(uuid,boolean,text) from public;
grant execute on function public.aluetoo_admin_add_bonus(uuid,integer) to authenticated;
grant execute on function public.aluetoo_admin_set_ban(uuid,boolean,text) to authenticated;
