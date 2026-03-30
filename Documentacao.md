# Documentação: Modelagem de Dados E-commerce

# Rascunho PRE-CLAUDÃO

---

### 1. Conceito Primário

Modelagem de banco de dados relacional para estruturação de um sistema de e-commerce.

### 2. Entidades Presentes

- **usuario**
- **endereco**
- **vendedor**
- **pedido**
- **itens_do_pedido**
- **pagamento**
- **produto**
- **categoria_produto**

### 3. Relacionamentos

- **usuario (1) ─── (0..n) endereco -> 1 usuario pode possuir nenhum ou muitos endereços, enquanto cada endereço só pertence a um usuario**
- **usuario (1) ─── (0..n) pedido -> 1 usuario pode ter nenhum ou muitos pedidos, enquanto um pedido só pertence a um usuario**
- **vendedor (1) ─── (0..n) produto -> 1 vendendor pode possuir nenhum ou muitos produtos, enquanto um produto só pertence a um vendedor**
- **pedido (1) ─── (1..n) itens_do_pedido -> 1 pedido precisa de no minimo um item mas pode ter varios, enquanto um item só pode existir em 1 pedido**
- **produto (1) ─── (0..n) itens_do_pedido -> 1 produto pode ter varios itens do mesmo tipo, enquanto cada item só pode ser um produto**
- **categoria_produto (1) ─── (0..n) produto -> 1 produto só pode pertencer a uma categoria, enquanto uma categoria pode possuir varios produtos**

### 4. Propriedades átipicas

- **estado(2) -> Definido como abreviaçao, exemplo: MG/SP**
- **cep(8) -> quantidade de digitos sem hífen**
- **tipo_endereco -> campo pequeno para especficar se é casa,ap,etc...**
- **preco_unitario(18,2) -> padrao para valores monetários**
- **descricao(500) -> cabe quantidade razoavel de informação e nao aloca muito espaço desnecessário**
- **cnpj(14) -> Tamanho em digitos do cnpj**
- **status/categoria_produto -> Ambos enum para padronizar com controle via backend**

---

# Resultado PÓS-CLAUDÃO

### Prompt

```
Vou te enviar um .md, ele é um rascunho com as informacoes principais sobre um diagrama de modelagem de dados, quero q vc mantenha minha parte e adicione a sua logo após o (PÓS-CLAUDAO), quero que foque em deixar mais profissional como se realmente fosse uma parte de uma documentação escrita por um senior.
```

---

### Não atingiu resultado esperado. Mais um prompt

```
Gostaria que fosse mais compacto, porem mantendo todas informacoes necessarias, pode ser criativo na hora de montar o .md, so mantenha as mesmas informacoes e integridade dos dados.
```

### Resultado

# Resultado PÓS-CLAUDÃO

---

## Análise Técnica do Modelo Relacional

O modelo segue o paradigma **relacional normalizado (3FN)**, estruturado em torno de dois fluxos principais: **gestão de usuários/endereços** e **ciclo de vida de pedidos**. A separação de responsabilidades entre entidades garante baixo acoplamento e facilita evolução independente de cada domínio.

---

### Detalhamento das Entidades

| Entidade            | Papel no Domínio                                         | Decisão de Design                                                                                                                            |
| ------------------- | -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `usuario`           | Entidade central; referenciada por `endereco` e `pedido` | Não armazena endereço diretamente — delega à entidade própria                                                                                |
| `endereco`          | Dependente de `usuario`                                  | `estado CHAR(2)` segue padrão IBGE de UF; `cep CHAR(8)` sem hífen facilita integração com APIs como ViaCEP                                   |
| `vendedor`          | Fornecedor de produtos; isolado do fluxo de compra       | `cnpj CHAR(14)` sem formatação simplifica validações pelo algoritmo Módulo 11                                                                |
| `produto`           | Entidade de catálogo                                     | `descricao VARCHAR(500)` — compromisso entre expressividade e eficiência de armazenamento                                                    |
| `categoria_produto` | Classificação de produtos                                | Entidade própria (vs. `ENUM`) habilita extensão futura de atributos por categoria sem alteração de schema                                    |
| `status`            | Classifição de status                                    | Entidade própria (vs. `ENUM`) habilita extensão futura de atributos por status sem alteração de schema                                       |
| `pedido`            | Transação do usuário                                     | Cardinalidade `(1..n)` com `itens_do_pedido` é restrição de negócio — pedido vazio não tem significado semântico                             |
| `itens_do_pedido`   | Resolve o N:N entre `pedido` e `produto`                 | `preco_unitario DECIMAL(18,2)` armazenado aqui para **preservar valor histórico** da compra, independente de atualizações futuras no produto |
| `pagamento`         | Registro de forma e status do pagamento                  | Separada de `pedido` para suportar múltiplas tentativas/métodos por transação                                                                |

---

### Pontos de Atenção

> **Hierarquia de categorias —** modelo atual suporta apenas um nível. Para estruturas hierárquicas, avaliar _Adjacency List_ ou _Nested Set_ em `categoria_produto`.
>
> **Soft delete —** entidades como `produto` e `usuario` devem considerar exclusão lógica (`deleted_at TIMESTAMP`) para preservar histórico sem violar integridade referencial.
>
> **Índices —** colunas de alta frequência em filtros (`usuario_id`, `pedido_id`, `produto_id`) devem receber índices explícitos para garantir performance em alto volume.
