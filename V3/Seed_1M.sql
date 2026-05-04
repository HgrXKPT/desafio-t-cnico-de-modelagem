-- =============================================================
-- Seed de dados mock ~ 1.005.530 registros
-- Banco: ECommerce (SQL Server)
--
-- Execute APOS o Script.sql principal.
-- Tempo estimado: 5-15 minutos dependendo do servidor.
--
-- Distribuicao:
--   Categoria_produto :      30 novas
--   Vendedor          :     500 novos
--   Produto           :   5.000 novos
--   Usuarios          : 100.000 novos
--   Endereco          : 100.000 novos  (1 por usuario novo)
--   Pedido            : 200.000 novos
--   Pagamento         : 200.000 novos  (1 por pedido novo)
--   Itens_pedido      : 400.000 novos  (2 por pedido novo)
--   TOTAL             : ~1.005.530
-- =============================================================

USE ECommerce;
GO
SET NOCOUNT ON;
GO

-- =============================================================
-- 1. Categoria_produto (30 novas)
-- =============================================================
PRINT 'Inserindo Categoria_produto...';
WITH
  E0 AS (SELECT 1 c UNION ALL SELECT 1),
  E1 AS (SELECT 1 c FROM E0 a, E0 b),
  E2 AS (SELECT 1 c FROM E1 a, E1 b),
  E3 AS (SELECT 1 c FROM E2 a, E2 b),
  Tally AS (SELECT TOP 30 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) n FROM E3)
INSERT INTO Categoria_produto(nome, status)
SELECT
    'Categoria ' + CAST(n AS VARCHAR(10)),
    1
FROM Tally;
GO

-- =============================================================
-- 2. Vendedor (500 novos)
--    CNPJ: 14 digitos numericos distintos (zero-padded)
-- =============================================================
PRINT 'Inserindo Vendedores...';
WITH
  E0 AS (SELECT 1 c UNION ALL SELECT 1),
  E1 AS (SELECT 1 c FROM E0 a, E0 b),
  E2 AS (SELECT 1 c FROM E1 a, E1 b),
  E3 AS (SELECT 1 c FROM E2 a, E2 b),
  Tally AS (SELECT TOP 500 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) n FROM E3 a, E2 b)
INSERT INTO Vendedor(nome_empresa, cnpj, data_cadastro, status)
SELECT
    'Empresa Mock ' + CAST(n AS VARCHAR(10)),
    RIGHT('00000000000000' + CAST(n + 10000 AS VARCHAR), 14),
    DATEADD(DAY, -(n % 730), GETDATE()),
    1
FROM Tally;
GO

-- =============================================================
-- 3. Produto (5.000 novos)
--    id_categoria : 2 a 31  (seed=1, novas=30)
--    id_vendedor  : 2 a 501 (seed=1, novas=500)
-- =============================================================
PRINT 'Inserindo Produtos...';
WITH
  E0 AS (SELECT 1 c UNION ALL SELECT 1),
  E1 AS (SELECT 1 c FROM E0 a, E0 b),
  E2 AS (SELECT 1 c FROM E1 a, E1 b),
  E3 AS (SELECT 1 c FROM E2 a, E2 b),
  Tally AS (SELECT TOP 5000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) n FROM E3 a, E3 b)
INSERT INTO Produto(nome, descricao, preco, quantidade_estoque, status, id_categoria, id_vendedor)
SELECT
    'Produto Mock ' + CAST(n AS VARCHAR(10)),
    'Descricao do produto mock numero ' + CAST(n AS VARCHAR(10)),
    CAST((ABS(CHECKSUM(NEWID())) % 99900 + 100) AS DECIMAL(18,2)) / 100.0,
    ABS(CHECKSUM(NEWID())) % 500,
    1,
    (n % 30) + 2,
    (n % 500) + 2
FROM Tally;
GO

-- =============================================================
-- 4. Usuarios (100.000 novos)
--    email   : user_N@mock.com  (unico)
--    telefone: 11 digitos zero-padded de N (unico)
-- =============================================================
PRINT 'Inserindo Usuarios...';
WITH
  E0 AS (SELECT 1 c UNION ALL SELECT 1),
  E1 AS (SELECT 1 c FROM E0 a, E0 b),
  E2 AS (SELECT 1 c FROM E1 a, E1 b),
  E3 AS (SELECT 1 c FROM E2 a, E2 b),
  E4 AS (SELECT 1 c FROM E3 a, E3 b),
  Tally AS (SELECT TOP 100000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) n FROM E4 a, E3 b)
