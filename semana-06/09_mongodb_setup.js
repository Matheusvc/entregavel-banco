// =============================================================================
// OXYGENI HUB  |  Sprint 6 - Introdução ao MongoDB (NoSQL)
// Arquivo: 09_mongodb_setup.js
// Objetivo: criar o banco de documentos do domínio (modelos de IA), com 2
//           collections relacionadas, demonstrando EMBEDDING e REFERENCING,
//           flexibilidade de esquema e a criação de índices (simples, composto
//           e de texto).
//
// Como executar:
//   mongosh "mongodb://localhost:27017/oxygeni_nosql" 09_mongodb_setup.js
//   (ou dentro do mongosh:  load("09_mongodb_setup.js"))
// =============================================================================

// Seleciona/cria o banco (no MongoDB o banco nasce ao gravar o primeiro doc).
db = db.getSiblingDB("oxygeni_nosql");

// Idempotência: limpa as collections para poder rodar o script quantas vezes quiser.
db.modelos.drop();
db.predicoes.drop();

// =============================================================================
// COLLECTION 1: modelos
// Estratégia: EMBEDDING. O responsável, os hiperparâmetros e as métricas são
// SEMPRE lidos junto com o modelo, têm tamanho limitado e não crescem de forma
// indefinida -> embutir evita "joins" e entrega o documento inteiro numa leitura.
// Também demonstra FLEXIBILIDADE DE ESQUEMA: cada tipo de modelo guarda campos
// diferentes (um NLP tem vocabulario_tamanho; um de visão tem resolucao_entrada).
// =============================================================================
const resModelos = db.modelos.insertMany([
  {
    _id: "mdl_fraude_pix",
    nome: "Detector de Fraude PIX",
    descricao: "Classifica transações PIX como fraude ou legítimas em tempo real.",
    tipo: "classificacao",
    algoritmo: "XGBoost",
    responsavel: { nome: "Dra. Ana Ferraz", email: "ana.ferraz@oxygeni.dev" }, // embedding
    hiperparametros: { max_depth: 8, learning_rate: 0.1, n_estimators: 300 },   // embedding (flexível)
    metricas: [                                                                 // embedding (array pequeno)
      { nome: "acuracia", valor: 0.9812, avaliado_em: ISODate("2026-09-20T10:00:00Z") },
      { nome: "f1",       valor: 0.9431, avaliado_em: ISODate("2026-09-20T10:00:00Z") }
    ],
    tags: ["fraude", "pix", "producao"],
    criado_em: ISODate("2026-09-01T09:00:00Z")
  },
  {
    _id: "mdl_churn",
    nome: "Previsor de Churn",
    descricao: "Estima a probabilidade de cancelamento de clientes.",
    tipo: "classificacao",
    algoritmo: "RandomForest",
    responsavel: { nome: "Bruno Lima", email: "bruno.lima@oxygeni.dev" },
    hiperparametros: { n_estimators: 500, max_features: "sqrt" },
    metricas: [{ nome: "acuracia", valor: 0.8734, avaliado_em: ISODate("2026-09-18T14:00:00Z") }],
    tags: ["churn", "retencao"],
    criado_em: ISODate("2026-08-15T11:30:00Z")
  },
  {
    _id: "mdl_sentimento",
    nome: "Análise de Sentimento BR",
    descricao: "Classifica sentimento de textos em português (fraude, elogio, reclamação).",
    tipo: "nlp",
    algoritmo: "BERT",
    responsavel: { nome: "Carla Souza", email: "carla.souza@oxygeni.dev" },
    // esquema flexível: modelo de NLP tem campos que os outros não têm
    hiperparametros: { embedding_dim: 768, max_tokens: 512, dropout: 0.1 },
    vocabulario_tamanho: 30522,
    idioma: "pt-BR",
    metricas: [{ nome: "f1", valor: 0.9105, avaliado_em: ISODate("2026-09-10T08:00:00Z") }],
    tags: ["nlp", "sentimento"],
    criado_em: ISODate("2026-07-20T16:45:00Z")
  },
  {
    _id: "mdl_visao_defeitos",
    nome: "Inspeção Visual de Defeitos",
    descricao: "Detecta defeitos em peças a partir de imagens da linha de produção.",
    tipo: "visao_computacional",
    algoritmo: "CNN",
    responsavel: { nome: "Diego Alves", email: "diego.alves@oxygeni.dev" },
    // esquema flexível: campos específicos de visão computacional
    hiperparametros: { batch_size: 32, epochs: 50 },
    resolucao_entrada: "224x224",
    canais: 3,
    metricas: [{ nome: "acuracia", valor: 0.9560, avaliado_em: ISODate("2026-09-05T13:00:00Z") }],
    tags: ["visao", "qualidade", "producao"],
    criado_em: ISODate("2026-06-30T10:15:00Z")
  },
  {
    _id: "mdl_recomendacao",
    nome: "Recomendador de Produtos",
    descricao: "Sugere produtos com base no histórico de navegação.",
    tipo: "recomendacao",
    algoritmo: "KMeans",
    responsavel: { nome: "Bruno Lima", email: "bruno.lima@oxygeni.dev" },
    hiperparametros: { k: 12 },
    // modelo recém-criado, ainda SEM métricas -> flexibilidade (campo ausente)
    tags: ["recomendacao"],
    criado_em: ISODate("2026-09-22T09:00:00Z")
  }
]);
print("modelos inseridos: " + resModelos.insertedIds.length);

