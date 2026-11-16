# Oxygeni Hub — Banco de Dados (Semanas 09-12)

Sistema de **recomendações com grafo** (Neo4j / Cypher) e **cache de carrinho de compras** (Redis), aplicando bancos de dados NoSQL especializados.

---

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| [`01_grafo_dados.cypher`](01_grafo_dados.cypher) | **Parte 1:** Criação de 6 nós `Usuario`, 6 nós `Produto` e relacionamentos `AMIGO_DE` (12) e `COMPROU` (11). |
| [`02_grafo_consultas.cypher`](02_grafo_consultas.cypher) | **Partes 2 e 3:** Consulta "amigos de amigos que compraram X", recomendação "quem comprou X também comprou Y" e recomendação personalizada por compras em comum. |
| [`03_cache_carrinho.redis`](03_cache_carrinho.redis) | **Partes 1, 2 e 3:** Key design (`cart:user:{id}`), operações do carrinho (`HSET`, `HGETALL`, `HINCRBY`, `HDEL`, `EXPIRE`) e invalidação no checkout (`DEL`). |

---

## Como executar

### Grafo (Neo4j)

```bash
# Inserir dados
cypher-shell -f 01_grafo_dados.cypher

# Consultas de recomendação
cypher-shell -f 02_grafo_consultas.cypher
```

> Ou colar os comandos no **Neo4j Browser** (`http://localhost:7474`).

### Cache (Redis)

```bash
# Executar todos os comandos
cat 03_cache_carrinho.redis | redis-cli

# Ou abrir o redis-cli e colar comando por comando
redis-cli
```

---

## Modelo do Grafo

```
(Ana)──AMIGO_DE──(Bruno)──AMIGO_DE──(Daniel)
  │                 │                   │
  │                 │                   AMIGO_DE
  │                 │                   │
  AMIGO_DE       AMIGO_DE           (Elena)
  │                 │
(Carla)──AMIGO_DE──(Felipe)

Compras:
  Ana    → Notebook, Fone
  Bruno  → Smart TV, Fone
  Carla  → Camiseta
  Daniel → Notebook, Teclado
  Elena  → Notebook, Mochila
  Felipe → Smart TV, Camiseta
```

## Estrutura do Cache (Redis)

```
KEY:   cart:user:1001
TYPE:  Hash

FIELD           VALUE
─────────────── ─────
product:101     2       ← Notebook Gamer ProX (qty: 2)
product:102     1       ← Fone Bluetooth ANC (qty: 1)
product:103     3       ← Camiseta Dry-Fit (qty: 3)

TTL: 86400s (24h) — carrinho abandonado expira automaticamente
```

---

## Parte 4 — Reflexão: Grafo vs SQL e Cache vs Banco Principal

### Pergunta

> Por que um banco de dados de grafos (como Neo4j) é mais eficiente para resolver o problema de "amigos de amigos" do que um banco de dados relacional tradicional (SQL) com JOINs? E por que usar um cache em memória (como Redis) para o carrinho de compras em vez de salvar direto no banco principal?

### Resposta

#### Grafo vs. SQL para "amigos de amigos"

Em um banco relacional, resolver "amigos de amigos que compraram X" exige **múltiplos JOINs** encadeados: um JOIN para encontrar os amigos, outro JOIN para encontrar os amigos dos amigos, e mais um JOIN para encontrar as compras. Cada nível de profundidade adiciona um novo JOIN, e o custo cresce **exponencialmente** com a profundidade — uma consulta de 3 níveis pode envolver milhões de combinações em tabelas grandes.

Em um banco de grafos como o Neo4j, os relacionamentos são **armazenados fisicamente como ponteiros** entre os nós. Navegar de um nó para seus vizinhos é uma operação de **tempo constante** (O(1) por salto), independente do tamanho total do grafo. A consulta `(eu)-[:AMIGO_DE*2]->(amigo2)-[:COMPROU]->(produto)` percorre apenas os caminhos relevantes, sem varrer tabelas inteiras. Isso é chamado de **index-free adjacency** — a principal vantagem arquitetural dos bancos de grafos.

**Resumo:** o grafo navega pelas conexões de forma nativa, sem o custo de JOINs complexos. Quanto mais profunda a consulta de relacionamento, maior a vantagem do grafo sobre o SQL.

#### Cache (Redis) vs. Banco Principal para o carrinho

O carrinho de compras é um dado **temporário e de alta frequência de acesso**: a cada clique do usuário (adicionar item, alterar quantidade, remover) o carrinho é lido e escrito. Usar o banco principal (PostgreSQL, MySQL) para isso gera problemas:

1. **Latência:** uma leitura no banco relacional envolve disco, parsing SQL e controle transacional. No Redis, a leitura é feita **em memória**, com latência de **microssegundos** (< 1ms) contra milissegundos do banco.
2. **Carga no banco:** milhares de carrinhos sendo atualizados a cada segundo sobrecarregam o banco principal, competindo com operações críticas (pedidos, pagamentos, estoque).
3. **Dados efêmeros:** a maioria dos carrinhos é abandonada. Com o `EXPIRE` do Redis, carrinhos abandonados desaparecem automaticamente, sem precisar de jobs de limpeza no banco.
4. **Escalabilidade:** o Redis escala horizontalmente com facilidade (Redis Cluster), mantendo a latência baixa mesmo com milhões de carrinhos simultâneos.

**Resumo:** o cache em memória oferece leitura/escrita em microssegundos, alivia o banco principal de operações transitórias e gerencia automaticamente dados temporários com TTL, melhorando a experiência do usuário e a estabilidade do sistema.

---

## Tecnologias

- **Neo4j** — banco de dados de grafos (Cypher)
- **Redis** — banco de dados chave-valor em memória
