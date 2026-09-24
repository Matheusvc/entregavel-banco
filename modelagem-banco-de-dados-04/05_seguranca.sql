-- =============================================================================
-- OXYGENI HUB  |  Sprint 4 - Modelagem Física (PostgreSQL)
-- Arquivo: 05_seguranca.sql
-- Objetivo: controle de acesso com PRINCÍPIO DO MENOR PRIVILÉGIO.
--   - 2 ROLES de grupo (NOLOGIN) que centralizam privilégios: leitura e app.
--   - 2 USUÁRIOS (LOGIN) com permissões diferentes, cada um herdando de um grupo.
--   - GRANT / REVOKE, incluindo REVOKE de dados sensíveis.
--   - Testes com SET ROLE provando as fronteiras de permissão.
--
-- Contém erros PROPOSITAIS (acessos negados) -> rode SEM ON_ERROR_STOP:
--   psql -d oxygeni_hub -f 05_seguranca.sql
--
-- Obs.: as senhas abaixo são exemplos didáticos. Troque em uso real.
-- =============================================================================
SET search_path TO oxygeni, public;

-- Limpeza idempotente: remove privilégios e roles de execuções anteriores.
-- (usuários antes dos grupos, pois são membros deles)
DO $$
DECLARE r text;
BEGIN
    FOREACH r IN ARRAY ARRAY['analista_bi','app_backend','oxygeni_app','oxygeni_leitura'] LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('DROP OWNED BY %I', r);
            EXECUTE format('DROP ROLE %I', r);
        END IF;
    END LOOP;
END $$;

-- =============================================================================
-- 1. ROLES DE GRUPO (NOLOGIN) -> "cargos". Não logam; só agrupam privilégios.
--    Gerenciar permissão no grupo é mais seguro que repetir GRANT por usuário.
-- =============================================================================

-- Grupo LEITURA: consultas analíticas / BI. Só SELECT.
CREATE ROLE oxygeni_leitura NOLOGIN;
GRANT USAGE ON SCHEMA oxygeni TO oxygeni_leitura;
GRANT SELECT ON ALL TABLES IN SCHEMA oxygeni TO oxygeni_leitura;
-- tabelas criadas no futuro também já entram como SELECT para o grupo:
ALTER DEFAULT PRIVILEGES IN SCHEMA oxygeni GRANT SELECT ON TABLES TO oxygeni_leitura;

-- Grupo APP: backend da aplicação. CRUD nos dados, mas NENHUM poder de DDL.
CREATE ROLE oxygeni_app NOLOGIN;
GRANT USAGE ON SCHEMA oxygeni TO oxygeni_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA oxygeni TO oxygeni_app;
-- sequences são necessárias para os INSERTs em colunas SERIAL/BIGSERIAL:
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA oxygeni TO oxygeni_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA oxygeni
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO oxygeni_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA oxygeni
    GRANT USAGE, SELECT ON SEQUENCES TO oxygeni_app;

-- Menor privilégio: remove o acesso implícito de PUBLIC ao schema.
REVOKE ALL ON SCHEMA oxygeni FROM PUBLIC;

-- =============================================================================
-- 2. USUÁRIOS (LOGIN) -> herdam permissões do grupo correspondente.
-- =============================================================================

-- Usuário 1: analista de BI -> APENAS leitura.
CREATE ROLE analista_bi LOGIN PASSWORD 'troque_esta_senha_bi';
GRANT oxygeni_leitura TO analista_bi;

-- Usuário 2: backend da aplicação -> CRUD (via grupo app).
CREATE ROLE app_backend LOGIN PASSWORD 'troque_esta_senha_app';
GRANT oxygeni_app TO app_backend;

-- =============================================================================
-- 3. REVOKE de granularidade fina (afinando o menor privilégio).
-- =============================================================================

-- (a) feedback guarda avaliação/opinião de usuário -> dado sensível.
--     O grupo de BI NÃO deve enxergar essa tabela.
REVOKE SELECT ON oxygeni.feedback FROM oxygeni_leitura;

-- (b) predicao é histórico/auditoria -> a aplicação pode inserir e consultar,
--     mas NÃO pode apagar registros.
REVOKE DELETE ON oxygeni.predicao FROM oxygeni_app;

-- =============================================================================
-- 4. TESTES DE FRONTEIRA (SET ROLE assume a identidade do usuário).
-- =============================================================================
\echo ''
\echo '################## TESTE analista_bi (somente leitura) ##################'
SET ROLE analista_bi;
\echo '-> SELECT em usuario (DEVE funcionar):'
SELECT count(*) AS usuarios_visiveis FROM oxygeni.usuario;
\echo '-> SELECT em feedback (REVOGADO, deve FALHAR):'
SELECT count(*) FROM oxygeni.feedback;
\echo '-> INSERT em usuario (sem permissao de escrita, deve FALHAR):'
INSERT INTO oxygeni.usuario (nome, email) VALUES ('Hacker', 'hacker@x.com');
RESET ROLE;

\echo ''
\echo '################## TESTE app_backend (CRUD sem DELETE em predicao) ##################'
SET ROLE app_backend;
\echo '-> INSERT em usuario (DEVE funcionar; desfeito com ROLLBACK):'
BEGIN;
INSERT INTO oxygeni.usuario (nome, email)
VALUES ('App Teste', 'appteste@oxygeni.dev') RETURNING id_usuario;
ROLLBACK;
\echo '-> DELETE em predicao (REVOGADO, deve FALHAR):'
DELETE FROM oxygeni.predicao WHERE id_predicao = 1;
RESET ROLE;

-- =============================================================================
-- 5. MATRIZ de privilégios resultante nas tabelas sensíveis.
-- =============================================================================
\echo ''
\echo '################## Privilegios em feedback e predicao ##################'
SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'oxygeni'
  AND table_name IN ('feedback', 'predicao')
  AND grantee IN ('oxygeni_leitura', 'oxygeni_app')
ORDER BY table_name, grantee, privilege_type;
