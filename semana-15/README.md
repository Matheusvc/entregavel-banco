# Oxygeni Hub — MER, Normalização e Chaves

Modelo Entidade-Relacionamento, normalização até 3FN e demonstração de integridade referencial para a **Plataforma de Cursos Online**.

---

## Parte 1 — Modelo Entidade-Relacionamento (MER)

### Entidades e Relacionamentos

```
  CATEGORIAS           USUARIOS
  ┌────────────┐       ┌──────────────┐
  │ PK id      │       │ PK id        │
  │    nome UQ │       │    nome      │
  │    descricao│      │    email UQ  │
  └──────┬─────┘       │    senha_hash│
         │ 1           │    tipo      │
         │             │    data_cad  │
         │ N           └──┬──┬──┬─────┘
  ┌──────▼──────────┐     │  │  │
  │     CURSOS      │  1  │  │  │
  ├─────────────────┤◄────┘  │  │
  │ PK id_curso     │        │  │
  │ FK id_instrutor │  1     │  │
  │ FK id_categoria │        │  │
  │    titulo       │        │  │
  │    preco        │        │  │
  │    carga_horaria│        │  │
  │    status       │        │  │
  └──┬─────────┬────┘        │  │
     │ 1       │ 1           │  │
     │         │             │  │
     │ N       │ N      N    │  │ N
  ┌──▼─────┐  │  ┌──────────▼──┤ ┌───────────▼──┐
  │MODULOS │  │  │ MATRICULAS  │ │  AVALIACOES  │
  ├────────┤  │  ├─────────────┤ ├──────────────┤
  │PK id   │  │  │PK id        │ │PK id         │
  │FK curso│  │  │FK id_usuario│ │FK id_usuario │
  │  titulo│  │  │FK id_curso  │ │FK id_curso   │
  │  ordem │  │  │  progresso  │ │   nota 1-5   │
  └──┬─────┘  │  │  data       │ │   comentario │
     │ 1      │  └──────┬──────┘ └──────────────┘
     │        │         │ 1
     │ N      │         │
  ┌──▼─────┐  │  ┌──────▼───────┐
  │ AULAS  │  │  │  PAGAMENTOS  │
  ├────────┤  │  ├──────────────┤
  │PK id   │  │  │PK id         │
  │FK modulo│ │  │FK id_matricula│
  │  titulo│  │  │   valor > 0  │
  │  tipo  │  │  │   metodo     │
  │  durac │  │  │   status     │
  │  ordem │  │  │   data       │
  └────────┘  │  └──────────────┘
              │
              └── (ligações N partem de CURSOS)
```

### Cardinalidades

| Relacionamento | Cardinalidade | Descrição |
|---|---|---|
| `USUARIOS` → `CURSOS` | 1:N | Um instrutor leciona vários cursos |
| `CATEGORIAS` → `CURSOS` | 1:N | Uma categoria classifica vários cursos |
| `CURSOS` → `MODULOS` | 1:N | Um curso contém vários módulos |
| `MODULOS` → `AULAS` | 1:N | Um módulo contém várias aulas |
| `USUARIOS` → `MATRICULAS` ← `CURSOS` | N:N | Alunos se matriculam em cursos (tabela associativa) |
| `MATRICULAS` → `PAGAMENTOS` | 1:1 | Cada matrícula gera um pagamento |
| `USUARIOS` → `AVALIACOES` ← `CURSOS` | N:N | Alunos avaliam cursos (tabela associativa) |

---

## Parte 2 — Normalização (1FN → 2FN → 3FN)

### Exemplo prático: evolução da tabela `cursos`

**Tabela não normalizada (pré-1FN):**

```
| id | titulo            | instrutor    | email_inst       | categoria     | desc_cat                   | tags              |
|----|-------------------|--------------|------------------|---------------|----------------------------|-------------------|
| 1  | Python para DS    | Ana Silva    | ana@email.com    | Data Science  | Análise de dados, ML e IA  | python, pandas    |
| 2  | BD na Prática     | Ana Silva    | ana@email.com    | Banco de Dados| Modelagem, SQL e NoSQL     | sql, mongodb      |
```

Problemas: campo `tags` com valores múltiplos (viola 1FN), dados do instrutor repetidos (viola 2FN), dados da categoria repetidos (viola 3FN).

---

**Após 1FN — atributos atômicos:**

Cada campo contém um único valor. O campo `tags` é removido (ou migrado para outra tabela/array se necessário).

```
| id | titulo            | id_instrutor | nome_inst   | email_inst    | nome_cat       | desc_cat                  |
|----|-------------------|-------------|-------------|---------------|----------------|---------------------------|
| 1  | Python para DS    | 1           | Ana Silva   | ana@email.com | Data Science   | Análise de dados, ML e IA |
| 2  | BD na Prática     | 1           | Ana Silva   | ana@email.com | Banco de Dados | Modelagem, SQL e NoSQL    |
```

---

**Após 2FN — sem dependências parciais:**

Todos os atributos não-chave dependem da chave inteira (`id_curso`). Os dados do instrutor (`nome_inst`, `email_inst`) dependem apenas de `id_instrutor`, não de `id_curso`. Extraímos para a tabela `usuarios`:

```
CURSOS: | id | titulo         | id_instrutor | nome_cat       | desc_cat                  |
USUARIOS: | id | nome        | email         | ...                                        |
```

---

**Após 3FN — sem dependências transitivas:**

