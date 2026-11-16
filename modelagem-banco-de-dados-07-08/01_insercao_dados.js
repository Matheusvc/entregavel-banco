// =============================================================================
// OXYGENI HUB  |  Semanas 07-08 — Modelagem NoSQL com MongoDB
// Arquivo: 01_insercao_dados.js
// Parte 1 — Manipulação e Inserção de Dados (Exercício Guiado)
//
// Objetivo: criar o banco de dados, a coleção principal e inserir documentos
//           com arrays e subdocumentos, modelando um catálogo de e-commerce.
//
// Como executar:
//   mongosh "mongodb://localhost:27017" 01_insercao_dados.js
//   (ou dentro do mongosh:  load("01_insercao_dados.js"))
// =============================================================================

// 1. Seleciona / cria o banco de dados
db = db.getSiblingDB("ecommerce_db");

// Idempotência: limpa a coleção para poder rodar o script quantas vezes quiser.
db.produtos.drop();

// 2. Inserção de documentos com insertMany()
//    Cada documento possui:
//    - Pelo menos um ARRAY (tags, variacoes)
//    - Pelo menos um SUBDOCUMENTO (fabricante)
const resultado = db.produtos.insertMany([
  {
    titulo: "Notebook Gamer ProX 15",
    descricao: "Notebook gamer com tela de 15.6 polegadas, placa de vídeo dedicada e SSD de 512 GB. Ideal para jogos e edição de vídeo.",
    preco: 6499.90,
    categoria: "Informática",
    estoque: 25,
    data_cadastro: new Date("2026-10-01"),
    tags: ["eletrônicos", "gamer", "notebook", "promoção"],
    fabricante: {
      nome: "TechVision",
      pais: "Brasil",
      contato: "suporte@techvision.com.br"
    },
    variacoes: [
      { cor: "Preto",  tamanho: "15.6\"", sku: "NB-GPX15-PT" },
      { cor: "Prata",  tamanho: "15.6\"", sku: "NB-GPX15-PR" }
    ],
    avaliacoes: [
      { usuario: "carlos_m",  nota: 5, comentario: "Excelente desempenho!" },
      { usuario: "ana_lucia", nota: 4, comentario: "Muito bom, mas esquenta um pouco." }
    ]
  },

  {
    titulo: "Fone de Ouvido Bluetooth ANC",
    descricao: "Fone over-ear com cancelamento ativo de ruído, bateria de 30 horas e conexão multipontos.",
    preco: 349.90,
    categoria: "Áudio",
    estoque: 120,
    data_cadastro: new Date("2026-09-15"),
    tags: ["eletrônicos", "áudio", "bluetooth", "promoção"],
    fabricante: {
      nome: "SoundWave",
      pais: "China",
      contato: "vendas@soundwave.cn"
    },
    variacoes: [
      { cor: "Preto", tamanho: "Único", sku: "FO-BT-ANC-PT" },
      { cor: "Branco", tamanho: "Único", sku: "FO-BT-ANC-BR" },
      { cor: "Azul",  tamanho: "Único", sku: "FO-BT-ANC-AZ" }
    ],
    avaliacoes: [
      { usuario: "pedro_h", nota: 5, comentario: "O cancelamento de ruído é incrível." },
      { usuario: "julia_r", nota: 3, comentario: "Bom, mas o Bluetooth desconecta às vezes." }
    ]
  },

  {
    titulo: "Camiseta Dry-Fit Esportiva",
    descricao: "Camiseta com tecido dry-fit de alta respirabilidade, ideal para corrida e treino funcional.",
    preco: 79.90,
    categoria: "Vestuário",
    estoque: 300,
    data_cadastro: new Date("2026-11-01"),
    tags: ["esporte", "vestuário", "corrida", "fitness"],
    fabricante: {
      nome: "MoveOn",
      pais: "Brasil",
      contato: "sac@moveon.com.br"
    },
    variacoes: [
      { cor: "Preto",    tamanho: "P",  sku: "CM-DF-PT-P" },
      { cor: "Preto",    tamanho: "M",  sku: "CM-DF-PT-M" },
      { cor: "Preto",    tamanho: "G",  sku: "CM-DF-PT-G" },
      { cor: "Azul",     tamanho: "M",  sku: "CM-DF-AZ-M" },
      { cor: "Azul",     tamanho: "G",  sku: "CM-DF-AZ-G" },
      { cor: "Vermelho", tamanho: "M",  sku: "CM-DF-VM-M" }
    ],
    avaliacoes: [
      { usuario: "marcos_s",  nota: 5, comentario: "Tecido excelente, muito leve." },
      { usuario: "camila_f",  nota: 4, comentario: "Boa qualidade, mas a cor desbotou após muitas lavagens." }
    ]
  },

  {
    titulo: "Smart TV 55\" 4K QLED",
    descricao: "Smart TV com resolução 4K, painel QLED, sistema operacional integrado e controle por voz.",
    preco: 3299.00,
    categoria: "Eletrônicos",
    estoque: 40,
    data_cadastro: new Date("2026-08-20"),
    tags: ["eletrônicos", "tv", "4k", "smart home"],
    fabricante: {
      nome: "VisuMax",
      pais: "Coreia do Sul",
      contato: "support@visumax.kr"
    },
    variacoes: [
      { cor: "Preto", tamanho: "55\"", sku: "TV-QLED-55-PT" },
      { cor: "Preto", tamanho: "65\"", sku: "TV-QLED-65-PT" }
    ],
    avaliacoes: [
      { usuario: "rafael_n", nota: 5, comentario: "Imagem espetacular, cores vibrantes." }
    ]
  },

  {
    titulo: "Mochila Notebook Impermeável 25L",
    descricao: "Mochila com compartimento acolchoado para notebook de até 17 polegadas, tecido impermeável e porta USB externa.",
    preco: 189.90,
    categoria: "Acessórios",
    estoque: 85,
    data_cadastro: new Date("2026-10-10"),
    tags: ["acessórios", "mochila", "notebook", "viagem"],
    fabricante: {
      nome: "UrbanPack",
      pais: "Brasil",
      contato: "contato@urbanpack.com.br"
    },
    variacoes: [
      { cor: "Preto",    tamanho: "25L", sku: "MC-IMP-PT-25" },
      { cor: "Cinza",    tamanho: "25L", sku: "MC-IMP-CZ-25" },
      { cor: "Azul Marinho", tamanho: "25L", sku: "MC-IMP-AM-25" }
    ],
    avaliacoes: [
      { usuario: "lucas_a",  nota: 5, comentario: "Perfeita para o dia a dia e viagens curtas." },
      { usuario: "bianca_m", nota: 4, comentario: "Muito boa, mas poderia ter mais bolsos laterais." }
    ]
  }
]);

print("\n=== PARTE 1 — Inserção de Dados ===");
print("Documentos inseridos: " + resultado.insertedIds.length);
print("IDs gerados:");
for (let i = 0; i < resultado.insertedIds.length; i++) {
  print("  [" + i + "] " + resultado.insertedIds[i]);
}

// Verificação: lista todos os produtos inseridos (apenas título e preço).
print("\nProdutos cadastrados:");
db.produtos.find({}, { titulo: 1, preco: 1, _id: 0 }).forEach(doc => {
  print("  - " + doc.titulo + "  |  R$ " + doc.preco.toFixed(2));
});

print("\n✔ Parte 1 concluída com sucesso.\n");
