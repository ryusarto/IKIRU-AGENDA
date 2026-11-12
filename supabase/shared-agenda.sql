-- Shared document preserves all legacy fields and identifiers; existing relational tables remain intact.
begin;
create table public.ikiru_agenda_state (
 id text primary key check(id='main'),
 payload jsonb not null,
 revision bigint not null default 1,
 updated_at timestamptz not null default now(),
 updated_by uuid references auth.users(id)
);
alter table public.ikiru_agenda_state enable row level security;
revoke all on public.ikiru_agenda_state from public, anon;
grant select,update on public.ikiru_agenda_state to authenticated;
create policy "active members read shared agenda" on public.ikiru_agenda_state
 for select to authenticated using(private.ikiru_role_is(array['admin','editor','viewer']::public.ikiru_role[]));
create policy "editors update shared agenda" on public.ikiru_agenda_state
 for update to authenticated using(private.ikiru_role_is(array['admin','editor']::public.ikiru_role[]))
 with check(private.ikiru_role_is(array['admin','editor']::public.ikiru_role[]));
create function public.ikiru_validate_agenda() returns trigger
language plpgsql security invoker set search_path='' as $$
declare collection text; item jsonb; event jsonb;
begin
 if jsonb_typeof(new.payload) is distinct from 'object' then raise exception 'Agenda inválida'; end if;
 foreach collection in array array['artists','projects','events'] loop
  if jsonb_typeof(new.payload->collection) is distinct from 'array' then raise exception 'Coleção inválida: %',collection; end if;
  if exists(select 1 from jsonb_array_elements(new.payload->collection) r group by r->>'id' having count(*)>1) then raise exception 'Identificadores duplicados'; end if;
  for item in select value from jsonb_array_elements(new.payload->collection) loop
   if jsonb_typeof(item) is distinct from 'object' or coalesce(item->>'id','')='' then raise exception 'Registro inválido'; end if;
  end loop;
 end loop;
 for event in select value from jsonb_array_elements(new.payload->'events') loop
  if coalesce(event->>'studio','') not in ('A','B','C','Fora') or coalesce(event->>'type','') not in ('Projeto IKIRU','Reunião','Projeto pessoal','Sessão de beat','Sessão de mix e master') then raise exception 'Estúdio ou tipo inválido'; end if;
  if coalesce(event->>'date','') !~ '^\d{4}-\d{2}-\d{2}$' or coalesce(event->>'start','') !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' or coalesce(event->>'end','') !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' then raise exception 'Data ou horário inválido'; end if;
  perform (event->>'date')::date;
  if (event->>'end') <= (event->>'start') then raise exception 'O término deve ser depois do início'; end if;
 end loop;
 if exists(
  select 1 from jsonb_array_elements(new.payload->'events') a
  join jsonb_array_elements(new.payload->'events') b
  on a->>'id'<b->>'id' and a->>'date'=b->>'date' and a->>'studio'=b->>'studio'
  and a->>'start'<b->>'end' and a->>'end'>b->>'start'
  where a->>'studio'<>'Fora'
 ) then raise exception 'Horário ocupado: existem sessões sobrepostas no mesmo estúdio'; end if;
 if TG_OP='UPDATE' then
  new.revision=old.revision+1;
  new.updated_at=now();
  new.updated_by=auth.uid();
 end if;
 return new;
end $$;
revoke all on function public.ikiru_validate_agenda() from public,anon,authenticated;
create trigger ikiru_validate_agenda before insert or update on public.ikiru_agenda_state
 for each row execute function public.ikiru_validate_agenda();
insert into public.ikiru_agenda_state(id,payload) values('main',$seed${"version":2,"artists":[{"id":"ikiru-artist-0","name":"Ryuchi","color":"#e65b5c","target":0,"priority":"Média","notes":""},{"id":"ikiru-artist-1","name":"Franco, the Sir!","color":"#a886f5","target":0,"priority":"Média","notes":""},{"id":"ikiru-artist-2","name":"Kenji","color":"#73b1dc","target":0,"priority":"Média","notes":""},{"id":"ikiru-artist-3","name":"Mvt","color":"#8bbda7","target":0,"priority":"Média","notes":""},{"id":"ikiru-artist-4","name":"Mdep","color":"#d8af71","target":0,"priority":"Média","notes":""},{"id":"ikiru-artist-5","name":"Okie","color":"#b6be81","target":0,"priority":"Média","notes":""},{"id":"ikiru-artist-6","name":"Dney","color":"#e19c73","target":0,"priority":"Média","notes":""},{"id":"ikiru-artist-7","name":"Desiiik","color":"#c9818e","target":0,"priority":"Média","notes":""},{"id":"ikiru-artist-8","name":"Jovem Jota","color":"#7cc5b2","target":0,"priority":"Média","notes":""},{"id":"ikiru-artist-9","name":"DJ Tevez","color":"#dcb477","target":0,"priority":"Média","notes":""}],"projects":[{"id":"ikiru-torii-hutukara","name":"Torii e Hutukara","artistId":"ikiru-artist-0","collaborators":"Franco, the Sir!","kind":"Álbum","releaseDate":"2026-11-27","stage":"Não informado","priority":"Média","notes":"Projeto colaborativo. Data planejada de lançamento: 27/11/2026. Atualize o estágio real e as entregas."}],"events":[]}$seed$::jsonb);
alter publication supabase_realtime add table public.ikiru_agenda_state;
commit;

-- Public access explicitly approved by owner.
begin;
grant select,update on public.ikiru_agenda_state to anon;
create policy "public read agenda" on public.ikiru_agenda_state for select to anon using(id='main');
create policy "public edit agenda" on public.ikiru_agenda_state for update to anon using(id='main') with check(id='main');
commit;