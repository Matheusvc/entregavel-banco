// =============================================================================
// OXYGENI HUB  |  Semana 13 — Persistência Poliglota
// Contexto: ESTOQUE (MongoDB)
// Arquivo: produtos.js
//
// Objetivo: demonstrar a flexibilidade de esquema do modelo de documentos,
//           onde cada produto pode ter atributos diferentes sem alterar tabelas.
// Foco: schema flexível, sem JOINs, leitura rápida.
//
// Como executar:
//   mongosh "mongodb://localhost:27017" produtos.js
// =============================================================================

db = db.getSiblingDB("estoque_db");

// Idempotência
db.produtos.drop();

// -----------------------------------------------------------------------------
// Inserção de produtos com esquema flexível
//
// Cada produto tem campos comuns (nome, categoria, preco, estoque, fornecedor)
// e campos ESPECÍFICOS que variam por tipo de produto.
//
// Em um banco relacional, isso exigiria:
//   - Uma tabela genérica + tabelas auxiliares por tipo (EAV pattern), ou
//   - Muitas colunas NULL para atributos que não se aplicam a todos os produtos
//
// No MongoDB, cada documento pode ter sua própria estrutura.
// -----------------------------------------------------------------------------

const resultado = db.produtos.insertMany([
  {
    nome: "Smartphone Galaxy Ultra 256GB",
    categoria: "Eletrônicos",
    preco: 5499.90,
    estoque: 45,
    fornecedor: { nome: "TechDistribui", cnpj: "12.345.678/0001-90" },
    tags: ["smartphone", "5G", "android"],
    especificacoes: {
      tela: "6.8 polegadas AMOLED",
      bateria: "5000 mAh",
      ram: "12 GB",
      armazenamento: "256 GB",
      camera_principal: "200 MP",
      camera_frontal: "12 MP",
      processador: "Snapdragon 8 Gen 3",
      sistema_operacional: "Android 15",
      resistencia_agua: "IP68"
    }
  },

  {
    nome: "Camiseta Básica Algodão",
    categoria: "Vestuário",
    preco: 49.90,
    estoque: 500,
    fornecedor: { nome: "TextilBR", cnpj: "98.765.432/0001-10" },
    tags: ["vestuário", "básico", "algodão"],
    especificacoes: {
      material: "100% algodão",
      cor: "Branco",
      tamanho: "M"
    }
  },

  {
    nome: "Notebook ProBook 15",
    categoria: "Informática",
    preco: 4299.00,
    estoque: 30,
    fornecedor: { nome: "TechDistribui", cnpj: "12.345.678/0001-90" },
    tags: ["notebook", "trabalho", "portátil"],
    especificacoes: {
      tela: "15.6 polegadas IPS",
      processador: "Intel Core i7-13700H",
      ram: "16 GB DDR5",
      armazenamento: "512 GB SSD NVMe",
      placa_video: "Intel Iris Xe",
      bateria: "56 Wh",
      peso: "1.7 kg",
      sistema_operacional: "Windows 11 Pro"
    }
  },

  {
    nome: "Cadeira Ergonômica Office Pro",
    categoria: "Móveis",
    preco: 1899.00,
    estoque: 15,
    fornecedor: { nome: "MóveisTop", cnpj: "11.222.333/0001-44" },
    tags: ["escritório", "ergonômico", "home office"],
    especificacoes: {
      material_assento: "Mesh respirável",
      material_estrutura: "Aço e nylon",
      peso_suportado: "150 kg",
      ajuste_altura: true,
      apoio_lombar: true,
      apoio_braco: "4D ajustável",
      rodizio: "Silicone (piso duro)"
    }
  },

  {
    nome: "Café Especial Orgânico 1kg",
    categoria: "Alimentos",
    preco: 89.90,
    estoque: 200,
    fornecedor: { nome: "FazendaBoa", cnpj: "55.666.777/0001-88" },
    tags: ["café", "orgânico", "especial"],
    especificacoes: {
      origem: "Sul de Minas Gerais",
      torra: "Média",
      tipo_grao: "Arábica",
      altitude_cultivo: "1200m",
      certificacao: "Orgânico Brasil",
      validade: "12 meses",
      peso_liquido: "1 kg"
    }
  }
]);

print("\n=== CONTEXTO ESTOQUE — MongoDB ===");
print("Produtos inseridos: " + resultado.insertedIds.length);

// -----------------------------------------------------------------------------
// Demonstração: cada produto tem especificações completamente diferentes
// -----------------------------------------------------------------------------
print("\n--- Flexibilidade de esquema ---");
db.produtos.find({}, { nome: 1, "especificacoes": 1, _id: 0 }).forEach(doc => {
  const campos = Object.keys(doc.especificacoes);
  print("\n  " + doc.nome);
  print("  Campos de especificação (" + campos.length + "): " + campos.join(", "));
});

// Um smartphone tem 9 campos de especificação; uma camiseta tem 3.
// No MongoDB, isso é natural. No SQL, seria um pesadelo de NULLs ou JOINs.

// Consulta: produtos em estoque baixo (< 20 unidades)
print("\n--- Produtos com estoque baixo (<20) ---");
db.produtos.find(
  { estoque: { $lt: 20 } },
  { nome: 1, estoque: 1, _id: 0 }
).forEach(doc => {
  print("  " + doc.nome + " — " + doc.estoque + " unidades");
});

// Consulta: buscar por fornecedor
print("\n--- Produtos do fornecedor 'TechDistribui' ---");
db.produtos.find(
  { "fornecedor.nome": "TechDistribui" },
  { nome: 1, preco: 1, _id: 0 }
).forEach(doc => {
  print("  " + doc.nome + " — R$ " + doc.preco.toFixed(2));
});

print("\n✔ Contexto Estoque concluído.\n");
