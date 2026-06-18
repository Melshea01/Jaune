-- =====================================================================
-- Jaune — Classement entre amis (Phase 2)
-- Schéma + Row Level Security.
--
-- À exécuter dans le SQL Editor de ton projet Supabase (région EU
-- recommandée pour la confidentialité des données sensibles).
-- =====================================================================

-- --- Profils -----------------------------------------------------------
-- Un profil = un utilisateur (anonyme). L'id reflète auth.uid().
-- Les stats partagées sont volontairement minimales.
create table if not exists public.profiles (
  id             uuid primary key references auth.users (id) on delete cascade,
  username       text not null default '',
  health_percent real not null default 1.0,   -- borné 0..1
  streak_days    integer not null default 0,
  equipped_skin  text not null default '',
  updated_at     timestamptz not null default now()
);

-- --- Amitiés ------------------------------------------------------------
-- Modèle dirigé : requester a sollicité addressee.
-- status: 'pending' (en attente) -> 'accepted' (bilatéral).
-- L'unicité empêche les doublons dans un sens donné.
create table if not exists public.friendships (
  id         uuid primary key default gen_random_uuid(),
  requester  uuid not null references public.profiles (id) on delete cascade,
  addressee  uuid not null references public.profiles (id) on delete cascade,
  status     text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  unique (requester, addressee),
  check (requester <> addressee)
);

create index if not exists friendships_addressee_idx on public.friendships (addressee);
create index if not exists friendships_requester_idx on public.friendships (requester);

-- =====================================================================
-- Row Level Security — confidentialité absolue
-- =====================================================================
alter table public.profiles    enable row level security;
alter table public.friendships enable row level security;

-- --- profiles ----------------------------------------------------------
-- Lecture : son propre profil, OU le profil de toute personne avec qui il
-- existe un lien (demande dans un sens ou l'autre, ou amitié acceptée).
-- Cela couvre : voir le pseudo d'un demandeur, et les stats des amis.
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
  for select using (
    id = auth.uid()
    or exists (
      select 1 from public.friendships f
      where (f.requester = auth.uid() and f.addressee = profiles.id)
         or (f.addressee = auth.uid() and f.requester = profiles.id)
    )
  );

drop policy if exists "profiles_insert" on public.profiles;
create policy "profiles_insert" on public.profiles
  for insert with check (id = auth.uid());

drop policy if exists "profiles_update" on public.profiles;
create policy "profiles_update" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- --- friendships -------------------------------------------------------
-- Lecture : uniquement les liens qui me concernent.
drop policy if exists "friendships_select" on public.friendships;
create policy "friendships_select" on public.friendships
  for select using (requester = auth.uid() or addressee = auth.uid());

-- Création : je ne peux envoyer une demande qu'en tant que requester, et
-- elle démarre forcément 'pending'.
drop policy if exists "friendships_insert" on public.friendships;
create policy "friendships_insert" on public.friendships
  for insert with check (requester = auth.uid() and status = 'pending');

-- Acceptation : seul le destinataire (addressee) peut passer à 'accepted'.
drop policy if exists "friendships_update" on public.friendships;
create policy "friendships_update" on public.friendships
  for update using (addressee = auth.uid()) with check (addressee = auth.uid());

-- Suppression : ignorer une demande reçue, annuler une demande envoyée,
-- ou retirer un ami — dans tous les cas, un des deux partis.
drop policy if exists "friendships_delete" on public.friendships;
create policy "friendships_delete" on public.friendships
  for delete using (requester = auth.uid() or addressee = auth.uid());

-- =====================================================================
-- Realtime — pour rafraîchir la pastille de demandes en direct.
-- =====================================================================
alter publication supabase_realtime add table public.friendships;
