# Compatibilidade Conceitual GSAN → OpenGSAN

> **Fase 0 — 19ª execução (2026-09-15).** Responde a **uma** pergunta: *em que sentido o OpenGSAN continua sendo o GSAN — e onde escolhemos deliberadamente deixar de ser iguais?*
>
> ⚠️ **Compatibilidade conceitual, funcional e semântica. Nunca operacional.** Nada aqui trata de ETL, coexistência, sincronização, cutover, replicação, ordem de importação ou transformação física de dados — isso pertence ao **projeto de migração**, separado (ADR-0005).

---

## 1. Objetivo

Permitir olhar para qualquer conceito central do GSAN e responder, **sem conhecer tabela, framework, classe ou tecnologia**:

```text
No GSAN ele significa X.
No OpenGSAN ele significa Y.
A relação entre os dois é: equivalente · reorganizada ·
deliberadamente diferente · inexistente · ou ainda pendente.
```

E, junto com isso, **qual oráculo de teste governa a diferença** — porque é essa a ponte para a próxima atividade (§22).

---

## 2. Escopo

### 2.1 🔴 O que este documento acrescenta

⚠️ Três documentos já tocam o tema. Registrar o que **não** se repete aqui é parte da honestidade do conjunto:

| Documento | Pergunta que responde | Relação com este |
| --------- | --------------------- | ---------------- |
| [`estruturas-centrais.md`](estruturas-centrais.md) | *O que fazemos com a estrutura existente?* — 64 decisões `PRESERVAR/MODERNIZAR/REESTRUTURAR/NÃO TRANSPORTAR` | ⚠️ **Referenciado, nunca repetido.** As 64 decisões são o **insumo**; aqui elas viram correspondência conceitual |
| [`visao-conceitual-opengsan.md §26`](../dominio/visao-conceitual-opengsan.md) | *Como o OpenGSAN deve ser organizado?* — 30 temas GSAN × OpenGSAN com veredito de evolução | 🔵 Cobre **temas**, não conceitos, e não diz **qual oráculo** governa cada diferença |
| [`visao-conceitual-opengsan.md §30`](../dominio/visao-conceitual-opengsan.md) | Lista de correspondência em 26 linhas de seta | 🔵 Diz *para onde vai*, não *o que significa* nem *o que se exige do teste* |

🟢 **O que só existe aqui**: (a) a **classificação** de cada conceito em cinco classes; (b) a **semântica** declarada dos dois lados, não só o destino; (c) o **oráculo** que governa cada diferença, com a divergência `D-xx` referenciada; (d) conceitos que nenhuma das listas anteriores cobria — estrutura territorial, anormalidade, grupo de faturamento, faixa, esgoto, impostos, negativação, situação especial, relatórios, integrações, canal digital, identidade do cliente final; (e) os **candidatos a divergência** encontrados (§20.3).

### 2.2 Fora de escopo

🔴 ETL · scripts · coexistência · sincronização · cutover · replicação · migração módulo a módulo · transformação física de banco · rollback de migração · mapeamento coluna a coluna · chave primária física.

⚠️ Também **não** se faz aqui: reclassificar as 64 estruturas, reabrir a ordem de implementação, decidir a ADR-0007 ou especificar cenários de teste.

---

## 3. O que significa compatibilidade

🔴 **Compatibilidade não é semelhança técnica.** Não significa:

```text
mesmas tabelas · mesmas classes · mesmas APIs
mesma tecnologia · mesmos bugs
```

Significa preservar, **quando deliberadamente decidido**:

```text
conceito + significado + regra de negócio
+ identidade relevante + resultado funcional
```

ainda que a representação técnica seja diferente.

### 3.1 🔴 O corolário que governa o resto

> Onde o legado está errado, **a igualdade é o defeito**.

É a razão de existirem dois oráculos e um registro de divergências. Preservar SHA-1 sem salt seria compatibilidade perfeita — e erro grave.

---

## 4. Tipos de compatibilidade

| Classe | Nome (resultado) | Significado | Oráculo |
| ------ | ---------------- | ----------- | ------- |
| **C1** | **EQUIVALENTE** | Mesmo conceito, mesma semântica, mesmo resultado | **1** — igualdade exigida |
| **C2** | **EQUIVALENTE COM REORGANIZAÇÃO** | Semântica preservada; representação, propriedade ou forma diferentes | **1** — ⚠️ comparação **semântica via mapeamento**, nunca estrutural |
| **C3** | **DIVERGÊNCIA DELIBERADA** | Comportamento diferente por decisão registrada | **2** — ⚠️ **igualdade é defeito** |
| **C4** | **SEM EQUIVALENTE DIRETO** | Estrutura ou mecanismo que não é levado adiante | **nenhum** — ver §4.2 |
| **C5** | **PENDENTE** | Decisão ainda aberta | **nenhum ainda** — ver §4.3 |

🔵 As cinco classes são as mesmas cinco do resultado esperado: `EQUIVALENTE`, `EQUIVALENTE COM REORGANIZAÇÃO`, `DIVERGÊNCIA DELIBERADA`, `SEM EQUIVALENTE DIRETO`, `PENDENTE`. **Um vocabulário só**, para não haver dois sistemas de nomes concorrendo.

### 4.1 🔴 C3 exige decisão registrada — sempre

⚠️ Uma diferença **só** é C3 se houver divergência aprovada (`D-xx`), correção de segurança registrada, correção funcional explicitamente aceita ou decisão arquitetural documentada. 🔴 **Diferença sem registro é defeito, não divergência** — sem exceção. Onde esta análise encontrou algo que *talvez* devesse mudar e ainda não está registrado, a marcação é **CANDIDATO A DIVERGÊNCIA** (§20.3), nunca C3.

### 4.2 C4 tem duas direções — e confundi-las é erro de categoria

| Direção | Exemplo | Consequência para o teste |
| ------- | ------- | ------------------------- |
| **C4** — existe no GSAN, não vai adiante | EJB, MDB, JMS, Quartz 1.5, applet, serialização Java, tabelas de backup | 🔴 **Não há o que comparar.** Afirmar equivalência seria erro de categoria |
| **C4-i** — existe no OpenGSAN, **sem antecedente** no GSAN | 🟢 A **camada de integração** — o GSAN não tem uma (§15) | Idem: nada a comparar, porque nada existia |

⚠️ C4-i é raro e merece marcação própria: tratá-lo como C2 afirmaria uma semântica preservada que **nunca existiu**.

### 4.3 C5 é o que a próxima atividade não pode especificar

🔵 Consequência direta e acionável: **conceito em C5 não tem cenário de teste especificável** — não porque falte esforço, mas porque falta decisão. A lista de C5 (§23) é, literalmente, a lista do que bloqueia a especificação de cenários.

---

## 5. Matriz consolidada

⚠️ **Seleção dos conceitos mais centrais**, não o total. O detalhe por área está em §6–§15, e é lá que a contagem completa vive (§5.1).

