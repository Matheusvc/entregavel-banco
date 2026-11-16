# Oxygeni Hub — Projeto Final: Plataforma de Cursos Online

Escopo inicial do projeto final da disciplina de **Banco de Dados**.

---

## Parte 1 — Formação e Escopo

### Integrantes

| Nome | Função |
|---|---|
| Matheus Vitor | Desenvolvedor / Arquiteto de dados |

### Tema

**Plataforma de Cursos Online** — sistema para criação, venda e consumo de cursos digitais, com instrutores que publicam conteúdo e alunos que se matriculam, acompanham progresso e realizam pagamentos.

### Requisitos Funcionais

| # | Requisito |
|---|---|
| RF01 | Cadastrar usuários com perfis distintos (aluno, instrutor, admin). |
| RF02 | Permitir que instrutores criem cursos com módulos e aulas de diferentes formatos (vídeo, texto, exercício, quiz, notebook). |
| RF03 | Realizar matrícula de alunos em cursos, registrando progresso (0–100%). |
| RF04 | Processar pagamentos via Pix, cartão ou boleto, com controle de status (pendente, aprovado, recusado, estornado). |
| RF05 | Consultar o catálogo de cursos com filtros por categoria, nível e preço. |
| RF06 | Exibir o progresso do aluno em cada curso matriculado. |
| RF07 | Listar os cursos de um instrutor com total de alunos e receita. |

### Requisitos Não-Funcionais

| # | Requisito |
|---|---|
| RNF01 | Os dados financeiros (pagamentos e matrículas) devem ser **altamente consistentes** — transações ACID obrigatórias para evitar cobranças duplicadas ou matrículas sem pagamento. |
| RNF02 | O catálogo de cursos deve suportar **diferentes estruturas de conteúdo** sem necessidade de migração de esquema — um curso de programação tem exercícios com linguagem e arquivo; um curso teórico tem leituras com referências bibliográficas; um curso de ML tem notebooks com dataset e framework. |
| RNF03 | O sistema deve suportar **10.000 acessos simultâneos** ao catálogo de cursos sem degradação de performance. |

---

## Parte 2 — Entidades e Decisão Tecnológica

### Entidades Principais

#### 1. `Usuario`
Representa alunos, instrutores e administradores da plataforma.

| Campo | Tipo | Restrição |
|---|---|---|
| id_usuario | SERIAL | PK |
| nome | VARCHAR(100) | NOT NULL |
| email | VARCHAR(150) | UNIQUE, NOT NULL |
| tipo | VARCHAR(20) | CHECK: aluno, instrutor, admin |
| data_cadastro | DATE | DEFAULT CURRENT_DATE |

#### 2. `Curso` (metadados + conteúdo)
Dividido em duas partes:
- **`cursos_meta`** (PostgreSQL): preço, instrutor, status — dados transacionais.
- **`cursos`** (MongoDB): módulos, aulas, especificações — schema flexível.

**cursos_meta (PostgreSQL):**

| Campo | Tipo | Restrição |
|---|---|---|
| id_curso | SERIAL | PK |
| titulo | VARCHAR(200) | NOT NULL |
| id_instrutor | INTEGER | FK → usuarios |
| preco | DECIMAL(10,2) | CHECK >= 0 |
| status | VARCHAR(20) | CHECK: rascunho, publicado, arquivado |

**cursos (MongoDB):** documento com `modulos[]` → `aulas[]`, cada aula com campos variáveis por tipo.

#### 3. `Matricula`
Relacionamento N:N entre aluno e curso, com acompanhamento de progresso.

| Campo | Tipo | Restrição |
|---|---|---|
| id_matricula | SERIAL | PK |
| id_usuario | INTEGER | FK → usuarios |
| id_curso | INTEGER | FK → cursos_meta |
| progresso | INTEGER | CHECK: 0–100 |
| data_matricula | DATE | DEFAULT CURRENT_DATE |

