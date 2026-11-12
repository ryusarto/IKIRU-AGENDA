# IKIRU AGENDA

Painel de produção da IKIRU: agenda semanal e anual, reservas dos **Estúdios A, B e C**, acompanhamento dos artistas e lançamentos.

## Contador do Apocalipse (v5)

O início do painel exibe **TEMPO ATÉ A IKIRU CONSEGUIR SE PAGAR**, com dias, horas, minutos e segundos até **01/07/2027 às 00:00 (horário de São Paulo)**. O horário foi adotado como padrão provisório porque o dia exato em julho ainda não foi especificado. Para alterar o prazo, edite `IKIRU_APOCALYPSE_DEADLINE` em `index.html`.

O contador funciona localmente, não depende do backend e não muda nem remove reservas.

## Abrir o protótipo

Abra `index.html` no navegador ou publique os arquivos estáticos em uma hospedagem HTTPS.

**Estado atual:** a interface v5 exige Supabase Auth e vínculo ativo em `ikiru_members` antes de mostrar o painel. As permissões RLS estão no banco, mas as reservas/artistas/projetos do protótipo ainda usam `localStorage`, NÃO sincronizam entre dispositivos, e a interface estática não constitui uma fronteira de segurança para dados embutidos no HTML. **Não cadastre dados privados antes de substituir `localStorage` por CRUD autenticado.** Não considere os dados protegidos contra perda ou sincronizados entre dispositivos até a integração do backend.

### Funcionalidades do protótipo
- Tema claro por padrão; alternância para escuro.
- Três estúdios com status **LIVRE/OCUPADO** e horários exatos da próxima reserva ou liberação.
- Reservas com detecção de conflito no navegador, tipos de sessão, artistas e participantes.
- Agenda por dia, semana, mês e ano; metas por artista e roadmap de lançamentos.
- Backup manual JSON; importação de backup existente; exportação .ics.

## Supabase Auth e permissões — aplicado em 12/11/2026

Projeto: [IKIRU AGENDA](https://supabase.com/dashboard/project/aifpibaodlsbnmygewox) (região Canadá). Schema aplicado como migração `ikiru_agenda_auth_membership_rls`: `ikiru_members`, `ikiru_artists`, `ikiru_projects`, `ikiru_sessions` e `ikiru_session_participants`, com RLS e prevenção de conflitos por estúdio.

O HTML usa Supabase Auth (e-mail/senha), recupera sessão, lê associação ativa em `ikiru_members`, oculta o painel sem autorização, suporta `#/dashboard`, `#/calendar`, `#/studios`, `#/projects`, `#/artists`, e possui logout. Os papéis admin/editor podem editar o protótipo local, viewer somente lê. A URL do projeto e a publishable key são públicas por projeto; nunca inclua service role.

**Conceder acesso:** 1) Crie ou convide uma conta em [Authentication > Users](https://supabase.com/dashboard/project/aifpibaodlsbnmygewox/auth/users); 2) copie o UUID autenticado; 3) rode no [SQL Editor](https://supabase.com/dashboard/project/aifpibaodlsbnmygewox/sql/new), como administrador confiável:

```sql
insert into public.ikiru_members (user_id, display_name, role, active)
values ('COLE_AQUI_O_UUID_DO_AUTH_USER'::uuid, 'Nome da pessoa', 'admin', true);
```

Nunca crie o primeiro admin via formulário público; convidados sem vínculo ativo ficam bloqueados. Para os demais use `editor` ou `viewer`. Confirme o e-mail e revise [Auth URL Configuration](https://supabase.com/dashboard/project/aifpibaodlsbnmygewox/auth/url-configuration) para recuperação de senha. Configure URLs HTTPS de hospedagem e SMTP antes do uso em equipe.

**Limitação pendente:** o formulário e a navegação foram protegidos, mas os dados de agenda ainda estão no navegador e não usam as tabelas Supabase. Migrar backup JSON para a base, substituir gravações e leituras locais por CRUD com RLS, implementar controle de concorrência e atualizar as telas de compartilhamento; até lá, não chamar a plataforma de agenda compartilhada em produção.

O arquivo `supabase/schema.sql` documenta o esquema já aplicado. Não reexecute o script sem adaptação idempotente ou migração de versão.

## Segurança e continuidade

Não commitar `.env`, senhas, chaves `service_role`, tokens, backups com dados reais nem informações pessoais dos artistas.

O GitHub versiona **código**, não é backup operacional do banco de dados.

## Catálogo inicial
Estúdios: A, B e C.
Categorias: Projeto IKIRU, Reunião, Projeto pessoal, Sessão de beat, Sessão de mix e master.
Artistas: Ryuchi, Franco, Kenji, Mvt, Mdep, Okie, Dney, Desiiik, Jovem Jota, DJ Tevez.

## Organização
- `index.html` — protótipo da interface v4.
- `supabase/schema.sql` — primeira versão do esquema de banco.
- `README.md` — operação e próximos passos.
