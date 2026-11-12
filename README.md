# IKIRU AGENDA

Painel de produção da IKIRU: agenda semanal e anual, reservas dos **Estúdios A, B e C**, acompanhamento dos artistas e lançamentos.

## Contador do Apocalipse (v5)

O início do painel exibe **TEMPO ATÉ A IKIRU CONSEGUIR SE PAGAR**, com dias, horas, minutos e segundos até **01/07/2027 às 00:00 (horário de São Paulo)**. O horário foi adotado como padrão provisório porque o dia exato em julho ainda não foi especificado. Para alterar o prazo, edite `IKIRU_APOCALYPSE_DEADLINE` em `index.html`.

O contador funciona localmente, não depende do backend e não muda nem remove reservas.

## Abrir o protótipo

Abra `index.html` no navegador ou publique os arquivos estáticos em uma hospedagem HTTPS.

**Estado atual:** a interface v4 é funcional como protótipo local e armazena dados no `localStorage` do navegador. **Não é multiusuário, não tem login e não está conectada ao PostgreSQL.** Não considere os dados protegidos contra perda ou sincronizados entre dispositivos até a integração do backend.

### Funcionalidades do protótipo
- Tema claro por padrão; alternância para escuro.
- Três estúdios com status **LIVRE/OCUPADO** e horários exatos da próxima reserva ou liberação.
- Reservas com detecção de conflito no navegador, tipos de sessão, artistas e participantes.
- Agenda por dia, semana, mês e ano; metas por artista e roadmap de lançamentos.
- Backup manual JSON; importação de backup existente; exportação .ics.

## Backend — fundação inicial

`supabase/schema.sql` contém uma primeira modelagem PostgreSQL/Supabase com:
- autenticação pelo Supabase Auth e associação de usuários à organização;
- perfis e papéis de administrador, editor e leitor;
- artistas, projetos, sessões e participantes;
- regras RLS para que usuários não vinculados à organização não acessem dados;
- restrição de sobreposição de sessões por estúdio **no banco**, não apenas na interface;
- trilha de criação/atualização e número de versão nos registros.

**Ainda não aplicado em nenhum banco.** Para colocar em produção:
1. Criar projeto Supabase e armazenar credenciais no painel do provedor, nunca no GitHub.
2. Revisar e executar `supabase/schema.sql` no SQL Editor, em ambiente de desenvolvimento.
3. Configurar autenticação, criar primeiro administrador **com processo confiável** e convidar a equipe.
4. Substituir o `localStorage` em `index.html` por um cliente autenticado e CRUD via banco, com tratamento de erros e atualização em tempo real.
5. Configurar backups automáticos e **testar restauração**, monitoramento, MFA para administradores e políticas de retenção.
6. Migrar o JSON exportado do painel local para o banco após validar os dados.

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