#### 4. `Pagamento`
Transação financeira vinculada a uma matrícula.

| Campo | Tipo | Restrição |
|---|---|---|
| id_pagamento | SERIAL | PK |
| id_matricula | INTEGER | FK → matriculas |
| valor | DECIMAL(10,2) | CHECK > 0 |
| metodo | VARCHAR(30) | CHECK: pix, cartao, boleto |
| status | VARCHAR(20) | CHECK: pendente, aprovado, recusado, estornado |

### Relacionamentos

```
Usuario 1 ──── N Curso (como instrutor)
Usuario 1 ──── N Matricula (como aluno)
Curso   1 ──── N Matricula
Matricula 1 ── 1 Pagamento
```

### Decisão Tecnológica: **Híbrido (PostgreSQL + MongoDB)**

Escolhemos a abordagem **híbrida** porque o sistema possui dois padrões de dados fundamentalmente diferentes:

**PostgreSQL** para usuários, matrículas e pagamentos — esses dados são **transacionais e relacionais**: uma matrícula depende de um usuário e de um curso, um pagamento depende de uma matrícula. A integridade referencial (FK) e as transações ACID são obrigatórias aqui. Um pagamento aprovado sem matrícula correspondente, ou uma matrícula duplicada, seriam falhas graves. O modelo relacional com `CHECK`, `UNIQUE` e `FOREIGN KEY` impede esses cenários na origem.

**MongoDB** para o conteúdo dos cursos — cada curso tem uma estrutura de módulos e aulas **completamente diferente**. Um curso de programação tem aulas com `linguagem` e `arquivo`; um curso teórico tem aulas com `texto_md` e `referencias`; um curso de Machine Learning tem aulas com `dataset`, `framework` e `gpu_recomendada`. No modelo relacional, isso exigiria uma tabela de aulas com dezenas de colunas `NULL` ou um padrão EAV (Entity-Attribute-Value) com JOINs complexos. No MongoDB, cada aula simplesmente tem os campos que precisa — sem NULLs, sem tabelas auxiliares, sem JOINs.

A ponte entre os dois bancos é o campo `id_curso_pg` no MongoDB, que referencia o `id_curso` do PostgreSQL.

---

## Parte 3 — Diagrama e Script Inicial

### Diagrama Entidade-Relacionamento (Contexto Relacional)

```
┌──────────────────┐
│     USUARIO      │
├──────────────────┤
│ PK id_usuario    │
│    nome          │
│    email (UQ)    │
│    tipo          │
│    data_cadastro │
└───────┬──────────┘
        │ 1
        │                    ┌─────────────────────┐
        │ N                  │     CURSOS_META      │
┌───────▼──────────┐        ├─────────────────────┤
│    MATRICULA     │   N    │ PK id_curso          │
├──────────────────┤◄───────│    titulo             │
│ PK id_matricula  │   1    │ FK id_instrutor → U   │
│ FK id_usuario    │        │    preco (CHECK ≥ 0)  │
│ FK id_curso      │        │    status              │
│    progresso     │        │    data_criacao        │
│    data_matricula│        └───────────────────────┘
└───────┬──────────┘
        │ 1
        │
        │ 1
┌───────▼──────────┐
│    PAGAMENTO     │
├──────────────────┤
│ PK id_pagamento  │
│ FK id_matricula  │
│    valor (> 0)   │
│    metodo        │
│    status        │
│    data_pagamento│
└──────────────────┘
```

### Diagrama de Documentos (Contexto MongoDB)

