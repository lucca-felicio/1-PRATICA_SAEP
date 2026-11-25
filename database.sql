CREATE TABLE jogadores (
    id_jogador SERIAL PRIMARY KEY,
    nickname VARCHAR(40) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    senha VARCHAR(100) NOT NULL,
    status VARCHAR(15) NOT NULL DEFAULT 'Ativo'
        CHECK (status IN ('Ativo', 'Inativo', 'Banido')),
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categorias (
    id_categoria SERIAL PRIMARY KEY,
    nome VARCHAR(60) NOT NULL UNIQUE,
    descricao TEXT
);

CREATE TABLE partidas (
    id_partida SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    jogador_id INTEGER NOT NULL REFERENCES jogadores(id_jogador),
    categoria_id INTEGER NOT NULL REFERENCES categorias(id_categoria),
    data_agendamento TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Agendada'
        CHECK (status IN ('Agendada', 'Em andamento', 'Concluida', 'Cancelada')),
    data_criacao TIMESTAMP NOT NULL
);

CREATE TABLE historico_partidas (
    id_historico SERIAL PRIMARY KEY,
    partida_id INTEGER NOT NULL REFERENCES partidas(id_partida),
    acao VARCHAR(50) NOT NULL,
    descricao TEXT,
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO jogadores (nickname, email, senha, status) VALUES
('NinjaBR', 'ninja@email.com', '123', 'Ativo'),
('PlayerX', 'playerx@email.com', '123', 'Ativo'),
('GamerSul', 'gamersul@email.com', '123', 'Inativo');

INSERT INTO categorias (nome, descricao) VALUES
('FPS', 'Jogos de tiro'),
('MOBA', 'Arena multiplayer'),
('Battle Royale', 'Jogos de sobrevivencia');

CREATE OR REPLACE FUNCTION fn_validar_partida()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM jogadores
        WHERE id_jogador = NEW.jogador_id
          AND status = 'Ativo'
    ) THEN
        RAISE EXCEPTION 'Jogador inativo ou inexistente';
    END IF;

    NEW.data_criacao := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_partida
BEFORE INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_partida();

CREATE OR REPLACE FUNCTION fn_registrar_historico()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_partidas (partida_id, acao, descricao)
    VALUES (NEW.id_partida, 'Cadastro', 'Partida cadastrada');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_historico_partidas
AFTER INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_historico();

INSERT INTO partidas (titulo, jogador_id, categoria_id, data_agendamento, status) VALUES
('Campeonato Valorant', 1, 1, CURRENT_TIMESTAMP + INTERVAL '2 days', 'Agendada'),
('Torneio LoL', 2, 2, CURRENT_TIMESTAMP + INTERVAL '5 days', 'Agendada'),
('Copa Fortnite', 1, 3, CURRENT_TIMESTAMP + INTERVAL '8 days', 'Agendada');

CREATE OR REPLACE FUNCTION fn_buscar_jogadores(termo TEXT)
RETURNS TABLE (
    id_jogador INTEGER,
    nickname VARCHAR(40),
    email VARCHAR(100),
    status VARCHAR(15)
) AS $$
BEGIN
    RETURN QUERY
    SELECT j.id_jogador, j.nickname, j.email, j.status
    FROM jogadores AS j
    WHERE j.nickname ILIKE '%' || termo || '%'
       OR j.email ILIKE '%' || termo || '%';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW vw_painel_principal AS
SELECT
    j.nickname,
    p.titulo AS titulo_partida,
    c.nome AS modalidade,
    p.data_agendamento,
    p.status
FROM partidas AS p
INNER JOIN jogadores AS j ON p.jogador_id = j.id_jogador
INNER JOIN categorias AS c ON p.categoria_id = c.id_categoria;

CREATE OR REPLACE VIEW vw_cronograma_partidas AS
SELECT
    p.id_partida,
    p.titulo,
    p.data_agendamento,
    p.status,
    p.data_agendamento::DATE - CURRENT_DATE AS dias_restantes,
    j.nickname
FROM partidas AS p
INNER JOIN jogadores AS j ON p.jogador_id = j.id_jogador
ORDER BY p.data_agendamento ASC;

SELECT * FROM jogadores;
SELECT * FROM categorias;
SELECT * FROM partidas;
SELECT * FROM historico_partidas;
SELECT * FROM fn_buscar_jogadores('Player');
SELECT * FROM vw_painel_principal;
SELECT * FROM vw_cronograma_partidas;
