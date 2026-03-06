-- =============================================================
--  LAB: Índices no PostgreSQL
--  Banco de e-commerce para estudo de índices
--
--  Tabelas:  clientes, produtos, pedidos, itens_pedido
--  Volume:   5.000 clientes | 100 produtos
--            50.000 pedidos | ~125.000 itens
--
--  Como usar:
--    psql -U seu_usuario -d seu_banco -f ecommerce_lab.sql
-- =============================================================


-- -------------------------------------------------------------
--  0. LIMPEZA (reexecução segura)
-- -------------------------------------------------------------
DROP TABLE IF EXISTS itens_pedido CASCADE;
DROP TABLE IF EXISTS pedidos      CASCADE;
DROP TABLE IF EXISTS produtos     CASCADE;
DROP TABLE IF EXISTS clientes     CASCADE;


-- -------------------------------------------------------------
--  1. DDL — CRIAÇÃO DAS TABELAS (sem índices além das PKs)
-- -------------------------------------------------------------

CREATE TABLE clientes (
    id          SERIAL          PRIMARY KEY,
    nome        TEXT            NOT NULL,
    email       TEXT            NOT NULL UNIQUE,
    cidade      TEXT            NOT NULL,
    pais        TEXT            NOT NULL DEFAULT 'Brasil',
    ativo       BOOLEAN         NOT NULL DEFAULT TRUE,
    criado_em   TIMESTAMP       NOT NULL DEFAULT NOW(),
    deletado_em TIMESTAMP
);

CREATE TABLE produtos (
    id        SERIAL   PRIMARY KEY,
    nome      TEXT     NOT NULL,
    categoria TEXT     NOT NULL,
    preco     NUMERIC(10,2) NOT NULL CHECK (preco > 0),
    estoque   INTEGER  NOT NULL DEFAULT 0,
    ativo     BOOLEAN  NOT NULL DEFAULT TRUE
);

CREATE TABLE pedidos (
    id          SERIAL          PRIMARY KEY,
    cliente_id  INTEGER         NOT NULL REFERENCES clientes(id),
    status      TEXT            NOT NULL CHECK (status IN ('pendente','entregue','cancelado')),
    total       NUMERIC(12,2)   NOT NULL,
    criado_em   TIMESTAMP       NOT NULL DEFAULT NOW(),
    aprovado_em TIMESTAMP,
    entregue_em TIMESTAMP
);

CREATE TABLE itens_pedido (
    id             SERIAL          PRIMARY KEY,
    pedido_id      INTEGER         NOT NULL REFERENCES pedidos(id),
    produto_id     INTEGER         NOT NULL REFERENCES produtos(id),
    quantidade     INTEGER         NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(10,2)   NOT NULL
);


-- -------------------------------------------------------------
--  2. SEED — DADOS DE EXEMPLO
--
--  Usamos generate_series + funções aleatórias do PostgreSQL
--  para gerar volume realista sem arquivos externos.
-- -------------------------------------------------------------

-- 2.1  Clientes (5.000 registros)
INSERT INTO clientes (nome, email, cidade, ativo, criado_em, deletado_em)
SELECT
    (ARRAY['Ana','Bruno','Carla','Diego','Elena','Felipe','Gabriela',
           'Henrique','Isabela','João','Karina','Lucas','Mariana',
           'Nicolas','Olivia','Paulo','Rafael','Sara','Thiago','Vera'])
        [1 + (i % 20)]
    || ' ' ||
    (ARRAY['Silva','Costa','Mendes','Rocha','Souza','Lima','Neto',
           'Alves','Ferreira','Pereira','Santos','Oliveira','Gomes',
           'Ribeiro','Castro','Martins','Barbosa','Cardoso','Monteiro','Azevedo'])
        [1 + ((i * 7) % 20)]
    || ' ' || i                                         AS nome,

    'usuario' || i || '@email.com'                      AS email,

    (ARRAY['São Paulo','Rio de Janeiro','Belo Horizonte','Curitiba',
           'Porto Alegre','Salvador','Fortaleza','Recife','Manaus','Brasília'])
        [1 + (i % 10)]                                  AS cidade,

    (random() > 0.1)                                    AS ativo,

    NOW() - (random() * INTERVAL '730 days')            AS criado_em,

    CASE WHEN random() > 0.9
         THEN NOW() - (random() * INTERVAL '200 days')
         ELSE NULL
    END                                                 AS deletado_em

FROM generate_series(1, 5000) AS s(i);


-- 2.2  Produtos (100 registros — 5 categorias x 5 itens x 4 variações)
INSERT INTO produtos (nome, categoria, preco, estoque)
SELECT
    item || ' ' || ROW_NUMBER() OVER ()                 AS nome,
    categoria,
    ROUND((20 + random() * 2980)::NUMERIC, 2)           AS preco,
    (random() * 500)::INTEGER                           AS estoque
