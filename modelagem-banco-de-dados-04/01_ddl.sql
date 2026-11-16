-- =============================================================================
-- OXYGENI HUB  |  Sprint 4 - Modelagem Física (PostgreSQL)
-- Arquivo: 01_ddl.sql
-- Objetivo: definição física completa do banco -> tabelas, chaves, restrições
--           (NOT NULL, UNIQUE, CHECK, DEFAULT), tipos específicos do PostgreSQL
--           (SERIAL/BIGSERIAL, NUMERIC, TIMESTAMPTZ, TEXT, SMALLINT) e índices.
--
-- Como executar (a partir de um banco chamado oxygeni_hub):
--   createdb oxygeni_hub                         -- ou: CREATE DATABASE oxygeni_hub;
--   psql -d oxygeni_hub -f 01_ddl.sql
--
-- Script idempotente: recria o schema do zero a cada execução.
-- =============================================================================

-- Schema dedicado: isola os objetos do domínio e casa com o GRANT USAGE
-- aplicado no controle de acesso (05_seguranca.sql). Não polui o schema public.
DROP SCHEMA IF EXISTS oxygeni CASCADE;
CREATE SCHEMA oxygeni;
SET search_path TO oxygeni, public;

-- =============================================================================
-- 1. USUARIO  -> pessoas que criam modelos e enviam feedback
-- =============================================================================
CREATE TABLE usuario (
    id_usuario  SERIAL       PRIMARY KEY,
    nome        VARCHAR(100) NOT NULL,
    -- e-mail é identificador de negócio: UNIQUE + CHECK de formato mínimo.
    email       VARCHAR(255) NOT NULL UNIQUE
                             CHECK (email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
    criado_em   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- =============================================================================
-- 2. MODELO_IA  -> modelo de IA pertencente a um usuário
-- =============================================================================
CREATE TABLE modelo_ia (
    id_modelo   SERIAL       PRIMARY KEY,
    nome        VARCHAR(100) NOT NULL,
    -- domínio controlado por CHECK (evita a necessidade de uma tabela de apoio).
    tipo        VARCHAR(30)  NOT NULL
                             CHECK (tipo IN ('classificacao','regressao','clusterizacao',
                                             'nlp','visao_computacional','recomendacao')),
    algoritmo   VARCHAR(100) NOT NULL,
    id_usuario  INTEGER      NOT NULL,
    criado_em   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    -- RESTRICT: não deixa apagar um usuário que ainda tem modelos.
    CONSTRAINT fk_modelo_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE RESTRICT
);

-- =============================================================================
-- 3. DATASET  -> conjunto de dados associado a um modelo
-- =============================================================================
CREATE TABLE dataset (
    id_dataset  SERIAL        PRIMARY KEY,
    nome        VARCHAR(100)  NOT NULL,
    descricao   TEXT,                                    -- texto livre e potencialmente longo
    tamanho_mb  NUMERIC(12,2) NOT NULL CHECK (tamanho_mb > 0),
    id_modelo   INTEGER       NOT NULL,
    criado_em   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    -- CASCADE: dataset não existe sem o modelo dono.
    CONSTRAINT fk_dataset_modelo
        FOREIGN KEY (id_modelo) REFERENCES modelo_ia (id_modelo) ON DELETE CASCADE
);

-- =============================================================================
-- 4. TREINAMENTO  -> execução de treino de um modelo sobre um dataset
-- =============================================================================
CREATE TABLE treinamento (
    id_treinamento SERIAL      PRIMARY KEY,
    data_inicio    TIMESTAMPTZ NOT NULL DEFAULT now(),
    data_fim       TIMESTAMPTZ,                          -- NULL enquanto o treino não termina
    status         VARCHAR(20) NOT NULL DEFAULT 'pendente'
                               CHECK (status IN ('pendente','em_andamento','concluido','falhou')),
    id_modelo      INTEGER     NOT NULL,
    id_dataset     INTEGER     NOT NULL,
    -- coerência temporal: fim nunca antes do início.
    CONSTRAINT ck_treino_periodo CHECK (data_fim IS NULL OR data_fim >= data_inicio),
    CONSTRAINT fk_treino_modelo
        FOREIGN KEY (id_modelo)  REFERENCES modelo_ia (id_modelo) ON DELETE CASCADE,
    CONSTRAINT fk_treino_dataset
        FOREIGN KEY (id_dataset) REFERENCES dataset (id_dataset)  ON DELETE RESTRICT
);

-- =============================================================================
-- 5. METRICA  -> métricas resultantes de um treinamento
-- =============================================================================
CREATE TABLE metrica (
    id_metrica     SERIAL        PRIMARY KEY,
    nome           VARCHAR(50)   NOT NULL,               -- acuracia, precisao, recall, f1...
    valor          NUMERIC(10,4) NOT NULL CHECK (valor >= 0),
    data_avaliacao TIMESTAMPTZ   NOT NULL DEFAULT now(),
    id_treinamento INTEGER       NOT NULL,
    CONSTRAINT fk_metrica_treino
        FOREIGN KEY (id_treinamento) REFERENCES treinamento (id_treinamento) ON DELETE CASCADE
);

-- =============================================================================
-- 6. DEPLOY  -> publicação de um modelo em um ambiente
-- =============================================================================
CREATE TABLE deploy (
    id_deploy   SERIAL      PRIMARY KEY,
    ambiente    VARCHAR(20) NOT NULL
                            CHECK (ambiente IN ('desenvolvimento','homologacao','producao')),
    versao      VARCHAR(50) NOT NULL,
    data_deploy TIMESTAMPTZ NOT NULL DEFAULT now(),
    status      VARCHAR(20) NOT NULL DEFAULT 'ativo'
                            CHECK (status IN ('ativo','inativo','descontinuado')),
    id_modelo   INTEGER     NOT NULL,
    CONSTRAINT fk_deploy_modelo
        FOREIGN KEY (id_modelo) REFERENCES modelo_ia (id_modelo) ON DELETE CASCADE
);

-- =============================================================================
-- 7. PREDICAO  -> inferência feita por um modelo (tabela de alto volume)
--    BIGSERIAL: predições crescem rápido -> id de 8 bytes evita estouro do int.
-- =============================================================================
CREATE TABLE predicao (
    id_predicao BIGSERIAL   PRIMARY KEY,
    data_hora   TIMESTAMPTZ NOT NULL DEFAULT now(),
    entrada     TEXT        NOT NULL,                    -- payload de entrada (JSON/texto)
    resultado   TEXT        NOT NULL,
    id_modelo   INTEGER     NOT NULL,
    CONSTRAINT fk_predicao_modelo
        FOREIGN KEY (id_modelo) REFERENCES modelo_ia (id_modelo) ON DELETE CASCADE
);

-- =============================================================================
-- 8. FEEDBACK  -> avaliação humana de uma predição (dado sensível)
-- =============================================================================
CREATE TABLE feedback (
    id_feedback   BIGSERIAL   PRIMARY KEY,
    descricao     TEXT,
    -- nota de 1 a 5: SMALLINT economiza espaço, CHECK garante a faixa.
    nota          SMALLINT    NOT NULL CHECK (nota BETWEEN 1 AND 5),
    data_feedback TIMESTAMPTZ NOT NULL DEFAULT now(),
    id_predicao   BIGINT      NOT NULL,
    id_usuario    INTEGER     NOT NULL,
    CONSTRAINT fk_feedback_predicao
        FOREIGN KEY (id_predicao) REFERENCES predicao (id_predicao) ON DELETE CASCADE,
    CONSTRAINT fk_feedback_usuario
        FOREIGN KEY (id_usuario)  REFERENCES usuario (id_usuario)  ON DELETE RESTRICT
);

-- =============================================================================
-- 9. PERMISSAO  -> tipo de acesso de um usuário a um modelo
-- =============================================================================
CREATE TABLE permissao (
    id_permissao SERIAL      PRIMARY KEY,
    tipo         VARCHAR(20) NOT NULL
                             CHECK (tipo IN ('leitura','escrita','admin')),
    id_usuario   INTEGER     NOT NULL,
    id_modelo    INTEGER     NOT NULL,
    -- um usuário não repete o mesmo tipo de permissão no mesmo modelo.
    CONSTRAINT uq_permissao UNIQUE (id_usuario, id_modelo, tipo),
    CONSTRAINT fk_permissao_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_permissao_modelo
        FOREIGN KEY (id_modelo)  REFERENCES modelo_ia (id_modelo) ON DELETE CASCADE
);

-- =============================================================================
-- ÍNDICES
-- -----------------------------------------------------------------------------
-- Regra adotada: NÃO indexar tudo. O PostgreSQL já cria índice automático para
-- toda PRIMARY KEY e restrição UNIQUE. Aqui criamos índices apenas onde há
-- ganho real de leitura: (a) colunas de CHAVE ESTRANGEIRA usadas em JOIN e
-- (b) colunas usadas com frequência em WHERE / ORDER BY. Cada índice extra
-- deixa INSERT/UPDATE/DELETE mais lentos, então cada um abaixo tem justificativa.
-- =============================================================================

-- (a) Índices em FKs -> aceleram JOINs e as buscas "filhos de um pai".
--     Sem eles, o PostgreSQL faz Seq Scan na tabela filha a cada JOIN.
CREATE INDEX idx_modelo_usuario     ON modelo_ia  (id_usuario);
CREATE INDEX idx_dataset_modelo     ON dataset    (id_modelo);
CREATE INDEX idx_treino_modelo      ON treinamento(id_modelo);
CREATE INDEX idx_treino_dataset     ON treinamento(id_dataset);
CREATE INDEX idx_metrica_treino     ON metrica    (id_treinamento);
CREATE INDEX idx_deploy_modelo      ON deploy     (id_modelo);
CREATE INDEX idx_predicao_modelo    ON predicao   (id_modelo);
CREATE INDEX idx_feedback_predicao  ON feedback   (id_predicao);
CREATE INDEX idx_feedback_usuario   ON feedback   (id_usuario);
CREATE INDEX idx_permissao_modelo   ON permissao  (id_modelo);

-- (b) Consultas frequentes de dashboard:
-- "predições recentes por período" -> WHERE data_hora >= ... ORDER BY data_hora DESC.
-- DESC no índice espelha o ORDER BY e permite ler já ordenado + LIMIT eficiente.
CREATE INDEX idx_predicao_data_hora ON predicao (data_hora DESC);

-- Índice COMPOSTO: relatório "deploys de um ambiente com um status".
-- A ordem (ambiente, status) serve tanto o filtro só por ambiente quanto por ambos.
CREATE INDEX idx_deploy_ambiente_status ON deploy (ambiente, status);

-- Índice PARCIAL: 99% das consultas operacionais só olham o que está no ar.
-- Indexar apenas os deploys ativos em produção deixa o índice minúsculo e rápido.
CREATE INDEX idx_deploy_producao_ativo ON deploy (id_modelo)
    WHERE ambiente = 'producao' AND status = 'ativo';