| Área | Conceito GSAN | OpenGSAN | Classe | Semântica preservada | Diferença deliberada | Ref. |
| ---- | ------------- | -------- | ------ | -------------------- | -------------------- | ---- |
| Cadastro | Imóvel / matrícula com DV | Imóvel, mesma identidade | **C1** | Identidade estável do ponto de serviço | — | CAD-01 |
| Cadastro | Economia em três representações | Conceito explícito; composição é fonte única | **C2** | Unidade de consumo que multiplica tarifa e mínimo | Redundância concorrente eliminada | CAD-05 |
| Cadastro | Situação da ligação **no Imóvel** | Situação **na Ligação** | **C2** | Estado operacional da ligação | Propriedade corrigida | CAD-08 |
| Micromedição | Hidrômetro × Instalação | Equipamento × Instalação | **C1** | Equipamento tem vida própria; instalação é vínculo datado | — | MIC-01 |
| Micromedição | Consumo (3 valores + origem) | Idem | **C1** | Quantidade com procedência declarada | — | MIC-04 |
| Micromedição | Retificação escreve em `ConsumoHistorico` | Micromedição aplica, a pedido | **C3** | Consumo continua correto | 🔴 Fronteira de agregado | **D-14** |
| Faturamento | `ContaGeral` + `Conta` + `ContaHistorico` | Identidade documental + versão + histórico + linhagem | **C2** | 🔴 Documento referenciável **por toda a vida** | Forma livre; tabelas-espelho não obrigatórias | FAT-02/03 |
| Faturamento | Snapshots do cálculo | Idem, com a razão documentada | **C1** | Responder *"com quais dados esta conta foi calculada"* | — | FAT-04 |
| Faturamento | 5 políticas de arredondamento | Idem, **explícitas e nomeadas** | **C1 estrita** | 🔴 Resultado ao centavo | ⚠️ Nenhuma — visibilidade não é comportamento | FAT-08 |
| Faturamento | Consumo fixo 20 em código | Parâmetro configurável | **C3** | Fallback de consumo | Constante mágica em caminho financeiro | **D-15** |
| Cobrança | Posição de dívida por consulta | Consulta **nomeada** no domínio | **C2** | 🔴 Derivada, não persistida | Ganha nome; continua derivada | COB-01 |
| Cobrança | Obrigação financeira implícita | Conceito comum **proposto** | **C5** | — | — | COB-02 |
| Cobrança | Parcelamento (composição + memória) | Idem | **C1** | Negociação rastreável item a item | — | COB-05 |
| Arrecadação | Recepção separada da classificação | Idem | **C1** | 🔴 Registrar o que chegou ≠ decidir o que significa | — | ARR-01 |
| Arrecadação | Identidade do pagamento **perdida no arquivamento** | Identidade estável por toda a vida | **C2** | Recebimento rastreável | Anomalia corrigida | ARR-04 |
| Atendimento | RA ≠ OS | Idem | **C1** | Demanda ≠ execução | — | ATE-01 |
| Atendimento | `SolicitacaoTipoEspecificacao` | Política de atendimento versionada | **C2** | Regra vem do dado, não do código | Ganha versionamento | ATE-03 |
| Atendimento | OS altera domínio alheio | OS **solicita**; o dono aplica | **C2** | 🔴 **Resultado funcional idêntico** | Ownership reorganizado | ATE-06 / D-14 |
| Segurança | Grupo × Funcionalidade × Operação (por URL) | Concessão por **identificador estável de domínio** | **C2** | Quem pode fazer o quê | Deixa de depender da rota | SEG-02 |
| Segurança | Abrangência aplicada por chamada manual | Escopo aplicado **por construção** | **C5** | Conceito preservado | ⚠️ Pendente de **D-17** | SEG-03 |
| Segurança | Senha em SHA-1 sem salt | BCrypt/Argon2 | **C3** | Autenticar o usuário | 🔴 Igualdade seria reproduzir a falha | **D-01** |
| Processamento | Processo / Etapa / Unidade | Idem | **C1** | Trabalho em volume observável sem log técnico | — | BAT-01 |
| Processamento | EJB · MDB · JMS · Quartz 1.5 | — | **C4** | — | — | BAT-03 |
| Relatórios | Definição · solicitação · artefato | Idem | **C1** | Três conceitos distintos | — | REL-01 |
| Relatórios | Artefato acessível por identificador, sem dono | Verificação de propriedade e escopo | **C3** | Entregar o artefato a quem o pediu | 🔴 Correção de IDOR | **D-03** |
| Integrações | Sete padrões sem política comum | Camada única de fronteira | **C4-i** | ⚠️ Nenhuma — **não havia camada** | Estrutura criada | INT-01 |
| Integrações | Escrita direta no banco do parceiro | Contrato explícito e idempotente | **C3** | Entregar o dado ao parceiro | Erro durável e observável | **D-12** |

### 5.1 Distribuição

⚠️ **Conferida por script**, conforme a regra permanente 6 de [`procedencia.md`](../procedencia.md). Composição da contagem, declarada para ser reproduzível: as tabelas de classificação de **§6–§15** (132 linhas com classe explícita) **mais** as 11 divergências de §12.2 e as 2 pendências de §12.3, que são classificadas em prosa por serem tabelas de outro formato.

| Classe | Qtd | Leitura |
| ------ | --: | ------- |
| **C1 — Equivalente** | 90 | 🔴 **A maioria larga.** O OpenGSAN é reconhecível como o GSAN porque 62% dos conceitos centrais permanecem intactos |
| **C2 — Equivalente com reorganização** | 25 | Semântica preservada; forma, propriedade ou visibilidade diferentes |
| **C3 — Divergência deliberada** | 17 | ⚠️ **Todas com `D-xx` registrada** — 16 divergências distintas, porque **D-03 aparece em duas áreas** (Segurança e Relatórios). Nenhuma inventada aqui |
| **C4 — Sem equivalente** | 5 | Mecanismos que não vão adiante |
| **C4-i — Sem antecedente no GSAN** | 1 | A camada de integração |
| **C5 — Pendente** | 7 | 🔴 O que bloqueia a especificação de cenários |
| **Total** | **145** | — |

🔵 **A leitura que responde à pergunta central**: **115 dos 145 conceitos (C1 + C2) mantêm a semântica** — 90 deles sem qualquer mudança. As 16 divergências distintas concentram-se em **segurança (11)**, fronteira e mecanismo (4) e **um defeito funcional** (D-13) — nenhuma em regra de negócio. 🔴 **Nenhuma divergência deliberada atinge cálculo financeiro**, e isso é decisão, não acaso (§9.4).

⚠️ **As 16 divergências estão todas cobertas**: D-01…D-16, sem lacuna. D-17 não entra na contagem por ser **proposta**, não aprovada (§20.2).

---

## 6. Cadastro

| Conceito GSAN | Semântica | Representação no GSAN | Conceito OpenGSAN | Classe | Ref. |
| ------------- | --------- | --------------------- | ----------------- | ------ | ---- |
| **Imóvel / matrícula** | Ponto de serviço identificável de forma estável | Identificador com dígito verificador | Imóvel, mesma identidade | **C1** | CAD-01 |
| **Dígito verificador da matrícula** | Validação de digitação | 🟢 Regra com variante por companhia | Regra de formatação como **ponto de extensão** | **C2** | CAD-01 |
| **Imóvel como agregado** | Um registro reúne dados de vários domínios | 🔴 Acumula situação de ligação, de cobrança e contadores | Imóvel restrito ao que é seu | **C2** | CAD-02 |
| **Cliente** | Pessoa física ou jurídica com relação com a companhia | Registro próprio | Cliente | **C1** | CAD-03 |
| **Cliente × Imóvel** | Vínculo com **papel** e **vigência** | Tabela de vínculo com papel, início, fim e motivo | Idem | **C1** | CAD-04 |
| **Economia** | 🔴 Unidade de consumo que multiplica tarifa e mínimo | ⚠️ **Três representações concorrentes**: total no imóvel, agregado por subcategoria, contagens auxiliares | Conceito explícito; **a composição por categoria é a fonte única**; o total é derivação | **C2** | CAD-05 |
| **Categoria / Subcategoria** | Classificação que determina tarifa e limiares de crítica | Catálogo com parâmetros de consumo | Idem | **C1** | CAD-06 |
| **Denormalizações de conveniência** | Acesso rápido a totais e classificação principal | Colunas mantidas no Imóvel | Projeções/derivações | **C2** | CAD-07 · ⚠️ §20.3 |
| **Ligação de água** | Vínculo físico do imóvel à rede, com estado operacional | 🟢 Chave **compartilhada** com o imóvel | Ligação com **identidade própria**; o 1:1 vira restrição, não chave | **C2** | CAD-08 |
| **Ligação de esgoto** | Idem, com percentuais que afetam o cálculo | Idem, com percentual de coleta/esgotamento | Idem; ⚠️ os percentuais continuam **fotografados na conta** | **C2** | CAD-08 |
| **Situação da ligação** | Estado que governa faturabilidade e ações de cobrança | 🔴 Guardado **no Imóvel** | Guardado **na Ligação** | **C2** | CAD-08 |
| **Localidade · Setor · Quadra** | Hierarquia territorial do atendimento | Encadeamento com identificadores próprios | Idem | **C1** | CAD-09 |
| **Rota** | 🟢 **Três finalidades distintas**: leitura (via quadra), entrega, alternativa (override) | Três colunas no Imóvel | Vínculo **por finalidade** | **C2** | CAD-10 |
| **Estrutura territorial como escopo** | Eixo de restrição de acesso | Usada pela abrangência da Segurança | Idem — 🔴 e é **pré-requisito** de S2 | **C1** | §12 |
| **Extensões de companhia no núcleo** | Necessidade real de uma companhia | 🔴 Campos e regras **nomeados** no núcleo | Configuração → política → extensão | **C2** | CAD-11 · §19 |

### 6.1 🔴 Economia — o caso que mais exige explicação

⚠️ **Compatibilidade aqui é de semântica, não de contagem de representações.**

```text
GSAN      total no imóvel  +  agregado por subcategoria  +  contagens auxiliares
                    ↓ (três fontes que podem divergir entre si)
OpenGSAN  composição por categoria = FONTE ÚNICA
                    ↓
          total = derivação da composição
```

🔵 **O que se preserva**: a economia continua sendo a unidade que **multiplica a tarifa mínima** e determina o valor mínimo por categoria — a regra financeira é idêntica. 🔴 **O que não se preserva**: a obrigação de manter três representações sincronizadas. Preservar a redundância seria preservar a possibilidade de divergência interna, que não é regra de negócio.

⚠️ **Oráculo 1 aplica-se ao resultado**: total de economias e valor mínimo calculado devem bater imóvel a imóvel. A forma de armazenar não entra na comparação.

### 6.2 Ligações — relação funcional preservada, chave não

🟢 No GSAN a ligação **usa a chave do imóvel**. 🔵 No OpenGSAN a relação 1:1 é preservada como **restrição**, não como identidade compartilhada.

⚠️ **Por que isso não é reestruturação por estética**: enquanto a ligação não tem identidade própria, ela não pode ter estado próprio — e é exatamente por isso que a situação da ligação acabou guardada no Imóvel. Uma coisa causou a outra.

---

## 7. Micromedição

