# Oxygeni Hub — Banco de Dados (Semanas 07-08)

Modelagem de um **catálogo de e-commerce** no **MongoDB**, aplicando os conceitos de
bancos de dados NoSQL orientados a documentos: arrays, subdocumentos, índices e
consultas avançadas.

---

## Estrutura do repositório

| Arquivo | Conteúdo |
|---|---|
| [`01_insercao_dados.js`](01_insercao_dados.js) | **Parte 1:** Criação do banco `ecommerce_db`, coleção `produtos` e inserção de 5 documentos com `insertMany()`. Cada documento possui arrays (`tags`, `variacoes`, `avaliacoes`) e subdocumentos (`fabricante`). |
| [`02_indices_consultas.js`](02_indices_consultas.js) | **Parte 2:** Criação de índice simples (`preco`) e índice de texto (`titulo` + `descricao`). Três consultas: operadores de comparação (`$gt`/`$lte`), busca em array (`tags`) e busca textual (`$text`). |
| [`03_desafio.js`](03_desafio.js) | **Parte 3:** Consulta com `$elemMatch` para filtrar variações (tamanho + cor no mesmo subdocumento). Bônus: `explain("executionStats")` comprovando uso do índice `idx_preco`. |

---

## Como executar

**Pré-requisito:** MongoDB instalado e `mongosh` disponível no terminal.

```bash
# 1. Inserção de dados
mongosh "mongodb://localhost:27017" 01_insercao_dados.js

# 2. Índices e consultas
mongosh "mongodb://localhost:27017" 02_indices_consultas.js

# 3. Desafio ($elemMatch + explain)
mongosh "mongodb://localhost:27017" 03_desafio.js
```

> Os scripts devem ser executados **na ordem** (01 → 02 → 03), pois cada um
> depende dos dados e índices criados pelo anterior.

---

## Modelo de dados

A coleção `produtos` utiliza a estratégia de **embedding** (incorporação), onde
cada documento contém todas as informações do produto em um único registro:

```json
{
  "titulo": "Notebook Gamer ProX 15",
  "descricao": "Notebook gamer com tela de 15.6 polegadas...",
  "preco": 6499.90,
  "categoria": "Informática",
  "estoque": 25,
  "data_cadastro": "2026-10-01",
  "tags": ["eletrônicos", "gamer", "notebook", "promoção"],
  "fabricante": {
    "nome": "TechVision",
    "pais": "Brasil",
    "contato": "suporte@techvision.com.br"
  },
  "variacoes": [
    { "cor": "Preto", "tamanho": "15.6\"", "sku": "NB-GPX15-PT" }
  ],
  "avaliacoes": [
    { "usuario": "carlos_m", "nota": 5, "comentario": "Excelente desempenho!" }
  ]
}
```

---

## Parte 4 — Reflexão: Embedding vs. Referencing

### Pergunta

> No MongoDB, qual é a principal diferença de arquitetura entre **Embedding**
> (incorporar dados, como um subdocumento) e **Referencing** (referenciar dados,
> como um ID de outra coleção)? Em que cenário de um e-commerce ou blog cada um
> deve ser usado?

### Resposta

**Embedding (incorporação)** consiste em armazenar dados relacionados
**diretamente dentro do documento pai**, como subdocumentos ou arrays. Isso
significa que todas as informações são recuperadas em uma **única leitura** do
banco, sem a necessidade de operações adicionais (equivalentes a JOINs no
modelo relacional).

**Referencing (referenciamento)** consiste em armazenar apenas o **`_id`
(identificador) de um documento de outra coleção** dentro do documento atual,
criando um vínculo entre as coleções. Para obter os dados completos, é
necessário fazer uma segunda consulta ou utilizar o operador `$lookup`
(equivalente a um JOIN).

#### Quando usar cada abordagem

| Critério | Embedding | Referencing |
|---|---|---|
| **Padrão de leitura** | Dados sempre lidos juntos | Dados acessados de forma independente |
| **Frequência de atualização** | Dados mudam pouco | Dados mudam com frequência |
| **Tamanho dos dados** | Subdocumento pequeno e limitado | Dados podem crescer indefinidamente |
| **Cardinalidade** | Relação 1:1 ou 1:poucos | Relação 1:muitos ou muitos:muitos |
| **Duplicação** | Aceitável (dados contidos) | Deve ser evitada (dados compartilhados) |

#### Exemplos práticos em e-commerce

- **Embedding é ideal para:**
  - **Fabricante dentro do produto:** o nome, país e contato do fabricante são
    lidos junto com o produto e raramente mudam. Embutir evita uma segunda
    consulta.
  - **Variações (cor, tamanho, SKU):** as variações pertencem exclusivamente
    àquele produto e não crescem de forma descontrolada.
  - **Endereço de entrega dentro do pedido:** um pedido sempre precisa do
    endereço e, uma vez registrado, ele não muda.

- **Referencing é ideal para:**
  - **Avaliações de um produto muito popular:** se um produto recebe milhares
    de avaliações, embuti-las estouraria o limite de 16 MB do documento.
    Separar em uma coleção `avaliacoes` com referência ao `_id` do produto
    resolve o problema.
  - **Categorias compartilhadas entre produtos:** em vez de duplicar o objeto
    da categoria em cada produto, armazenar um `categoria_id` evita
    inconsistências quando o nome ou a descrição da categoria mudam.
  - **Dados de usuário em um blog:** os posts referenciam o `_id` do autor em
    vez de embutir todo o perfil, pois o mesmo autor escreve muitos posts e
    seus dados (foto, bio) podem ser atualizados a qualquer momento.

#### Resumo

A decisão entre embedding e referencing deve considerar **como os dados são
consultados** e **com que frequência mudam**. Embedding otimiza a leitura ao
entregar tudo em um documento; referencing otimiza a escrita e evita
duplicação, sendo a melhor escolha para dados voláteis ou compartilhados entre
muitos documentos.

---

## Tecnologias

- **MongoDB 7+** (banco de dados NoSQL orientado a documentos)
- **mongosh** (shell interativo do MongoDB)