INSERT INTO Usuarios(nome, email, telefone, data_cadastro, status)
SELECT
    'Usuario Mock ' + CAST(n AS VARCHAR(10)),
    'user_' + CAST(n AS VARCHAR(10)) + '@mock.com',
    RIGHT('00000000000' + CAST(n AS VARCHAR), 11),
    DATEADD(DAY, -(n % 1825), GETDATE()),
    1
FROM Tally;
GO

-- =============================================================
-- 5. Endereco (100.000 novos)
--    id_usuario: 2 a 100.001 (1 endereco por usuario novo)
-- =============================================================
PRINT 'Inserindo Enderecos...';
WITH
  E0 AS (SELECT 1 c UNION ALL SELECT 1),
  E1 AS (SELECT 1 c FROM E0 a, E0 b),
  E2 AS (SELECT 1 c FROM E1 a, E1 b),
  E3 AS (SELECT 1 c FROM E2 a, E2 b),
  E4 AS (SELECT 1 c FROM E3 a, E3 b),
  Tally AS (SELECT TOP 100000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) n FROM E4 a, E3 b)
INSERT INTO Endereco(rua, numero, complemento, cidade, estado, cep, pais, id_usuario, tipo_endereco)
SELECT
    'Rua Mock ' + CAST(n AS VARCHAR(10)),
    CAST((n % 9999) + 1 AS VARCHAR(10)),
    CASE WHEN n % 3 = 0 THEN 'Apto ' + CAST(n % 200 AS VARCHAR) ELSE NULL END,
    CASE n % 5
        WHEN 0 THEN 'Sao Paulo'
        WHEN 1 THEN 'Belo Horizonte'
        WHEN 2 THEN 'Rio de Janeiro'
        WHEN 3 THEN 'Curitiba'
        ELSE 'Porto Alegre'
    END,
    CASE n % 5 WHEN 0 THEN 'SP' WHEN 1 THEN 'MG' WHEN 2 THEN 'RJ' WHEN 3 THEN 'PR' ELSE 'RS' END,
    RIGHT('00000000' + CAST(n AS VARCHAR), 8),
    'Brasil',
    n + 1,
    CASE n % 3 WHEN 0 THEN 'Residencial' WHEN 1 THEN 'Comercial' ELSE 'Outros' END
FROM Tally;
GO

-- =============================================================
-- 6. Pedido (200.000 novos)
--    id_usuario  : distribuido ciclicamente entre 2 e 100.001
--    id_endereco : mesmo id do usuario (insercao 1:1 sequencial)
--    status      : 1-4 (ciclico)
--    valor_total : R$ 1,00 a R$ 9.999,00 (placeholder; recalculado apos itens)
-- =============================================================
PRINT 'Inserindo Pedidos...';
WITH
  E0 AS (SELECT 1 c UNION ALL SELECT 1),
  E1 AS (SELECT 1 c FROM E0 a, E0 b),
  E2 AS (SELECT 1 c FROM E1 a, E1 b),
  E3 AS (SELECT 1 c FROM E2 a, E2 b),
  E4 AS (SELECT 1 c FROM E3 a, E3 b),
  Tally AS (SELECT TOP 200000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) n FROM E4 a, E3 b)
INSERT INTO Pedido(data, status, valor_total, id_usuario, id_endereco)
SELECT
    DATEADD(DAY, -(n % 730), GETDATE()),
    (n % 4) + 1,
    CAST((ABS(CHECKSUM(NEWID())) % 999900 + 100) AS DECIMAL(18,2)) / 100.0,
    (n % 100000) + 2,
    (n % 100000) + 2
FROM Tally;
GO

-- =============================================================
-- 7. Pagamento (200.000 novos — 1 por pedido novo)
--    metodo: ciclico 1-3 baseado no id do pedido.
--    Exclui id=1 (pedido do seed ja tem pagamento).
-- =============================================================
PRINT 'Inserindo Pagamentos...';
INSERT INTO Pagamento(metodo, valor, status, data_transacao, id_pedido)
SELECT
    (p.id % 3) + 1,
    p.valor_total,
    (ABS(CHECKSUM(NEWID())) % 2) + 1,
    DATEADD(HOUR, ABS(CHECKSUM(NEWID())) % 72, p.data),
    p.id
FROM Pedido p
WHERE p.id >= 2;
GO

