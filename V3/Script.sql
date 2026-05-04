--Criacao Database
CREATE DATABASE ECommerce;
GO

USE ECommerce;
GO

--Criacao das tabelas

CREATE TABLE Usuarios (
    id int IDENTITY(1,1) PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    telefone VARCHAR(11) NOT NULL CONSTRAINT CHK_usuarios_telefone CHECK (LEN(telefone) = 11),
    data_cadastro DATETIME DEFAULT GETDATE(),
    status int NOT NULL CONSTRAINT CHK_usuarios_status CHECK (status IN (1, 2))  -- 1-Ativo 2-Inativo
);

CREATE TABLE Endereco(
    id int IDENTITY(1,1) PRIMARY KEY,
    rua VARCHAR(100) NOT NULL,
    numero VARCHAR(10) NOT NULL CONSTRAINT CHK_endereco_numero CHECK (LEN(numero) >= 1),
    complemento VARCHAR(50),
    cidade VARCHAR(100) NOT NULL,
    estado VARCHAR(2) NOT NULL CONSTRAINT CHK_endereco_estado CHECK (LEN(estado) = 2),
    cep VARCHAR(8) NOT NULL CONSTRAINT CHK_endereco_cep CHECK (LEN(cep) = 8),
    pais VARCHAR(30) NOT NULL,
    id_usuario int NOT NULL,
    tipo_endereco VARCHAR(20) NOT NULL CONSTRAINT CHK_endereco_tipo CHECK (tipo_endereco IN ('Residencial', 'Comercial', 'Condominio', 'Outros')),
    FOREIGN KEY (id_usuario) REFERENCES Usuarios(id)
);

CREATE TABLE Pedido(
    id int IDENTITY(1,1) PRIMARY KEY,
    data DATETIME DEFAULT GETDATE(),
    status INT NOT NULL CONSTRAINT CHK_pedido_status CHECK(status IN (1, 2, 3, 4)),  -- 1-Aguardando Pagamento 2-Processando NFE 3-Enviado 4-Entregue
    valor_total DECIMAL(18,2) NOT NULL CONSTRAINT CHK_pedido_valor_total CHECK(valor_total > 0),
    id_usuario int NOT NULL,
    id_endereco int NOT NULL,
    FOREIGN KEY(id_usuario) REFERENCES Usuarios(id),
    FOREIGN KEY(id_endereco) REFERENCES Endereco(id)
);

CREATE TABLE Pagamento(
    id int IDENTITY(1,1) PRIMARY KEY,
    metodo int NOT NULL CONSTRAINT CHK_pagamento_metodo CHECK(metodo IN (1, 2, 3)),  -- 1-Cartao 2-Boleto 3-Pix
    valor DECIMAL(18,2) NOT NULL CONSTRAINT CHK_pagamento_valor CHECK(valor > 0),
    status int NOT NULL CONSTRAINT CHK_pagamento_status CHECK(status IN (1, 2)),  -- 1-Aguardando pagamento 2-Pagamento Concluido
    data_transacao DATETIME DEFAULT GETDATE(),
    id_pedido int NOT NULL,
    FOREIGN KEY(id_pedido) REFERENCES Pedido(id),
    CONSTRAINT UQ_pagamento_pedido UNIQUE(id_pedido)
);

CREATE TABLE Vendedor(
    id int IDENTITY(1,1) PRIMARY KEY,
    nome_empresa VARCHAR(100) NOT NULL,
    cnpj VARCHAR(14) NOT NULL CONSTRAINT CHK_vendedor_cnpj CHECK (LEN(cnpj) = 14),
    data_cadastro DATETIME DEFAULT GETDATE(),
    status INT NOT NULL CONSTRAINT CHK_vendedor_status CHECK (status IN (1, 2))  -- 1-Ativo 2-Inativo
);

CREATE TABLE Categoria_produto(
    id int IDENTITY(1,1) PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    status int NOT NULL CONSTRAINT CHK_categoria_status CHECK (status IN (1, 2))  -- 1-Ativa 2-Inativa
);

CREATE TABLE Produto(
    id int IDENTITY(1,1) PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(500) NOT NULL,
    preco DECIMAL(18,2) NOT NULL CONSTRAINT CHK_produto_preco CHECK(preco > 0),
    quantidade_estoque int NOT NULL CONSTRAINT CHK_produto_quantidade_estoque CHECK(quantidade_estoque >= 0),
    status int NOT NULL CONSTRAINT CHK_produto_status CHECK (status IN (1, 2)),  -- 1-Ativo 2-Inativo
    data_criacao DATETIME DEFAULT GETDATE(),
    id_categoria int NOT NULL,
    id_vendedor int NOT NULL,
    FOREIGN KEY(id_vendedor) REFERENCES Vendedor(id),
    FOREIGN KEY(id_categoria) REFERENCES Categoria_produto(id)
);