| Conceito GSAN | Semântica | Representação no GSAN | Conceito OpenGSAN | Classe | Ref. |
| ------------- | --------- | --------------------- | ----------------- | ------ | ---- |
| **Hidrômetro (equipamento)** | 🔴 Bem físico com vida própria, independente de onde está | Registro do equipamento | Equipamento | **C1** | MIC-01 |
| **Instalação** | Vínculo datado entre equipamento e ligação | Histórico com leituras de fronteira na troca | Instalação | **C1** | MIC-01 |
| **Histórico de instalação** | Série de vínculos ao longo do tempo | Registros sucessivos | Idem | **C1** | MIC-01 |
| **Ponteiro de instalação vigente** | Acesso rápido à instalação corrente | Coluna no Imóvel/Ligação | Derivação do histórico | **C2** | MIC-02 |
| **Leitura** | Valor observado no equipamento, com data e leiturista | Registro por referência | Leitura | **C1** | MIC-03 |
| **Informado × faturamento** | 🔴 O que foi coletado ≠ o que foi usado no cálculo | Par de colunas em leitura, anormalidade e consumo | Idem, **como princípio declarado** | **C1** | MIC-03 |
| **Anormalidade** | Situação atípica que altera o tratamento, com ação escalonada | Catálogo paramétrico; pode emitir OS | Idem | **C1** | MIC-05 |
| **Consumo (3 valores)** | Real, média e mínimo, distinguíveis | `ConsumoHistorico` com valores e tipo | Idem | **C1** | MIC-04 |
| **Origem do consumo** | 🔴 Procedência declarada do número faturado | Tipo de consumo | Idem | **C1** | MIC-04 |
| **Média** | Estimativa usada quando não há leitura confiável | Cálculo sobre série anterior | Idem | **C1** | MIC-04 |
| **Referência (AAAAMM)** | Competência do ciclo | Coluna de ano/mês | Idem | **C1** | FAT-10 |
| **Escrita de consumo pela retificação** | Corrigir consumo ao retificar conta | 🔴 Faturamento escreve direto em `ConsumoHistorico` | Micromedição valida, aplica, versiona e responde | **C3** | **D-14** |
| **Subclasses de controlador por companhia** | Variação de cálculo por instalação | Herança de controlador | Ponto de extensão | **C4** | MIC-06 |

### 7.1 🔴 Equipamento ≠ instalação é compatibilidade obrigatória

⚠️ É o ponto em que o GSAN **acertou de forma não óbvia**, e por isso merece registro explícito: um hidrômetro trocado de imóvel mantém histórico próprio, e uma ligação acumula instalações sucessivas. Fundir os dois — tentação comum em modelagem "simplificadora" — destruiria o rastreio do parque de equipamentos **e** as leituras de fronteira na troca.

---

## 8. Faturamento

🔴 **A área que mais exige equivalência funcional.** Todas as linhas abaixo, salvo as duas divergências marcadas, são **oráculo 1 com igualdade ao centavo**.

| Conceito GSAN | Semântica | Representação no GSAN | Conceito OpenGSAN | Classe | Ref. |
| ------------- | --------- | --------------------- | ----------------- | ------ | ---- |
| **Grupo de faturamento** | Agrupamento operacional com cronograma que sincroniza leitura e faturamento | Grupo + cronograma por atividade e rota | Idem | **C1** | §11 |
| **Referência** | Competência do faturamento | AAAAMM (⚠️ distinta da referência contábil) | Idem, com a distinção preservada | **C1** | FAT-10 |
| **Tarifa** | Preço do serviço por categoria e faixa | Estrutura própria | Idem | **C1** | FAT-06 |
| **Vigência** | 🔴 A tarifa vale **por período**; conta antiga usa a tarifa da época | Vigência datada | Idem | **C1** | FAT-06 |
| **Faixa progressiva** | Consumo tarifado por escalões dentro da categoria | Faixas por vigência | Idem | **C1** | FAT-06 |
| **Consumo mínimo** | 🔴 Σ (tarifa mínima × economias) **por categoria** | Cálculo por categoria | Idem | **C1** | FAT-06 |
| **Cálculo de água** | Valor a partir de consumo, categoria, economias, faixas e mínimos | `gerarConta` + `gerarContaCategoria*` | Motor de conta individual | **C1** | §13 |
| **Cálculo de esgoto** | Percentual sobre a água, conforme a ligação | Percentuais **fotografados** na conta | Idem | **C1** | FAT-04 |
| **Impostos deduzidos** | Tributos calculados e destacados | Registro por conta | Idem | **C1** | FAT-08 |
| **Conta** | Documento financeiro de um imóvel numa referência | Entidade com situação, valor, vencimento | Conta | **C1** | FAT-01 |
| **Identidade documental** | 🔴 O documento é referenciável **por toda a vida**, corrente ou arquivado | `ContaGeral` + `Conta` + `ContaHistorico` (1:1) | Identidade estável + versão + histórico | **C2** | FAT-02/03 |
| **Snapshot do cálculo** | 🔴 Responder *"com quais dados esta conta foi calculada"* | `conta_categoria`, `cliente_conta`, percentuais | Contexto congelado | **C1** | FAT-04 |
| **Retificação** | Conta nova substitui a anterior, com vínculo de origem | `cnta_idorigem` | Linhagem | **C1** | FAT-05 |
| **Cancelamento** | 🔴 Documento cancelado é **estado**, não exclusão | Situação da conta | Idem | **C1** | FAT-01 |
| **Precisão financeira** | 🔴 **5 políticas de arredondamento** aplicadas em pontos específicos | HALF_UP 27 · UP 21 · DOWN 5 · HALF_DOWN 2 · FLOOR 2 | Idem, **explícitas e nomeadas** | **C1 estrita** | FAT-08 |
| **Débito · Crédito** | Lançamentos em **dois momentos**: a cobrar e cobrado/realizado | Entidades separadas por momento | Idem | **C1** | FAT-09 |
| **Guia de pagamento** | Documento pagável fora do ciclo da conta | Entidade própria | Idem | **C1** | FAT-09 |
| **Consumo fixo 20 em código** | Fallback quando falta consumo | 🔴 `setNumeroConsumoFaturadoMes(20)` | Parâmetro configurável | **C3** | **D-15** |
| **Variação de cálculo por companhia** | Regras de faixa específicas | 🔴 Métodos nomeados por companhia no núcleo | Política tarifária como extensão | **C2** | FAT-07 |
| **Cálculo individual × lote** | 🟢 **Mesma lógica** nos dois | `gerarConta` invocado pelo lote imóvel a imóvel | Idem — motor individual, lote orquestra | **C1** | §13 |

### 8.1 🔴 Identidade documental — a correspondência mais importante do documento

```text
GSAN                                   OpenGSAN
────────────────────────────────       ──────────────────────────────
ContaGeral    (identidade)        →    identidade documental
Conta         (versão corrente)   →    versão corrente
ContaHistorico(versão arquivada)  →    histórico
cnta_idorigem (encadeamento)      →    linhagem
```

🔴 **A compatibilidade está na semântica, não na tabela.** O que é inegociável: um pagamento, um item de cobrança ou uma parcela que apontem para um documento **continuam apontando para ele depois de retificado, cancelado ou arquivado**.

⚠️ **Por que errar aqui é o pior erro possível**: quebra pagamento, cobrança e parcelamento de contas retificadas ou arquivadas **ao mesmo tempo**. Foi classificada como a decisão nº 1 entre as cinco que mais importam.

🔵 **O que fica livre**: se a versão arquivada mora em tabela-espelho, em versionamento na mesma tabela ou em outro arranjo é **decisão de implementação** — nenhuma forma é exigida pela compatibilidade.

### 8.2 Snapshot — comportamento preservado, não estrutura tolerada

⚠️ Os snapshots **parecem** desnormalização e não são: são **auditoria retroativa**. O OpenGSAN deve continuar respondendo:

> *"Com quais dados esta conta foi calculada naquele momento?"*

🔴 **mesmo que o Cadastro tenha mudado depois** — categoria alterada, economias acrescentadas, percentual de esgoto revisto, tarifa nova. Uma conta de 2019 recalculada com o cadastro de hoje daria outro valor; a fotografia é o que impede isso.

### 8.3 Retificação — o que precisa sobreviver

```text
Conta A  ──origem──►  Conta B
```

Preservado integralmente: **documento anterior**, **documento sucessor**, **motivo**, **estado de cada um** e **rastreabilidade da cadeia**. 🔵 A retificação não apaga nem edita: **encadeia**. ⚠️ O único ponto que muda é *como* o consumo é corrigido no caminho — pela operação da Micromedição, não por escrita direta (**D-14**).

### 8.4 🔴 Precisão financeira — compatibilidade estrita de resultado

Registrado explicitamente, porque é onde a tentação de "melhorar" é maior:

| Item | Exigência |
| ---- | --------- |
| Arredondamento · tarifas · mínimos · esgoto · impostos · créditos · débitos · parcelamento · pagamento | 🔴 **Oráculo 1, igualdade ao centavo** |

⚠️ **As cinco políticas permanecem comportamento**, não dívida técnica. Unificar tudo em `HALF_UP` alteraria **valores cobrados do cliente** — isso é decisão de negócio, jamais técnica. 🔴 **Diferença de arredondamento não é "melhoria técnica": é defeito**, até que exista divergência registrada e aprovada.

