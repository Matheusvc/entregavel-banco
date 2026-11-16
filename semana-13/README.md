# Oxygeni Hub — Banco de Dados (Semana 13)

Análise de um sistema de e-commerce dividido em **3 contextos** (Vendas, Estoque, Financeiro), cada um usando o SGBD mais adequado — aplicando o conceito de **Persistência Poliglota**.

---

## Arquivos

| Contexto | Pasta | Arquivo | SGBD |
|---|---|---|---|
| Financeiro | [`financeiro/`](financeiro/) | [`faturas.sql`](financeiro/faturas.sql) | PostgreSQL |
| Estoque | [`estoque/`](estoque/) | [`produtos.js`](estoque/produtos.js) | MongoDB |
| Vendas | [`vendas/`](vendas/) | [`carrinho.redis`](vendas/carrinho.redis) | Redis |

---

## Parte 1 — Arquitetura e Contextos

### Visão geral

```
┌─────────────────────────────────────────────────────────────────┐
│                     E-COMMERCE OXYGENI HUB                      │
├───────────────────┬───────────────────┬─────────────────────────┤
│   VENDAS (Redis)  │ ESTOQUE (MongoDB) │  FINANCEIRO (PostgreSQL)│
│                   │                   │                         │
│  • Carrinho       │  • Catálogo       │  • Faturas              │
│  • Sessão         │  • Produtos       │  • Clientes             │
│  • Cache          │  • Fornecedores   │  • Transações           │
│                   │                   │                         │
│  Prioridade:      │  Prioridade:      │  Prioridade:            │
│  PERFORMANCE      │  FLEXIBILIDADE    │  CONSISTÊNCIA           │
│  (AP no CAP)      │  (esquema livre)  │  (CP no CAP)            │
└───────────────────┴───────────────────┴─────────────────────────┘
```

### Contexto 1 — Financeiro (PostgreSQL)

| Item | Detalhe |
|---|---|
| **SGBD** | PostgreSQL (relacional) |
| **Entidades** | `clientes`, `faturas` |
| **Prioridade** | Consistência e integridade (ACID) |

**Justificativa:** o contexto financeiro lida com dinheiro — faturas, saldos e pagamentos. Qualquer inconsistência (cobrar duas vezes, não debitar o saldo) gera prejuízo real. O PostgreSQL garante **transações ACID completas**: se uma operação de pagamento falha no meio, o `ROLLBACK` desfaz tudo automaticamente. Além disso, constraints como `CHECK`, `NOT NULL` e `FOREIGN KEY` impedem dados inválidos na origem. É o caso clássico onde **consistência é inegociável** — no Teorema CAP, prioriza-se **CP (Consistency + Partition Tolerance)**.

### Contexto 2 — Estoque (MongoDB)

| Item | Detalhe |
|---|---|
| **SGBD** | MongoDB (documentos NoSQL) |
| **Entidades** | `produtos` (com subdocumento `fornecedor` e objeto `especificacoes`) |
| **Prioridade** | Flexibilidade de esquema |

**Justificativa:** no estoque de um e-commerce, cada tipo de produto tem atributos completamente diferentes. Um smartphone tem tela, bateria, RAM e câmera; uma camiseta tem cor, tamanho e material; um café tem origem, torra e certificação. No modelo relacional, isso exigiria:
- Dezenas de colunas com `NULL` em uma tabela única (design ruim), ou
- Tabelas auxiliares por tipo + JOINs complexos (EAV pattern — lento e difícil de manter)

No MongoDB, cada documento pode ter sua própria estrutura dentro da mesma coleção. Adicionar um novo tipo de produto (ex: "móvel" com `peso_suportado` e `ajuste_altura`) não exige alterar nenhum esquema — é só inserir o documento. Isso torna o catálogo **ágil e escalável**.

### Contexto 3 — Vendas (Redis)

| Item | Detalhe |
|---|---|
| **SGBD** | Redis (chave-valor em memória) |
| **Entidades** | Sessões de carrinho (`cart:session:{id}`), mapeamento usuário-sessão |
| **Prioridade** | Performance e baixa latência |

**Justificativa:** o carrinho de compras é acessado a cada clique do usuário — adicionar item, alterar quantidade, remover. Essas operações precisam responder em **menos de 1 milissegundo** para não degradar a experiência. Salvar no banco principal (PostgreSQL) a cada interação criaria gargalo de I/O e competição por locks com operações críticas.

O Redis armazena tudo **em memória**, responde em microssegundos e oferece `EXPIRE` nativo para carrinhos abandonados (TTL). Usando a estrutura `Hash`, é possível atualizar a quantidade de um único item sem reescrever o carrinho inteiro. No Teorema CAP, o carrinho prioriza **AP (Availability + Partition Tolerance)** — se o cache falhar momentaneamente, o usuário pode reconstruir o carrinho, mas a loja não pode ficar fora do ar.

---

## Parte 3 — Integração Assíncrona entre Contextos

### Como os 3 bancos se comunicam em um cenário real?

Em uma arquitetura de microsserviços, os contextos se comunicam por **eventos assíncronos** (mensageria), usando ferramentas como **RabbitMQ**, **Apache Kafka** ou **Amazon SQS**. Nenhum serviço acessa diretamente o banco do outro.

### Fluxo: Finalização de uma compra (checkout)