```json
// Coleção: cursos
{
  "titulo": "Python para Data Science",
  "id_curso_pg": 1,              // ← ponte com PostgreSQL
  "carga_horaria": 40,
  "nivel": "Iniciante",
  "tags": ["python", "data science"],
  "modulos": [
    {
      "ordem": 1,
      "titulo": "Fundamentos do Python",
      "aulas": [
        { "tipo": "video",     "titulo": "...", "duracao_min": 25, "url_video": "..." },
        { "tipo": "exercicio", "titulo": "...", "linguagem": "python", "arquivo": "..." },
        { "tipo": "notebook",  "titulo": "...", "arquivo": "...", "dataset": "..." },
        { "tipo": "quiz",      "titulo": "...", "questoes": 10, "nota_minima": 7 }
      ]
    }
  ]
}
```

### Scripts Iniciais

| Script | Banco | Conteúdo |
|---|---|---|
| [`database/init_relacional.sql`](database/init_relacional.sql) | PostgreSQL | 4 tabelas com PK, FK, CHECK constraints + dados iniciais |
| [`database/init_documentos.js`](database/init_documentos.js) | MongoDB | Coleção `cursos` com Schema Validation + 3 cursos com aulas de tipos variados |

---

## Parte 4 — Reflexão: Escolha do SGBD

### Pergunta

> Por que a escolha do SGBD (Relacional vs. NoSQL) deve ser feita com base nos requisitos de acesso aos dados e não na preferência da equipe? Qual o impacto de uma escolha errada no início do projeto?

### Resposta

A escolha do SGBD deve ser orientada pelos **padrões de acesso aos dados** — como os dados são escritos, lidos, atualizados e relacionados — e não pela familiaridade ou preferência pessoal da equipe. Cada tipo de banco de dados foi projetado para resolver um tipo específico de problema, e forçar um banco a resolver um problema para o qual ele não foi feito gera consequências técnicas concretas.

#### Impactos de uma escolha errada

**Usar MongoDB onde deveria ser PostgreSQL (ex: dados financeiros):**
- Sem transações ACID nativas em múltiplas coleções (até a versão 4.0 não existiam), o sistema pode gerar estados inconsistentes: um pagamento registrado sem a matrícula correspondente, ou um estorno que não devolve o saldo.
- Sem `FOREIGN KEY`, a integridade referencial depende 100% da aplicação — qualquer bug no código pode corromper os dados.
- Consultas de relatório financeiro com agregações (SUM, GROUP BY, JOINs) são mais naturais e otimizadas no SQL.

**Usar PostgreSQL onde deveria ser MongoDB (ex: conteúdo de cursos):**
- Uma tabela `aulas` precisaria de colunas como `linguagem`, `dataset`, `framework`, `url_video`, `texto_md`, `nota_minima`, `prazo_dias` — a maioria seria `NULL` para cada tipo de aula, gerando uma tabela esparsa e difícil de manter.
- Adicionar um novo tipo de aula (ex: "simulação interativa" com campos `motor_3d` e `resolucao`) exigiria `ALTER TABLE` com migração de dados em produção.
- O padrão EAV (Entity-Attribute-Value) resolve a flexibilidade, mas transforma consultas simples em JOINs complexos com pivoteamento, prejudicando performance e legibilidade.

**Usar Redis onde deveria haver persistência durável:**
- Dados em memória podem ser perdidos em caso de reinicialização se o RDB/AOF não estiver configurado.
- Sem estrutura relacional ou documental, modelar entidades complexas se torna inviável.

#### Resumo

A escolha errada no início do projeto gera **dívida técnica acumulativa**: conforme o sistema cresce, os workarounds se multiplicam (queries complexas para compensar a modelagem, código na aplicação para compensar a falta de constraints, migrações de esquema arriscadas). Refatorar o banco de dados depois que o sistema já está em produção é uma das migrações mais caras e arriscadas em engenharia de software. Por isso, investir tempo na análise de requisitos antes de escolher a tecnologia economiza meses de retrabalho no futuro.

---

## Tecnologias

- **PostgreSQL** — dados transacionais (usuários, matrículas, pagamentos)
- **MongoDB** — conteúdo de cursos (módulos, aulas, schema flexível)
