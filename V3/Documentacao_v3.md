    # Documentação: Script SQL — E-commerce (V3)

## Prompts usados:

```
Com base nessa documentacao:

e em esse script, quero que analise e crie uma nova documentacao a respeito dos novos scripts/seed, seguindo o modelo e informacoes abstraídas do primeiro script/doc.
```

## Estrutura Geral do Script

O script da V3 evoluiu para suportar não apenas a estrutura, mas também a integridade avançada e o teste de estresse da aplicação. Ele está dividido nos seguintes blocos lógicos:

| Bloco                    | Conteúdo                                                                                                                 |
| :----------------------- | :----------------------------------------------------------------------------------------------------------------------- |
| **DDL – Database**       | Criação do banco `ECommerce` e definição de escopo (`USE`).                                                              |
| **DDL – Tabelas**        | Criação das 8 tabelas com PKs, FKs e adoção rigorosa de **Constraints Nomeadas** para facilitar o debug.                 |
| **Índices**              | Criação de índices focados em performance para buscas via Chaves Estrangeiras (FKs).                                     |
| **Triggers (Novidade)**  | Lógica de negócio no banco para controle de estoque e recálculo automático de valor de pedidos.                          |
| **Seed Inicial**         | Carga mínima para validação de integridade (1 registro por tabela).                                                      |
| **Carga Massiva (Mock)** | Script de inserção em lote utilizando CTEs (Tally Tables) para gerar ~1.000.000 de registros para testes de performance. |

---

## Ordem de Criação das Tabelas

A hierarquia de dependências foi sutilmente alterada na V3, já que `Pedido` agora também depende de `Endereco` para registro preciso do local de entrega daquela transação específica.

```text
Usuarios → Endereco
             ↓
         Pedido ← Usuarios
             ↓
         Pagamento

Vendedor → Categoria_produto → Produto → Itens_pedido (Depende de Pedido e Produto)
```

---

## Detalhamento das Tabelas (Novidades e Constraints)

Na V3, todas as constraints de validação (CHECK) receberam nomes explícitos (ex: `CHK_usuarios_telefone`), o que é uma excelente prática para facilitar a identificação de erros de inserção no backend.

### Usuarios

| Coluna        | Tipo         | Constraints / Observações                                   |
| :------------ | :----------- | :---------------------------------------------------------- |
| id            | INT IDENTITY | PK auto-incremento                                          |
| nome          | VARCHAR(100) | NOT NULL                                                    |
| email         | VARCHAR(150) | UNIQUE NOT NULL (Gera índice único automático)              |
| telefone      | VARCHAR(11)  | `CHK_usuarios_telefone` — Garante exatamente 11 caracteres  |
| data_cadastro | DATETIME     | DEFAULT GETDATE()                                           |
| status        | INT          | `CHK_usuarios_status` — Restrito a 1 (Ativo) ou 2 (Inativo) |

---

### Endereco

Permite múltiplos endereços por usuário. Agora possui validação estrita de tipos.

| Coluna        | Tipo         | Constraints / Observações                                                           |
| :------------ | :----------- | :---------------------------------------------------------------------------------- |
| id            | INT IDENTITY | PK                                                                                  |
| cep / estado  | VARCHAR      | Validação de tamanho via `CHK_endereco_cep` e `CHK_endereco_estado`                 |
| id_usuario    | INT          | FK → Usuarios(id)                                                                   |
| tipo_endereco | VARCHAR(20)  | `CHK_endereco_tipo` — Restrito a 'Residencial', 'Comercial', 'Condominio', 'Outros' |

---

### Pedido

Nova FK: Agora amarra qual foi o endereço selecionado no momento do checkout, mantendo histórico.

| Coluna      | Tipo          | Constraints / Observações                             |
| :---------- | :------------ | :---------------------------------------------------- |
| id          | INT IDENTITY  | PK                                                    |
| status      | INT           | `CHK_pedido_status` — Enum (1, 2, 3, 4)               |
| valor_total | DECIMAL(18,2) | `CHK_pedido_valor_total > 0` (Atualizado via Trigger) |
| id_usuario  | INT           | FK → Usuarios(id)                                     |
| id_endereco | INT           | FK → Endereco(id)                                     |

---

### Pagamento

Relação 1:1 garantida pelo banco.

| Coluna    | Tipo         | Constraints / Observações                        |
| :-------- | :----------- | :----------------------------------------------- |
| id        | INT IDENTITY | PK                                               |
| metodo    | INT          | `CHK_pagamento_metodo` — (1, 2, 3)               |
| id_pedido | INT          | FK → Pedido(id) + UNIQUE (`UQ_pagamento_pedido`) |

---

### Tabelas de Catálogo

#### Vendedor, Categoria_produto, Produto

- **Status padronizado**: 1 (Ativo) ou 2 (Inativo)
- **Produto (Estoque)**: `CHK_produto_quantidade_estoque >= 0`

---

### Itens_pedido

Tabela de junção transacional.

| Coluna          | Tipo          | Constraints / Observações         |
| :-------------- | :------------ | :-------------------------------- |
| preco           | DECIMAL(18,2) | Valor da unidade no ato da compra |
| UQ_itens_pedido | CONSTRAINT    | UNIQUE(id_pedido, id_produto)     |

---

## Índices (Foco em Performance)

A V3 adota índices em todas as FKs usadas em JOIN/WHERE:

- `UIX_Vendedor_cnpj` (unicidade)
- `IX_Endereco_id_usuario`
- `IX_Pedido_id_usuario`
- `IX_Pedido_id_endereco`
- `IX_Produto_id_vendedor`
- `IX_Produto_id_categoria`
- `IX_Itens_pedido_id_pedido`
- `IX_Itens_pedido_id_produto`

> Nota: `Pagamento.id_pedido` já possui índice por ser UNIQUE.

---

## Triggers (Regras de Negócio)

### 1. TR_Itens_pedido_AtualizaValorTotal

- **Gatilho**: AFTER INSERT, UPDATE, DELETE na tabela `Itens_pedido`
- **Ação**: Recalcula o `valor_total` da tabela `Pedido` somando (`preco * quantidade_itens`)
- **Performance**: Uso de JOIN para evitar subqueries lentas

---

### 2. TR_Itens_pedido_Estoque

- **Gatilho**: AFTER INSERT, UPDATE, DELETE na tabela `Itens_pedido`
- **Ação**:
  - Se itens forem removidos/diminuídos → estoque é devolvido
  - Se novos itens entrarem → valida estoque
  - Se não houver estoque → `RAISERROR` + `ROLLBACK TRANSACTION`
  - Caso haja → estoque é debitado

---

## Seed e Geração Massiva de Dados (Stress Test)

### Seed Básico

- 1 INSERT por tabela
- Simula cenário real (ex: usuário comprando produtos com cartão no seu endereço)

---

### Mock Data (~1.000.000 de registros)

#### Como funciona

- Uso de **CTEs + Tally Tables (E0, E1, …)**
- Muito mais performático que `WHILE`

#### Distribuição

- 100k Usuários
- 200k Pedidos
- 400k Itens

---

### Otimizações durante a carga

- `DISABLE TRIGGER` temporariamente:
  - Evita bloqueio por validação de estoque
  - Evita overhead de recálculo a cada insert

---

### Reconciliação final

- Reativa triggers (`ENABLE TRIGGER`)
- Executa `UPDATE` massivo para recalcular todos os pedidos
- Garante integridade e consistência dos dados
