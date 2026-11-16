// =============================================================================
// OXYGENI HUB  |  Semanas 09-12 — Grafos e Cache
// Arquivo: 02_grafo_consultas.cypher
// Parte 2 — Consulta de Recomendação  |  Parte 3 — Desafio
//
// Objetivo: consultas Cypher para recomendação de produtos com base em
//           amizades e compras compartilhadas.
//
// Pré-requisito: executar 01_grafo_dados.cypher antes.
//
// Como executar:
//   cypher-shell -f 02_grafo_consultas.cypher
// =============================================================================

// =============================================================================
// PARTE 2 — Recomendação: "Amigos de amigos que compraram o Produto X"
// =============================================================================

// Cenário: Ana Silva quer saber quais produtos os amigos dos amigos dela
// compraram. Isso permite sugerir produtos que estão a "2 saltos" de distância
// no grafo social.
//
// Caminho no grafo:
//   (Ana)-[:AMIGO_DE]->(amigo)-[:AMIGO_DE]->(amigo_do_amigo)-[:COMPROU]->(produto)
//
// Filtros:
//   - O amigo do amigo não pode ser a própria Ana
//   - O produto não pode ser algo que Ana já comprou

MATCH (eu:Usuario {nome: "Ana Silva"})-[:AMIGO_DE]->(amigo)-[:AMIGO_DE]->(amigo2:Usuario)-[:COMPROU]->(produto:Produto)
WHERE amigo2 <> eu
  AND NOT (eu)-[:COMPROU]->(produto)
RETURN DISTINCT
  amigo2.nome   AS recomendado_por,
  produto.nome  AS produto_sugerido,
  produto.preco AS preco
ORDER BY produto.preco DESC;

// Resultado esperado: Daniel, Elena e Felipe (amigos dos amigos de Ana) compraram
// produtos que Ana ainda não tem — Smart TV, Teclado Mecânico, Mochila, Camiseta.

// -----------------------------------------------------------------------------
// Consulta complementar: ver o grafo de amizades de Ana (2 níveis)
// -----------------------------------------------------------------------------
MATCH caminho = (eu:Usuario {nome: "Ana Silva"})-[:AMIGO_DE*1..2]-(outro:Usuario)
WHERE outro <> eu
RETURN DISTINCT outro.nome AS conexao,
  length(caminho) AS distancia
ORDER BY distancia, conexao;

// =============================================================================
// PARTE 3 — Desafio: "Quem comprou X também comprou Y"
// =============================================================================

// Cenário: um usuário está vendo o "Notebook Gamer ProX". Queremos sugerir
// outros produtos que foram comprados por usuários que TAMBÉM compraram
// esse notebook.
//
// Caminho no grafo:
//   (produto_atual)<-[:COMPROU]-(outros_usuarios)-[:COMPROU]->(produto_sugerido)
//
// É o padrão clássico de "collaborative filtering" em grafos.

MATCH (alvo:Produto {nome: "Notebook Gamer ProX"})<-[:COMPROU]-(comprador)-[:COMPROU]->(sugestao:Produto)
WHERE sugestao <> alvo
RETURN sugestao.nome       AS produto_sugerido,
       sugestao.categoria  AS categoria,
       sugestao.preco      AS preco,
       count(comprador)    AS compradores_em_comum
ORDER BY compradores_em_comum DESC, sugestao.preco DESC;

// Resultado esperado: quem comprou o Notebook também comprou Fone Bluetooth,
// Teclado Mecânico e Mochila. O campo compradores_em_comum indica a força
// da recomendação (quanto mais pessoas compraram ambos, mais relevante).

// -----------------------------------------------------------------------------
// Consulta extra: recomendação personalizada para um usuário específico
// Combina os dois padrões — amizade + compras em comum
// -----------------------------------------------------------------------------
MATCH (eu:Usuario {nome: "Ana Silva"})-[:COMPROU]->(meu_produto)<-[:COMPROU]-(similar)-[:COMPROU]->(sugestao:Produto)
WHERE similar <> eu
  AND NOT (eu)-[:COMPROU]->(sugestao)
RETURN sugestao.nome      AS produto_sugerido,
       sugestao.categoria AS categoria,
       sugestao.preco     AS preco,
       count(similar)     AS score
ORDER BY score DESC;

// Esta consulta encontra: "usuários que compraram os mesmos produtos que Ana
// também compraram esses outros produtos que Ana ainda não comprou".