🔵 O que muda é só a **visibilidade**: as políticas passam a ser nomeadas e explícitas em vez de espalhadas. Visibilidade não é comportamento.

---

## 9. Cobrança

| Conceito GSAN | Semântica | Representação no GSAN | Conceito OpenGSAN | Classe | Ref. |
| ------------- | --------- | --------------------- | ----------------- | ------ | ---- |
| **Posição / estoque de dívida** | 🔴 Quanto está em aberto, por imóvel ou cliente | ⚠️ **Consulta**, não entidade | Consulta **nomeada** no domínio | **C2** | COB-01 |
| **Obrigação financeira** | Valor devido, identificável, cobrável e quitável | ⚠️ Implícito em 5 tipos de documento | 🟡 Conceito comum **PROPOSTO** | **C5** | COB-02 |
| **Elegibilidade / critério** | Quais dívidas entram numa ação | Critérios parametrizados | Idem | **C1** | COB-04 |
| **Ação de cobrança** | Passo de um fluxo, com predecessora e situações-alvo | Catálogo com cronograma | Idem | **C1** | COB-04 |
| **Política de cobrança** | A estratégia que emerge do conjunto de ações | ⚠️ Emergente de dado disperso; sem nome | Conceito **nomeado e simulável** | **C2** | §12.3 |
| **Documento de cobrança** | Instrumento da ação, com itens rastreáveis dívida a dívida | Documento + itens | Idem | **C1** | COB-03 |
| **Parcelamento** | Negociação que substitui dívidas por prestações | Composição por item + **memória financeira integral** | Idem | **C1** | COB-05 |
| **Prestação** | Parcela da negociação, cobrada em conta futura | Débito a cobrar gerado pelo parcelamento | Idem | **C1** | COB-05 |
| **Desfazimento** | 🔴 Entrada não paga desfaz o acordo, com **estornos tipificados** | Rotina com estornos | Idem | **C1** | COB-05 |
| **Reparcelamento** | Novo acordo encadeado ao anterior | Encadeamento | Idem | **C1** | COB-05 |
| **Negativação** | Registrar inadimplente em bureau, e reabilitar | Critérios + movimentos do negativador | Domínio preservado; **integração por contrato** | **C1** / C2 | COB-06 |
| **Situação especial de cobrança** | Suspensão ou tratamento diferenciado, com histórico | Entidade com vigência | Idem | **C1** | COB-04 |
| **Situação de cobrança do imóvel** | Estado de cobrança do ponto de serviço | 🔴 Guardado **no Imóvel** | Guardado na **Cobrança** | **C2** | CAD-02 |
| **Contadores de reincidência** | Histórico de repetição do inadimplemento | Colunas no Imóvel | Derivação ou entidade da Cobrança | **C2** | COB-07 |
| **Fórmulas de acréscimo por impontualidade** | Juros e multa por atraso | ⚠️ Em código | Parametrização | **C5** | COB-07 |
| **Cobrança terceirizada por carteira** | Entregar carteira a empresa e remunerar por recuperação | Comando por empresa + acompanhamento | Idem | **C1** | COB-06 |

### 9.1 🔴 Posição de dívida — nomenclatura precisa

⚠️ **Não escrever "a dívida nasce na cobrança".** É falso nos dois sistemas.

```text
A OBRIGAÇÃO nasce com o DOCUMENTO           (Faturamento emite)
        ↓
o que depende dos recebimentos é a
POSIÇÃO EM ABERTO                            (derivada)
        ↓
a Cobrança ATUA sobre essa posição           (não a cria)
```

🟢 **Evidência do legado**: não existe entidade "Dívida" persistida. A posição é derivada de documentos, situações, pagamentos, cancelamentos e parcelamentos — e 🟢 *"a dívida cai por consulta"*, sem que o pagamento altere campo no documento.

🔵 **No OpenGSAN a posição continua derivada**, salvo decisão futura. Formalizar ≠ materializar: dar nome ao conceito não obriga a persisti-lo.

### 9.2 Obrigação financeira — `PROPOSTO`, não decisão

⚠️ Apresentar como decidido seria falso. O estado real:

| | |
| - | - |
| **GSAN** | 🟢 Cinco tipos de documento convivem como destino de recebimento e como item de cobrança e parcelamento |
| **OpenGSAN** | 🟡 **Pode** reconhecer conceitualmente uma obrigação financeira comum |
| **Status** | 🔴 **`PROPOSTO`** — depende de esclarecer a semântica de "Fatura" e de verificar se os candidatos têm ciclo de vida realmente comum |
| **Risco de antecipar** | Uma abstração errada aqui contamina Faturamento, Cobrança e Arrecadação **de uma vez** |

### 9.3 Negativação — domínio e integração separados

🔵 Caso exemplar da regra do §15: a **decisão** de negativar (critérios, elegibilidade, reabilitação) é domínio da Cobrança e é **C1**; o **envio ao bureau** é integração e passa a contrato explícito — **C2**. Confundir os dois foi o que levou o legado a espalhar integração por sete padrões.

### 9.4 🔴 Nenhuma divergência deliberada no cálculo financeiro

Registro deliberado: **nenhuma linha desta seção, nem da anterior, é C3.** Todas as 16 divergências estão em segurança, fronteira de módulo, mecanismo técnico ou defeito funcional que alcança o cliente (**D-13**). ⚠️ É uma propriedade a **manter**: divergência em cálculo financeiro exige aprovação do dono do negócio, não decisão técnica.

---

## 10. Arrecadação

🔴 **A separação em quatro momentos é compatibilidade obrigatória.**

```text
recepção      →  registrar o que chegou, bruto, com totais de conferência
   ↓
classificação →  decidir o que cada pagamento significa
   ↓
aplicação     →  baixar contra o documento
   ↓
conciliação   →  conferir calculado × informado pelo banco
```

⚠️ Fundir recepção e classificação — tentação de "simplificar" — destrói a capacidade de reprocessar a classificação sem perder o que o arrecadador enviou.

| Conceito GSAN | Semântica | Representação no GSAN | Conceito OpenGSAN | Classe | Ref. |
| ------------- | --------- | --------------------- | ----------------- | ------ | ---- |
| **Movimento do arrecadador** | Lote recebido, com totais para conferência | Registro do movimento | Idem | **C1** | ARR-01 |
| **Registro bruto preservado** | 🔴 O que chegou é guardado como chegou | Linha original mantida | Idem | **C1** | ARR-02 |
| **Recepção × classificação** | Receber ≠ interpretar | Etapas separadas | Idem | **C1** | ARR-01 |
| **Catálogo de situações do pagamento** | 🔴 **Nada é descartado**; situação anterior preservada | 14 situações | Idem, como catálogo governado | **C1** | ARR-03 |
| **Aplicação (baixa)** | Reduzir a obrigação pelo recebimento | Busca o documento na versão corrente **e** no histórico | Idem | **C1** | ARR-03 |
| **Identidade do pagamento** | Recebimento rastreável ao longo da vida | 🔴 **Perdida no arquivamento** — única anomalia do padrão de identidade | Estável por toda a vida | **C2** | ARR-04 |
| **Conciliação por aviso bancário** | Calculado × informado, com acertos e deduções | Aviso + acertos | Idem | **C1** | ARR-05 |
| **Excedente / devolução** | Recebido a mais retorna por instrumento próprio | Guia de devolução | Idem | **C1** | ARR-06 |
| **Débito automático** | Autorização de débito em conta, em três níveis | Três entidades | Idem | **C1** | ARR-06 |
| **Encerramento mensal** | 🔴 **Fechamento contábil**, com retenções e consolidação | Rotina de encerramento | Idem | **C1** | §19 |
| **Layouts bancários** | Interpretar arquivos de arrecadadores | 🟢 Embutidos no controlador | Contrato de integração por arrecadador | **C2** | ARR-07 |

### 10.1 Identidade do pagamento — C2, e por que não C3

⚠️ 🔴 **Não há `D-xx` para isto, e não se inventa um.** A classificação correta é **C2 — semântica preservada, representação corrigida**: o recebimento continua sendo o mesmo fato financeiro; o que muda é que seu identificador deixa de mudar ao ser arquivado.

🔵 **Consequência concreta para o teste**: a comparação de pagamentos deve ser feita por **mapeamento semântico** (valor, data, documento alvo, situação), **nunca por igualdade de identificador** — no legado o identificador do pagamento arquivado não é o mesmo de antes.

---

## 11. Atendimento

