 Sprint 3 - Do Conceito à Tabela

 Banco de Dados para Gerenciamento de Modelos de Inteligência Artificial

Este projeto foi desenvolvido como parte da Sprint 3, cujo objetivo é transformar o modelo conceitual em um modelo lógico estruturado, aplicando as regras de normalização até a Terceira Forma Normal (3FN).

O banco de dados foi desenvolvido utilizando PostgreSQL.


1. Objetivo

O objetivo do banco de dados é permitir o gerenciamento de modelos de Inteligência Artificial, seus usuários, datasets, treinamentos, métricas, deploys, predições, feedbacks e permissões.

O modelo foi estruturado buscando:

- Evitar redundância de dados;
- Garantir a integridade das informações;
- Organizar corretamente os relacionamentos;
- Utilizar chaves primárias e estrangeiras;
- Aplicar as regras de normalização até a 3FN.


2. Tecnologias utilizadas

- PostgreSQL
- pgAdmin 4
- SQL
- Git
- GitHub

3. Estrutura do Banco de Dados

O banco de dados possui 9 tabelas:

| Tabela | Descrição |
|---|---|
| usuario | Armazena os usuários do sistema |
| modelo_ia | Armazena os modelos de Inteligência Artificial |
| dataset | Armazena os conjuntos de dados utilizados pelos modelos |
| treinamento | Registra os treinamentos realizados |
| metrica | Armazena as métricas dos treinamentos |
| deploy | Registra os deploys dos modelos |
| predicao | Armazena as predições realizadas pelos modelos |
| feedback | Armazena os feedbacks dos usuários sobre as predições |
| permissao | Controla as permissões dos usuários sobre os modelos |


4. Chaves Primárias e Estrangeiras

As tabelas possuem chaves primárias para identificar cada registro de forma única.

Principais relacionamentos

 usuario → modelo_ia

Um usuário pode estar associado a modelos de IA.

```text
usuario.id_usuario
        ↓
modelo_ia.id_usuario
