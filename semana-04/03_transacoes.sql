-- =============================================================================
-- OXYGENI HUB  |  Sprint 4 - Modelagem Física (PostgreSQL)
-- Arquivo: 03_transacoes.sql
-- Objetivo: 2 transações que gravam em MÚLTIPLAS tabelas garantindo atomicidade
--           (ACID). Demonstra BEGIN, COMMIT, ROLLBACK, SAVEPOINT e o uso de
--           RETURNING para capturar IDs gerados (SERIAL/BIGSERIAL) e reutilizá-los
--           nas tabelas filhas dentro da MESMA transação.
--
-- IMPORTANTE: este script contém ERROS PROPOSITAIS para demonstrar a recuperação.
-- Rode SEM ON_ERROR_STOP para que as transações sigam até o fim:
--   psql -d oxygeni_hub -f 03_transacoes.sql
--
-- Mecanismo do RETURNING: o comando \gset do psql guarda o valor retornado numa
-- variável (ex.: :t1_modelo) que é injetada nos INSERTs seguintes.
-- =============================================================================
SET search_path TO oxygeni, public;

-- =============================================================================
-- TRANSAÇÃO 1 -> Onboarding completo de um modelo (usuario -> modelo -> dataset
-- -> treinamento -> metrica), com SAVEPOINT para se recuperar de um erro sem
-- perder o trabalho já feito. Termina em COMMIT.
-- =============================================================================
\echo ''
\echo '########## TRANSACAO 1: onboarding de modelo (SAVEPOINT + RETURNING) ##########'
BEGIN;

INSERT INTO usuario (nome, email)
VALUES ('Dra. Ana Ferraz', 'ana.ferraz@oxygeni.dev')
RETURNING id_usuario AS t1_usuario \gset
\echo '-> usuario criado, id =' :t1_usuario

INSERT INTO modelo_ia (nome, tipo, algoritmo, id_usuario)
VALUES ('Detector de Fraude PIX', 'classificacao', 'XGBoost', :t1_usuario)
RETURNING id_modelo AS t1_modelo \gset
\echo '-> modelo criado, id =' :t1_modelo

-- Ponto de restauração antes de uma operação que pode falhar.
SAVEPOINT sp_dataset;

-- ERRO PROPOSITAL: tamanho_mb negativo viola o CHECK (tamanho_mb > 0).
\echo '-> tentando inserir dataset invalido (deve falhar):'
INSERT INTO dataset (nome, tamanho_mb, id_modelo)
VALUES ('fraude_pix_bruto', -120.00, :t1_modelo);

-- Volta ao SAVEPOINT: descarta só o INSERT que falhou, mantendo usuario e modelo.
ROLLBACK TO SAVEPOINT sp_dataset;
\echo '-> ROLLBACK TO SAVEPOINT: usuario e modelo preservados, erro descartado'

-- Reinsere o dataset com valor válido.
INSERT INTO dataset (nome, tamanho_mb, id_modelo)
VALUES ('fraude_pix_bruto', 845.30, :t1_modelo)
RETURNING id_dataset AS t1_dataset \gset
\echo '-> dataset corrigido, id =' :t1_dataset

INSERT INTO treinamento (data_fim, status, id_modelo, id_dataset)
VALUES (now(), 'concluido', :t1_modelo, :t1_dataset)
RETURNING id_treinamento AS t1_treino \gset
\echo '-> treinamento criado, id =' :t1_treino

INSERT INTO metrica (nome, valor, id_treinamento)
VALUES ('acuracia', 0.9812, :t1_treino);

COMMIT;
\echo '-> COMMIT: onboarding gravado de forma atômica.'

-- =============================================================================
-- TRANSAÇÃO 2 -> Registro de predição + feedback. Um erro na regra de negócio
-- dispara um ROLLBACK TOTAL (a predição some junto com o feedback inválido).
-- Em seguida, a versão correta é gravada com COMMIT.
-- =============================================================================
\echo ''
\echo '########## TRANSACAO 2: predicao + feedback (ROLLBACK total e depois COMMIT) ##########'
BEGIN;

INSERT INTO predicao (entrada, resultado, id_modelo)
VALUES ('{"valor": 15000, "canal": "pix"}', 'fraude', :t1_modelo)
RETURNING id_predicao AS t2_pred \gset
\echo '-> predicao criada (provisoria), id =' :t2_pred

-- ERRO PROPOSITAL: nota 9 viola o CHECK (nota BETWEEN 1 AND 5).
\echo '-> tentando inserir feedback com nota 9 (deve falhar):'
INSERT INTO feedback (nota, id_predicao, id_usuario)
VALUES (9, :t2_pred, :t1_usuario);

-- Sem SAVEPOINT aqui: o erro invalida a operação inteira -> desfaz TUDO.
ROLLBACK;
\echo '-> ROLLBACK: a predicao provisoria tambem foi desfeita (atomicidade).'

-- Versão correta, agora consistente.
BEGIN;
INSERT INTO predicao (entrada, resultado, id_modelo)
VALUES ('{"valor": 15000, "canal": "pix"}', 'fraude', :t1_modelo)
RETURNING id_predicao AS t2_pred_ok \gset

INSERT INTO feedback (nota, descricao, id_predicao, id_usuario)
VALUES (5, 'Predicao correta, fraude confirmada', :t2_pred_ok, :t1_usuario);
COMMIT;
\echo '-> COMMIT: predicao valida id =' :t2_pred_ok 'gravada com o feedback.'

-- =============================================================================
-- PROVA de que o ROLLBACK funcionou: a entrada específica da T2 aparece
-- exatamente 1 vez (a versão descartada não persistiu; só a versão com COMMIT).
-- =============================================================================
\echo ''
\echo '########## Verificacao de atomicidade ##########'
SELECT count(*) AS predicoes_pix_persistidas
FROM predicao
WHERE entrada = '{"valor": 15000, "canal": "pix"}';
