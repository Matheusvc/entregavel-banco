# Oxygeni Hub — Banco de Dados (Sprint 6)

Projeto de banco de dados do **Oxygeni Hub**, uma plataforma de gestão de **modelos
de Inteligência Artificial**. Esta entrega **finaliza** o projeto: parte do modelo
relacional em **PostgreSQL** (modelagem, índices, transações, controle de acesso e
otimização — herdado das sprints anteriores) e acrescenta **rotina de backup/restauração**
e uma **introdução ao NoSQL com MongoDB**.

> **Continuidade da numeração:** os arquivos `01`–`05` são a base relacional construída
> nas sprints anteriores. Os artefatos **novos desta sprint** começam no `08_backup.sh`
> (nome exigido pela atividade); os números `06`/`07` ficam reservados à documentação de
> normalização/otimização produzida na Sprint 5.

---

## 📦 Estrutura do repositório

| Arquivo | Conteúdo |
|---|---|
| [`01_ddl.sql`](01_ddl.sql) | DDL: 9 tabelas, PK/FK, restrições (`NOT NULL`/`UNIQUE`/`CHECK`/`DEFAULT`), tipos do PostgreSQL e índices. |
| [`02_dados.sql`](02_dados.sql) | Massa de teste (~225 mil linhas) via `generate_series()`. |
| [`03_transacoes.sql`](03_transacoes.sql) | 2 transações multi-tabela (`SAVEPOINT`/`ROLLBACK`/`RETURNING`). |
| [`04_explain.sql`](04_explain.sql) | `EXPLAIN (ANALYZE, BUFFERS)` com comparação antes/depois do índice. |
| [`05_seguranca.sql`](05_seguranca.sql) | 2 *roles* de grupo + 2 usuários, `GRANT`/`REVOKE`, menor privilégio. |
| **[`08_backup.sh`](08_backup.sh)** | **Backup lógico com `pg_dump -Fc`, nome com data, tratamento de erro e retenção de 30 dias.** |
| **[`09_mongodb_setup.js`](09_mongodb_setup.js)** | **MongoDB: 2 collections, 13 documentos, Embedding + Referencing, 3 índices.** |
| **[`10_mongodb_consultas.js`](10_mongodb_consultas.js)** | **MongoDB: `find`/`sort`/projeção, busca textual, `$lookup` e `explain()`.** |

---

## 🗺️ Domínio e modelo lógico

O domínio gira em torno de **modelos de IA** criados por **usuários**. Cada modelo tem
**datasets**, passa por **treinamentos** (que geram **métricas**), é publicado em
**deploys** e produz **predições**, que por sua vez recebem **feedback**. A tabela
**permissão** liga usuários a modelos.

```
usuario ──< modelo_ia ──< dataset
                 │        └─< treinamento ──< metrica
                 ├─< deploy
                 └─< predicao ──< feedback >── usuario
usuario ──< permissao >── modelo_ia
```

O modelo físico relacional completo (tipos, restrições e índices) está em
[`01_ddl.sql`](01_ddl.sql). Em resumo, as decisões relacionais foram:

- **Tipos do PostgreSQL:** `SERIAL`/`BIGSERIAL` (PKs, com `BIGSERIAL` nas tabelas de alto
  volume `predicao`/`feedback`), `NUMERIC` (valores exatos), `TIMESTAMPTZ` (datas com fuso),
  `TEXT` (conteúdo livre) e `SMALLINT` (`nota` 1–5).
- **Restrições:** `PRIMARY KEY`, `FOREIGN KEY` com `ON DELETE` (CASCADE/RESTRICT), `NOT NULL`,
  `UNIQUE` (`email`), `CHECK` (faixas e domínios) e `DEFAULT` (`now()`, status).
- **Índices:** nas FKs usadas em `JOIN`, em `predicao(data_hora DESC)`, um composto em
  `deploy(ambiente,status)` e um **parcial** em deploys ativos de produção — sem indexar tudo,
  para não penalizar a escrita.
- **Transações e segurança:** `SAVEPOINT`/`ROLLBACK`/`RETURNING` e *roles* de grupo com
  menor privilégio (`analista_bi` só leitura; `app_backend` CRUD sem `DELETE` em `predicao`).

### Como executar a parte PostgreSQL
```bash
createdb oxygeni_hub
psql -d oxygeni_hub -f 01_ddl.sql
psql -d oxygeni_hub -f 02_dados.sql
psql -d oxygeni_hub -f 04_explain.sql
psql -d oxygeni_hub -f 03_transacoes.sql   # contém erros propositais -> sem ON_ERROR_STOP
psql -d oxygeni_hub -f 05_seguranca.sql    # idem
```

---

## 💾 Backup ([`08_backup.sh`](08_backup.sh))

Script shell que automatiza o **backup lógico** do PostgreSQL:

