### Queries dos Relatórios.

- Cada relatório usa JOIN, GROUP BY e funções de agregação (COUNT, SUM, AVG).
- Padrão de JOIN é sempre FK = PK, e o GROUP BY agrupa pela PK da entidade pra não fundir homônimos.

### Relatório 1 - Pedidos por usuário

- Lista cada usuário com a quantidade de pedidos e o valor total gasto.
- LEFT JOIN pra trazer também os usuários que nunca compraram.

```
USE ECommerce;

SELECT
    u.nome                        AS Usuario,
    COUNT(p.id)                   AS Quantidade_pedido,
    SUM(p.valor_total) AS valor_total_gasto
FROM Usuarios u
LEFT JOIN Pedido p ON p.id_usuario = u.id
GROUP BY u.id, u.nome
ORDER BY valor_total_gasto DESC;
```

### Relatório 2 - Produtos mais vendidos

- Lista cada produto com quantidade vendida e receita gerada.
- INNER JOIN porque produto que nunca vendeu não interessa no ranking.

```
USE ECommerce;

SELECT
    pr.nome                              AS Produto,
    SUM(ipr.quantidade_itens)            AS quantidade_vendida,
    SUM(ipr.preco * ipr.quantidade_itens) AS receita_gerada
FROM Produto pr
INNER JOIN Itens_pedido ipr ON ipr.id_produto = pr.id
GROUP BY pr.id, pr.nome
ORDER BY quantidade_vendida DESC;
```

### Relatório 3 - Vendas por vendedor

- Lista cada vendedor com a quantidade de pedidos distintos e a receita.
- COUNT DISTINCT no id_pedido pra não contar o mesmo pedido várias vezes quando o vendedor tem mais de um produto nele.

```
USE ECommerce;

SELECT
    v.nome_empresa                                  AS nome_vendedor,
    COUNT(DISTINCT ipr.id_pedido)                   AS quantidade_pedidos,
    ISNULL(SUM(ipr.preco * ipr.quantidade_itens), 0) AS receita_gerada
FROM Vendedor v
LEFT JOIN Produto      pr  ON pr.id_vendedor = v.id
LEFT JOIN Itens_pedido ipr ON ipr.id_produto = pr.id
GROUP BY v.id, v.nome_empresa
ORDER BY receita_gerada DESC;
```

### Pós claude

## Prompt

```
Analise meu relatório de queries e padronize ele no estilo dos outros .md,
mantendo a parte simples com o que eu fiz e adicionando uma parte mais
profunda com explicações resumidas, sem perder meu tom.
```

### Por que FK = PK no JOIN

- A regra de toda relação é: a FK de uma tabela aponta pra PK de outra. O `ON` só reflete isso.
- Ligar PK com PK (tipo `pr.id = v.id`) só "casa" linhas por coincidência de número, não por relação real.
- Bug que apareceu nas versões anteriores: `ON ipr.id = p.id` no Relatório 2 e `ON id_endereco = u.id` no Relatório 1. Os dois foram corrigidos pras FKs corretas.

### LEFT vs INNER

- **LEFT JOIN**: traz todos da tabela da esquerda, mesmo sem match na direita. Bom pra relatório que precisa mostrar "vazios" (usuário sem compra, vendedor sem venda).
- **INNER JOIN**: só traz linhas que dão match dos dois lados. Bom pra ranking, onde quem não tem dados não interessa.

### Por que COUNT(DISTINCT) no Relatório 3

- Quando o vendedor tem 3 produtos no mesmo pedido, o JOIN duplica esse pedido 3 vezes nas linhas.
- `COUNT(id_pedido)` puro contaria 3. `COUNT(DISTINCT id_pedido)` conta 1.
- Regra mental: se a coisa que você quer contar pode aparecer várias vezes por causa de JOIN, usa DISTINCT.

### Por que ISNULL nos SUMs

- `SUM` de zero linhas retorna `NULL`, não `0`.
- Com LEFT JOIN, uma entidade sem venda cai aqui e mostraria NULL na receita.
- `ISNULL(SUM(...), 0)` força 0,00 — fica bonito no relatório.

### Por que GROUP BY pela PK

- Agrupar só por nome funde homônimos (dois "João Silva" viram uma linha só).
- Agrupar pela PK garante uma linha por entidade real.
- O nome entra no GROUP BY só pra poder aparecer no SELECT.

### Por que ipr.preco e não pr.preco no Relatório 2

- `Produto.preco` é o preço atual, que pode ter mudado depois da venda.
- `Itens_pedido.preco` é o preço congelado no momento da compra.
- Pra receita histórica, sempre o preço da venda — senão a receita "muda" se o produto mudar de preço hoje.

### Sanity check do Relatório 3

- 500 vendedores × 400 pedidos = 200.000 pedidos. Bate com o total do seed.
- Receita média ~R$ 2,2M por vendedor (800 itens × ~R$ 500 × ~5,5 unidades).
- "Frame" aparece com 1 pedido / R$ 1.900 — é o seed inicial do Script.sql, não veio do bulk.