// =============================================================================
// COLLECTION 2: predicoes
// Estratégia: REFERENCING. Uma predição aponta para o modelo via `modelo_id`.
// Predições crescem INDEFINIDAMENTE (milhões) e são consultadas à parte (por
// período, por modelo) -> NÃO podem ser embutidas no documento do modelo
// (estouraria o limite de 16 MB e cresceria sem controle).
// Já o `feedback` é EMBEDDED: é 1:1 com a predição, lido junto e de tamanho fixo.
// Nem toda predição tem feedback -> demonstra flexibilidade (campo opcional).
// =============================================================================
const resPred = db.predicoes.insertMany([
  { modelo_id: "mdl_fraude_pix", entrada: { valor: 15000, canal: "pix" }, resultado: "fraude",   score: 0.97, criado_em: ISODate("2026-10-08T12:00:00Z"),
    feedback: { nota: 5, comentario: "Fraude confirmada pelo analista", usuario: "ana.ferraz@oxygeni.dev", em: ISODate("2026-10-08T12:30:00Z") } },
  { modelo_id: "mdl_fraude_pix", entrada: { valor: 50, canal: "pix" },    resultado: "legitimo", score: 0.12, criado_em: ISODate("2026-10-08T12:05:00Z") }, // sem feedback
  { modelo_id: "mdl_fraude_pix", entrada: { valor: 8300, canal: "ted" },  resultado: "fraude",   score: 0.88, criado_em: ISODate("2026-10-07T22:14:00Z"),
    feedback: { nota: 2, comentario: "Falso positivo", usuario: "bruno.lima@oxygeni.dev", em: ISODate("2026-10-07T23:00:00Z") } },
  { modelo_id: "mdl_churn",      entrada: { meses_ativo: 3, planos: 1 },   resultado: "churn",    score: 0.76, criado_em: ISODate("2026-10-06T09:30:00Z"),
    feedback: { nota: 4, comentario: "Cliente realmente cancelou", usuario: "bruno.lima@oxygeni.dev", em: ISODate("2026-10-09T09:00:00Z") } },
  { modelo_id: "mdl_churn",      entrada: { meses_ativo: 40, planos: 3 },  resultado: "ativo",    score: 0.08, criado_em: ISODate("2026-10-05T18:00:00Z") },
  { modelo_id: "mdl_sentimento", entrada: { texto: "Péssimo atendimento" }, resultado: "reclamacao", score: 0.93, criado_em: ISODate("2026-10-08T15:20:00Z"),
    feedback: { nota: 5, comentario: "Classificação correta", usuario: "carla.souza@oxygeni.dev", em: ISODate("2026-10-08T16:00:00Z") } },
  { modelo_id: "mdl_sentimento", entrada: { texto: "Adorei o produto!" },   resultado: "elogio",     score: 0.95, criado_em: ISODate("2026-10-08T15:25:00Z") },
  { modelo_id: "mdl_visao_defeitos", entrada: { imagem: "peca_0042.png" },  resultado: "defeito",    score: 0.81, criado_em: ISODate("2026-10-04T10:10:00Z"),
    feedback: { nota: 3, comentario: "Defeito leve, revisar limiar", usuario: "diego.alves@oxygeni.dev", em: ISODate("2026-10-04T11:00:00Z") } }
]);
print("predicoes inseridas: " + resPred.insertedIds.length);
print("total de documentos: " + (resModelos.insertedIds.length + resPred.insertedIds.length));

// =============================================================================
// ÍNDICES (pelo menos 2) -> simples, composto e de texto.
// =============================================================================

// (1) SIMPLES: filtrar modelos por tipo é uma consulta frequente de catálogo.
db.modelos.createIndex({ tipo: 1 }, { name: "idx_modelos_tipo" });

// (2) COMPOSTO: "predições de um modelo, mais recentes primeiro" -> casa o filtro
//     por modelo_id (referencing) com a ordenação por data (criado_em DESC).
db.predicoes.createIndex({ modelo_id: 1, criado_em: -1 }, { name: "idx_pred_modelo_data" });

// (3) TEXTO: busca livre por nome/descrição/tags do modelo.
db.modelos.createIndex(
  { nome: "text", descricao: "text", tags: "text" },
  { name: "idx_modelos_texto", default_language: "portuguese" }
);

print("indices em modelos:");
printjson(db.modelos.getIndexes().map(i => i.name));
print("indices em predicoes:");
printjson(db.predicoes.getIndexes().map(i => i.name));
