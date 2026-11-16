-- =============================================================================
-- OXYGENI HUB  |  Sprint 4 - Modelagem Física (PostgreSQL)
-- Arquivo: 04_explain.sql
-- Objetivo: usar EXPLAIN (ANALYZE, BUFFERS) para PROVAR que os índices criados
--           estão sendo usados pelo planejador (Index Scan) em vez de varredura
--           completa (Seq Scan). A opção BUFFERS mostra o custo real de I/O.
--
-- Executar depois de 01/02:  psql -d oxygeni_hub -f 04_explain.sql
-- =============================================================================
SET search_path TO oxygeni, public;

-- =============================================================================
-- CONSULTA 1 -> JOIN de 3 tabelas usando índices de CHAVE ESTRANGEIRA.
-- "Métricas dos treinamentos concluídos de um determinado usuário."
-- Esperado: filtro seletivo por id_usuario (idx_modelo_usuario) e Nested Loop
-- descendo por idx_treino_modelo e idx_metrica_treino, sem Seq Scan nas filhas.
-- =============================================================================
\echo ''
\echo '################## CONSULTA 1: JOIN com indices de FK ##################'
EXPLAIN (ANALYZE, BUFFERS)
SELECT mo.nome  AS modelo,
       t.status,
       m.nome   AS metrica,
       m.valor
FROM metrica m
JOIN treinamento t ON t.id_treinamento = m.id_treinamento
JOIN modelo_ia  mo ON mo.id_modelo      = t.id_modelo
WHERE t.status = 'concluido'
  AND mo.id_usuario = 7;

-- =============================================================================
-- CONSULTA 2 -> WHERE por período + ORDER BY em tabela grande (200 mil linhas).
-- Demonstração ANTES x DEPOIS: removemos o índice para ver o Seq Scan + Sort,
-- depois recriamos para ver o Index Scan que atende WHERE e ORDER BY de uma vez.
-- =============================================================================
\echo ''
\echo '################## CONSULTA 2 (ANTES): SEM indice em data_hora ##################'
DROP INDEX IF EXISTS idx_predicao_data_hora;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id_predicao, data_hora, id_modelo, resultado
FROM predicao
WHERE data_hora >= now() - interval '7 days'
ORDER BY data_hora DESC
LIMIT 100;

\echo ''
\echo '################## CONSULTA 2 (DEPOIS): COM indice em data_hora ##################'
CREATE INDEX idx_predicao_data_hora ON predicao (data_hora DESC);
EXPLAIN (ANALYZE, BUFFERS)
SELECT id_predicao, data_hora, id_modelo, resultado
FROM predicao
WHERE data_hora >= now() - interval '7 days'
ORDER BY data_hora DESC
LIMIT 100;
