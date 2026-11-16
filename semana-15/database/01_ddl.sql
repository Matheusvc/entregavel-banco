-- =============================================================================
-- OXYGENI HUB  |  Semana 15 — MER, Normalização e Chaves
-- Plataforma de Cursos Online
-- Arquivo: 01_ddl.sql
--
-- Modelo Lógico normalizado até a 3FN com PK, FK e constraints.
--
-- Como executar:
--   psql -U postgres -f 01_ddl.sql
-- =============================================================================

DROP TABLE IF EXISTS pagamentos        CASCADE;
DROP TABLE IF EXISTS avaliacoes         CASCADE;
DROP TABLE IF EXISTS matriculas         CASCADE;
DROP TABLE IF EXISTS aulas              CASCADE;
DROP TABLE IF EXISTS modulos            CASCADE;
DROP TABLE IF EXISTS cursos             CASCADE;
DROP TABLE IF EXISTS categorias         CASCADE;
DROP TABLE IF EXISTS usuarios           CASCADE;

-- -----------------------------------------------------------------------------
-- 1. CATEGORIAS
-- Extraída para evitar dependência transitiva (3FN).
-- Antes: o nome da categoria ficava direto na tabela cursos, gerando duplicação.
-- Agora: cada categoria é um registro único referenciado por FK.
-- -----------------------------------------------------------------------------

CREATE TABLE categorias (
    id_categoria SERIAL       PRIMARY KEY,
    nome         VARCHAR(100) NOT NULL UNIQUE,
    descricao    VARCHAR(300)
);

-- -----------------------------------------------------------------------------
-- 2. USUARIOS
-- Alunos, instrutores e administradores.
-- PK: id_usuario  |  UQ: email
-- -----------------------------------------------------------------------------

CREATE TABLE usuarios (
    id_usuario    SERIAL       PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    senha_hash    VARCHAR(255) NOT NULL,
    tipo          VARCHAR(20)  NOT NULL CHECK (tipo IN ('aluno', 'instrutor', 'admin')),
    data_cadastro DATE         NOT NULL DEFAULT CURRENT_DATE
);

-- -----------------------------------------------------------------------------
-- 3. CURSOS
-- Metadados do curso. O conteúdo (módulos/aulas) fica em tabelas próprias.
-- FK: id_instrutor → usuarios  |  FK: id_categoria → categorias
-- CHECK: preco >= 0
-- -----------------------------------------------------------------------------

CREATE TABLE cursos (
    id_curso      SERIAL        PRIMARY KEY,
    titulo        VARCHAR(200)  NOT NULL,
    descricao     TEXT,
    id_instrutor  INTEGER       NOT NULL REFERENCES usuarios(id_usuario),
    id_categoria  INTEGER       NOT NULL REFERENCES categorias(id_categoria),
    preco         DECIMAL(10,2) NOT NULL CHECK (preco >= 0),
    carga_horaria INTEGER       NOT NULL CHECK (carga_horaria > 0),
    status        VARCHAR(20)   NOT NULL DEFAULT 'rascunho'
                  CHECK (status IN ('rascunho', 'publicado', 'arquivado')),
    data_criacao  DATE          NOT NULL DEFAULT CURRENT_DATE
);

-- -----------------------------------------------------------------------------
-- 4. MODULOS
-- Divisão de conteúdo dentro de um curso.
-- FK: id_curso → cursos
-- UQ: (id_curso, ordem) — não pode haver dois módulos com a mesma ordem.
-- -----------------------------------------------------------------------------

CREATE TABLE modulos (
    id_modulo SERIAL       PRIMARY KEY,
    id_curso  INTEGER      NOT NULL REFERENCES cursos(id_curso) ON DELETE CASCADE,
    titulo    VARCHAR(200) NOT NULL,
    ordem     INTEGER      NOT NULL CHECK (ordem > 0),
    UNIQUE (id_curso, ordem)
);

-- -----------------------------------------------------------------------------
-- 5. AULAS
-- Cada aula pertence a um módulo. Atributos atômicos (1FN).
-- FK: id_modulo → modulos
-- UQ: (id_modulo, ordem)
-- -----------------------------------------------------------------------------

CREATE TABLE aulas (
    id_aula     SERIAL       PRIMARY KEY,
    id_modulo   INTEGER      NOT NULL REFERENCES modulos(id_modulo) ON DELETE CASCADE,
    titulo      VARCHAR(200) NOT NULL,
    tipo        VARCHAR(30)  NOT NULL CHECK (tipo IN ('video', 'texto', 'exercicio', 'quiz')),
    duracao_min INTEGER      CHECK (duracao_min > 0),
    ordem       INTEGER      NOT NULL CHECK (ordem > 0),
    UNIQUE (id_modulo, ordem)
);

-- -----------------------------------------------------------------------------
-- 6. MATRICULAS
-- Relacionamento N:N entre usuarios (alunos) e cursos.
-- Tabela associativa com atributos próprios (progresso, data).
-- PK: id_matricula  |  UQ: (id_usuario, id_curso) — impede matrícula dupla.
-- -----------------------------------------------------------------------------

CREATE TABLE matriculas (
    id_matricula   SERIAL  PRIMARY KEY,
    id_usuario     INTEGER NOT NULL REFERENCES usuarios(id_usuario),
    id_curso       INTEGER NOT NULL REFERENCES cursos(id_curso),
    data_matricula DATE    NOT NULL DEFAULT CURRENT_DATE,
    progresso      INTEGER NOT NULL DEFAULT 0 CHECK (progresso BETWEEN 0 AND 100),
    UNIQUE (id_usuario, id_curso)
);

-- -----------------------------------------------------------------------------
-- 7. PAGAMENTOS
-- Transação financeira vinculada a uma matrícula.
-- FK: id_matricula → matriculas
-- CHECK: valor > 0
-- -----------------------------------------------------------------------------

CREATE TABLE pagamentos (
    id_pagamento   SERIAL        PRIMARY KEY,
    id_matricula   INTEGER       NOT NULL REFERENCES matriculas(id_matricula),
    valor          DECIMAL(10,2) NOT NULL CHECK (valor > 0),
    metodo         VARCHAR(30)   NOT NULL CHECK (metodo IN ('pix', 'cartao', 'boleto')),
    status         VARCHAR(20)   NOT NULL DEFAULT 'pendente'
                   CHECK (status IN ('pendente', 'aprovado', 'recusado', 'estornado')),
    data_pagamento TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 8. AVALIACOES
-- Relacionamento N:N entre alunos e cursos com nota e comentário.
-- UQ: (id_usuario, id_curso) — um aluno só avalia um curso uma vez.
-- CHECK: nota entre 1 e 5.
-- -----------------------------------------------------------------------------

CREATE TABLE avaliacoes (
    id_avaliacao SERIAL  PRIMARY KEY,
    id_usuario   INTEGER NOT NULL REFERENCES usuarios(id_usuario),
    id_curso     INTEGER NOT NULL REFERENCES cursos(id_curso),
    nota         INTEGER NOT NULL CHECK (nota BETWEEN 1 AND 5),
    comentario   TEXT,
    data_avaliacao DATE  NOT NULL DEFAULT CURRENT_DATE,
    UNIQUE (id_usuario, id_curso)
);