FROM (
    SELECT
        unnest(ARRAY['Smartphone','Notebook','Tablet','Fone de Ouvido','Smartwatch',
                     'Camiseta','Calça Jeans','Vestido','Jaqueta','Tênis',
                     'Cadeira','Mesa','Luminária','Tapete','Almofada',
                     'Romance','Técnico','Infantil','Autoajuda','História',
                     'Bicicleta','Haltere','Tapete Yoga','Garrafa','Mochila']) AS item,
        unnest(ARRAY['Eletrônicos','Eletrônicos','Eletrônicos','Eletrônicos','Eletrônicos',
                     'Roupas','Roupas','Roupas','Roupas','Roupas',
                     'Casa','Casa','Casa','Casa','Casa',
                     'Livros','Livros','Livros','Livros','Livros',
                     'Esportes','Esportes','Esportes','Esportes','Esportes']) AS categoria
) base,
generate_series(1, 4);   -- 4 variações por item = 100 produtos


-- 2.3  Pedidos (50.000 registros)
--      ~85% entregue | ~10% pendente | ~5% cancelado
INSERT INTO pedidos (cliente_id, status, total, criado_em, aprovado_em, entregue_em)
SELECT
    1 + (random() * 4999)::INTEGER                      AS cliente_id,

    (ARRAY(
        SELECT unnest(ARRAY['entregue','entregue','entregue','entregue','entregue',
                            'entregue','entregue','entregue','entregue','entregue',
                            'entregue','entregue','entregue','entregue','entregue',
                            'entregue','entregue','pendente','pendente','cancelado'])
    ))[1 + (random() * 19)::INTEGER]                    AS status,

    ROUND((50 + random() * 9950)::NUMERIC, 2)           AS total,

    NOW() - (random() * INTERVAL '700 days')            AS criado_em,

    CASE WHEN random() > 0.1
         THEN NOW() - (random() * INTERVAL '698 days')
         ELSE NULL
    END                                                 AS aprovado_em,

    CASE WHEN random() > 0.15
         THEN NOW() - (random() * INTERVAL '680 days')
         ELSE NULL
    END                                                 AS entregue_em

FROM generate_series(1, 50000);


-- 2.4  Itens de pedido (2-3 itens por pedido em média)
INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario)
SELECT
    p.id                                                AS pedido_id,
    1 + (random() * 99)::INTEGER                        AS produto_id,
    1 + (random() * 3)::INTEGER                         AS quantidade,
    ROUND((10 + random() * 2990)::NUMERIC, 2)           AS preco_unitario
FROM pedidos p,
     generate_series(1, 2 + (random() * 1)::INTEGER);  -- 2 ou 3 itens


-- 2.5  Atualiza o total dos pedidos com base nos itens reais
UPDATE pedidos p
SET total = sub.total_calculado
FROM (
    SELECT pedido_id,
           ROUND(SUM(quantidade * preco_unitario)::NUMERIC, 2) AS total_calculado
    FROM itens_pedido
    GROUP BY pedido_id
) sub
WHERE p.id = sub.pedido_id;


-- -------------------------------------------------------------
--  3. VERIFICAÇÃO — contagem após o seed
-- -------------------------------------------------------------
SELECT 'clientes'     AS tabela, COUNT(*) AS total FROM clientes
UNION ALL
SELECT 'produtos',    COUNT(*) FROM produtos
UNION ALL
SELECT 'pedidos',     COUNT(*) FROM pedidos
UNION ALL
SELECT 'itens_pedido',COUNT(*) FROM itens_pedido;


-- =============================================================
--  4. EXERCÍCIOS DE ÍNDICES
--     Descomente cada bloco conforme o estudo avança.
-- =============================================================


-- -------------------------------------------------------------
--  EX 01 — Seq Scan vs Index Scan
--  Execute o EXPLAIN antes e depois de criar o índice.
-- -------------------------------------------------------------

-- PASSO A: rode sem índice e observe o Seq Scan
EXPLAIN ANALYZE
SELECT id, cliente_id, status, total, criado_em
FROM pedidos
WHERE cliente_id = 42;

-- PASSO B: crie o índice
-- CREATE INDEX idx_pedidos_cliente ON pedidos (cliente_id);

-- PASSO C: rode novamente e compare o Index Scan
-- EXPLAIN ANALYZE
-- SELECT id, cliente_id, status, total, criado_em
-- FROM pedidos
-- WHERE cliente_id = 42;


-- -------------------------------------------------------------
--  EX 02 — Ordem das colunas no índice composto
-- -------------------------------------------------------------

-- Índice com ordem menos seletiva primeiro
-- CREATE INDEX idx_status_cliente ON pedidos (status, cliente_id);

-- EXPLAIN ANALYZE
-- SELECT id, cliente_id, status, total
-- FROM pedidos
-- WHERE cliente_id = 99 AND status = 'pendente';

