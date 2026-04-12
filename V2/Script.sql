--Criacao Database
CREATE DATABASE ECommerce;


--Criacao das tabelas

CREATE TABLE Usuarios (
    id int IDENTITY(1,1) PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    telefone VARCHAR(11) NOT NULL CONSTRAINT CHK_telefone_tamanho CHECK (LEN(telefone) = 11),
    data_cadastro DATETIME DEFAULT GETDATE(),
    status int NOT NULL,
);

CREATE TABLE Endereco(
    id int IDENTITY(1,1) PRIMARY KEY,
    rua VARCHAR(100) NOT NULL,
    numero VARCHAR(10) NOT NULL CONSTRAINT CHK_numero_tamanho CHECK (LEN(numero) = 1) ,
    complemento VARCHAR(50),
    cidade VARCHAR(100) NOT NULL,
    estado VARCHAR(2) NOT NULL CONSTRAINT CHK_estado_tamanho CHECK (LEN(estado) = 2),
    cep VARCHAR(8) NOT NULL CONSTRAINT CHK_cep_tamanho CHECK (LEN(cep) = 8),
    pais VARCHAR(30) NOT NULL,
    id_usuario int NOT NULL,
    tipo_endereco VARCHAR(20) NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuarios(id)
)

CREATE TABLE Pedido(
    id int IDENTITY(1,1) PRIMARY KEY,
    data DATETIME DEFAULT GETDATE() ,
    status INT NOT NULL,
    valor_total DECIMAL(18,2) NOT NULL CONSTRAINT CHK_valor_tamanho CHECK(valor_total > 0),
    metodo_pagamento int NOT NULL,
    id_usuario int NOT NULL,
    FOREIGN KEY(id_usuario) REFERENCES Usuarios(id)

);

CREATE TABLE Pagamento(
    id int IDENTITY(1,1) PRIMARY KEY,
    metodo int NOT NULL,
    valor DECIMAL(18,2) NOT NULL CONSTRAINT CHK_valor_tamanho CHECK(valor > 0),
    status int NOT NULL,
    data_transacao DATETIME DEFAULT GETDATE(),
    id_pedido int not null,
    FOREIGN KEY(id_pedido) REFERENCES Pedido(id)
);

CREATE TABLE Vendedor(
    id int IDENTITY(1,1) PRIMARY KEY,
    nome_empresa VARCHAR(100) NOT NULL,
    cnpj VARCHAR(14) NOT NULL CONSTRAINT CHK_cnpj_tamanho CHECK (LEN(cnpj) = 14),
    data_cadastro DATETIME DEFAULT GETDATE(),
    status INT
);

CREATE TABLE Categoria_produto(
    id int IDENTITY(1,1) PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    status int NOT NULL
);

CREATE TABLE Produto(
    id int IDENTITY(1,1) PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(500) NOT NULL,
    preco DECIMAL(18,2) NOT NULL CONSTRAINT CHK_preco_tamanho CHECK(preco > 0),
    quantidade_estoque int  NOT NULL,
    status int NOT NULL,
    data_criacao DATETIME DEFAULT GETDATE(),
    id_categoria int NOT NULL,
    id_vendedor int NOT NULL,
    FOREIGN KEY(id_vendedor) REFERENCES Vendedor(id),
    FOREIGN KEY(id_categoria) REFERENCES Categoria_produto(id)

);

CREATE TABLE Itens_pedido(
    id int IDENTITY(1,1) PRIMARY KEY,
    nome_item VARCHAR(100),
    quantidade_itens int NOT NULL,
    preco DECIMAL(18,2) NOT NULL CONSTRAINT CHK_preco_tamanho CHECK(preco > 0),
    id_pedido int NOT NULL,
    id_produto int NOT NULL,
    FOREIGN KEY(id_pedido) REFERENCES Pedido(id),
    FOREIGN KEY(id_produto) REFERENCES Produto(id)

);

--Indices

CREATE UNIQUE INDEX UIX_Usuarios_email ON Usuarios(email);
CREATE UNIQUE INDEX UIX_Vendedor_cnpj ON Vendedor(cnpj);

-- Seed inicial

INSERT INTO Usuarios(nome, email,telefone,status) VALUES(
    'Higor', 'Higor@gmail.com', '31999572171', 1
);

INSERT INTO Endereco(rua,numero,complemento,cidade,estado,cep,pais,tipo_endereco) VALUES(
    'Begonia', '24', 'B', 'Betim', 'MG', '32673146', 'Brasil', 'Condominio'
);

INSERT INTO Pedido(status,valor_total,metodo_pagamento,id_usuario) VALUES(
    1, 1520.00, 1, 1
);

INSERT INTO pagamento(metodo,valor,status) VALUES(
    1, 1520.00, 1
);

INSERT INTO Vendedor(nome_empresa,cnpj,status) VALUES(
    'Frame', '31207001197', 1
);

INSERT INTO Categoria_produto(nome, status) VALUES(
    'Periféricos', 1
);

INSERT INTO Produto(nome, descricao,preco,quantidade_estoque,status,id_categoria,id_vendedor) VALUES(
    'Cadeira', 'Cadeira corsair TC100 RELAXED', 950.99, 15, 1, 1, 1
);

INSERT INTO Itens_pedido(nome_item,quantidade_itens,preco,id_pedido,id_produto) VALUES(
    'Cadeira', 2, 950.00, 1, 1
)

