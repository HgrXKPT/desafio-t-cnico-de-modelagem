# Documentação: Script SQL — E-commerce

# Rascunho sobre definição script

---

# Segmento

Ordem lógica pensada na hora de seguir na criacao do script foi olhar nas dependencias de cada tabela uma com a outra, segue fluxo.

Usuarios -> Endereco -> Pedido -> Pagamento -> Vendedor -> Categoria_produto -> Produto -> Itens_pedido

Definicoes de tamanho, tipos de variaveis seguem fielmente ao diagrama proposta na ultima 1:1, seguindo mesma lógica de FK, somente adicionando novos indices.

Além disso inclui Constraints e o seed inicial para o script, assim mantendo ele de forma completa e robusta.

# Index

Index foram definidos em Usuarios e Vendedor, sendo eles EMAIL,CNPJ. Ambos visando facilitar uma query para localizar individuo correspodente.

# Inserts

Existe um exemplo para Insert em cada uma das tabelas, no qual faz um seed inicial do script para assim possuir uma carga de dados inicial.

---

# Pós-claude

## Script:

`analise esse docmuento e melhore a documentacao dele, vasculhe no projeto em busca de contexto para entender, foque no arquivo script.sql`

---

## Estrutura Geral do Script

O script está organizado em quatro blocos sequenciais, cada qual com responsabilidade bem definida:

| Bloco              | Conteúdo                                                      |
| ------------------ | ------------------------------------------------------------- |
| **DDL – Database** | Criação do banco `ECommerce`                                  |
| **DDL – Tabelas**  | Criação das 8 tabelas, com PKs, FKs e constraints inline      |
| **Índices**        | Índices únicos para colunas de busca frequente                |
| **Seed**           | Um `INSERT` por tabela para carga inicial de dados de exemplo |

---

## Ordem de Criação das Tabelas

A sequência de `CREATE TABLE` respeita a hierarquia de dependências entre FKs, de forma que toda tabela referenciada já exista no momento em que a referência é declarada:

```
Usuarios → Endereco → Pedido → Pagamento
                             ↓
Vendedor → Categoria_produto → Produto → Itens_pedido
```

---

## Detalhamento das Tabelas

### Usuarios

Entidade raiz do modelo. Nenhuma FK de entrada; é referenciada por `Endereco` e `Pedido`.

| Coluna          | Tipo         | Constraints / Observações                                   |
| --------------- | ------------ | ----------------------------------------------------------- |
| `id`            | INT IDENTITY | PK auto-incremento                                          |
| `nome`          | VARCHAR(100) | NOT NULL                                                    |
| `email`         | VARCHAR(150) | UNIQUE NOT NULL — base para o índice `UIX_Usuarios_email`   |
| `telefone`      | VARCHAR(11)  | CHECK `LEN = 11` — formato sem formatação (DDD + 9 dígitos) |
| `data_cadastro` | DATETIME     | DEFAULT `GETDATE()` — auditoria de criação                  |
| `status`        | INT          | NOT NULL — gerenciado via enum no backend                   |

---

### Endereco

Dependente de `Usuarios`. Permite múltiplos endereços por usuário (`0..n`).

| Coluna          | Tipo         | Constraints / Observações                                   |
| --------------- | ------------ | ----------------------------------------------------------- |
| `id`            | INT IDENTITY | PK                                                          |
| `rua`           | VARCHAR(100) | NOT NULL                                                    |
| `numero`        | VARCHAR(10)  | NOT NULL                                                    |
| `complemento`   | VARCHAR(50)  | Nullable — campo opcional                                   |
| `cidade`        | VARCHAR(100) | NOT NULL                                                    |
| `estado`        | VARCHAR(2)   | CHECK `LEN = 2` — sigla de UF (ex.: `MG`, `SP`)             |
| `cep`           | VARCHAR(8)   | CHECK `LEN = 8` — sem hífen, facilita integração com ViaCEP |
| `tipo_endereco` | VARCHAR(20)  | NOT NULL — ex.: `Casa`, `Apartamento`, `Condomínio`         |
| `id_usuario`    | INT          | FK → `Usuarios(id)` NOT NULL                                |

---

### Pedido

Representa a transação de compra. Ligado a `Usuarios` e pai de `Itens_pedido` e `Pagamento`.

| Coluna             | Tipo          | Constraints / Observações                       |
| ------------------ | ------------- | ----------------------------------------------- |
| `id`               | INT IDENTITY  | PK                                              |
| `data`             | DATETIME      | NOT NULL                                        |
| `status`           | INT           | NOT NULL — enum de ciclo de vida do pedido      |
| `valor_total`      | DECIMAL(18,2) | CHECK `> 0` — padrão monetário                  |
| `metodo_pagamento` | INT           | NOT NULL — enum espelhado em `Pagamento.metodo` |
| `id_usuario`       | INT           | FK → `Usuarios(id)` NOT NULL                    |

---

### Pagamento

