-- ============================================================
-- SPRINT 3 - DO CONCEITO À TABELA
-- Banco de Dados: PostgreSQL
-- ============================================================

-- ============================================================
-- 1. TABELA USUARIO
-- ============================================================

CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE
);

-- ============================================================
-- 2. TABELA MODELO_IA
-- ============================================================

CREATE TABLE modelo_ia (
    id_modelo SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    algoritmo VARCHAR(100) NOT NULL,
    id_usuario INTEGER NOT NULL,

    CONSTRAINT modelo_ia_id_usuario_fkey
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
);

-- ============================================================
-- 3. TABELA DATASET
-- ============================================================

CREATE TABLE dataset (
    id_dataset SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(255),
    tamanho_mb NUMERIC(10,2) CHECK (tamanho_mb >= 0),
    id_modelo INTEGER NOT NULL,

    CONSTRAINT dataset_id_modelo_fkey
        FOREIGN KEY (id_modelo)
        REFERENCES modelo_ia(id_modelo)
);

-- ============================================================
-- 4. TABELA TREINAMENTO
-- ============================================================

CREATE TABLE treinamento (
    id_treinamento SERIAL PRIMARY KEY,
    data_inicio TIMESTAMP NOT NULL,
    data_fim TIMESTAMP,
    status VARCHAR(50) NOT NULL,
    id_modelo INTEGER NOT NULL,
    id_dataset INTEGER NOT NULL,

    CONSTRAINT treinamento_id_modelo_fkey
        FOREIGN KEY (id_modelo)
        REFERENCES modelo_ia(id_modelo),

    CONSTRAINT treinamento_id_dataset_fkey
        FOREIGN KEY (id_dataset)
        REFERENCES dataset(id_dataset),

    CONSTRAINT treinamento_datas_check
        CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);

-- ============================================================
-- 5. TABELA METRICA
-- ============================================================

CREATE TABLE metrica (
    id_metrica SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    valor NUMERIC(10,4) CHECK (valor >= 0),
    data_avaliacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_treinamento INTEGER NOT NULL,

    CONSTRAINT metrica_id_treinamento_fkey
        FOREIGN KEY (id_treinamento)
        REFERENCES treinamento(id_treinamento)
);

-- ============================================================
-- 6. TABELA DEPLOY
-- ============================================================

CREATE TABLE deploy (
    id_deploy SERIAL PRIMARY KEY,
    ambiente VARCHAR(50) NOT NULL,
    versao VARCHAR(50) NOT NULL,
    data_deploy TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL,
    id_modelo INTEGER NOT NULL,

    CONSTRAINT deploy_id_modelo_fkey
        FOREIGN KEY (id_modelo)
        REFERENCES modelo_ia(id_modelo)
);

-- ============================================================
-- 7. TABELA PREDICAO
-- ============================================================

CREATE TABLE predicao (
    id_predicao SERIAL PRIMARY KEY,
    data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entrada TEXT NOT NULL,
    resultado TEXT NOT NULL,
    id_modelo INTEGER NOT NULL,

    CONSTRAINT predicao_id_modelo_fkey
        FOREIGN KEY (id_modelo)
        REFERENCES modelo_ia(id_modelo)
);

-- ============================================================
-- 8. TABELA FEEDBACK
-- ============================================================

CREATE TABLE feedback (
    id_feedback SERIAL PRIMARY KEY,
    descricao TEXT,
    nota INTEGER NOT NULL CHECK (nota BETWEEN 1 AND 5),
    data_feedback TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_predicao INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,

    CONSTRAINT feedback_id_predicao_fkey
        FOREIGN KEY (id_predicao)
        REFERENCES predicao(id_predicao),

    CONSTRAINT feedback_id_usuario_fkey
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
);

-- ============================================================
-- 9. TABELA PERMISSAO
-- ============================================================

CREATE TABLE permissao (
    id_permissao SERIAL PRIMARY KEY,
    tipo VARCHAR(50) NOT NULL,
    id_usuario INTEGER NOT NULL,
    id_modelo INTEGER NOT NULL,

    CONSTRAINT permissao_id_usuario_fkey
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario),

    CONSTRAINT permissao_id_modelo_fkey
        FOREIGN KEY (id_modelo)
        REFERENCES modelo_ia(id_modelo)
);

-- ============================================================
-- INSERTS
-- 3 REGISTROS POR TABELA
-- ============================================================

-- ============================================================
-- 10. INSERTS - USUARIO
-- ============================================================

INSERT INTO usuario (nome, email)
VALUES
('Maria Silva', 'maria.silva@email.com'),
('Joao Santos', 'joao.santos@email.com'),
('Ana Oliveira', 'ana.oliveira@email.com');

