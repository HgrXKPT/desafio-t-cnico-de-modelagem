### Destrinchando Seed.

- Cria um Mock virtual com base no E0-E1(Valores que seguyem uma equacao e definem a quantidade de linha)
- Vai realizar um insert com base nos dados que passamos no Select

```

  E0 AS (SELECT 1 c UNION ALL SELECT 1),
  E1 AS (SELECT 1 c FROM E0 a, E0 b),
  E2 AS (SELECT 1 c FROM E1 a, E1 b),
  E3 AS (SELECT 1 c FROM E2 a, E2 b),
  Tally AS (SELECT TOP 30 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) n FROM E3)
```

- Cria uma tabela virtual de 256 Linhas(16x16), com base nisso Define Tally(variavel) como as top 30 do E3 que sao as ultimas linhas.

```
INSERT INTO Categoria_produto(nome, status)
SELECT
    'Categoria ' + CAST(n AS VARCHAR(10)),
    1
FROM Tally;
```

- Insere na Categoria_produto(nome,status) os dados Categoria + n, no caso Categoria + 1(sendo auto incrementado)
- CAST converte o valor de N em string, podendo concatenar com o 1 valor.
- Esses valores vem do primeiro select que é o Tally.

### Pós claude

## Prompt

```
Com base nessa análise superficial do seed e sua funcionalidade,
quero que expanda a explicação de forma mais profunda, mas ao mesmo
tempo mantendo a simplicidade e forma de escrita.
```

### Por que CTEs em cascata?

- SQL não tem `for` nativo pra gerar N linhas. A saída é montar uma "tabela de números" (Tally) e usar ela como base do `INSERT`.
- Cada CTE (E0, E1, E2...) dobra de forma exponencial a quantidade de linhas via CROSS JOIN. É barato porque o SQL Server só materializa o que for consumido pelo `TOP`.
- Esse padrão é chamado de **Tally Table CTE** e é mais rápido que `WHILE` ou cursor — tudo é executado em uma única operação set-based.

### A matemática do E0 até o E3

```
E0 AS (SELECT 1 c UNION ALL SELECT 1)   -- 2 linhas
E1 AS (SELECT 1 c FROM E0 a, E0 b)       -- 2 * 2 = 4
E2 AS (SELECT 1 c FROM E1 a, E1 b)       -- 4 * 4 = 16
E3 AS (SELECT 1 c FROM E2 a, E2 b)       -- 16 * 16 = 256
```

- O `FROM E0 a, E0 b` é um **CROSS JOIN implícito** — cada linha de `a` é combinada com cada linha de `b`.
- O crescimento é ao quadrado a cada nível: 2 → 4 → 16 → 256 → 65.536 → 4 bilhões. Com 4 ou 5 níveis já dá pra alimentar qualquer seed.
- Pros inserts maiores (5.000, 100.000, 200.000) o seed adiciona um `E4` e cruza `E4 a, E3 b` pra chegar no volume necessário. É só ajustar quantos níveis usar.
- O conteúdo é sempre `1 c` (uma coluna constante). Não importa o valor — o que interessa é a **contagem de linhas**.

### O papel do Tally

```
Tally AS (SELECT TOP 30 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) n FROM E3)
```

- `ROW_NUMBER() OVER (...)` numera cada linha sequencialmente: 1, 2, 3, ...
- `ORDER BY (SELECT NULL)` é um truque pra dizer "**não me importa a ordem**". Como todas as linhas têm o mesmo valor, ordenar de verdade seria desperdício de CPU — esse hack pula a etapa de sort.
- `TOP 30` corta o resultado no tamanho desejado. É aqui que se define **quantas linhas vão ser inseridas**.
- O resultado final é uma única coluna `n` com 1, 2, 3, ..., 30 — funcionando como o índice de um `for` em outras linguagens.

### O INSERT em si

```
INSERT INTO Categoria_produto(nome, status)
SELECT
    'Categoria ' + CAST(n AS VARCHAR(10)),
    1
FROM Tally;
```

- Pra cada linha do Tally, o `SELECT` produz uma tupla e o `INSERT` consome todas de uma vez. 30 linhas → 30 inserts em **um único comando** (set-based, não linha-a-linha).
- `CAST(n AS VARCHAR(10))` converte o número pra string. Sem isso, `'Categoria ' + n` daria erro: o SQL Server tentaria converter `'Categoria '` pra número e falharia (`Conversion failed when converting the varchar value`).
- A constante `1` na coluna `status` é replicada pra todas as linhas — todas categorias nascem ativas.
- Resultado final na tabela: `Categoria 1`, `Categoria 2`, ..., `Categoria 30`.

### Por que esse padrão é bom

- **Set-based**: o SQL Server insere tudo numa operação só. Loop com `WHILE` seria várias ordens de magnitude mais lento (cada iteração tem overhead de transação e rede interna).
- **Escalável**: muda só o `TOP N` e dá pra gerar de 30 a milhões de linhas com o mesmo template.
- **Sem tabela auxiliar**: as CTEs vivem só durante a execução, não sujam o schema com tabelas permanentes de números.
- **Determinístico**: o `n` sempre começa em 1 e vai crescendo de 1 em 1 — útil pra gerar dados previsíveis (emails únicos, CNPJs sequenciais, FKs cíclicas com `(n % X) + offset`).