Registro da transação financeira. Separado de `Pedido` para suportar múltiplas tentativas por pedido.

| Coluna           | Tipo          | Constraints / Observações              |
| ---------------- | ------------- | -------------------------------------- |
| `id`             | INT IDENTITY  | PK                                     |
| `metodo`         | INT           | NOT NULL — enum de método de pagamento |
| `valor`          | DECIMAL(18,2) | CHECK `> 0`                            |
| `status`         | INT           | NOT NULL                               |
| `data_transacao` | DATETIME      | NOT NULL                               |
| `id_pedido`      | INT           | FK → `Pedido(id)` NOT NULL             |

---

### Vendedor

Entidade independente que fornece produtos. Sem FK de entrada no modelo atual.

| Coluna          | Tipo         | Constraints / Observações                                        |
| --------------- | ------------ | ---------------------------------------------------------------- |
| `id`            | INT IDENTITY | PK                                                               |
| `nome_empresa`  | VARCHAR(100) | NOT NULL                                                         |
| `cnpj`          | VARCHAR(14)  | CHECK `LEN = 14` — sem formatação; base para `UIX_Vendedor_cnpj` |
| `data_cadastro` | DATETIME     | NOT NULL                                                         |
| `status`        | INT          | Nullable — gerenciado via enum no backend                        |

---

### Categoria_produto

Classificação de produtos. Entidade própria (em vez de `ENUM`) permite adicionar atributos por categoria sem alterar o schema.

| Coluna   | Tipo         | Constraints |
| -------- | ------------ | ----------- |
| `id`     | INT IDENTITY | PK          |
| `nome`   | VARCHAR(100) | NOT NULL    |
| `status` | INT          | NOT NULL    |

---

### Produto

Catálogo de itens vendáveis. Referencia `Vendedor` e `Categoria_produto`.

| Coluna               | Tipo          | Constraints / Observações                                                      |
| -------------------- | ------------- | ------------------------------------------------------------------------------ |
| `id`                 | INT IDENTITY  | PK                                                                             |
| `nome`               | VARCHAR(100)  | NOT NULL                                                                       |
| `descricao`          | VARCHAR(500)  | NOT NULL — limite equilibra expressividade e storage                           |
| `preco`              | DECIMAL(18,2) | CHECK `> 0` — valor de catálogo (pode divergir do histórico em `Itens_pedido`) |
| `quantidade_estoque` | INT           | NOT NULL                                                                       |
| `status`             | INT           | NOT NULL                                                                       |
| `data_criacao`       | DATETIME      | NOT NULL                                                                       |
| `id_categoria`       | INT           | FK → `Categoria_produto(id)` NOT NULL                                          |
| `id_vendedor`        | INT           | FK → `Vendedor(id)` NOT NULL                                                   |

---

### Itens_pedido

Tabela de junção entre `Pedido` e `Produto`. O campo `preco` registra o valor **no momento da compra**, preservando o histórico mesmo que o preço do produto seja alterado futuramente.

| Coluna             | Tipo          | Constraints / Observações               |
| ------------------ | ------------- | --------------------------------------- |
| `id`               | INT IDENTITY  | PK                                      |
| `quantidade_itens` | INT           | NOT NULL                                |
| `preco`            | DECIMAL(18,2) | CHECK `> 0` — valor histórico da compra |
| `id_pedido`        | INT           | FK → `Pedido(id)` NOT NULL              |
| `id_produto`       | INT           | FK → `Produto(id)` NOT NULL             |

---

## Índices

Ambos os índices são do tipo `UNIQUE` e criados em colunas utilizadas como identificadores de negócio, complementando as PKs técnicas de identidade.

| Índice               | Tabela     | Coluna  | Motivação                                                 |
| -------------------- | ---------- | ------- | --------------------------------------------------------- |
| `UIX_Usuarios_email` | `Usuarios` | `email` | Busca de usuário por e-mail (login, recuperação de senha) |
| `UIX_Vendedor_cnpj`  | `Vendedor` | `cnpj`  | Busca de vendedor por CNPJ; impede duplicatas no cadastro |

---

## Seed Inicial

Um `INSERT` por tabela, suficiente para validar integridade referencial e executar queries básicas sem dados externos.

| Tabela              | Dado de Exemplo                                    |
| ------------------- | -------------------------------------------------- |
| `Usuarios`          | Higor — `higor@gmail.com` — telefone `31999572171` |
| `Endereco`          | Rua Begônia, 24 — Betim/MG — CEP `32673146`        |
| `Pedido`            | Valor `R$ 1.520,00` — método pagamento `1`         |
| `Pagamento`         | Valor `R$ 1.520,00` — método `1`                   |
| `Vendedor`          | Frame — CNPJ `31207001197`                         |
| `Categoria_produto` | Periféricos                                        |
| `Produto`           | Cadeira Corsair TC100 — `R$ 950,99` — estoque `15` |
| `Itens_pedido`      | 2x Cadeira — `R$ 950,00` por unidade               |

---
