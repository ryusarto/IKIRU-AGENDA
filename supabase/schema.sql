-- IKIRU Agenda — fundação PostgreSQL/Supabase (ainda não aplicada).
-- Execute somente depois de revisar as permissões e plano de migração.
create extension if not exists pgcrypto;
create extension if not exists btree_gist;

create type public.ikiru_role as enum ('admin','editor','viewer');
create type public.ikiru_studio as enum ('A','B','C');
create type public.ikiru_session_kind as enum ('projeto_ikiru','reuniao','projeto_pessoal','beat','mix_master');

create table public.ikiru_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(trim(display_name)) between 1 and 120),
  role public.ikiru_role not null default 'viewer',
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.ikiru_artists (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 1 and 150),
  monthly_session_goal integer not null default 0 check (monthly_session_goal between 0 and 100),
  active boolean not null default true,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1
);
create unique index ikiru_artists_name_unique on public.ikiru_artists (lower(name));

create table public.ikiru_projects (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 1 and 200),
  lead_artist_id uuid references public.ikiru_artists(id) on delete set null,
  kind text not null default 'Projeto',
  release_date date,
  status text not null default 'planejamento',
  priority text not null default 'media',
  notes text not null default '',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1
);

create table public.ikiru_sessions (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) between 1 and 200),
  studio public.ikiru_studio not null,
  kind public.ikiru_session_kind not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  lead_artist_id uuid references public.ikiru_artists(id) on delete set null,
  project_id uuid references public.ikiru_projects(id) on delete set null,
  responsible text not null default '',
  notes text not null default '',
  cancelled_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  constraint valid_session_range check (starts_at < ends_at),
  constraint studio_no_overlap exclude using gist (
    studio with =,
    tstzrange(starts_at,ends_at,'[)') with &&
  ) where (cancelled_at is null)
);
create index ikiru_sessions_starts_at_idx on public.ikiru_sessions(starts_at);
create index ikiru_sessions_project_idx on public.ikiru_sessions(project_id);

create table public.ikiru_session_participants (
  session_id uuid not null references public.ikiru_sessions(id) on delete cascade,
  artist_id uuid not null references public.ikiru_artists(id) on delete cascade,
  primary key(session_id,artist_id)
);

create or replace function public.ikiru_role_is(allowed public.ikiru_role[])
returns boolean language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.ikiru_members m
    where m.user_id = (select auth.uid()) and m.active and m.role = any(allowed)
  );
$$;

create or replace function public.ikiru_touch_record()
returns trigger language plpgsql set search_path = ''
as $$
begin
  new.updated_at = now();
  new.version = old.version + 1;
  return new;
end;
$$;
create trigger ikiru_artists_touch before update on public.ikiru_artists
for each row execute function public.ikiru_touch_record();
create trigger ikiru_projects_touch before update on public.ikiru_projects
for each row execute function public.ikiru_touch_record();
create trigger ikiru_sessions_touch before update on public.ikiru_sessions
for each row execute function public.ikiru_touch_record();

alter table public.ikiru_members enable row level security;
alter table public.ikiru_artists enable row level security;
alter table public.ikiru_projects enable row level security;
alter table public.ikiru_sessions enable row level security;
alter table public.ikiru_session_participants enable row level security;

create policy "members read own or admin list" on public.ikiru_members
for select to authenticated using (
 user_id = (select auth.uid()) or public.ikiru_role_is(array['admin']::public.ikiru_role[])
);
create policy "admins manage members" on public.ikiru_members
for all to authenticated
using (public.ikiru_role_is(array['admin']::public.ikiru_role[]))
with check (public.ikiru_role_is(array['admin']::public.ikiru_role[]));

create policy "members read artists" on public.ikiru_artists
for select to authenticated using (public.ikiru_role_is(array['admin','editor','viewer']::public.ikiru_role[]));
create policy "editors manage artists" on public.ikiru_artists
for all to authenticated
using (public.ikiru_role_is(array['admin','editor']::public.ikiru_role[]))
with check (public.ikiru_role_is(array['admin','editor']::public.ikiru_role[]));

create policy "members read projects" on public.ikiru_projects
for select to authenticated using (public.ikiru_role_is(array['admin','editor','viewer']::public.ikiru_role[]));
create policy "editors manage projects" on public.ikiru_projects
for all to authenticated
using (public.ikiru_role_is(array['admin','editor']::public.ikiru_role[]))
with check (public.ikiru_role_is(array['admin','editor']::public.ikiru_role[]));

create policy "members read sessions" on public.ikiru_sessions
for select to authenticated using (public.ikiru_role_is(array['admin','editor','viewer']::public.ikiru_role[]));
create policy "editors manage sessions" on public.ikiru_sessions
for all to authenticated
using (public.ikiru_role_is(array['admin','editor']::public.ikiru_role[]))
with check (public.ikiru_role_is(array['admin','editor']::public.ikiru_role[]));

create policy "members read participants" on public.ikiru_session_participants
for select to authenticated using (public.ikiru_role_is(array['admin','editor','viewer']::public.ikiru_role[]));
create policy "editors manage participants" on public.ikiru_session_participants
for all to authenticated
using (public.ikiru_role_is(array['admin','editor']::public.ikiru_role[]))
with check (public.ikiru_role_is(array['admin','editor']::public.ikiru_role[]));

-- Não crie um usuário admin via formulário público.
-- O primeiro admin deve ser atribuído por um operador confiável usando ambiente administrativo.
-- Não exponha a service_role key no frontend.