-- =============================================================
-- 8. Itens_pedido (400.000 novos — 2 por pedido novo)
--
--    Triggers desabilitadas para o bulk insert:
--      - TR_Itens_pedido_Estoque bloquearia inserts por estoque insuficiente
--        (demanda media ~440 unidades vs estoque medio ~250 por produto).
--      - TR_Itens_pedido_AtualizaValorTotal executaria 400k UPDATEs em Pedido.
--    Ambos sao reconciliados em lote apos os inserts.
--
--    Constraint UNIQUE(id_pedido, id_produto) exige produtos
--    distintos dentro do mesmo pedido.
--
--    Passo 1: id_produto = ((id_pedido - 2) % 5000) + 2
--    Passo 2: id_produto = (((id_pedido - 2) + 2500) % 5000) + 2
--
--    Prova de unicidade por pedido:
--      p1 - p2 = 2500 mod 5000 != 0  => sempre distintos.
-- =============================================================
DISABLE TRIGGER TR_Itens_pedido_AtualizaValorTotal ON Itens_pedido;
DISABLE TRIGGER TR_Itens_pedido_Estoque ON Itens_pedido;
GO

PRINT 'Inserindo Itens_pedido (passo 1 de 2)...';
INSERT INTO Itens_pedido(nome_item, quantidade_itens, preco, id_pedido, id_produto)
SELECT
    'Item A - Pedido ' + CAST(id AS VARCHAR),
    (ABS(CHECKSUM(NEWID())) % 10) + 1,
    CAST((ABS(CHECKSUM(NEWID())) % 99900 + 100) AS DECIMAL(18,2)) / 100.0,
    id,
    ((id - 2) % 5000) + 2
FROM Pedido
WHERE id >= 2;
GO

PRINT 'Inserindo Itens_pedido (passo 2 de 2)...';
INSERT INTO Itens_pedido(nome_item, quantidade_itens, preco, id_pedido, id_produto)
SELECT
    'Item B - Pedido ' + CAST(id AS VARCHAR),
    (ABS(CHECKSUM(NEWID())) % 10) + 1,
    CAST((ABS(CHECKSUM(NEWID())) % 99900 + 100) AS DECIMAL(18,2)) / 100.0,
    id,
    (((id - 2) + 2500) % 5000) + 2
FROM Pedido
WHERE id >= 2;
GO

ENABLE TRIGGER TR_Itens_pedido_AtualizaValorTotal ON Itens_pedido;
ENABLE TRIGGER TR_Itens_pedido_Estoque ON Itens_pedido;
GO

-- =============================================================
-- Reconciliacao pos-seed
--    valor_total: recalculado em lote para todos os pedidos novos.
--    quantidade_estoque: descontado o total vendido (minimo 0).
-- =============================================================
PRINT 'Reconciliando valor_total dos Pedidos...';
UPDATE Pedido
SET valor_total = sub.total
FROM Pedido
JOIN (
    SELECT id_pedido, SUM(preco * quantidade_itens) AS total
    FROM Itens_pedido
    GROUP BY id_pedido
) sub ON sub.id_pedido = Pedido.id
WHERE Pedido.id >= 2;
GO

PRINT 'Reconciliando valor dos Pagamentos...';
UPDATE Pagamento
SET valor = p.valor_total
FROM Pagamento pag
JOIN Pedido p ON p.id = pag.id_pedido
WHERE pag.id_pedido >= 2;
GO

PRINT 'Reconciliando quantidade_estoque dos Produtos...';
UPDATE Produto
SET quantidade_estoque =
    CASE
        WHEN quantidade_estoque - ISNULL(v.total_vendido, 0) < 0 THEN 0
        ELSE quantidade_estoque - ISNULL(v.total_vendido, 0)
    END
FROM Produto
LEFT JOIN (
    SELECT id_produto, SUM(quantidade_itens) AS total_vendido
    FROM Itens_pedido
    WHERE id_pedido >= 2  -- exclui pedido do seed (trigger ja debitou na insercao)
    GROUP BY id_produto
) v ON v.id_produto = Produto.id;
GO

-- =============================================================
-- Verificacao final de contagens
-- =============================================================
PRINT 'Contagem final por tabela:';
SELECT tabela, total FROM (
    SELECT 'Categoria_produto' tabela, COUNT(*) total FROM Categoria_produto UNION ALL
    SELECT 'Vendedor',                 COUNT(*) FROM Vendedor               UNION ALL
    SELECT 'Produto',                  COUNT(*) FROM Produto                UNION ALL
    SELECT 'Usuarios',                 COUNT(*) FROM Usuarios               UNION ALL
    SELECT 'Endereco',                 COUNT(*) FROM Endereco               UNION ALL
    SELECT 'Pedido',                   COUNT(*) FROM Pedido                 UNION ALL
    SELECT 'Pagamento',                COUNT(*) FROM Pagamento              UNION ALL
    SELECT 'Itens_pedido',             COUNT(*) FROM Itens_pedido
) contagens
ORDER BY total;
GO
