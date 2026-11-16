// =============================================================================
// OXYGENI HUB  |  Sprint 6 - Consultas e análise no MongoDB
// Arquivo: 10_mongodb_consultas.js
// Objetivo: demonstrar consultas com filtro (find), ordenação (sort) e projeção
//           de campos, uma busca por índice de TEXTO, a leitura de dados
//           EMBEDDED e REFERENCED, e a análise de plano com explain().
//
// Pré-requisito: rodar antes o 09_mongodb_setup.js (cria dados e índices).
// Como executar:
//   mongosh "mongodb://localhost:27017/oxygeni_nosql" 10_mongodb_consultas.js
// =============================================================================
db = db.getSiblingDB("oxygeni_nosql");

print("\n===== 1) FIND + PROJECTION + SORT =====");
// Predições de fraude do modelo de PIX, só os campos úteis, mais recentes primeiro.
// Filtro (find) + projeção (esconde _id/entrada) + ordenação (sort por data DESC).
db.predicoes.find(
  { modelo_id: "mdl_fraude_pix", resultado: "fraude" },     // filtro
  { _id: 0, resultado: 1, score: 1, criado_em: 1 }          // projeção
).sort({ criado_em: -1 }).forEach(printjson);               // ordenação

print("\n===== 2) BUSCA POR ÍNDICE DE TEXTO =====");
// Usa o índice de texto (idx_modelos_texto) para procurar "fraude" em nome/descrição/tags.
db.modelos.find(
  { $text: { $search: "fraude" } },
  { _id: 1, nome: 1, tipo: 1, score: { $meta: "textScore" } }
).sort({ score: { $meta: "textScore" } }).forEach(printjson);

print("\n===== 3) LEITURA DE DADOS EMBEDDED =====");
// Hiperparâmetros e métricas vêm embutidos: uma única leitura, sem join.
db.modelos.find(
  { tipo: "classificacao" },
  { _id: 1, nome: 1, "hiperparametros": 1, "metricas.nome": 1, "metricas.valor": 1 }
).forEach(printjson);

print("\n===== 4) REFERENCING: juntar predição -> modelo manualmente =====");
// Como modelo_id é uma REFERÊNCIA, a "junção" é feita pela aplicação (ou $lookup).
// Aqui mostramos o nome do modelo de cada predição com feedback registrado.
db.predicoes.find({ feedback: { $exists: true } }).forEach(function (p) {
  const m = db.modelos.findOne({ _id: p.modelo_id }, { nome: 1 });
  print("- " + (m ? m.nome : "?") + " | resultado=" + p.resultado +
        " | nota_feedback=" + p.feedback.nota);
});

print("\n===== 4b) REFERENCING com $lookup (agregação) =====");
// Alternativa nativa ao join: $lookup liga predicoes.modelo_id -> modelos._id.
db.predicoes.aggregate([
  { $match: { resultado: "fraude" } },
  { $lookup: { from: "modelos", localField: "modelo_id", foreignField: "_id", as: "modelo" } },
  { $project: { _id: 0, resultado: 1, score: 1, "modelo.nome": 1 } }
]).forEach(printjson);

print("\n===== 5) EXPLAIN(): o índice composto está sendo usado? =====");
// Mesma consulta do item 1, agora com explain("executionStats").
// Esperado: stage IXSCAN usando idx_pred_modelo_data (sem COLLSCAN).
const plano = db.predicoes.find({ modelo_id: "mdl_fraude_pix" })
  .sort({ criado_em: -1 })
  .explain("executionStats");

printjson({
  vencedor_stage: plano.queryPlanner.winningPlan,
  indice_usado:
    (plano.queryPlanner.winningPlan.inputStage &&
     plano.queryPlanner.winningPlan.inputStage.indexName) ||
    (plano.queryPlanner.winningPlan.stage),
  docsExaminados: plano.executionStats.totalDocsExamined,
  chavesExaminadas: plano.executionStats.totalKeysExamined,
  docsRetornados: plano.executionStats.nReturned,
  tempo_ms: plano.executionStats.executionTimeMillis
});