- **`pg_dump -Fc`** → formato **customizado**: compactado e que permite restauração
  **seletiva** (tabela a tabela) com `pg_restore`.
- **Nome com data**: `oxygeni_hub_AAAA-MM-DD_HHMMSS.dump` → nunca sobrescreve backups anteriores.
- **Tratamento de erro**: `set -euo pipefail` + `trap ... ERR` aborta com código ≠ 0 e
  remove arquivos pela metade; a senha vem de `~/.pgpass`/`PGPASSWORD`, nunca do script.
- **Retenção de 30 dias**: `find ... -mtime +30 -delete` remove backups antigos.

```bash
# execução manual (o PG_BIN é opcional; serve p/ apontar o pg_dump no Windows)
BACKUP_DIR=./backups ./08_backup.sh
```

**Saída real da execução neste projeto:**
```
[2026-10-08 19:03:48] Iniciando backup de 'oxygeni_hub' em localhost:5432...
[2026-10-08 19:03:50] OK: backup criado -> ./backups/oxygeni_hub_2026-10-08_190348.dump (4.7M)
[2026-10-08 19:03:50] Aplicando retenção de 30 dias...
[2026-10-08 19:03:50] Retenção concluída (0 arquivo(s) antigo(s) removido(s)).
[2026-10-08 19:03:50] Backup finalizado com sucesso.
```

### ⏰ Agendamento (Cron)
Execução **diária às 2h da manhã** (crontab do Linux/macOS):
```cron
0 2 * * * /caminho/para/08_backup.sh >> /var/log/oxygeni_backup.log 2>&1
```
`0 2 * * *` = minuto 0, hora 2, todo dia. No **Windows**, o equivalente é o **Agendador de
Tarefas** executando `bash 08_backup.sh` (ou via WSL) no mesmo horário.

### 🧷 Regra 3-2-1
Backup confiável segue **3-2-1**:
- **3** cópias dos dados (1 em produção + 2 backups);
- **2** mídias/tecnologias diferentes (ex.: disco local + armazenamento de objetos);
- **1** cópia **off-site** (fora do servidor — ex.: nuvem/outra localidade).

O `08_backup.sh` cobre a **primeira cópia local**. Para completar a regra, basta
sincronizar a pasta `backups/` para um segundo destino off-site (ex.: `aws s3 sync`,
`rsync` para outro servidor, ou um bucket) — idealmente como um passo extra no mesmo cron.

### ✅ Teste de restauração (o "teste unitário" do backup)
> **Nunca confie em um backup que não foi restaurado.** Restauramos o dump num banco de
> teste e comparamos a **contagem de registros** com o original.

```bash
# cria um banco limpo e restaura o dump customizado nele
psql  -c "CREATE DATABASE oxygeni_hub_teste;"
pg_restore --no-owner -d oxygeni_hub_teste ./backups/oxygeni_hub_2026-10-08_190348.dump
# confere a integridade
psql -d oxygeni_hub_teste -c "SELECT count(*) FROM oxygeni.predicao;"
```

**Resultado real (original × restaurado) — íntegro em todas as tabelas:**

| Tabela | Original | Restaurado | |
|---|---:|---:|:--:|
| usuario | 51 | 51 | ✅ |
| modelo_ia | 201 | 201 | ✅ |
| dataset | 201 | 201 | ✅ |
| treinamento | 1.001 | 1.001 | ✅ |
| metrica | 4.001 | 4.001 | ✅ |
| deploy | 400 | 400 | ✅ |
| predicao | 200.001 | 200.001 | ✅ |
| feedback | 20.001 | 20.001 | ✅ |
| permissao | 496 | 496 | ✅ |

> Observação: `pg_dump` de um banco salva **esquema + dados** daquele banco; *roles*/usuários
> são globais do cluster e, se necessário, são salvos à parte com `pg_dumpall --roles-only`.

---

## 🍃 MongoDB — introdução ao NoSQL ([`09_mongodb_setup.js`](09_mongodb_setup.js), [`10_mongodb_consultas.js`](10_mongodb_consultas.js))

Banco `oxygeni_nosql` com **2 collections** do mesmo domínio e **13 documentos**.

> ℹ️ As saídas do MongoDB abaixo são **esperadas** — descrevem o resultado dos scripts
> quando executados em uma instância `mongod`. Este ambiente não tinha MongoDB instalado,
> então os `.js` estão prontos para rodar com `mongosh`, mas não foram executados ao vivo.

### Modelagem: Embedding × Referencing

A regra de ouro é **modelar pelo padrão de acesso**, não pela estrutura dos dados:
*se os dados são lidos juntos → Embedding; se são lidos à parte ou crescem sem limite → Referencing.*