| Conceito GSAN | Semântica | Representação no GSAN | Conceito OpenGSAN | Classe | Ref. |
| ------------- | --------- | --------------------- | ----------------- | ------ | ---- |
| **RA (registro de atendimento)** | 🔴 **Protocolo da demanda** — alguém pediu algo | Entidade com estados e prazo | Protocolo de demanda | **C1** | ATE-01 |
| **OS (ordem de serviço)** | 🔴 **Unidade de execução** — alguém precisa fazer algo | Entidade com marcos e situação | Unidade de execução | **C1** | ATE-01 |
| **RA ≠ OS** | Demanda e execução são coisas distintas | 🟢 RA sem OS existe; há OS de origem não individual | Idem | **C1** | ATE-01 |
| **Cardinalidade RA ↔ OS** | Quantas OS por RA, e vice-versa | ❔ Física não determinada | — | **C5** | ATE-02 |
| **`SolicitacaoTipoEspecificacao`** | 🔴 **Núcleo paramétrico**: prazo, obrigatoriedades, geração de OS, efeitos financeiros, encerramento automático | Registro de parametrização | Política de atendimento **versionada** | **C2** | ATE-03 |
| **Tipo de serviço** | Segundo nível de regra, já com débito/crédito associados | Catálogo | Idem | **C1** | ATE-04 |
| **Tramitação** | Histórico auditável de por onde a demanda passou | Registros + unidade atual | Idem | **C1** | ATE-04 |
| **Prazo original × atual** | O prazo pode mudar, o original não se perde | Par de campos | Idem | **C1** | ATE-04 |
| **Espera e reiteração** | Demanda suspensa e demanda repetida | 🟢 Campos agregados que **sobrescrevem** | Histórico de estado | **C2** | ATE-05 |
| **Estados do RA e da OS** | Pendente/encerrado/bloqueado; ⚠️ inclusive **encerrada não executada** | Situações com marcos | Idem | **C1** | ATE-01 |
| **Efeito da OS em outro domínio** | Executar o serviço **muda o mundo** fora do Atendimento | 🔴 Operações "Efetuar…" alteram o domínio alheio | OS **solicita**; o dono valida e aplica | **C2** | ATE-06 · D-14 |
| **Indicadores de efeito na OS** | Registro de que a atualização ocorreu | Flags na OS | Idem | **C1** | ATE-06 |
| **Reativação / duplicidade** | Protocolos encadeados | Encadeamento | Idem | **C1** | §21 |
| **Códigos de exibição de RA** | Rótulos de tela (referência/atual/anterior) | Colunas | — | **C4** | ATE-06 |

### 11.1 🔴 Efeitos da OS — resultado preservado, ownership reorganizado

```text
GSAN                                OpenGSAN
─────────────────────────────       ──────────────────────────────────
OS executada                        OS executada
   ↓                                   ↓
operação altera o domínio alheio    o MÓDULO DONO recebe a solicitação
   ↓                                   ↓
estado alterado                     o dono valida, aplica e responde
                                       ↓
                                    estado alterado (pelo dono)
```

🔵 **O resultado funcional é o mesmo** — encerrar uma OS de religação continua deixando a ligação ativa. Por isso é **C2**, não C3: sob o oráculo 1, o estado final deve ser idêntico.

⚠️ A exceção é **D-14** (escrita de consumo pela retificação), onde o legado ultrapassa a fronteira de um jeito que o OpenGSAN **não** reproduz — e aí a diferença é de mecanismo, com o resultado ainda equivalente.

---

## 12. Segurança

🔴 **A área com a separação mais forte entre semântica preservada e implementação deliberadamente diferente.** Confundir as duas foi o defeito que criou a necessidade do registro de divergências.

### 12.1 Semântica preservada

| Conceito GSAN | Semântica | Representação no GSAN | Conceito OpenGSAN | Classe | Ref. |
| ------------- | --------- | --------------------- | ----------------- | ------ | ---- |
| **Usuário** | Identidade de quem opera | Registro com situação | Idem | **C1** | SEG-01 |
| **Grupo** | Conjunto de concessões atribuível | Registro | Idem | **C1** | SEG-01 |
| **Funcionalidade / Operação** | Unidade do que pode ser feito | 🔴 Ancoradas na **URL da Action** | **Identificador estável de domínio** | **C2** | SEG-02 |
| **Concessão por união de grupos** | Usuário recebe a soma das concessões dos seus grupos | Consulta por grupos | Idem | **C1** | SEG-01 |
| **Permissões especiais nomeadas** | Exceções dentro de uma funcionalidade | Catálogo | Idem | **C1** | SEG-04 |
| **Abrangência territorial (conceito)** | Restringir o que se vê ao território do usuário | Vínculo do usuário a níveis territoriais | Escopo territorial | **C1** | SEG-03 |
| **Bloqueio · expiração · histórico de senha** | Controles do ciclo de vida da credencial | Eixos independentes | Idem — ⚠️ **nenhum pode ser reduzido** | **C1** | SEG-04 |
| **Solicitação de acesso** | Fluxo de pedido e concessão | Workflow | Idem | **C1** | SEG-04 |
| **Auditoria em dois níveis** | Operação efetuada **e** alteração por linha/coluna | Duas estruturas | Idem — ⚠️ auditoria ≠ histórico de negócio | **C1** | SEG-05 |
| **Identidade de sistema (batch, API)** | Ator não humano, fora do RBAC de tela | Usuário técnico | Idem, como tipo de ator | **C1** | SEG-01 |
| **Unidade organizacional** | Posicionamento de fluxo, **não** autorização | Entidade | Idem | **C1** | SEG-01 |

### 12.2 Implementação deliberadamente diferente

⚠️ Todas **C3**, todas com divergência registrada. Nenhuma inventada aqui.

| Comportamento do GSAN | Comportamento do OpenGSAN | Conceito afetado | `D-xx` |
| --------------------- | ------------------------- | ---------------- | ------ |
| Senha em **SHA-1 sem salt** | BCrypt/Argon2 com salt | Autenticação | **D-01** |
| Token **MD5** efêmero em servlets auxiliares | Token com escopo e expiração | Autenticação auxiliar | **D-02** |
| Artefato de relatório recuperável por identificador, **sem dono e sem usuário autenticado** | Verificação de propriedade e escopo | Entrega de relatório | **D-03** |
| `/api/ordem-servico/*` **sem credencial** em `encerrar`, `fotos`, `programadas` | Autenticação em **todos** os endpoints | API de OS | **D-04** |
| Coleta de campo grava leitura **sem identificar a origem** | Autenticação de dispositivo antes de qualquer escrita | Integração de campo | **D-05** |
| Filtro de pagamento valida o **host do próprio servidor** e não bloqueia | Autenticação real do chamador, com recusa | API de pagamento | **D-06** |
| `FiltroSSO` com ramos idênticos; `FiltroSessaoExpirada` com guarda inalcançável | 🔴 **Nenhum filtro decorativo** | Cadeia de filtros | **D-07** |
| Chave de API **no código-fonte** e em properties versionado | Segredo em cofre/variável de ambiente | Segredos | **D-08** |
| URL `http://` fixa em integração | TLS obrigatório | Transporte | **D-09** |
| Servlet com `request`/`response` como campos de instância | Componentes sem estado por requisição | API de OS | **D-10** |
| Assinatura cobrindo **apenas o login**, sem corpo/nonce/timestamp | Assinatura com expiração e escopo, cobrindo a requisição | Integração GIS | **D-11** |

🔵 **A lista acima é a resposta honesta a "o OpenGSAN é compatível com o GSAN?"**: em segurança, **deliberadamente não é** — e cada ponto tem registro, motivo e teste próprio sob o oráculo 2.

### 12.3 🔴 Dois pendentes que mudam o desenho

| Pendência | Situação | Bloqueia |
| --------- | -------- | -------- |
| **Aplicação da abrangência** (por chamada manual × por construção) | **C5** — depende de **D-17**, que continua `PROPOSTA` | O bloco S2 da Segurança. ⚠️ **COMPATIBILIDADE PENDENTE DE DECISÃO** — não tratar como aprovada |
| **Existe mecanismo de negação?** (`UsuarioGrupoRestricao`) | **C5** — 🟢 a tabela existe; ⚠️ 🟢 **o uso no cálculo de autorização não foi observado** | 🔴 O modelo inteiro de autorização: *allow-only* × com *deny*. **Único bloqueio de dia 1** |

⚠️ **A existência da tabela não prova o uso** — a mesma lição registrada no catálogo de funcionalidades futuras para fiscal e SPED.

### 12.4 Identidade interna ≠ cliente final

🔴 **Não fundir os conceitos.**

| | Usuário interno | Cliente final |
| - | --------------- | ------------- |
| Quem é | Funcionário da companhia | Pessoa atendida pelo serviço |
| Autorização | RBAC por funcionalidade/operação + escopo territorial | 🔴 **Verificação de vínculo** com imóvel/cliente — não é RBAC |
| Origem no GSAN | Modelo `seguranca.*` | 🟢 Cadastro de login do cliente **no portal** |
| Classe | **C1** | **C2** — existe no legado, mas fora do modelo de segurança |

🔵 O cliente final **não é conceito novo**: existe no portal do legado. O que muda é deixar de ser um apêndice do portal e passar a ser um **tipo de ator** reconhecido.

---

## 13. Processamento

🔴 A compatibilidade está **no modelo funcional**, não na tecnologia.

