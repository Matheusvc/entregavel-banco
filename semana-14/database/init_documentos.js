// =============================================================================
// OXYGENI HUB  |  Semana 14 — Projeto Final (Escopo Inicial)
// Plataforma de Cursos Online — Contexto de Documentos
// Arquivo: init_documentos.js
//
// Coleção: cursos (conteúdo detalhado com schema flexível)
// Foco: cada curso tem estrutura de módulos/aulas diferente.
//
// Como executar:
//   mongosh "mongodb://localhost:27017" init_documentos.js
// =============================================================================

db = db.getSiblingDB("plataforma_cursos");

// Idempotência
db.cursos.drop();

// -----------------------------------------------------------------------------
// Schema Validation (Bônus)
// Garante que todo documento tenha os campos obrigatórios e que carga_horaria
// seja positiva — equivalente ao CHECK constraint do SQL.
// -----------------------------------------------------------------------------

db.createCollection("cursos", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["titulo", "id_curso_pg", "carga_horaria", "modulos"],
      properties: {
        titulo: {
          bsonType: "string",
          description: "Título do curso — obrigatório"
        },
        id_curso_pg: {
          bsonType: "int",
          description: "FK para cursos_meta no PostgreSQL — obrigatório"
        },
        carga_horaria: {
          bsonType: "int",
          minimum: 1,
          description: "Carga horária em horas — deve ser >= 1"
        },
        modulos: {
          bsonType: "array",
          description: "Lista de módulos — obrigatório"
        }
      }
    }
  }
});

print("\n=== Coleção 'cursos' criada com Schema Validation ===\n");

// -----------------------------------------------------------------------------
// Inserção de cursos com schema flexível
//
// Cada curso tem estrutura de aulas diferente:
//   - Curso de programação: aulas com código, exercícios, linguagem
//   - Curso teórico: aulas com leitura, referências, slides
//   - Curso de ML: aulas com datasets, notebooks, métricas
//
// No PostgreSQL, isso exigiria tabelas auxiliares complexas.
// No MongoDB, cada módulo/aula pode ter campos diferentes naturalmente.
// -----------------------------------------------------------------------------

db.cursos.insertMany([
  {
    titulo: "Python para Data Science",
    id_curso_pg: 1,
    carga_horaria: NumberInt(40),
    nivel: "Iniciante",
    tags: ["python", "data science", "pandas", "numpy"],
    modulos: [
      {
        ordem: 1,
        titulo: "Fundamentos do Python",
        aulas: [
          { tipo: "video",     titulo: "Variáveis e tipos",     duracao_min: 25, url_video: "/videos/py-101-01.mp4" },
          { tipo: "exercicio", titulo: "Prática com variáveis",  linguagem: "python", arquivo: "ex_01.py" },
          { tipo: "video",     titulo: "Estruturas de controle", duracao_min: 30, url_video: "/videos/py-101-02.mp4" }
        ]
      },
      {
        ordem: 2,
        titulo: "Pandas e NumPy",
        aulas: [
          { tipo: "video",     titulo: "Introdução ao Pandas",  duracao_min: 35, url_video: "/videos/py-102-01.mp4" },
          { tipo: "notebook",  titulo: "Manipulando DataFrames", arquivo: "pandas_intro.ipynb", dataset: "vendas.csv" },
          { tipo: "quiz",      titulo: "Quiz de Pandas",        questoes: 10, nota_minima: 7 }
        ]
      }
    ]
  },

  {
    titulo: "Banco de Dados na Prática",
    id_curso_pg: 2,
    carga_horaria: NumberInt(30),
    nivel: "Intermediário",
    tags: ["sql", "postgresql", "mongodb", "banco de dados"],
    modulos: [
      {
        ordem: 1,
        titulo: "Modelagem Relacional",
        aulas: [
          { tipo: "video",     titulo: "Entidades e Relacionamentos", duracao_min: 40, url_video: "/videos/db-201-01.mp4" },
          { tipo: "leitura",   titulo: "Normalização até 3FN",        texto_md: "normalizacao.md", referencias: ["Date, C.J. - Introdução a Sistemas de Bancos de Dados"] },
          { tipo: "exercicio", titulo: "Criar schema de e-commerce",  linguagem: "sql", arquivo: "ex_schema.sql" }
        ]
      },
      {
        ordem: 2,
        titulo: "NoSQL com MongoDB",
        aulas: [
          { tipo: "video",     titulo: "Documentos e Coleções",    duracao_min: 30, url_video: "/videos/db-202-01.mp4" },
          { tipo: "exercicio", titulo: "CRUD no MongoDB",          linguagem: "javascript", arquivo: "ex_mongo.js" },
          { tipo: "leitura",   titulo: "Embedding vs Referencing", texto_md: "embedding.md" }
        ]
      }
    ]
  },

  {
    titulo: "Machine Learning Avançado",
    id_curso_pg: 3,
    carga_horaria: NumberInt(60),
    nivel: "Avançado",
    tags: ["machine learning", "python", "tensorflow", "redes neurais"],
    pre_requisitos: ["Python para Data Science"],
    modulos: [
      {
        ordem: 1,
        titulo: "Redes Neurais Profundas",
        aulas: [
          { tipo: "video",    titulo: "Arquitetura de CNNs",      duracao_min: 50, url_video: "/videos/ml-301-01.mp4" },
          { tipo: "notebook", titulo: "Classificação de Imagens", arquivo: "cnn_imagens.ipynb", dataset: "cifar10", framework: "tensorflow", gpu_recomendada: true },
          { tipo: "projeto",  titulo: "Detector de Objetos",      entrega: "modelo_detector.h5", prazo_dias: 14, metricas_avaliacao: ["mAP", "precision", "recall"] }
        ]
      }
    ]
  }
]);

print("Cursos inseridos: 3\n");

// Verificação: mostrar a diferença de schema entre os cursos
print("--- Flexibilidade de schema por tipo de aula ---\n");
db.cursos.find({}, { titulo: 1, _id: 0 }).forEach(curso => {
  print("  Curso: " + curso.titulo);
});

print("\n--- Tipos de aula encontrados ---");
const tipos = db.cursos.aggregate([
  { $unwind: "$modulos" },
  { $unwind: "$modulos.aulas" },
  { $group: { _id: "$modulos.aulas.tipo", total: { $sum: 1 } } },
  { $sort: { total: -1 } }
]).toArray();
tipos.forEach(t => print("  " + t._id + ": " + t.total + " aula(s)"));

print("\n✔ Init documentos concluído.\n");