-- ============================================================
-- 11. INSERTS - MODELO_IA
-- ============================================================

INSERT INTO modelo_ia
(nome, tipo, algoritmo, id_usuario)
VALUES
('Classificador de Imagens', 'Classificacao', 'CNN', 1),
('Previsor de Vendas', 'Regressao', 'Random Forest', 2),
('Detector de Objetos', 'Visao Computacional', 'YOLO', 3);

-- ============================================================
-- 12. INSERTS - DATASET
-- ============================================================

INSERT INTO dataset
(nome, descricao, tamanho_mb, id_modelo)
VALUES
(
    'Dataset Imagens Produtos',
    'Imagens utilizadas para classificacao de produtos',
    850.50,
    1
),
(
    'Dataset Vendas 2025',
    'Dados historicos de vendas',
    320.75,
    2
),
(
    'Dataset Objetos',
    'Imagens para deteccao de objetos',
    1250.30,
    3
);

-- ============================================================
-- 13. INSERTS - TREINAMENTO
-- ============================================================

INSERT INTO treinamento
(data_inicio, data_fim, status, id_modelo, id_dataset)
VALUES
(
    '2026-09-01 08:00:00',
    '2026-09-01 10:30:00',
    'Concluido',
    1,
    1
),
(
    '2026-09-02 09:00:00',
    '2026-09-02 12:00:00',
    'Concluido',
    2,
    2
),
(
    '2026-09-03 14:00:00',
    '2026-09-03 18:00:00',
    'Concluido',
    3,
    3
);

-- ============================================================
-- 14. INSERTS - METRICA
-- ============================================================

INSERT INTO metrica
(nome, valor, data_avaliacao, id_treinamento)
VALUES
(
    'Acuracia',
    0.9450,
    '2026-09-01 11:00:00',
    1
),
(
    'Precisao',
    0.9125,
    '2026-09-02 13:00:00',
    2
),
(
    'Recall',
    0.8890,
    '2026-09-03 19:00:00',
    3
);

-- ============================================================
-- 15. INSERTS - DEPLOY
-- ============================================================

INSERT INTO deploy
(ambiente, versao, status, id_modelo)
VALUES
(
    'Producao',
    '1.0.0',
    'Ativo',
    1
),
(
    'Homologacao',
    '1.2.0',
    'Ativo',
    2
),
(
    'Desenvolvimento',
    '2.0.0',
    'Testando',
    3
);

-- ============================================================
-- 16. INSERTS - PREDICAO
-- ============================================================

INSERT INTO predicao
(entrada, resultado, id_modelo)
VALUES
(
    'imagem_produto_001.jpg',
    'Produto classificado como eletronico',
    1
),
(
    'vendas_janeiro.csv',
    'Previsao de vendas: R$ 15000',
    2
),
(
    'imagem_camera_001.jpg',
    'Objeto detectado: pessoa',
    3
);

-- ============================================================
-- 17. INSERTS - FEEDBACK
-- ============================================================

INSERT INTO feedback
(descricao, nota, id_predicao, id_usuario)
VALUES
(
    'Resultado muito preciso',
    5,
    1,
    1
),
(
    'Previsao apresentou bom desempenho',
    4,
    2,
    2
),
(
    'Deteccao poderia ser mais precisa',
    3,
    3,
    3
);

-- ============================================================
-- 18. INSERTS - PERMISSAO
-- ============================================================

INSERT INTO permissao
(tipo, id_usuario, id_modelo)
VALUES
(
    'Administrador',
    1,
    1
),
(
    'Editor',
    2,
    2
),
(
    'Visualizador',
    3,
    3
);

-- ============================================================
-- SELECTS COM JOIN
-- ============================================================

-- ============================================================
-- 19. SELECT 1
-- Usuarios e seus modelos de IA
-- ============================================================

SELECT
    u.id_usuario,
    u.nome AS usuario,
    u.email,
    m.id_modelo,
    m.nome AS modelo,
    m.tipo,
    m.algoritmo
FROM usuario u
INNER JOIN modelo_ia m
    ON u.id_usuario = m.id_usuario;

-- ============================================================
-- 20. SELECT 2
-- Treinamentos, modelos, datasets e metricas
-- ============================================================

SELECT
    t.id_treinamento,
    m.nome AS modelo,
    d.nome AS dataset,
    t.status AS status_treinamento,
    me.nome AS metrica,
    me.valor
FROM treinamento t
INNER JOIN modelo_ia m
    ON t.id_modelo = m.id_modelo
INNER JOIN dataset d
    ON t.id_dataset = d.id_dataset
INNER JOIN metrica me
    ON t.id_treinamento = me.id_treinamento;
