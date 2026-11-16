-- =============================================================================
-- OXYGENI HUB  |  Sprint 4 - Modelagem Física (PostgreSQL)
-- Arquivo: 02_dados.sql
-- Objetivo: popular o banco com VOLUME realista usando generate_series().
--           Sem volume, o otimizador escolhe Seq Scan de propósito (é mais
--           barato varrer uma tabela pequena). Com ~200 mil predições, os
--           índices do 04_explain.sql passam a valer a pena e aparecem no plano.
--
-- Executar depois do 01_ddl.sql:  psql -d oxygeni_hub -f 02_dados.sql
-- =============================================================================
SET search_path TO oxygeni, public;

-- Semente fixa -> dados pseudo-aleatórios reproduzíveis entre execuções.
SELECT setseed(0.42);

-- 1. USUARIOS (50) ------------------------------------------------------------
INSERT INTO usuario (nome, email)
SELECT 'Usuario '  || g,
       'usuario' || g || '@oxygeni.dev'
FROM generate_series(1, 50) AS g;

-- 2. MODELOS_IA (200) ---------------------------------------------------------
INSERT INTO modelo_ia (nome, tipo, algoritmo, id_usuario)
SELECT 'Modelo '  || g,
       (ARRAY['classificacao','regressao','clusterizacao','nlp',
              'visao_computacional','recomendacao'])[1 + floor(random()*6)::int],
       (ARRAY['XGBoost','RandomForest','LogisticRegression','KMeans',
              'BERT','CNN'])[1 + floor(random()*6)::int],
       1 + floor(random()*50)::int
FROM generate_series(1, 200) AS g;

-- 3. DATASETS (200) -----------------------------------------------------------
INSERT INTO dataset (nome, descricao, tamanho_mb, id_modelo)
SELECT 'dataset_' || g,
       'Conjunto de dados sintético número ' || g,
       round((random()*5000 + 1)::numeric, 2),
       1 + floor(random()*200)::int
FROM generate_series(1, 200) AS g;

-- 4. TREINAMENTOS (1000) ------------------------------------------------------
--    status e data_fim coerentes: só treinos finalizados têm data de fim.
INSERT INTO treinamento (data_inicio, data_fim, status, id_modelo, id_dataset)
SELECT ini,
       CASE WHEN st IN ('concluido','falhou')
            THEN ini + (random() * interval '36 hours')
            ELSE NULL END,
       st,
       1 + floor(random()*200)::int,
       1 + floor(random()*200)::int
FROM (
    SELECT now() - (random() * interval '200 days') AS ini,
           (ARRAY['pendente','em_andamento','concluido','falhou'])[1 + floor(random()*4)::int] AS st
    FROM generate_series(1, 1000)
) s;

-- 5. METRICAS (4000) ----------------------------------------------------------
INSERT INTO metrica (nome, valor, id_treinamento)
SELECT (ARRAY['acuracia','precisao','recall','f1'])[1 + floor(random()*4)::int],
       round(random()::numeric, 4),
       1 + floor(random()*1000)::int
FROM generate_series(1, 4000) AS g;

-- 6. DEPLOYS (400) ------------------------------------------------------------
INSERT INTO deploy (ambiente, versao, status, id_modelo)
SELECT (ARRAY['desenvolvimento','homologacao','producao'])[1 + floor(random()*3)::int],
       'v' || (1 + floor(random()*5)::int) || '.' || floor(random()*10)::int,
       (ARRAY['ativo','inativo','descontinuado'])[1 + floor(random()*3)::int],
       1 + floor(random()*200)::int
FROM generate_series(1, 400) AS g;

-- 7. PREDICOES (200000) -> tabela grande, alvo do índice em data_hora ---------
INSERT INTO predicao (data_hora, entrada, resultado, id_modelo)
SELECT now() - (random() * interval '365 days'),
       '{"feature_a": ' || g || ', "feature_b": ' || round((random()*100)::numeric, 2) || '}',
       (ARRAY['positivo','negativo','fraude','legitimo'])[1 + floor(random()*4)::int],
       1 + floor(random()*200)::int
FROM generate_series(1, 200000) AS g;

-- 8. FEEDBACKS (20000) --------------------------------------------------------
INSERT INTO feedback (descricao, nota, id_predicao, id_usuario)
SELECT CASE WHEN random() < 0.5 THEN 'Comentário de avaliação ' || g ELSE NULL END,
       1 + floor(random()*5)::int,
       1 + floor(random()*200000)::int,
       1 + floor(random()*50)::int
FROM generate_series(1, 20000) AS g;

-- 9. PERMISSOES (500) -> ON CONFLICT protege a UNIQUE (id_usuario,id_modelo,tipo)
INSERT INTO permissao (tipo, id_usuario, id_modelo)
SELECT (ARRAY['leitura','escrita','admin'])[1 + floor(random()*3)::int],
       1 + floor(random()*50)::int,
       1 + floor(random()*200)::int
FROM generate_series(1, 500) AS g
ON CONFLICT (id_usuario, id_modelo, tipo) DO NOTHING;

-- Atualiza as estatísticas para o planejador tomar boas decisões no EXPLAIN.
ANALYZE;

-- Conferência rápida de volume por tabela.
SELECT 'usuario'     AS tabela, count(*) FROM usuario
UNION ALL SELECT 'modelo_ia',   count(*) FROM modelo_ia
UNION ALL SELECT 'dataset',     count(*) FROM dataset
UNION ALL SELECT 'treinamento', count(*) FROM treinamento
UNION ALL SELECT 'metrica',     count(*) FROM metrica
UNION ALL SELECT 'deploy',      count(*) FROM deploy
UNION ALL SELECT 'predicao',    count(*) FROM predicao
UNION ALL SELECT 'feedback',    count(*) FROM feedback
UNION ALL SELECT 'permissao',   count(*) FROM permissao;
