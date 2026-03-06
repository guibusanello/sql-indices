# SQL - Índices

Esse repositório tem o objetivo de aprofundar conhecimentos relacionados ao uso de índices no SQL com exercícios para fixação.

## O que é um índice?

Um índice é uma estrutura de dados auxiliar que o PostgreSQL mantém para acelerar consultas. Funciona como o índice de um livro: em vez de ler página por página, você vai direto ao conteúdo.

**Sem índice:** PostgreSQL faz um Sequential Scan — lê todas as linhas da tabela.

**Com índice:** PostgreSQL faz um Index Scan — vai direto às linhas relevantes.

## Sintaxe básica

```sql
-- Criar índice simples
CREATE INDEX idx_nome ON tabela (coluna);

-- Criar índice único
CREATE UNIQUE INDEX idx_email ON usuarios (email);

-- Índice composto (múltiplas colunas)
CREATE INDEX idx_nome_data ON pedidos (cliente_id, criado_em);

-- Índice parcial (apenas parte das linhas)
CREATE INDEX idx_ativos ON usuarios (email) WHERE ativo = true;

-- Índice com expressão
CREATE INDEX idx_email_lower ON usuarios (LOWER(email));

-- Remover índice
DROP INDEX idx_nome;
```

## Explain Analyze
O EXPLAIN ANALYZE é a ferramenta mais poderosa para entender o que o PostgreSQL está fazendo de verdade com suas queries. 
```sql
-- EXPLAIN mostra o plano de execução
EXPLAIN SELECT * FROM usuarios WHERE email = 'joao@email.com';

-- EXPLAIN ANALYZE executa a query e mostra métricas reais
EXPLAIN ANALYZE SELECT * FROM usuarios WHERE email = 'joao@email.com';
```