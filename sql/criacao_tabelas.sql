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