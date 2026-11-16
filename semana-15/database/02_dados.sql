-- =============================================================================
-- OXYGENI HUB  |  Semana 15 — MER, Normalização e Chaves
-- Plataforma de Cursos Online
-- Arquivo: 02_dados.sql
--
-- Inserção de dados de teste e demonstração de integridade referencial.
--
-- Pré-requisito: executar 01_ddl.sql antes.
-- Como executar:
--   psql -U postgres -f 02_dados.sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Inserção de dados válidos
-- -----------------------------------------------------------------------------

INSERT INTO categorias (nome, descricao) VALUES
    ('Programação',      'Cursos de linguagens de programação e desenvolvimento'),
    ('Banco de Dados',   'Modelagem, SQL e NoSQL'),
    ('Data Science',     'Análise de dados, machine learning e IA'),
    ('DevOps',           'Infraestrutura, CI/CD e cloud');

INSERT INTO usuarios (nome, email, senha_hash, tipo) VALUES
    ('Ana Silva',      'ana@email.com',      'hash_ana_123',    'instrutor'),
    ('Bruno Costa',    'bruno@email.com',    'hash_bruno_456',  'aluno'),
    ('Carla Mendes',   'carla@email.com',    'hash_carla_789',  'aluno'),
    ('Daniel Rocha',   'daniel@email.com',   'hash_daniel_012', 'instrutor'),
    ('Elena Ferreira', 'elena@email.com',    'hash_elena_345',  'aluno');

INSERT INTO cursos (titulo, descricao, id_instrutor, id_categoria, preco, carga_horaria, status) VALUES
    ('Python para Data Science',   'Do zero ao pandas',              1, 3, 199.90, 40, 'publicado'),
    ('Banco de Dados na Prática',  'SQL, NoSQL e modelagem',         1, 2, 149.90, 30, 'publicado'),
    ('Machine Learning Avançado',  'Redes neurais e deep learning',  4, 3, 299.90, 60, 'publicado');

INSERT INTO modulos (id_curso, titulo, ordem) VALUES
    (1, 'Fundamentos do Python',  1),
    (1, 'Pandas e NumPy',         2),
    (2, 'Modelagem Relacional',   1),
    (2, 'NoSQL com MongoDB',      2),
    (3, 'Redes Neurais',          1);

INSERT INTO aulas (id_modulo, titulo, tipo, duracao_min, ordem) VALUES
    (1, 'Variáveis e tipos',         'video',     25, 1),
    (1, 'Estruturas de controle',    'video',     30, 2),
    (1, 'Prática com listas',        'exercicio', 20, 3),
    (2, 'Introdução ao Pandas',      'video',     35, 1),
    (2, 'Quiz de Pandas',            'quiz',      15, 2),
    (3, 'Entidades e Relacionamentos','video',    40, 1),
    (3, 'Normalização até 3FN',      'texto',     30, 2),
    (4, 'Documentos e Coleções',     'video',     30, 1),
    (5, 'Arquitetura de CNNs',       'video',     50, 1);

INSERT INTO matriculas (id_usuario, id_curso, progresso) VALUES
    (2, 1, 45),
    (2, 2, 80),
    (3, 1, 20),
    (3, 3, 10),
    (5, 2, 100);

INSERT INTO pagamentos (id_matricula, valor, metodo, status) VALUES
    (1, 199.90, 'pix',    'aprovado'),
    (2, 149.90, 'cartao', 'aprovado'),
    (3, 199.90, 'pix',    'aprovado'),
    (4, 299.90, 'boleto', 'pendente'),
    (5, 149.90, 'cartao', 'aprovado');

INSERT INTO avaliacoes (id_usuario, id_curso, nota, comentario) VALUES
    (2, 1, 5, 'Excelente didática, recomendo!'),
    (2, 2, 4, 'Muito bom, mas poderia ter mais exercícios.'),
    (5, 2, 5, 'Melhor curso de banco de dados que já fiz.');

-- -----------------------------------------------------------------------------
-- Consulta de verificação: JOINs entre tabelas relacionadas
-- -----------------------------------------------------------------------------

SELECT u.nome       AS aluno,
       c.titulo     AS curso,
       cat.nome     AS categoria,
       m.progresso  AS progresso,
       p.status     AS pagamento
FROM matriculas m
JOIN usuarios u     ON m.id_usuario  = u.id_usuario
JOIN cursos c       ON m.id_curso    = c.id_curso
JOIN categorias cat ON c.id_categoria = cat.id_categoria
JOIN pagamentos p   ON m.id_matricula = p.id_matricula
ORDER BY u.nome, c.titulo;

-- =============================================================================
-- BÔNUS: Demonstração de violação de integridade referencial
-- =============================================================================

-- Teste 1: FK inexistente — tentar matricular um usuário que não existe
-- Esperado: ERROR — violação de FK (id_usuario = 999 não existe)
DO $$
BEGIN
    INSERT INTO matriculas (id_usuario, id_curso) VALUES (999, 1);
EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE '✘ ERRO ESPERADO (FK): Não é possível matricular o usuário 999 — ele não existe na tabela usuarios.';
END $$;

-- Teste 2: FK inexistente — tentar criar curso com instrutor que não existe
-- Esperado: ERROR — violação de FK (id_instrutor = 888 não existe)
DO $$
BEGIN
    INSERT INTO cursos (titulo, id_instrutor, id_categoria, preco, carga_horaria)
    VALUES ('Curso Fantasma', 888, 1, 99.90, 10);
EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE '✘ ERRO ESPERADO (FK): Não é possível criar curso com instrutor 888 — ele não existe.';
END $$;

-- Teste 3: PK duplicada — tentar inserir matrícula duplicada (mesmo aluno, mesmo curso)
-- Esperado: ERROR — violação de UNIQUE (id_usuario, id_curso)
DO $$
BEGIN
    INSERT INTO matriculas (id_usuario, id_curso) VALUES (2, 1);
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE '✘ ERRO ESPERADO (UNIQUE): Bruno já está matriculado no curso 1 — duplicação impedida.';
END $$;

-- Teste 4: CHECK constraint — tentar inserir nota fora do intervalo 1–5
DO $$
BEGIN
    INSERT INTO avaliacoes (id_usuario, id_curso, nota) VALUES (3, 1, 10);
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE '✘ ERRO ESPERADO (CHECK): Nota 10 está fora do intervalo permitido (1–5).';
END $$;

-- Teste 5: CHECK constraint — tentar inserir preço negativo
DO $$
BEGIN
    INSERT INTO cursos (titulo, id_instrutor, id_categoria, preco, carga_horaria)
    VALUES ('Curso Grátis Errado', 1, 1, -50.00, 10);
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE '✘ ERRO ESPERADO (CHECK): Preço negativo não é permitido (CHECK preco >= 0).';
END $$;
