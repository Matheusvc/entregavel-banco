// =============================================================================
// OXYGENI HUB  |  Semanas 07-08 — Modelagem NoSQL com MongoDB
// Arquivo: 02_indices_consultas.js
// Parte 2 — Mini Projeto (Índices e Consultas)
//
// Objetivo: criar índices (simples e de texto) e realizar consultas com filtros
//           variados sobre a coleção de produtos do e-commerce.
//
// Pré-requisito: executar 01_insercao_dados.js antes deste script.
//
// Como executar:
//   mongosh "mongodb://localhost:27017" 02_indices_consultas.js
// =============================================================================

db = db.getSiblingDB("ecommerce_db");

print("\n=== PARTE 2 — Índices e Consultas ===\n");

// -----------------------------------------------------------------------------
// 2.1  Índice simples em campo de alta consulta
// Justificativa: consultas por faixa de preço são muito comuns em e-commerce
// (ex: "produtos até R$ 500"). Índice ascendente para ordenação do menor para
// o maior preço.
// -----------------------------------------------------------------------------
print("--- 2.1  Criando índice simples em 'preco' ---");
db.produtos.createIndex({ preco: 1 }, { name: "idx_preco" });
print("Índice 'idx_preco' criado com sucesso.\n");

// -----------------------------------------------------------------------------
// 2.2  Índice de texto para busca textual
// Justificativa: permite que o usuário pesquise produtos por palavras-chave
// presentes no título e na descrição (ex: "notebook gamer").
// NOTA: o MongoDB permite apenas UM índice de texto por coleção.
// -----------------------------------------------------------------------------
print("--- 2.2  Criando índice de texto em 'titulo' e 'descricao' ---");
db.produtos.createIndex(
  { titulo: "text", descricao: "text" },
  { name: "idx_texto_titulo_descricao", default_language: "portuguese" }
);
print("Índice de texto 'idx_texto_titulo_descricao' criado com sucesso.\n");

// Verificação dos índices criados
print("--- Índices da coleção 'produtos' ---");
db.produtos.getIndexes().forEach(idx => {
  print("  " + idx.name + "  →  " + JSON.stringify(idx.key));
});

// -----------------------------------------------------------------------------
// 2.3  Consultas com filtros variados
// -----------------------------------------------------------------------------

// CONSULTA 1: Operadores de comparação ($gt, $lte)
// Encontrar produtos com preço entre R$ 100 e R$ 1000
print("\n--- Consulta 1: Produtos com preço entre R$ 100 e R$ 1000 ($gt / $lte) ---");
db.produtos.find(
  { preco: { $gt: 100, $lte: 1000 } },
  { titulo: 1, preco: 1, _id: 0 }
).forEach(doc => {
  print("  " + doc.titulo + "  |  R$ " + doc.preco.toFixed(2));
});

// CONSULTA 2: Busca por valor dentro de um array
// Encontrar todos os produtos que possuem a tag "promoção"
print("\n--- Consulta 2: Produtos com a tag 'promoção' (busca em array) ---");
db.produtos.find(
  { tags: "promoção" },
  { titulo: 1, tags: 1, _id: 0 }
).forEach(doc => {
  print("  " + doc.titulo + "  |  tags: [" + doc.tags.join(", ") + "]");
});

// CONSULTA 3: Busca textual usando o índice de texto
// Pesquisar produtos que mencionem "notebook" no título ou na descrição
print("\n--- Consulta 3: Busca textual por 'notebook' ($text / $search) ---");
db.produtos.find(
  { $text: { $search: "notebook" } },
  { titulo: 1, descricao: 1, score: { $meta: "textScore" }, _id: 0 }
).sort(
  { score: { $meta: "textScore" } }
).forEach(doc => {
  print("  [score: " + doc.score.toFixed(2) + "]  " + doc.titulo);
  print("    " + doc.descricao.substring(0, 80) + "...");
});

print("\n✔ Parte 2 concluída com sucesso.\n");