CREATE TABLE Itens_pedido(
    id int IDENTITY(1,1) PRIMARY KEY,
    nome_item VARCHAR(100) NOT NULL,
    quantidade_itens int NOT NULL,
    preco DECIMAL(18,2) NOT NULL CONSTRAINT CHK_itens_pedido_preco CHECK(preco > 0),
    id_pedido int NOT NULL,
    id_produto int NOT NULL,
    FOREIGN KEY(id_pedido) REFERENCES Pedido(id),
    FOREIGN KEY(id_produto) REFERENCES Produto(id),
    CONSTRAINT UQ_itens_pedido UNIQUE(id_pedido, id_produto)
);

--Indices

CREATE UNIQUE INDEX UIX_Vendedor_cnpj ON Vendedor(cnpj);

CREATE INDEX IX_Endereco_id_usuario      ON Endereco(id_usuario);
CREATE INDEX IX_Pedido_id_usuario        ON Pedido(id_usuario);
CREATE INDEX IX_Pedido_id_endereco       ON Pedido(id_endereco);
-- IX_Pagamento_id_pedido omitido: UNIQUE constraint UQ_pagamento_pedido ja cria indice unico na coluna
CREATE INDEX IX_Produto_id_vendedor      ON Produto(id_vendedor);
CREATE INDEX IX_Produto_id_categoria     ON Produto(id_categoria);
CREATE INDEX IX_Itens_pedido_id_pedido   ON Itens_pedido(id_pedido);
CREATE INDEX IX_Itens_pedido_id_produto  ON Itens_pedido(id_produto);
GO

-- Triggers

CREATE TRIGGER TR_Itens_pedido_AtualizaValorTotal
ON Itens_pedido
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- JOIN em vez de subquery correlacionada: se todos os itens do pedido forem
    -- deletados, a subquery retorna zero linhas e o UPDATE simplesmente nao ocorre,
    -- evitando setar valor_total = NULL.
    UPDATE Pedido
    SET valor_total = sub.total
    FROM Pedido
    JOIN (
        SELECT id_pedido, SUM(preco * quantidade_itens) AS total
        FROM Itens_pedido
        WHERE id_pedido IN (
            SELECT id_pedido FROM inserted
            UNION
            SELECT id_pedido FROM deleted
        )
        GROUP BY id_pedido
    ) sub ON sub.id_pedido = Pedido.id;
END;
GO

CREATE TRIGGER TR_Itens_pedido_Estoque
ON Itens_pedido
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Devolve estoque de itens removidos ou com quantidade reduzida.
    -- GROUP BY garante comportamento correto em batch com mesmo id_produto.
    UPDATE Produto
    SET quantidade_estoque = quantidade_estoque + grp.total
    FROM Produto
    JOIN (
        SELECT id_produto, SUM(quantidade_itens) AS total
        FROM deleted
        GROUP BY id_produto
    ) grp ON grp.id_produto = Produto.id;

    -- Verifica disponibilidade e debita estoque dos novos itens.
    -- GROUP BY garante comportamento correto em batch com mesmo id_produto.
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        IF EXISTS (
            SELECT 1 FROM Produto p
            JOIN (
                SELECT id_produto, SUM(quantidade_itens) AS total
                FROM inserted
                GROUP BY id_produto
            ) grp ON grp.id_produto = p.id
            WHERE p.quantidade_estoque < grp.total
        )
        BEGIN
            RAISERROR('Estoque insuficiente para o produto', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        UPDATE Produto
        SET quantidade_estoque = quantidade_estoque - grp.total
        FROM Produto
        JOIN (
            SELECT id_produto, SUM(quantidade_itens) AS total
            FROM inserted
            GROUP BY id_produto
        ) grp ON grp.id_produto = Produto.id;
    END;
END;
GO

-- Seed inicial

INSERT INTO Usuarios(nome, email, telefone, status) VALUES(
    'Higor', 'Higor@gmail.com', '31999572171', 1
);

INSERT INTO Endereco(rua, numero, complemento, cidade, estado, cep, pais, id_usuario, tipo_endereco) VALUES(
    'Begonia', '24', 'B', 'Betim', 'MG', '32673146', 'Brasil', 1, 'Condominio'
);

INSERT INTO Pedido(status, valor_total, id_usuario, id_endereco) VALUES(
    1, 1900.00, 1, 1
);

INSERT INTO Pagamento(metodo, valor, status, id_pedido) VALUES(
    1, 1900.00, 1, 1
);

INSERT INTO Vendedor(nome_empresa, cnpj, status) VALUES(
    'Frame', '31207001000197', 1
);

INSERT INTO Categoria_produto(nome, status) VALUES(
    'Periféricos', 1
);

INSERT INTO Produto(nome, descricao, preco, quantidade_estoque, status, id_categoria, id_vendedor) VALUES(
    'Cadeira', 'Cadeira corsair TC100 RELAXED', 950.99, 15, 1, 1, 1
);

INSERT INTO Itens_pedido(nome_item, quantidade_itens, preco, id_pedido, id_produto) VALUES(
    'Cadeira', 2, 950.00, 1, 1
);