O campo `nome_cat` e `desc_cat` dependem de `id_categoria`, não de `id_curso`. Há uma dependência transitiva: `id_curso → id_categoria → nome_cat`. Extraímos para a tabela `categorias`:

```
CURSOS:     | id | titulo         | id_instrutor | id_categoria |
CATEGORIAS: | id | nome           | descricao                   |
USUARIOS:   | id | nome           | email | ...                  |
```

Resultado: **8 tabelas em 3FN**, sem redundância, sem dependências parciais ou transitivas.

---

## Parte 3 — Desnormalização: quando e por quê

### Cenário: relatório de matrículas

Na versão normalizada (3FN), para exibir "aluno X está matriculado no curso Y da categoria Z com pagamento W", precisamos de **5 JOINs**:

```sql
SELECT u.nome, c.titulo, cat.nome, m.progresso, p.status
FROM matriculas m
JOIN usuarios u     ON m.id_usuario   = u.id_usuario
JOIN cursos c       ON m.id_curso     = c.id_curso
JOIN categorias cat ON c.id_categoria = cat.id_categoria
JOIN pagamentos p   ON m.id_matricula = p.id_matricula;
```

### Versão desnormalizada (para leitura)

Se essa consulta fosse executada milhares de vezes por segundo (ex: dashboard de analytics), poderíamos criar uma **view materializada** ou uma tabela desnormalizada:

```sql
CREATE MATERIALIZED VIEW vw_painel_matriculas AS
SELECT u.nome       AS aluno,
       c.titulo     AS curso,
       cat.nome     AS categoria,
       m.progresso,
       p.status     AS pagamento,
       p.valor
FROM matriculas m
JOIN usuarios u     ON m.id_usuario   = u.id_usuario
JOIN cursos c       ON m.id_curso     = c.id_curso
JOIN categorias cat ON c.id_categoria = cat.id_categoria
JOIN pagamentos p   ON m.id_matricula = p.id_matricula;
```

**Trade-off:** a view materializada elimina os JOINs em tempo de leitura, mas precisa ser atualizada (`REFRESH MATERIALIZED VIEW`) sempre que os dados de origem mudam. Em cenários de escrita frequente, a 3FN continua sendo a melhor escolha para as tabelas de origem.

---

## Parte 4 — Demonstração de integridade referencial

O script [`database/02_dados.sql`](database/02_dados.sql) inclui 5 testes de violação de constraints:

| # | Tipo | O que tenta | Resultado esperado |
|---|---|---|---|
| 1 | FK | Matricular `id_usuario = 999` (inexistente) | `foreign_key_violation` |
| 2 | FK | Criar curso com `id_instrutor = 888` (inexistente) | `foreign_key_violation` |
| 3 | UNIQUE | Duplicar matrícula (mesmo aluno, mesmo curso) | `unique_violation` |
| 4 | CHECK | Inserir `nota = 10` (fora de 1–5) | `check_violation` |
| 5 | CHECK | Inserir `preco = -50` (negativo) | `check_violation` |

Cada teste usa `DO $$ ... EXCEPTION WHEN ... $$` para capturar o erro e exibir uma mensagem explicativa sem interromper a execução.

---

## Parte 5 — Reflexão: por que normalizar e usar PK/FK?

### Por que normalizar?

A normalização não é apenas uma regra acadêmica — ela resolve problemas reais de manutenção de dados:

- **Anomalia de inserção:** sem a tabela `categorias` separada, não seria possível cadastrar uma nova categoria sem antes ter um curso nela.
- **Anomalia de atualização:** se "Data Science" mudasse para "Ciência de Dados", seria necessário atualizar todas as linhas da tabela `cursos` que possuem essa categoria. Com a 3FN, atualiza-se em um único lugar.
- **Anomalia de exclusão:** se o único curso da categoria "DevOps" fosse excluído, a categoria desapareceria junto. Com a tabela separada, ela permanece disponível.

### Por que usar chaves primárias e estrangeiras?

- **PK (Primary Key)** garante unicidade: cada registro tem um identificador único e imutável. Sem ela, não há como distinguir dois alunos com o mesmo nome.
- **FK (Foreign Key)** garante integridade referencial: é impossível criar um pagamento para uma matrícula que não existe, ou matricular um aluno em um curso inexistente. O banco impede na origem, sem depender do código da aplicação.
- **Constraints (CHECK, UNIQUE)** adicionam regras de negócio diretamente no banco: nota entre 1 e 5, preço não negativo, email único. Mesmo que a aplicação tenha um bug, o banco não aceita dados inválidos.

### Resumo

A combinação de normalização + PK/FK + constraints transfere a responsabilidade de integridade dos dados da aplicação para o banco. Isso significa que **qualquer** cliente que acesse o banco (API, script, ferramenta de admin) está sujeito às mesmas regras — não apenas o frontend. É a diferença entre "esperar que ninguém erre" e "garantir que ninguém consiga errar".

---

## Scripts

| Arquivo | Descrição |
|---|---|
| [`database/01_ddl.sql`](database/01_ddl.sql) | DDL — 8 tabelas normalizadas até 3FN com PK, FK, CHECK e UNIQUE |
| [`database/02_dados.sql`](database/02_dados.sql) | Dados de teste + consulta de verificação + 5 testes de violação de constraints |

## Como executar

```bash
psql -U postgres -f database/01_ddl.sql
psql -U postgres -f database/02_dados.sql
```

## Tecnologias

- **PostgreSQL** — banco relacional, normalização, constraints
