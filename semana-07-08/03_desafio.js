// =============================================================================
// OXYGENI HUB  |  Semanas 07-08 — Modelagem NoSQL com MongoDB
// Arquivo: 03_desafio.js
// Parte 3 — Tarefa de Casa (Desafio)
//
// Objetivo: utilizar $elemMatch para filtrar arrays de subdocumentos e
//           .explain("executionStats") para comprovar o uso de índices.
//
// Pré-requisito: executar 01_insercao_dados.js e 02_indices_consultas.js
//                antes deste script.
//
// Como executar:
//   mongosh "mongodb://localhost:27017" 03_desafio.js
// =============================================================================

db = db.getSiblingDB("ecommerce_db");

print("\n=== PARTE 3 — Desafio ===\n");

// -----------------------------------------------------------------------------
// 3.1  Consulta com $elemMatch
//
// Cenário: encontrar produtos que possuam uma variação de tamanho "M" E cor
// "Azul" no MESMO elemento do array `variacoes`.
//
// Por que $elemMatch? Sem ele, a query { "variacoes.cor": "Azul",
// "variacoes.tamanho": "M" } retornaria documentos que têm "Azul" em QUALQUER
// elemento e "M" em QUALQUER outro — mesmo que não existam juntos.
// $elemMatch garante que AMBAS as condições sejam satisfeitas no MESMO
// subdocumento do array.
// -----------------------------------------------------------------------------
print('--- 3.1  $elemMatch: variação com tamanho "M" e cor "Azul" ---');

const resultadoElemMatch = db.produtos.find(
  {
    variacoes: {
      $elemMatch: { tamanho: "M", cor: "Azul" }
    }
  },
  { titulo: 1, variacoes: 1, _id: 0 }
).toArray();

if (resultadoElemMatch.length === 0) {
  print("  Nenhum produto encontrado com variação tamanho 'M' e cor 'Azul'.");
} else {
  resultadoElemMatch.forEach(doc => {
    print("  Produto: " + doc.titulo);
    doc.variacoes.forEach(v => {
      const match = (v.tamanho === "M" && v.cor === "Azul") ? " ← MATCH" : "";
      print("    - cor: " + v.cor + ", tamanho: " + v.tamanho + ", sku: " + v.sku + match);
    });
  });
}

// Demonstração extra: consulta SEM $elemMatch (resultado incorreto)
print('\n--- Comparação: mesma busca SEM $elemMatch (pode retornar falsos positivos) ---');

const semElemMatch = db.produtos.find(
  {
    "variacoes.tamanho": "M",
    "variacoes.cor": "Azul"
  },
  { titulo: 1, _id: 0 }
).toArray();

print("  Produtos encontrados SEM $elemMatch: " + semElemMatch.length);
semElemMatch.forEach(doc => print("    - " + doc.titulo));

print("  Produtos encontrados COM $elemMatch: " + resultadoElemMatch.length);
resultadoElemMatch.forEach(doc => print("    - " + doc.titulo));

print("\n  → Se os números diferirem, significa que a consulta sem $elemMatch");
print("    trouxe falsos positivos (documentos onde 'M' e 'Azul' estão em");
print("    subdocumentos DIFERENTES do array).\n");

// -----------------------------------------------------------------------------
// 3.2  BÔNUS: explain("executionStats")
//
// Comprova que o índice idx_preco criado na Parte 2 está sendo utilizado.
// Métricas importantes:
//   - winningPlan.stage → deve ser IXSCAN (Index Scan) em vez de COLLSCAN
//   - totalKeysExamined → número de chaves do índice percorridas
//   - totalDocsExamined → número de documentos lidos
//   - executionTimeMillis → tempo de execução em milissegundos
// -----------------------------------------------------------------------------
print("--- 3.2  BÔNUS: explain('executionStats') sobre consulta com índice de preço ---");
print("    Consulta: produtos com preço menor que R$ 500\n");

const explicacao = db.produtos.find(
  { preco: { $lt: 500 } }
).explain("executionStats");

const stats = explicacao.executionStats;
const plan  = explicacao.queryPlanner.winningPlan;

// Função auxiliar para encontrar o estágio IXSCAN na árvore de planos
function encontrarEstagio(node, tipo) {
  if (node.stage === tipo) return node;
  if (node.inputStage) return encontrarEstagio(node.inputStage, tipo);
  if (node.inputStages) {
    for (const child of node.inputStages) {
      const found = encontrarEstagio(child, tipo);
      if (found) return found;
    }
  }
  return null;
}

print("  Plano vencedor (winningPlan.stage): " + plan.stage);

const ixscan = encontrarEstagio(plan, "IXSCAN");
if (ixscan) {
  print("  Estágio de índice encontrado: IXSCAN");
  print("  Índice utilizado: " + ixscan.indexName);
  print("  Direção do scan: " + ixscan.direction);
} else {
  print("  ⚠ Nenhum IXSCAN encontrado — o índice pode não ter sido usado.");
}

print("\n  === Estatísticas de Execução ===");
print("  Documentos retornados (nReturned):     " + stats.nReturned);
print("  Chaves do índice examinadas (totalKeysExamined): " + stats.totalKeysExamined);
print("  Documentos examinados (totalDocsExamined):       " + stats.totalDocsExamined);
print("  Tempo de execução (executionTimeMillis):         " + stats.executionTimeMillis + " ms");

if (stats.totalKeysExamined > 0 && stats.totalKeysExamined <= stats.totalDocsExamined) {
  print("\n  ✔ O índice 'idx_preco' está sendo utilizado! O MongoDB percorreu");
  print("    apenas " + stats.totalKeysExamined + " chave(s) do índice para encontrar " + stats.nReturned + " documento(s),");
  print("    em vez de fazer um COLLSCAN (varredura completa da coleção).");
} else if (stats.totalKeysExamined > 0) {
  print("\n  ✔ O índice está sendo utilizado (totalKeysExamined = " + stats.totalKeysExamined + ").");
}

print("\n✔ Parte 3 concluída com sucesso.\n");
