CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100)
);

CREATE TABLE modelo_ia (
    id_modelo SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    tipo VARCHAR(50),
    algoritmo VARCHAR(100),
    id_usuario INTEGER,
    CONSTRAINT modelo_ia_id_usuario_fkey
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
);

CREATE TABLE dataset (
    id_dataset SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    descricao VARCHAR(255),
    tamanho_mb NUMERIC(10,2),
    id_modelo INTEGER,
    CONSTRAINT dataset_id_modelo_fkey
        FOREIGN KEY (id_modelo)
        REFERENCES modelo_ia(id_modelo)
);

CREATE TABLE treinamento (
    id_treinamento SERIAL PRIMARY KEY,
    data_inicio TIMESTAMP,
    data_fim TIMESTAMP,
    status VARCHAR(50),
    id_modelo INTEGER NOT NULL,
    id_dataset INTEGER NOT NULL,
    CONSTRAINT treinamento_id_modelo_fkey
        FOREIGN KEY (id_modelo)
        REFERENCES modelo_ia(id_modelo),
    CONSTRAINT treinamento_id_dataset_fkey
        FOREIGN KEY (id_dataset)
        REFERENCES dataset(id_dataset)
);

CREATE TABLE metrica (
    id_metrica SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    valor NUMERIC(10,4),
    data_avaliacao TIMESTAMP,
    id_treinamento INTEGER NOT NULL,
    CONSTRAINT metrica_id_treinamento_fkey
        FOREIGN KEY (id_treinamento)
        REFERENCES treinamento(id_treinamento)
);

CREATE TABLE deploy (
    id_deploy SERIAL PRIMARY KEY,
    ambiente VARCHAR(50),
    versao VARCHAR(50),
    data_deploy TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50),
    id_modelo INTEGER NOT NULL,
    CONSTRAINT deploy_id_modelo_fkey
        FOREIGN KEY (id_modelo)
        REFERENCES modelo_ia(id_modelo)
);

CREATE TABLE predicao (
    id_predicao SERIAL PRIMARY KEY,
    data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entrada TEXT,
    resultado TEXT,
    id_modelo INTEGER NOT NULL,
    CONSTRAINT predicao_id_modelo_fkey
        FOREIGN KEY (id_modelo)
        REFERENCES modelo_ia(id_modelo)
);

CREATE TABLE feedback (
    id_feedback SERIAL PRIMARY KEY,
    descricao TEXT,
    nota INTEGER,
    data_feedback TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_predicao INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,
    CONSTRAINT feedback_id_predicao_fkey
        FOREIGN KEY (id_predicao)
        REFERENCES predicao(id_predicao),
    CONSTRAINT feedback_id_usuario_fkey
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
);

CREATE TABLE permissao (
    id_permissao SERIAL PRIMARY KEY,
    tipo VARCHAR(50) NOT NULL,
    id_usuario INTEGER NOT NULL,
    id_modelo INTEGER NOT NULL,
    CONSTRAINT permissao_id_usuario_fkey
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario),
    CONSTRAINT permissao_id_modelo_fkey
        FOREIGN KEY (id_modelo)
        REFERENCES modelo_ia(id_modelo)
);

INSERT INTO usuario (nome, email)
VALUES ('Maria Silva', 'maria.silva@email.com');

COMMIT;