| Conceito GSAN | Semântica | Representação no GSAN | Conceito OpenGSAN | Classe | Ref. |
| ------------- | --------- | --------------------- | ----------------- | ------ | ---- |
| **Processo · Etapa · Unidade** | Três níveis, cada um com definição e execução | Tabelas do schema `batch` | Idem | **C1** | BAT-01 |
| **Estado, tempos, parâmetros e erro persistidos** | 🔴 Responder, **sem log técnico**, quem pediu, o que rodou, o que falhou | Colunas nas execuções | Idem | **C1** | BAT-01 |
| **Ordem das etapas como dado** | A sequência é configuração | `sequencialExecucao` | Idem | **C1** | BAT-01 |
| **Partição por unidade** | Trabalho dividido por rota, localidade etc. | Identificador real da partição | Idem | **C1** | BAT-01 |
| **Retomada por unidade** | 🔴 Unidade concluída **não** é reexecutada | Verificação de estado | Idem | **C1** | BAT-02 |
| **Reprocessamento por etapa** | Retomar do ponto certo | Reprocessamento | Idem | **C1** | BAT-02 |
| **Autorização de processo** | Permissão própria, distinta da tela | Indicador + estado de espera | Idem | **C1** | BAT-02 |
| **Etapas = funcionalidades da Segurança** | Catálogo compartilhado | Vínculo | Idem | **C1** | BAT-01 |
| **Atomicidade dentro da unidade** | Efeito parcial é possível? | ❔ **Não comprovado** | — | **C5** | BAT-02 · §20.3 |
| **Contexto de execução** | Parâmetros da execução | 🟢 Objeto **serializado em bytes** | Contexto legível e inspecionável | **C2** | BAT-03 |
| **EJB · MDB · JMS · Quartz 1.5** | Transporte e agendamento | Infraestrutura JBoss 4 | — | **C4** | BAT-03 |

🔵 **O que torna este modelo digno de preservação** e não é óbvio: ele responde perguntas operacionais **sem log técnico** — quem pediu, quando, com quais parâmetros, qual partição falhou, o que já terminou. Isso é observabilidade funcional de primeira classe, **independente da tecnologia** que orquestra.

---

## 14. Relatórios

| Conceito GSAN | Semântica | Representação no GSAN | Conceito OpenGSAN | Classe | Ref. |
| ------------- | --------- | --------------------- | ----------------- | ------ | ---- |
| **Definição** | O relatório catalogado | Registro | Idem | **C1** | REL-01 |
| **Solicitação** | Pedido parametrizado de um usuário | Tarefa | Idem | **C1** | REL-01 |
| **Artefato / resultado** | O documento produzido | Binário persistido | Idem — forma livre | **C1** | REL-01 |
| **Decisão automática online × assíncrono** | Volume decide o modo de execução | Contagem × limite por tipo | Idem | **C1** | REL-01 |
| **Aprovação operacional de relatório pesado** | Autorização de **custo**, distinta de permissão de acesso | Parâmetro global | Idem | **C1** | REL-01 |
| **Relatório vazio como situação nomeada** | Sem dados ≠ erro | Situação | Idem | **C1** | REL-01 |
| **Acesso ao artefato** | Entregar o documento a quem o pediu | 🔴 Recuperável por identificador, **sem dono e sem autenticação** | Verificação de propriedade e escopo | **C3** | **D-03** |
| **Retenção do artefato** | Por quanto tempo guardar | ❔ Não decidida | — | **C5** | REL-02 |
| **Motor Jasper 1.2.2** | Renderizar o template | Biblioteca EOL | Capacidade preservada, motor livre | **C4** | REL-03 |
| **Serialização Java da solicitação** | Guardar os parâmetros do pedido | Bytes da linguagem | Representação legível | **C4** | REL-03 |

⚠️ **A compatibilidade de relatório é de conteúdo, nunca de bytes**: PDFs carregam timestamp e metadados que variam entre execuções — comparação binária falharia inclusive do legado contra ele mesmo. A comparação é **semântica**, preferencialmente sobre o *datasource* que alimenta o template.

---

## 15. Integrações

🔴 **Regra que governa toda a área**: mapear **capacidade funcional**, nunca tecnologia.

```text
GSAN      integração bancária por mecanismo X
OpenGSAN  integração bancária por contrato explícito
          ↑ a capacidade permanece; o mecanismo não
```

| Conceito GSAN | Semântica | Representação no GSAN | Conceito OpenGSAN | Classe | Ref. |
| ------------- | --------- | --------------------- | ----------------- | ------ | ---- |
| **Camada de fronteira externa** | Contrato, autenticação, idempotência, erro, observabilidade | 🔴 **Não existe** — sete padrões independentes | Camada única | **C4-i** | INT-01 |
| **Coleta de leitura em campo** | Receber leituras coletadas fora do sistema | Actions e arquivos | Capacidade preservada, com identidade de dispositivo | **C1** | INT-02 |
| **Execução móvel de OS** | Receber execução feita em campo | Schema `mobile` + APIs | Idem | **C1** | INT-02 |
| **Arquivo de arrecadador / banco** | Trocar arquivos de cobrança e retorno | Layouts embutidos | Contrato por parceiro | **C2** | ARR-07 |
| **Bureau de crédito** | Negativar e reabilitar | SOAP + movimentos | Contrato explícito | **C2** | COB-06 |
| **Notificação (e-mail/SMS)** | Avisar o cliente | Serviços próprios | Capacidade com contrato de canal | **C1** | INT-04 |
| **SMS ignora o tipo da mensagem** | Cada tipo deve enviar seu texto | 🔴 `getJson` ignora `tipoMensagem` — **todo SMS envia o texto de cadastro no portal** | Cada tipo envia sua mensagem | **C3** | **D-13** |
| **Integração por banco compartilhado (UPA/SAM)** | Entregar dados ao sistema parceiro | 🔴 **Escrita direta no banco do parceiro**, com falha silenciosa | Contrato; idempotência por chave de negócio; erro durável | **C3** | **D-12** |
| **Cliente de serviço externo com OAuth2** | Consumir serviço autenticado | 🟢 `GsanApi` — credenciais em banco | Idem — 🔵 **a referência de maturidade do legado** | **C1** | INT-04 |
| **Credenciais de banco** | Acesso da aplicação ao dado | 🔴 Roles com senha = login, versionadas | Credencial por ambiente, menor privilégio | **C3** | **D-16** |

🔵 **D-13 merece destaque** entre as divergências: é a única que corrige um **defeito funcional que alcança o cliente final**, não uma fraqueza de segurança. O legado está errado; isso não é regra de negócio a preservar.

---

## 16. Identidades

⚠️ **Compatibilidade conceitual de identidade. Nenhuma chave primária física é definida aqui.**

### 16.1 🔴 Identidade externa ≠ chave primária

A distinção que evita dois erros opostos:

```text
IDENTIFICADOR FUNCIONAL     o que o usuário digita, fala ao telefone, lê no boleto
                            → precisa permanecer RECONHECÍVEL
CHAVE PRIMÁRIA FÍSICA       como o sistema referencia internamente
                            → decisão de implementação, LIVRE
```

⚠️ Confundi-los leva a: (a) preservar chave técnica do legado como se fosse regra de negócio; ou (b) descartar um identificador que o usuário reconhece porque "é só uma PK".

| Identidade | Semântica | Precisa permanecer reconhecível? | Classe |
| ---------- | --------- | -------------------------------- | ------ |
| **Imóvel / matrícula** | 🔴 O número que o cliente e o atendente usam; tem DV | **Sim** — é o identificador mais visível do sistema | **C1** |
| **Cliente** | Referência da pessoa na companhia | **Sim** | **C1** |
| **Hidrômetro** | Número do equipamento físico, gravado nele | 🔴 **Sim** — existe no mundo real, fora do sistema | **C1** |
| **Documento / Conta** | 🔴 Referência estável do documento por toda a vida | **Sim** — aparece no boleto e no atendimento | **C2** |
| **Parcelamento** | Referência do acordo | **Sim** | **C1** |
| **Pagamento / recebimento** | Referência do fato financeiro | ⚠️ **Sim** — e é justamente o que o legado perde ao arquivar | **C2** |
| **RA** | 🔴 **Protocolo** informado ao cliente | **Sim** — é a promessa feita a alguém | **C1** |
| **OS** | Referência da execução | Interna, com uso operacional | **C1** |
| **Usuário** | Login | **Sim** | **C1** |
| **Funcionalidade / operação** | Unidade de concessão | 🔴 Deixa de ser **URL** e passa a identificador de domínio | **C2** |

🔵 **O padrão de identidade do GSAN é bom e se preserva**: identidade estável + versão + linhagem. 🔴 **A única anomalia é o pagamento** — e é corrigida, não reproduzida.

---

## 17. Histórico, versão, linhagem e snapshot

🔴 **Não são a mesma coisa, e chamar todos de "histórico" cria falsa compatibilidade.** Seis mecanismos distintos, cada um com regra de escrita, leitura e retenção própria — deliberadamente **não unificados**.