| Collection | Abordagem | Justificativa |
|---|---|---|
| **`modelos`** | **Embedding** de `responsavel`, `hiperparametros` e `metricas` | São **sempre lidos junto** com o modelo, têm **tamanho limitado** e **não crescem indefinidamente** → embutir entrega o documento inteiro em **uma leitura**, sem *joins*. |
| **`predicoes`** | **Referencing** para o modelo via `modelo_id` | Predições **crescem indefinidamente** (milhões) e são consultadas **à parte** (por período/por modelo). Embutir no modelo estouraria o limite de **16 MB** por documento. |
| **`predicoes.feedback`** | **Embedding** do feedback | É **1:1** com a predição, **lido junto** e de tamanho fixo → embutir é natural. Nem toda predição tem feedback (**esquema flexível**: campo opcional). |

**Flexibilidade de esquema** (documentos da mesma collection com campos diferentes):
o modelo de **NLP** tem `vocabulario_tamanho`/`idioma`; o de **visão** tem
`resolucao_entrada`/`canais`; o de **recomendação** foi criado **sem `metricas`** ainda.

### Índices (3 — simples, composto e de texto)
```js
db.modelos.createIndex({ tipo: 1 });                              // simples
db.predicoes.createIndex({ modelo_id: 1, criado_em: -1 });        // composto
db.modelos.createIndex({ nome:"text", descricao:"text", tags:"text" }); // de texto
```

### Consultas (`find` + `sort` + projeção)
```js
db.predicoes.find(
  { modelo_id: "mdl_fraude_pix", resultado: "fraude" },   // filtro
  { _id: 0, resultado: 1, score: 1, criado_em: 1 }        // projeção
).sort({ criado_em: -1 });                                // ordenação
```
**Saída esperada** (2 predições de fraude, da mais recente p/ a mais antiga):
```json
{ "resultado": "fraude", "score": 0.97, "criado_em": ISODate("2026-10-08T12:00:00Z") }
{ "resultado": "fraude", "score": 0.88, "criado_em": ISODate("2026-10-07T22:14:00Z") }
```

### Análise com `explain()`
```js
db.predicoes.find({ modelo_id: "mdl_fraude_pix" })
  .sort({ criado_em: -1 })
  .explain("executionStats");
```
**Saída esperada** — o índice composto é usado (`IXSCAN`, sem `COLLSCAN`):
```json
{
  "winningPlan": { "stage": "FETCH",
    "inputStage": { "stage": "IXSCAN", "indexName": "idx_pred_modelo_data" } },
  "executionStats": {
    "nReturned": 3, "totalKeysExamined": 3, "totalDocsExamined": 3,
    "executionTimeMillis": 0 }
}
```
`totalDocsExamined = nReturned = 3` → o índice levou direto aos documentos certos, sem
varrer a collection. A ordenação por `criado_em` também é servida pelo índice (não há
estágio `SORT` em memória).

---

## ⚖️ PostgreSQL × MongoDB — quando usar cada um neste domínio

| Cenário do Oxygeni Hub | Melhor opção | Por quê |
|---|---|---|
| Onboarding de modelo (grava em várias tabelas) | **PostgreSQL** | Transação **ACID** com `SAVEPOINT`/`ROLLBACK` garante tudo-ou-nada. |
| Integridade entre modelo → treinamento → métrica | **PostgreSQL** | `FOREIGN KEY` impede dados órfãos; o Mongo não força isso. |
| Relatórios com `JOIN`/agregações e consistência forte | **PostgreSQL** | Otimizador maduro, `EXPLAIN ANALYZE`, dados sempre consistentes. |
| **Log de predições** em altíssimo volume e ingestão rápida | **MongoDB** | Escrita barata, escala horizontal (*sharding*), sem esquema rígido. |
| Cada modelo/predição com **estrutura diferente** (NLP × visão) | **MongoDB** | Esquema flexível por documento, sem `ALTER TABLE`. |
| Payloads aninhados lidos de uma vez (config + métricas) | **MongoDB** | Embedding entrega o agregado numa leitura, sem *joins*. |

**Resumo:** o **PostgreSQL** é a fonte da verdade transacional (consistência, integridade
referencial, relatórios), enquanto o **MongoDB** brilha no que é **alto volume, flexível e
lido em bloco** — como o histórico de predições e configurações heterogêneas de modelos.
Os dois se complementam (*polyglot persistence*).

---

## ✅ Checklist da entrega (Sprint 6)
- [x] `08_backup.sh` com `pg_dump -Fc`, nome com data, tratamento de erro e retenção de 30 dias
- [x] Expressão `cron` para backup diário às 2h
- [x] Teste de restauração documentado com contagem de registros (original × restaurado)
- [x] MongoDB: 2 collections, 13 documentos, Embedding **e** Referencing
- [x] Consultas com `find`, `sort` e projeção
- [x] 3 índices no MongoDB (simples, composto e de texto) + `explain()`
- [x] README com domínio, modelagem (Embedding × Referencing), regra 3-2-1, restauração e comparação PG × MongoDB

**Ambiente:** PostgreSQL 17 · MongoDB (scripts para `mongosh`).
