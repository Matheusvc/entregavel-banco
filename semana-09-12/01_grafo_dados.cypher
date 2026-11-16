// =============================================================================
// OXYGENI HUB  |  Semanas 09-12 — Grafos e Cache
// Arquivo: 01_grafo_dados.cypher
// Parte 1 — Manipulação e Inserção de Dados (Grafo)
//
// Objetivo: criar nós (Usuario, Produto) e relacionamentos (AMIGO_DE, COMPROU)
//           para um sistema de recomendações de e-commerce.
//
// Como executar:
//   cypher-shell -f 01_grafo_dados.cypher
//   (ou colar no Neo4j Browser em http://localhost:7474)
// =============================================================================

// Idempotência: limpa o grafo para poder rodar o script quantas vezes quiser.
MATCH (n) DETACH DELETE n;

// -----------------------------------------------------------------------------
// 1.1  Criação dos nós de Usuário
// Tipo de nó: Usuario
// Propriedades: nome, email, cidade
// -----------------------------------------------------------------------------
CREATE (u1:Usuario {nome: "Ana Silva",      email: "ana@email.com",      cidade: "São Paulo"})
CREATE (u2:Usuario {nome: "Bruno Costa",    email: "bruno@email.com",    cidade: "Rio de Janeiro"})
CREATE (u3:Usuario {nome: "Carla Mendes",   email: "carla@email.com",    cidade: "São Paulo"})
CREATE (u4:Usuario {nome: "Daniel Rocha",   email: "daniel@email.com",   cidade: "Belo Horizonte"})
CREATE (u5:Usuario {nome: "Elena Ferreira", email: "elena@email.com",    cidade: "Curitiba"})
CREATE (u6:Usuario {nome: "Felipe Lima",    email: "felipe@email.com",   cidade: "São Paulo"})

// -----------------------------------------------------------------------------
// 1.2  Criação dos nós de Produto
// Tipo de nó: Produto
// Propriedades: nome, categoria, preco
// -----------------------------------------------------------------------------
CREATE (p1:Produto {nome: "Notebook Gamer ProX",     categoria: "Informática", preco: 6499.90})
CREATE (p2:Produto {nome: "Fone Bluetooth ANC",      categoria: "Áudio",       preco: 349.90})
CREATE (p3:Produto {nome: "Smart TV 55\" 4K",        categoria: "Eletrônicos", preco: 3299.00})
CREATE (p4:Produto {nome: "Camiseta Dry-Fit",        categoria: "Vestuário",   preco: 79.90})
CREATE (p5:Produto {nome: "Mochila Impermeável 25L", categoria: "Acessórios",  preco: 189.90})
CREATE (p6:Produto {nome: "Teclado Mecânico RGB",    categoria: "Informática", preco: 459.90});

// -----------------------------------------------------------------------------
// 1.3  Criação dos relacionamentos AMIGO_DE
// Tipo de aresta: AMIGO_DE (bidirecional na lógica, duas arestas no grafo)
// -----------------------------------------------------------------------------
MATCH (u1:Usuario {nome: "Ana Silva"}),      (u2:Usuario {nome: "Bruno Costa"})    CREATE (u1)-[:AMIGO_DE]->(u2), (u2)-[:AMIGO_DE]->(u1);
MATCH (u1:Usuario {nome: "Ana Silva"}),      (u3:Usuario {nome: "Carla Mendes"})   CREATE (u1)-[:AMIGO_DE]->(u3), (u3)-[:AMIGO_DE]->(u1);
MATCH (u2:Usuario {nome: "Bruno Costa"}),    (u4:Usuario {nome: "Daniel Rocha"})   CREATE (u2)-[:AMIGO_DE]->(u4), (u4)-[:AMIGO_DE]->(u2);
MATCH (u2:Usuario {nome: "Bruno Costa"}),    (u5:Usuario {nome: "Elena Ferreira"}) CREATE (u2)-[:AMIGO_DE]->(u5), (u5)-[:AMIGO_DE]->(u2);
MATCH (u3:Usuario {nome: "Carla Mendes"}),   (u6:Usuario {nome: "Felipe Lima"})    CREATE (u3)-[:AMIGO_DE]->(u6), (u6)-[:AMIGO_DE]->(u3);
MATCH (u4:Usuario {nome: "Daniel Rocha"}),   (u5:Usuario {nome: "Elena Ferreira"}) CREATE (u4)-[:AMIGO_DE]->(u5), (u5)-[:AMIGO_DE]->(u4);