-- Índice com ordem mais seletiva primeiro (correto)
-- CREATE INDEX idx_cliente_status ON pedidos (cliente_id, status);

-- EXPLAIN ANALYZE
-- SELECT id, cliente_id, status, total
-- FROM pedidos
-- WHERE cliente_id = 99 AND status = 'pendente';


-- -------------------------------------------------------------
--  EX 03 — Índice parcial (fila de processamento)
-- -------------------------------------------------------------

-- PASSO A: sem índice parcial
-- EXPLAIN ANALYZE
-- SELECT id, cliente_id, total, criado_em
-- FROM pedidos
-- WHERE status = 'pendente'
-- ORDER BY criado_em
-- LIMIT 20;

-- PASSO B: crie o índice parcial
-- CREATE INDEX idx_parcial_pendentes ON pedidos (criado_em)
-- WHERE status = 'pendente';

-- PASSO C: rode novamente e compare
-- EXPLAIN ANALYZE
-- SELECT id, cliente_id, total, criado_em
-- FROM pedidos
-- WHERE status = 'pendente'
-- ORDER BY criado_em
-- LIMIT 20;


-- -------------------------------------------------------------
--  EX 04 — JOIN com índices (relatório de receita)
-- -------------------------------------------------------------

-- PASSO A: rode sem índices nas FKs/filtros
-- EXPLAIN ANALYZE
-- SELECT c.nome,
--        COUNT(p.id)              AS total_pedidos,
--        ROUND(SUM(p.total), 2)   AS receita
-- FROM   clientes c
-- JOIN   pedidos p ON p.cliente_id = c.id
-- WHERE  c.cidade = 'São Paulo'
--   AND  p.status = 'entregue'
-- GROUP BY c.id, c.nome
-- ORDER BY receita DESC
-- LIMIT 10;

-- PASSO B: crie os índices necessários
-- CREATE INDEX idx_clientes_cidade  ON clientes (cidade);
-- CREATE INDEX idx_pedidos_cliente2 ON pedidos  (cliente_id);

-- PASSO C: rode novamente e compare os planos


-- -------------------------------------------------------------
--  EX 05 — Índice parcial com unicidade condicional
-- -------------------------------------------------------------

-- Garante que cada cliente tem no máximo um endereço principal
-- (sem precisar de uma tabela de endereços completa para o exemplo)

-- CREATE UNIQUE INDEX idx_unico_ativo
-- ON clientes (cidade)        -- simplificado: 1 cliente ativo por cidade
-- WHERE ativo = TRUE;


-- -------------------------------------------------------------
--  EX 06 — Monitoramento: índices não utilizados
-- -------------------------------------------------------------

-- Crie um índice inútil para simular:
-- CREATE INDEX idx_inutil ON clientes (pais);

-- Veja que ele nunca é usado:
-- SELECT indexrelname, idx_scan
-- FROM pg_stat_user_indexes
-- WHERE relname = 'clientes';

-- Remova índices sem uso:
-- DROP INDEX idx_inutil;


-- -------------------------------------------------------------
--  EX 07 — Covering Index (Index Only Scan)
-- -------------------------------------------------------------

-- CREATE INDEX idx_covering
-- ON pedidos (cliente_id, status)
-- INCLUDE (total, criado_em);   -- colunas extras sem participar da navegação

-- EXPLAIN ANALYZE
-- SELECT status, total, criado_em
-- FROM pedidos
-- WHERE cliente_id = 42;
-- Observe: "Index Only Scan" + "Heap Fetches: 0"


-- =============================================================
--  5. QUERIES ÚTEIS DE MONITORAMENTO (rode quando quiser)
-- =============================================================

-- Tamanho de cada índice da tabela pedidos
-- SELECT indexname,
--        pg_size_pretty(pg_relation_size(indexname::regclass)) AS tamanho
-- FROM pg_indexes
-- WHERE tablename = 'pedidos'
-- ORDER BY pg_relation_size(indexname::regclass) DESC;

-- Índices nunca usados
-- SELECT s.relname AS tabela, s.indexrelname AS indice,
--        pg_size_pretty(pg_relation_size(s.indexrelid)) AS tamanho,
--        s.idx_scan AS vezes_usado
-- FROM pg_stat_user_indexes s
-- JOIN pg_indexes i ON s.indexrelname = i.indexname
-- WHERE s.idx_scan = 0
--   AND i.indisprimary = false
--   AND i.indisunique  = false
-- ORDER BY pg_relation_size(s.indexrelid) DESC;

-- Tabelas com mais sequential scans
-- SELECT relname, seq_scan, idx_scan,
--        ROUND(100.0 * seq_scan / NULLIF(seq_scan + idx_scan, 0), 2) AS pct_seq
-- FROM pg_stat_user_tables
-- ORDER BY seq_scan DESC
-- LIMIT 10;
