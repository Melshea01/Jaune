-- =====================================================================
-- Jaune — Notif sociale « un ami attaque l'apéro »
-- Table des tokens de push (FCM/APNs) + RLS.
--
-- À exécuter dans le SQL Editor de ton projet Supabase, APRÈS 0001.
-- La fonction Edge `notify-apero` lit cette table avec la clé service_role
-- (elle contourne donc la RLS pour fanout vers les amis).
-- =====================================================================

-- --- Tokens d'appareil --------------------------------------------------
-- Un device = une ligne (un même utilisateur peut avoir plusieurs appareils).
-- `token` est le registration token FCM (gère iOS via APNs sous le capot).
create table if not exists public.device_tokens (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  token      text not null,
  platform   text not null default 'unknown' check (platform in ('ios', 'android', 'unknown')),
  updated_at timestamptz not null default now(),
  primary key (user_id, token)
);

create index if not exists device_tokens_user_idx on public.device_tokens (user_id);

-- =====================================================================
-- Row Level Security — chacun ne gère QUE ses propres tokens.
-- La fonction Edge utilise service_role et n'est pas soumise à ces règles.
-- =====================================================================
alter table public.device_tokens enable row level security;

drop policy if exists "device_tokens_select" on public.device_tokens;
create policy "device_tokens_select" on public.device_tokens
  for select using (user_id = auth.uid());

drop policy if exists "device_tokens_insert" on public.device_tokens;
create policy "device_tokens_insert" on public.device_tokens
  for insert with check (user_id = auth.uid());

drop policy if exists "device_tokens_update" on public.device_tokens;
create policy "device_tokens_update" on public.device_tokens
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "device_tokens_delete" on public.device_tokens;
create policy "device_tokens_delete" on public.device_tokens
  for delete using (user_id = auth.uid());

-- --- Préférence : diffuser mon apéro à mes amis -------------------------
-- Opt-in côté serveur aussi (l'Edge Function la respecte pour l'émetteur).
-- Défaut false : aucun broadcast sans choix explicite de l'utilisateur.
alter table public.profiles
  add column if not exists apero_broadcast boolean not null default false;