| Mecanismo | Pergunta que responde | Exemplo no GSAN | Classe |
| --------- | --------------------- | --------------- | ------ |
| **Série histórica** | *"O que aconteceu em cada período?"* | Consumo e leitura por referência; instalações sucessivas | **C1** |
| **Histórico de estado** | *"Por quais estados isto passou?"* | Tramitação do RA; situação especial de cobrança | **C1** |
| **Versão** | *"Como este mesmo objeto estava antes?"* | Conta corrente × conta arquivada | **C2** |
| **Linhagem** | *"De qual documento este veio?"* | `cnta_idorigem`; reparcelamento encadeado | **C1** |
| **Snapshot** | 🔴 *"Com quais dados isto foi calculado naquele momento?"* | Categorias, economias e percentuais fotografados na conta | **C1** |
| **Auditoria** | *"Quem mexeu, quando e no quê?"* | Operação efetuada + alteração por linha/coluna | **C1** |

⚠️ 🔴 **Auditoria ≠ histórico de negócio.** Um é plataforma e existe para responder a quem alterou; o outro é domínio e existe para responder o que o negócio fez. Fundi-los produz histórico que não serve para auditar **e** auditoria que não serve ao negócio.

🔵 **Por que preservar seis e não unificar em um**: cada um tem retenção diferente (um snapshot vive o quanto viver o documento; uma auditoria segue política de retenção; uma série histórica é insumo de cálculo). Uma abstração única obrigaria a pior política a valer para todos.

---

## 18. Parametrização

```text
GSAN      16 famílias de "regra como dado", tipadas, sem versionamento
              ↓
OpenGSAN  parametrizações TIPADAS e VERSIONADAS onde afetam resultado financeiro
```

| Aspecto | GSAN | OpenGSAN | Classe |
| ------- | ---- | -------- | ------ |
| **Regra vem do dado, não do código** | 🟢 16 famílias | Idem — 🔴 princípio estrutural nº 1 preservado | **C1** |
| **Parâmetro tipado** | Catálogos com colunas próprias | Idem | **C1** |
| **Versionamento do parâmetro** | ⚠️ Ausente na maioria | Onde afeta resultado financeiro | **C2** |
| **Chave-valor genérica** | Não usada | 🔴 **Antipadrão a evitar** | — |

⚠️ 🔴 **Transformar família paramétrica em `enum` converte configuração em deploy** — é a forma mais comum de destruir esta compatibilidade sem perceber. A semântica de configuração permanece; só a estrutura física é livre.

🔵 **Por que versionar é C2 e não divergência**: um parâmetro sem versão impede reproduzir um cálculo antigo com a regra da época — e a capacidade de reproduzir já é exigida pelos snapshots. Versionar **completa** um comportamento existente em vez de mudá-lo.

---

## 19. Variação por companhia

| Mecanismo no GSAN | Avaliação | OpenGSAN |
| ----------------- | --------- | -------- |
| **Parâmetro** | 🟢 Adequado | Preservado — primeiro recurso |
| **Subclasse de controlador** | ⚠️ Funciona, mas fixa a variação em código | Política / ponto de extensão |
| **Hard-code no núcleo** | 🔴 Inadequado | Eliminado |
| **Schema customizado por instalação** | 🔴 Origem do drift | Extensão declarada |
| **Integração específica** | Adequado | Adapter por contrato |

Ordem de preferência no OpenGSAN — 🔴 **fork é exceção, não estratégia**:

```text
configuração → parametrização → política → extensão → código específico
```

### 19.1 🔴 A regra de compatibilidade das customizações

```text
customização do GSAN  ≠  automaticamente conceito do OpenGSAN
```

Quando a customização representa **necessidade geral**, ela sobe de nível:

```text
programa institucional específico     →  benefício social configurável
variante de faixa por companhia       →  política tarifária como extensão
DV próprio da matrícula               →  regra de formatação configurável
campanha nomeada                      →  campanha como parametrização
contrato de energia do imóvel         →  identificador externo genérico
```

🔵 **O padrão é consistente e vale registrar como conclusão**: quase toda "customização" encontrada é **instância de algo genérico que o GSAN já tinha**. O erro do legado não foi criar a necessidade — foi **nomeá-la no núcleo**.

⚠️ Corolário para a neutralidade do projeto aberto: **nenhum nome de companhia, URL fixa ou campo institucional no núcleo** — o GSAN falha nos três.

---

## 20. Divergências deliberadas

### 20.1 Como ler

⚠️ O registro completo é [`divergencias-aprovadas.md`](divergencias-aprovadas.md) — **não duplicado aqui**. Esta seção liga **conceito afetado** a `D-xx`, para que a leitura por conceito seja possível.

| `D-xx` | Conceito afetado | GSAN | OpenGSAN | Razão |
| ------ | ---------------- | ---- | -------- | ----- |
| **D-01** | Autenticação | SHA-1 sem salt | BCrypt/Argon2 | Regra de segurança do projeto |
| **D-02** | Autenticação auxiliar | Token MD5 efêmero | Token com escopo e expiração | Idem |
| **D-03** | Entrega de relatório | Artefato por identificador, sem dono nem autenticação | Propriedade e escopo verificados | IDOR confirmado |
| **D-04** | API de OS | Endpoints sem credencial | Autenticação em todos | Escrita anônima |
| **D-05** | Integração de campo | Leitura gravada sem origem | Identidade de dispositivo obrigatória | 🔴 Alimenta cálculo financeiro |
| **D-06** | API de pagamento | Valida o próprio host, não bloqueia | Autenticação real, com recusa | Controle inoperante |
| **D-07** | Cadeia de filtros | Dois elos decorativos | Nenhum filtro decorativo | Falsa sensação de controle |
| **D-08** | Segredos | Chave de API em código | Cofre/variável de ambiente | 🔴 Chave **comprometida**, em rotação |
| **D-09** | Transporte | `http://` fixo | TLS obrigatório | Dado em claro |
| **D-10** | API de OS | Servlet com estado | Componente sem estado | Vazamento entre requisições |
| **D-11** | Integração GIS | Assinatura só do login | Assinatura com escopo e expiração | Portador estático |
| **D-12** | Integração UPA/SAM | Escrita direta no banco do parceiro; erro engolido | Contrato, idempotência, erro durável | Acoplamento e perda silenciosa |
| **D-13** | Notificação | 🔴 Todo SMS envia o texto errado | Cada tipo envia sua mensagem | **Defeito funcional que alcança o cliente** |
| **D-14** | Fronteira de módulo | Retificação escreve em `ConsumoHistorico` | Operação exposta pela Micromedição | Fronteira de agregado |
| **D-15** | Consumo de fallback | Constante 20 em código | Parâmetro configurável | Constante mágica em caminho financeiro |
| **D-16** | Credenciais de banco | Senha = login, versionada | Credencial por ambiente, menor privilégio | Acesso trivial |

### 20.2 ⚠️ D-17 — compatibilidade **pendente de decisão**

```text
COMPATIBILIDADE PENDENTE DE DECISÃO
```

| | |
| - | - |
| **Conceito** | Aplicação do escopo territorial |
| **GSAN** | 🟢 Onde a verificação não é chamada, o usuário acessa dados **fora da sua abrangência** |
| **OpenGSAN proposto** | Escopo aplicado **sistematicamente**, em toda consulta |
| **Status** | 🔴 **PROPOSTA — não aprovada.** Não tratar como comportamento oficial |
| **Por que exige aprovação** | Altera comportamento **visível**: consultas que hoje retornam dados passariam a restringi-los. É correção, mas operadores podem percebê-la como perda de acesso |

### 20.3 🔴 Candidatos a divergência — encontrados aqui, **não aprovados**

⚠️ Dois comportamentos que **talvez** devam divergir e **não estão registrados**. Marcados como candidatos, nunca como C3. Ambos são **condicionais à caracterização** — nenhum afirma que o legado está errado.

| # | Conceito | Situação | Se a caracterização confirmar… |
| - | -------- | -------- | ------------------------------ |
| **CAND-01** | **Valores denormalizados no Imóvel** (total de economias, categoria principal) | 🔵 O OpenGSAN os calcula por derivação. A validação prevista é *"total derivado = total legado, imóvel a imóvel"* | ⚠️ …que existem valores **defasados** no legado, o derivado **divergirá**. Isso precisa virar divergência **registrada e aprovada** — não pode ser aceito em silêncio nem "corrigido" sem decisão |
| **CAND-02** | **Atomicidade dentro da unidade de processamento** | 🟢 O framework garante estado **por unidade**, **não** atomicidade do trabalho dentro dela — ⚠️ **não comprovado** | ⚠️ …que efeitos parciais ocorrem no legado, garanti-los no OpenGSAN é **mudança de comportamento observável** e exige divergência registrada |

🔵 **Por que registrar candidatos importa**: sem isso, a primeira comparação que acusar diferença terá duas leituras possíveis — defeito ou melhoria — e a escolha será feita sob pressão de prazo, não por decisão.

---

## 21. Funcionalidades futuras

⚠️ **Seção curta por decisão.** As 26 capacidades do [catálogo](../modulos/funcionalidades-futuras.md) **não entram na matriz principal**, porque a pergunta aqui é de continuidade, não de evolução.

| | Continuidade do núcleo GSAN | Evolução futura do OpenGSAN |
| - | --------------------------- | --------------------------- |
| **Pergunta** | Este conceito do GSAN sobrevive? | Esta capacidade deve existir? |
| **Critério** | Semântica e resultado | Valor e dependência |
| **Onde vive** | Este documento | O catálogo |

