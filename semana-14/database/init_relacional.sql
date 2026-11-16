-- =============================================================================
-- OXYGENI HUB  |  Semana 14 — Projeto Final (Escopo Inicial)
-- Plataforma de Cursos Online — Contexto Relacional
-- Arquivo: init_relacional.sql
--
-- Tabelas: usuarios, cursos_meta, matriculas, pagamentos
-- Foco: dados transacionais com integridade ACID.
--
-- Como executar:
--   psql -U postgres -f init_relacional.sql
-- =============================================================================

DROP TABLE IF EXISTS pagamentos;
DROP TABLE IF EXISTS matriculas;
DROP TABLE IF EXISTS cursos_meta;
DROP TABLE IF EXISTS usuarios;

-- -----------------------------------------------------------------------------
-- 1. USUARIOS
-- Alunos e instrutores da plataforma.
-- -----------------------------------------------------------------------------

CREATE TABLE usuarios (
    id_usuario   SERIAL       PRIMARY KEY,
    nome         VARCHAR(100) NOT NULL,
    email        VARCHAR(150) NOT NULL UNIQUE,
    tipo         VARCHAR(20)  NOT NULL CHECK (tipo IN ('aluno', 'instrutor', 'admin')),
    data_cadastro DATE        NOT NULL DEFAULT CURRENT_DATE
);

-- -----------------------------------------------------------------------------
-- 2. CURSOS_META
-- Metadados do curso (relacional): preço, instrutor, status.
-- O conteúdo detalhado (aulas, módulos) fica no MongoDB (schema flexível).
-- -----------------------------------------------------------------------------

CREATE TABLE cursos_meta (
    id_curso     SERIAL        PRIMARY KEY,
    titulo       VARCHAR(200)  NOT NULL,
    id_instrutor INTEGER       NOT NULL REFERENCES usuarios(id_usuario),
    preco        DECIMAL(10,2) NOT NULL CHECK (preco >= 0),
    status       VARCHAR(20)   NOT NULL DEFAULT 'rascunho'
                 CHECK (status IN ('rascunho', 'publicado', 'arquivado')),
    data_criacao DATE          NOT NULL DEFAULT CURRENT_DATE
);

-- -----------------------------------------------------------------------------
-- 3. MATRICULAS
-- Relacionamento N:N entre alunos e cursos.
-- -----------------------------------------------------------------------------

CREATE TABLE matriculas (
    id_matricula  SERIAL      PRIMARY KEY,
    id_usuario    INTEGER     NOT NULL REFERENCES usuarios(id_usuario),
    id_curso      INTEGER     NOT NULL REFERENCES cursos_meta(id_curso),
    data_matricula DATE       NOT NULL DEFAULT CURRENT_DATE,
    progresso     INTEGER     NOT NULL DEFAULT 0 CHECK (progresso BETWEEN 0 AND 100),
    UNIQUE (id_usuario, id_curso)
);

-- -----------------------------------------------------------------------------
-- 4. PAGAMENTOS
-- Transações financeiras — integridade ACID obrigatória.
-- Regra de negócio (Bônus): valor deve ser positivo e status controlado.
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
-- Dados iniciais
-- -----------------------------------------------------------------------------

INSERT INTO usuarios (nome, email, tipo) VALUES
    ('Ana Silva',      'ana@email.com',      'instrutor'),
    ('Bruno Costa',    'bruno@email.com',    'aluno'),
    ('Carla Mendes',   'carla@email.com',    'aluno'),
    ('Daniel Rocha',   'daniel@email.com',   'instrutor'),
    ('Elena Ferreira', 'elena@email.com',    'aluno');

INSERT INTO cursos_meta (titulo, id_instrutor, preco, status) VALUES
    ('Python para Data Science',    1, 199.90, 'publicado'),
    ('Banco de Dados na Prática',   1, 149.90, 'publicado'),
    ('Machine Learning Avançado',   4, 299.90, 'publicado'),
    ('Introdução ao DevOps',        4,   0.00, 'rascunho');

INSERT INTO matriculas (id_usuario, id_curso, progresso) VALUES
    (2, 1, 45),
    (2, 2, 80),
    (3, 1, 20),
    (3, 3, 10),
    (5, 2, 100);

INSERT INTO pagamentos (id_matricula, valor, metodo, status) VALUES
    (1, 199.90, 'pix',    'aprovado'),
    (2, 149.90, 'cartao', 'aprovado'),
    (3, 199.90, 'pix',    'aprovado'),
    (4, 299.90, 'boleto', 'pendente'),
    (5, 149.90, 'cartao', 'aprovado');

-- Consulta de verificação
SELECT u.nome, c.titulo, m.progresso, p.status AS pagamento
FROM matriculas m
JOIN usuarios u    ON m.id_usuario = u.id_usuario
JOIN cursos_meta c ON m.id_curso   = c.id_curso
JOIN pagamentos p  ON m.id_matricula = p.id_matricula
ORDER BY u.nome, c.titulo;
