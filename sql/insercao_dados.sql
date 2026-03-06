-- Clientes

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

-- Produtos

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


-- Pedidos

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

-- Itens do Pedido

INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario)
SELECT
    p.id                                                AS pedido_id,
    1 + (random() * 99)::INTEGER                        AS produto_id,
    1 + (random() * 3)::INTEGER                         AS quantidade,
    ROUND((10 + random() * 2990)::NUMERIC, 2)           AS preco_unitario
FROM pedidos p,
     generate_series(1, 2 + (random() * 1)::INTEGER);  -- 2 ou 3 itens por pedido

UPDATE pedidos p
SET total = sub.total_calculado
FROM (
    SELECT pedido_id,
           ROUND(SUM(quantidade * preco_unitario)::NUMERIC, 2) AS total_calculado
    FROM itens_pedido
    GROUP BY pedido_id
) sub
WHERE p.id = sub.pedido_id;