🔴 **Uma funcionalidade futura não precisa ter equivalente no GSAN público** — e a maioria não tem. PIX, boleto registrado, analytics e GIS não são questões de compatibilidade: são decisões de produto.

⚠️ **Exceção**: onde a capacidade futura **afeta um conceito compatível**, o registro fica aqui:

| Capacidade | Conceito compatível afetado | Nota |
| ---------- | --------------------------- | ---- |
| **Benefício social tarifário** | Estrutura tarifária (**C1**) | 🔴 **Afeta o cálculo da conta** — o ponto de extensão nasce com a tarifa, não depois |
| **Canal digital** | Conta, parcelamento, RA, cliente | 🔵 **Consome**; não é dono de nenhum — §21.1 |
| **Identidade do cliente final** | Segurança (**C2**) | Tipo de ator distinto; não é RBAC |
| **Documento fiscal** | Conta emitida | 🟡 Se decorrer da conta, o evento nasce no Faturamento. ⚠️ `EXIGE APROFUNDAMENTO` |

### 21.1 Portal / canal digital — canal consumidor, não dono

🔴 **Confirmado conceitualmente**: o portal 🟢 (47 classes no legado) faz 2ª via, extrato, parcelamento, certidão e solicitação de serviço — **todas operações de domínios existentes**. Ele **não é dono** de Conta, Atendimento, Parcelamento ou Cliente.

```text
canal digital  ──consome──►  Faturamento · Cobrança · Atendimento · Cadastro
               ✗ não é dono de nenhum
```

⚠️ Depende da decisão de interface (**ADR-0007**) e da identidade externa. 🔵 O único conceito que ele **cria** é o login do cliente — e isso é identidade, não domínio comercial.

---

## 22. Relação com os dois oráculos

🔴 **A classe de compatibilidade determina o oráculo.** É a ponte para a próxima atividade.

| Classe | Oráculo | O que o teste exige | Se der diferente |
| ------ | ------- | ------------------- | ---------------- |
| **C1** | **1** | Igualdade de resultado — 🔴 **ao centavo** no financeiro | **Defeito** |
| **C2** | **1** | Igualdade de resultado, por **mapeamento semântico** — nunca comparação estrutural | **Defeito** |
| **C3** | **2** | 🔴 **Diferença exigida**, conforme o `D-xx` | ⚠️ **Igualdade é defeito** |
| **C4** | — | Nada a comparar | ⚠️ Afirmar equivalência é **erro de categoria** |
| **C5** | — | 🔴 Cenário **não especificável** ainda | — |

### 22.1 Oráculo 1 — onde a igualdade é exigida

Regras comerciais · cálculos · estados válidos · comportamento funcional preservado · resultados financeiros. Concretamente: cálculo de conta, tarifa por vigência e faixas, mínimos, esgoto, impostos, **os modos de arredondamento ponto a ponto**, baixa de pagamento, parcelamento, consumo e média.

### 22.2 Oráculo 2 — onde a diferença é exigida

Segurança corrigida (D-01…D-11, D-16) · fronteiras corrigidas (D-14) · defeito funcional corrigido (D-13) · integração corrigida (D-12) · constante mágica (D-15). ⚠️ **Sempre com a divergência referenciada** — sem referência, não é oráculo 2.

### 22.3 🔴 Três armadilhas de comparação

| Armadilha | Por quê | Como comparar |
| --------- | ------- | ------------- |
| **Comparar C2 estruturalmente** | A representação mudou **por decisão** | Por significado, via mapeamento |
| **Comparar relatório byte a byte** | PDF carrega timestamp e metadados variáveis — falharia até do legado contra si mesmo | Pelo *datasource*, ou conteúdo extraído e normalizado |
| **Comparar pagamento por identificador** | 🔴 No legado o identificador **muda ao arquivar** | Por valor, data, documento alvo e situação |

---

## 23. Pendências

⚠️ Apenas as que **afetam compatibilidade**. As demais dúvidas seguem em cada mapa funcional.

| # | Pendência | Afeta | Bloqueia |
| - | --------- | ----- | -------- |
| 1 | 🔴 **Semântica de "Fatura"** | A decisão sobre obrigação financeira comum | Formalizar o conceito (COB-02) |
| 2 | 🔴 **Existe mecanismo de negação na autorização?** | O modelo inteiro de autorização | **Dia 1** da implementação |
| 3 | **Aprovação de D-17** | Aplicação do escopo territorial | O bloco S2 |
| 4 | **Individualização de economia** | Granularidade da composição | Cadastro |
| 5 | **Variantes reais por companhia** | Desenho do ponto de extensão tarifário | Faturamento |
| 6 | **Cardinalidade física RA ↔ OS** | Modelo do Atendimento | Atendimento |
| 7 | **Fórmulas de acréscimo por impontualidade** | Parametrização da Cobrança | Cobrança |
| 8 | **Atomicidade dentro da unidade** | Garantia do processamento | Processamento · CAND-02 |
| 9 | **Retenção de artefatos de relatório** | Política de guarda | Relatórios |

🔵 **Leitura para a próxima atividade**, com a distinção que a contagem obriga a fazer:

- **Sete são conceitos `C5`** (1, 2, 3, 6, 7, 8, 9) — ⚠️ o conceito inteiro está indeciso, e **nenhum cenário seu pode ser especificado** agora.
- **Duas (4 e 5) não são `C5`**: os conceitos que elas afetam — Economia e variação por companhia — já estão **decididos como `C2`**. O que falta é **granularidade** (a economia é individualizável?) e **inventário** (quais são as variantes reais). 🔵 Seus cenários **podem** ser especificados no nível já decidido; o que não se pode é especificar o nível mais fino.

---

## 24. Evidências

⚠️ Evidência **suficiente**, não exaustiva. Nenhum módulo foi reanalisado nesta execução; nenhuma das 64 decisões foi reclassificada.

| Fonte | O que forneceu |
| ----- | -------------- |
| [`estruturas-centrais.md`](estruturas-centrais.md) | As 64 decisões (CAD-01…INT-04) — semântica, representação atual e classificação de cada estrutura |
| [`divergencias-aprovadas.md`](divergencias-aprovadas.md) | D-01…D-16 aprovadas e D-17 proposta, com motivo e status |
| [`dominio/mapa-de-dominio.md`](../dominio/mapa-de-dominio.md) | Ownership, 14 fronteiras, 7 ciclos, conceitos sobrecarregados e implícitos |
| [`dominio/visao-conceitual-opengsan.md`](../dominio/visao-conceitual-opengsan.md) | Organização alvo, 30 temas de evolução, 12 decisões pendentes |
| [`dominio/glossario.md`](../dominio/glossario.md) | 25 conceitos com definição e relações |
| [`modulos/dependencias-e-ordem-implementacao.md`](../modulos/dependencias-e-ordem-implementacao.md) | Posição de cada capacidade e delimitação dos bloqueios |
| [`modulos/funcionalidades-futuras.md`](../modulos/funcionalidades-futuras.md) | As 26 capacidades e a fronteira entre continuidade e evolução |
| [`testes/estrategia-testes.md`](../testes/estrategia-testes.md) | Os dois oráculos, camadas de teste e comparação semântica |

---

## 25. Resposta à pergunta central

> **O OpenGSAN continua sendo funcionalmente reconhecível como evolução do GSAN?**

🟢 **Sim, e com margem larga.** Dos **145 conceitos centrais classificados, 115 preservam a semântica** — 90 sem qualquer mudança. Os quatro padrões estruturais do GSAN (regra como dado · identidade + versão + linhagem · snapshot · informado × efetivo) atravessam o OpenGSAN inteiro. **Todo o cálculo financeiro é equivalência estrita.**

> **E onde escolhemos conscientemente deixar de ser iguais?**

Em **três lugares, todos registrados** — 16 divergências, nenhuma em regra de negócio:

1. 🔴 **Segurança** — **11** (D-01…D-11). O legado autentica com hash sem salt, expõe endpoints sem credencial, entrega artefato sem dono e versiona segredo em código. Igualdade aqui seria reproduzir a falha.
2. **Fronteira e mecanismo** — **4** (D-12, D-14, D-15, D-16): escrita cruzada entre módulos, escrita no banco do parceiro, constante mágica em caminho financeiro, credencial de banco trivial.
3. **Um defeito funcional** — **D-13**, o SMS que envia sempre a mensagem errada. O legado está errado; isso não é regra de negócio a preservar.

⚠️ **E em sete conceitos ainda não escolhemos**, mais duas pendências de refinamento (§23) — registrados como pendência, não disfarçados de decisão. Somam-se a eles **dois candidatos a divergência** (§20.3), que dependem da caracterização para virar decisão.

---

## 26. Próxima atividade

**Especificação dos Cenários Críticos** — transformar o inventário de ~110 cenários em casos documentados, com resultado esperado, conforme o modelo obrigatório de [`testes/estrategia-testes.md`](../testes/estrategia-testes.md).

🔵 **Este documento é o insumo direto**: cada cenário herda o **oráculo** da classe de compatibilidade do conceito que exercita (§22) — e os nove conceitos **C5** são os que ainda **não podem** ser especificados. ⚠️ **Não executada aqui.**
