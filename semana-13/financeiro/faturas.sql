-- =============================================================================
-- OXYGENI HUB  |  Semana 13 — Persistência Poliglota
-- Contexto: FINANCEIRO (PostgreSQL)
-- Arquivo: faturas.sql
--
-- Objetivo: modelagem relacional com transações ACID para controle financeiro.
-- Foco: consistência, integridade e transações seguras.
--
-- Como executar:
--   psql -U postgres -f faturas.sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Criação do banco e tabelas
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS faturas;
DROP TABLE IF EXISTS clientes;

CREATE TABLE clientes (
    id_cliente  SERIAL       PRIMARY KEY,
    nome        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    saldo       DECIMAL(12,2) NOT NULL DEFAULT 0.00
);

CREATE TABLE faturas (
    id_fatura      SERIAL        PRIMARY KEY,
    id_cliente     INTEGER       NOT NULL REFERENCES clientes(id_cliente),
    descricao      VARCHAR(200)  NOT NULL,
    valor          DECIMAL(12,2) NOT NULL CHECK (valor > 0),
    status         VARCHAR(20)   NOT NULL DEFAULT 'pendente'
                   CHECK (status IN ('pendente', 'paga', 'cancelada')),
    data_emissao   DATE          NOT NULL DEFAULT CURRENT_DATE,
    data_vencimento DATE         NOT NULL
);

-- -----------------------------------------------------------------------------
-- Inserção de dados
-- -----------------------------------------------------------------------------

INSERT INTO clientes (nome, email, saldo) VALUES
    ('Ana Silva',    'ana@email.com',    5000.00),
    ('Bruno Costa',  'bruno@email.com',  1200.00),
    ('Carla Mendes', 'carla@email.com',   800.00);

INSERT INTO faturas (id_cliente, descricao, valor, status, data_emissao, data_vencimento) VALUES
    (1, 'Licença anual plataforma IA',      2400.00, 'paga',     '2026-10-01', '2026-10-31'),
    (1, 'Treinamento equipe técnica',        1500.00, 'pendente', '2026-11-01', '2026-11-30'),
    (2, 'Consultoria modelo preditivo',      3200.00, 'pendente', '2026-11-05', '2026-12-05'),
    (3, 'Suporte técnico mensal',             450.00, 'paga',     '2026-10-15', '2026-11-15'),
    (3, 'Deploy infraestrutura cloud',       1800.00, 'pendente', '2026-11-10', '2026-12-10');

-- -----------------------------------------------------------------------------
-- Parte 2 — Consulta: total faturado por status
-- -----------------------------------------------------------------------------

-- Total geral faturado
SELECT SUM(valor) AS total_faturado
FROM faturas;

-- Total faturado agrupado por status
SELECT status,
       COUNT(*)   AS quantidade,
       SUM(valor) AS total
FROM faturas
GROUP BY status
ORDER BY total DESC;

-- Total faturado por cliente
SELECT c.nome,
       COUNT(f.id_fatura) AS faturas,
       SUM(f.valor)       AS total_faturado
FROM clientes c
JOIN faturas f ON c.id_cliente = f.id_cliente
GROUP BY c.nome
ORDER BY total_faturado DESC;

-- =============================================================================
-- Parte 3 — BÔNUS: Transação que falha se o saldo for insuficiente
-- =============================================================================

-- Cenário: Carla Mendes (saldo R$ 800) tenta pagar a fatura de R$ 1800.
-- A transação deve verificar o saldo ANTES de debitar.
-- Se insuficiente, faz ROLLBACK e nenhuma alteração é persistida.

-- Transação 1: pagamento que FALHA (saldo insuficiente)
DO $$
DECLARE
    v_cliente_id  INTEGER := 3;    -- Carla Mendes
    v_fatura_id   INTEGER := 5;    -- Deploy infraestrutura cloud (R$ 1800)
    v_valor       DECIMAL(12,2);
    v_saldo       DECIMAL(12,2);
BEGIN
    -- Buscar valor da fatura
    SELECT valor INTO v_valor
    FROM faturas
    WHERE id_fatura = v_fatura_id;

    -- Buscar saldo do cliente
    SELECT saldo INTO v_saldo
    FROM clientes
    WHERE id_cliente = v_cliente_id;

    -- Verificar se o saldo é suficiente
    IF v_saldo < v_valor THEN
        RAISE NOTICE '✘ ROLLBACK: Saldo insuficiente. Saldo: R$ %, Valor da fatura: R$ %', v_saldo, v_valor;
        RAISE EXCEPTION 'Saldo insuficiente para o pagamento.';
    END IF;

    -- Se chegou aqui, o saldo é suficiente: debitar e marcar como paga
    UPDATE clientes SET saldo = saldo - v_valor WHERE id_cliente = v_cliente_id;
    UPDATE faturas  SET status = 'paga'         WHERE id_fatura = v_fatura_id;

    RAISE NOTICE '✔ COMMIT: Pagamento de R$ % realizado. Novo saldo: R$ %', v_valor, v_saldo - v_valor;
END $$;
-- Resultado: ROLLBACK — saldo de R$ 800 < fatura de R$ 1800

-- Verificar que nada mudou
SELECT nome, saldo FROM clientes WHERE id_cliente = 3;
SELECT id_fatura, descricao, valor, status FROM faturas WHERE id_fatura = 5;

-- Transação 2: pagamento que SUCEDE (saldo suficiente)
DO $$
DECLARE
    v_cliente_id  INTEGER := 1;    -- Ana Silva
    v_fatura_id   INTEGER := 2;    -- Treinamento equipe técnica (R$ 1500)
    v_valor       DECIMAL(12,2);
    v_saldo       DECIMAL(12,2);
BEGIN
    SELECT valor INTO v_valor FROM faturas WHERE id_fatura = v_fatura_id;
    SELECT saldo INTO v_saldo FROM clientes WHERE id_cliente = v_cliente_id;

    IF v_saldo < v_valor THEN
        RAISE EXCEPTION 'Saldo insuficiente para o pagamento.';
    END IF;

    UPDATE clientes SET saldo = saldo - v_valor WHERE id_cliente = v_cliente_id;
    UPDATE faturas  SET status = 'paga'         WHERE id_fatura = v_fatura_id;

    RAISE NOTICE '✔ COMMIT: Pagamento de R$ % realizado. Novo saldo: R$ %', v_valor, v_saldo - v_valor;
END $$;
-- Resultado: COMMIT — saldo de R$ 5000 > fatura de R$ 1500

-- Verificar que a alteração foi persistida
SELECT nome, saldo FROM clientes WHERE id_cliente = 1;
SELECT id_fatura, descricao, valor, status FROM faturas WHERE id_fatura = 2;