// -----------------------------------------------------------------------------
// 1.4  Criação dos relacionamentos COMPROU
// Tipo de aresta: COMPROU
// Propriedades: data, quantidade
// -----------------------------------------------------------------------------
MATCH (u:Usuario {nome: "Ana Silva"}),      (p:Produto {nome: "Notebook Gamer ProX"})     CREATE (u)-[:COMPROU {data: "2026-10-01", quantidade: 1}]->(p);
MATCH (u:Usuario {nome: "Ana Silva"}),      (p:Produto {nome: "Fone Bluetooth ANC"})      CREATE (u)-[:COMPROU {data: "2026-10-05", quantidade: 1}]->(p);
MATCH (u:Usuario {nome: "Bruno Costa"}),    (p:Produto {nome: "Smart TV 55\" 4K"})        CREATE (u)-[:COMPROU {data: "2026-09-20", quantidade: 1}]->(p);
MATCH (u:Usuario {nome: "Bruno Costa"}),    (p:Produto {nome: "Fone Bluetooth ANC"})      CREATE (u)-[:COMPROU {data: "2026-10-10", quantidade: 2}]->(p);
MATCH (u:Usuario {nome: "Carla Mendes"}),   (p:Produto {nome: "Camiseta Dry-Fit"})        CREATE (u)-[:COMPROU {data: "2026-10-15", quantidade: 3}]->(p);
MATCH (u:Usuario {nome: "Daniel Rocha"}),   (p:Produto {nome: "Notebook Gamer ProX"})     CREATE (u)-[:COMPROU {data: "2026-10-02", quantidade: 1}]->(p);
MATCH (u:Usuario {nome: "Daniel Rocha"}),   (p:Produto {nome: "Teclado Mecânico RGB"})    CREATE (u)-[:COMPROU {data: "2026-10-03", quantidade: 1}]->(p);
MATCH (u:Usuario {nome: "Elena Ferreira"}), (p:Produto {nome: "Notebook Gamer ProX"})     CREATE (u)-[:COMPROU {data: "2026-11-01", quantidade: 1}]->(p);
MATCH (u:Usuario {nome: "Elena Ferreira"}), (p:Produto {nome: "Mochila Impermeável 25L"}) CREATE (u)-[:COMPROU {data: "2026-11-02", quantidade: 1}]->(p);
MATCH (u:Usuario {nome: "Felipe Lima"}),    (p:Produto {nome: "Smart TV 55\" 4K"})        CREATE (u)-[:COMPROU {data: "2026-09-25", quantidade: 1}]->(p);
MATCH (u:Usuario {nome: "Felipe Lima"}),    (p:Produto {nome: "Camiseta Dry-Fit"})        CREATE (u)-[:COMPROU {data: "2026-10-20", quantidade: 2}]->(p);

// -----------------------------------------------------------------------------
// Verificação: contagem de nós e relacionamentos
// -----------------------------------------------------------------------------
MATCH (u:Usuario) RETURN "Usuários: " + count(u) AS resultado
UNION ALL
MATCH (p:Produto) RETURN "Produtos: " + count(p) AS resultado
UNION ALL
MATCH ()-[a:AMIGO_DE]->() RETURN "Arestas AMIGO_DE: " + count(a) AS resultado
UNION ALL
MATCH ()-[c:COMPROU]->() RETURN "Arestas COMPROU: " + count(c) AS resultado;