```
Usuário clica em "Finalizar Compra"
         │
         ▼
┌─────────────────────┐
│  1. VENDAS (Redis)   │  Lê o carrinho (HGETALL)
│                      │  Publica evento: "COMPRA_FINALIZADA"
│                      │  Deleta o carrinho (DEL)
└──────────┬──────────┘
           │ evento
     ┌─────┴──────┐
     ▼            ▼
┌──────────┐ ┌──────────────────┐
│ 2. ESTOQUE│ │ 3. FINANCEIRO     │
│ (MongoDB) │ │ (PostgreSQL)      │
│           │ │                   │
│ Consome   │ │ Consome evento    │
│ evento    │ │                   │
│           │ │ BEGIN             │
│ Atualiza  │ │   Verifica saldo  │
│ estoque:  │ │   Debita cliente  │
│ $inc:     │ │   Cria fatura     │
│ qty: -1   │ │ COMMIT ou ROLLBACK│
└──────────┘ └──────────────────┘
```

### Passo a passo

1. **Vendas (Redis):** o serviço de vendas lê o carrinho com `HGETALL cart:session:{id}`, monta o payload do pedido e publica um evento `COMPRA_FINALIZADA` na fila de mensagens com os dados do pedido (produtos, quantidades, usuário). Em seguida, invalida o carrinho com `DEL`.

2. **Estoque (MongoDB):** o serviço de estoque consome o evento `COMPRA_FINALIZADA` e, para cada produto do pedido, executa `db.produtos.updateOne({ _id: productId }, { $inc: { estoque: -quantidade } })`. Se o estoque ficar negativo, publica um evento `ESTOQUE_INSUFICIENTE` para notificar o serviço de vendas.

3. **Financeiro (PostgreSQL):** o serviço financeiro consome o mesmo evento e, dentro de uma **transação ACID**, verifica o saldo do cliente, debita o valor e cria a fatura. Se o saldo for insuficiente, faz `ROLLBACK` e publica um evento `PAGAMENTO_RECUSADO`.

### Por que assíncrono?

- **Desacoplamento:** cada serviço pode falhar e se recuperar independentemente.
- **Escalabilidade:** o Redis pode processar milhares de carrinhos por segundo sem esperar o PostgreSQL terminar a transação.
- **Resiliência:** se o serviço de estoque estiver fora, o evento fica na fila e é processado quando voltar (garantia de entrega).

---

## Parte 4 — Reflexão: Polyglot Persistence

### Pergunta

> O que é "Polyglot Persistence" (Persistência Poliglota) e por que grandes sistemas (como ERPs e E-commerces) não usam apenas um único tipo de banco de dados para tudo?

### Resposta

**Polyglot Persistence** (Persistência Poliglota) é a prática de usar **diferentes tipos de bancos de dados** dentro de um mesmo sistema, escolhendo o SGBD mais adequado para cada contexto ou domínio do negócio.

A razão é simples: **cada tipo de dado tem um padrão de acesso e uma necessidade de consistência diferente.** Um banco de dados é uma ferramenta, e assim como não usamos um martelo para apertar um parafuso, não devemos usar o mesmo banco para todos os problemas.

#### Por que não usar apenas um banco para tudo?

| Problema | Banco único (ex: só PostgreSQL) | Polyglot Persistence |
|---|---|---|
| **Carrinho de compras** | Escrita em disco a cada clique → lento, sobrecarrega o banco | Redis em memória → microssegundos, sem I/O |
| **Catálogo com atributos variáveis** | Tabelas com dezenas de NULLs ou JOINs EAV → complexo | MongoDB com schema flexível → natural |
| **Transações financeiras** | Funciona bem (ACID nativo) | PostgreSQL continua sendo a melhor escolha |
| **Recomendações sociais** | JOINs recursivos → exponencialmente lento | Neo4j com index-free adjacency → tempo constante |

#### Vantagens da Persistência Poliglota

1. **Performance otimizada:** cada banco opera no que faz melhor. Redis para leitura/escrita rápida, PostgreSQL para consistência, MongoDB para flexibilidade, Neo4j para relacionamentos.
2. **Escalabilidade independente:** o serviço de vendas (Redis) pode escalar horizontalmente sem afetar o financeiro (PostgreSQL).
3. **Modelagem simplificada:** em vez de forçar todos os dados em tabelas relacionais, cada contexto modela seus dados da forma mais natural.
4. **Resiliência:** a falha de um banco não derruba o sistema inteiro. O carrinho pode ficar indisponível sem afetar o faturamento.

#### Desvantagens e cuidados

- **Complexidade operacional:** manter e monitorar múltiplos SGBDs exige mais infraestrutura e conhecimento.
- **Consistência eventual:** como os dados estão em bancos diferentes, a sincronização entre contextos é eventualmente consistente (não imediata).
- **Integração:** exige um sistema de mensageria (Kafka, RabbitMQ) para coordenar os eventos entre os serviços.

#### Resumo

Usar o banco certo para o problema certo **evita gargalos de performance e simplifica a modelagem**. Grandes sistemas como ERPs e e-commerces adotam Polyglot Persistence porque cada parte do negócio tem necessidades diferentes — e tentar resolver tudo com um único banco gera compromissos que prejudicam performance, escalabilidade ou simplicidade.

---

## Tecnologias

- **PostgreSQL** — banco relacional (contexto financeiro)
- **MongoDB** — banco NoSQL de documentos (contexto estoque)
- **Redis** — banco chave-valor em memória (contexto vendas)
