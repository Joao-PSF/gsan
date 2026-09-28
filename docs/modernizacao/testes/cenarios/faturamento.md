# Cenários Críticos — Faturamento

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md).
>
> ⚠️ **Nenhum valor desta página foi capturado.** Baseline: `⬜ A CAPTURAR NA FASE 2` em todos os cenários.

🔴 **Leitura da área**: todo valor monetário aqui é **oráculo 1, igualdade ao centavo**. Nenhum cenário admite "diferença de arredondamento": as cinco políticas do legado são **comportamento**, não dívida técnica. A cobertura das cinco está consolidada no índice (§7).

⚠️ **Normalização proibida em toda a área**: dinheiro, referência, situação, identidade documental, política de arredondamento e ordem com semântica (faixas, prestações).

⚠️ **Escopo da localização das políticas**: os localizadores de arredondamento abaixo vêm de `ControladorFaturamentoFINAL.java` — **uma classe**. Outros controladores não foram varridos; ver pendências no índice.

---

## CEN-FAT-001 — Valor de água por economias, categorias e origem do consumo

- **Criticidade**: P0
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: tarifa, vigência, faixa, consumo mínimo, cálculo de água (C1) · Conta (C1) · snapshot (C1)
- **Objetivo**: caracterizar ao centavo o valor de água da conta individual — o **caso base** do motor de faturamento
- **Pré-condições**: tarifa TAR-01 com **uma** vigência cobrindo todo o período de leitura; consumos determinados por CEN-MIC-001/002
- **Entrada**:

  | Var. | Perfil | Consumo |
  | ---- | ------ | ------- |
  | V1 | IMV-01 — residencial, 1 economia | Real, acima do mínimo, atravessando duas faixas |
  | V2 | IMV-02 — N economias, mesma categoria | Real |
  | V3 | IMV-03 — várias categorias | Real |
  | V4 | IMV-12a | Por média |
  | V5 | IMV-12b — PARALISAR_LEITURA_FATURAR_TAXA_MINIMA | Taxa mínima |
  | V6 | IMV-01 | Real, **abaixo** do mínimo |
  | V7 | IMV-01 com tarifa de tipo de cálculo 4 | ⚠️ Só se o tipo existir na instância de referência |

- **Operação GSAN**: faturamento individual — `gerarConta`, que o lote reutiliza imóvel a imóvel
- **Operação conceitual OpenGSAN**: motor de conta individual
- **Observações semânticas**:
  - a) consumo usado por categoria e sua origem
  - b) valor de água **por categoria** e **por faixa**
  - c) mínimo aplicado por categoria
  - d) valor total de água
  - e) contexto congelado na conta: categorias, subcategorias, economias
  - f) situação e referência da conta
- **Localizadores GSAN**: `gerarConta` (`ControladorFaturamentoFINAL:53545`); `gerarContaCategoria*` (`:53835–54175`); despacho uma vigência × várias (`:3895–3925`); `calculoSimplesUmaTarifa` (🟢 HALF_UP `:4620`); `getCalcularValoresAguaEsgotoHelper` (HALF_UP `:5246/:5250/:5255`); `getCalcularValoresAguaEsgotoBigDecimalHelper` (🟢 **UP** `:5279`; HALF_UP `:5322/:5326/:5331`); `getCalcularValoresAguaEsgotoFaixaBigDecimalHelper` (🟢 **UP** `:5390`); `calculoConsumoDiretoNaFaixa` (tipo 4); `conta_categoria`
- **Resultado semântico esperado**: 🟢 mínimo = Σ (tarifa mínima × economias) **por categoria**; 🟢 imóvel com várias categorias é faturado **por categoria**, com consumo distribuído **proporcionalmente às economias**; 🟢 faixas progressivas aplicam-se **dentro da categoria**; 🟢 o contexto do cálculo fica **congelado na conta**. ❔ A granularidade das faixas (por economia individual × agregada por categoria) **não está comprovada** — V2/V3 a descobrem
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos da conta e dos registros de categoria
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 4 → 5 — *13 golden masters financeiros ao centavo*
- **Evidência**: [`modulos/faturamento.md`](../../modulos/faturamento.md) §6, §18, §31 itens 1–4; FAT-06; cobertura **HALF_UP** e **UP**

---

## CEN-FAT-002 — Mudança de vigência tarifária dentro do período de leitura

- **Criticidade**: P0
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: vigência (C1) — *a tarifa vale por período*
- **Objetivo**: caracterizar o cálculo quando o período entre as leituras atravessa o início de uma nova vigência
- **Pré-condições**: TAR-01 com vigências V₁ e V₂; IMV-18 cuja leitura anterior é anterior ao início de V₂ e a atual, posterior
- **Entrada**: V1 — início de V₂ no meio do período; V2 — início de V₂ no dia da leitura atual; V3 — duas mudanças de vigência dentro do período
- **Operação GSAN**: `gerarConta`, desviando para o cálculo proporcional
- **Operação conceitual OpenGSAN**: motor de conta individual com mais de uma vigência
- **Observações semânticas**: parcela do cálculo atribuída a cada vigência · valor por vigência e faixa · total de água · contexto congelado (quais vigências foram usadas)
- **Localizadores GSAN**: despacho `SF0002 — Cálculo Proporcional Para Mais de Uma Tarifa` (`:3918–3925`); `calculoProporcionalMaisDeUmaTarifa(dataLeituraAtual, dataLeituraAnterior, ...)` — 🟢 **HALF_UP em 9 pontos** (`:5540–5678`), a maior concentração da política no controlador
- **Resultado semântico esperado**: 🟢 havendo **mais de uma vigência** no período, o cálculo é **proporcional**, parametrizado pelas datas de leitura anterior e atual. ❔ **A base da proporção (dias, consumo ou outra) não está comprovada** — a baseline decide
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 4 → 5
- **Evidência**: 🟢 **código** (`ControladorFaturamentoFINAL:3895–3925`, `:5412`, `:5540–5678`), consultado nesta execução. ⚠️ **Cenário ausente de todo o inventário** — derivado da localização das políticas de arredondamento

---

## CEN-FAT-003 — Esgoto: percentual padrão, alternativo e poço

- **Criticidade**: P0
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: cálculo de esgoto (C1) · ligação de esgoto (C2) · snapshot (C1)
- **Objetivo**: caracterizar o valor de esgoto e o volume que o compõe
- **Pré-condições**: IMV-01 (esgoto com percentual padrão); IMV-11a (percentual alternativo acima do limite); IMV-11b (poço — medição tipo 2 — compondo o volume)
- **Entrada**: V1 IMV-01 · V2 IMV-11a · V3 IMV-11b
- **Operação GSAN**: `gerarConta`, ramo de esgoto
- **Operação conceitual OpenGSAN**: motor de conta individual — componente de esgoto
- **Observações semânticas**: volume de esgoto e sua composição · percentual aplicado · valor de esgoto por categoria · total de esgoto · percentuais **fotografados** na conta
- **Localizadores GSAN**: despacho com `ConstantesSistema.CALCULAR_ESGOTO` (`:3895–3925`); `percentualEsgoto`; linha de consumo de esgoto em `consumo_historico` (`LigacaoTipo` LIGACAO_ESGOTO=2)
- **Resultado semântico esperado**: 🟢 esgoto calculado a partir dos percentuais **da ligação, fotografados na conta**; 🟢 poço compõe o volume de esgoto
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 4 → 5
- **Evidência**: [`modulos/faturamento.md`](../../modulos/faturamento.md) §31 item 6; [`modulos/micromedicao.md`](../../modulos/micromedicao.md) §13 item 12

---

## CEN-FAT-004 — Débitos cobrados e créditos realizados na conta

- **Criticidade**: P0
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: débito e crédito em dois momentos (C1)
- **Objetivo**: caracterizar a incorporação de débitos a cobrar e créditos a realizar na conta
- **Pré-condições**: IMV-01 com: débito a cobrar de serviço em N parcelas; prestação de parcelamento a cobrar; crédito a realizar
- **Entrada**: V1 — faturamento com débito de serviço (parcela k de N); V2 — com prestação de parcelamento; V3 — com crédito a realizar; V4 — os três juntos; V5 — emissão com **taxa de emissão de conta**, ⚠️ somente se o parâmetro que a ativa estiver ligado na instância de referência
- **Operação GSAN**: `gerarConta` → `gerarDebitoCobrado` e realização de créditos; `gerarDebitoACobrarTaxaEmissaoConta` (V5)
- **Operação conceitual OpenGSAN**: motor de conta individual — lançamentos
- **Observações semânticas**: débitos cobrados (tipo, parcela, valor) · créditos realizados (tipo, valor) · **saldo remanescente** do débito a cobrar e do crédito a realizar · valor total da conta · débito de taxa de emissão gerado (V5)
- **Localizadores GSAN**: `gerarDebitoCobrado` (`:1490`, `:52581`, `:53101`; 🟢 **DOWN** `:53141`); `gerarDebitoACobrarTaxaEmissaoConta` (🟢 **HALF_UP** `:34800`)
- **Resultado semântico esperado**: 🟢 débito e crédito existem em **dois momentos** — a cobrar/a realizar e cobrado/realizado; a conta incorpora a parcela devida e o saldo é atualizado
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos dos lançamentos
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 4 → 5
- **Evidência**: [`modulos/faturamento.md`](../../modulos/faturamento.md) §31 item 7; FAT-09; cobertura **DOWN**

---

## CEN-FAT-005 — Impostos deduzidos

- **Criticidade**: P0
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: impostos deduzidos (C1)
- **Objetivo**: caracterizar a base, as alíquotas e os valores dos impostos deduzidos da conta
- **Pré-condições**: IMV-14 com cliente de natureza sujeita a retenção (órgão público); alíquotas vigentes
- **Entrada**: V1 — base com centavos que exercitam o **truncamento**; V2 — valores de imposto na fronteira de meio centavo
- **Operação GSAN**: `gerarImpostosDeduzidosConta`; `gerarDadosAliquotasImpostos`
- **Operação conceitual OpenGSAN**: motor de conta individual — tributos
- **Observações semânticas**: base de cálculo · alíquota por imposto · valor por imposto · total deduzido · valor líquido
- **Localizadores GSAN**: `conta_impostos_deduzidos`; `gerarImpostosDeduzidosConta` — 🟢 **DOWN** na base (`:29943`, `setScale(2, ROUND_DOWN)`) e em `:30003`, `:30021`; 🟢 **HALF_DOWN** em `:29981`, `:30000`; `gerarDadosAliquotasImpostos` — 🟢 **HALF_UP** (`:61671`, `:61672`)
- **Resultado semântico esperado**: 🟢 a base é **truncada** a duas casas; os valores de imposto usam **política diferente** da base. ⚠️ **Três políticas convivem num único cálculo** — reimplementar com uma só produz divergência de centavos
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 4 → 5
- **Evidência**: [`modulos/faturamento.md`](../../modulos/faturamento.md) §27 e §31 item 8; cobertura **DOWN**, **HALF_DOWN**, **HALF_UP**

---

## CEN-FAT-006 — Rateio de micro-condomínio

- **Criticidade**: P0
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: consumo de condomínio (C1) · rateio por economia (C1)
- **Objetivo**: caracterizar o consumo e o valor rateados às unidades de um micro-condomínio
- **Pré-condições**: condomínio principal com medição e consumo na referência; IMV-13, unidade de micro-condomínio; quantidade de economias do condomínio conhecida
- **Entrada**: V1 — valor a ratear divisível sem resto; V2 — valor a ratear com resto na divisão por economias
- **Operação GSAN**: `atualizarConsumosCondominios` (Micromedição) e rateio de valor no `gerarConta` da unidade
- **Operação conceitual OpenGSAN**: rateio de consumo (Micromedição) e de valor (Faturamento)
- **Observações semânticas**: consumo do principal · consumo rateado à unidade · valor a ratear (água e esgoto) · economias do condomínio · valor por economia · valor na conta da unidade
- **Localizadores GSAN**: `ControladorMicromedicao:39797/39837/39858`; `cshi_idconsumoimovelcondominio`; `calcularValorRateioImovel` (`:60767`, chamado em `:53607` e `:53891`); `calcularValorRateioPorEconomia` (chamado em `:54049` e `:60776`) — 🟢 **FLOOR** em `:60604` e `:60611`, precedido de acréscimo `new BigDecimal(0.005)`
- **Resultado semântico esperado**: 🟢 o valor a ratear recebe acréscimo e é **dividido pelas economias com FLOOR**. ⚠️ O acréscimo é construído a partir de **`double`** — seu valor exato não é 0,005 —, e a escala resultante depende da divisão e de arredondamento posterior não mapeado. 🔴 **O efeito sobre os centavos não é presumido**: nem "equivale a HALF_UP", nem "é truncamento". A baseline decide
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 4 → 5
- **Evidência**: 🟢 **código** consultado nesta execução; [`modulos/micromedicao.md`](../../modulos/micromedicao.md) §13 item 10 e §15 dúvida 2; cobertura **FLOOR** — ⚠️ **a única política cujo ponto de uso não aparecia em nenhum cenário do inventário**

---

## CEN-FAT-007 — Retificação de conta

- **Criticidade**: P0
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: linhagem (C1) · identidade documental (C2) · escrita de consumo pela retificação (C3)
- **Objetivo**: caracterizar a substituição de uma conta por outra da mesma referência, preservando o documento anterior e a cadeia
- **Pré-condições**: DOC-01 (conta A, emitida, não paga); DOC-01P (conta emitida **e paga**); IMV-01 com consumo da referência conhecido
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Retificar A alterando valor, sem alterar consumo |
  | V2 | Retificar A **alterando o consumo** |
  | V3 | Retificar a conta já paga |
  | V4 | Retificação originada por RA |

- **Operação GSAN**: retificar conta
- **Operação conceitual OpenGSAN**: retificar documento — com a correção de consumo **solicitada à Micromedição**
- **Observações semânticas**:
  - a) conta A: situação depois (retificada), valores **preservados**
  - b) conta B: valores, situação, referência
  - c) linhagem B → A
  - d) A continua **referenciável** pela sua identidade
  - e) consumo da referência depois da retificação (V2)
  - f) pagamento vinculado continua apontando para A (V3)
  - g) forma da alteração de consumo (V2): o valor anterior é recuperável?
- **Localizadores GSAN**: `cnta_idorigem`; `ContaGeral`; `ControladorRetificarConta:263` (`atualizarLeituraRetificarConta`) e `:267–273` (`corrigirConsumos` — **atualização em lugar** de `ConsumoHistorico`)
- **Resultado semântico esperado**: 🟢 retificar **cria documento novo com linhagem**, não edita; 🟢 o pagamento **continua apontando a conta que efetivamente pagou**. (g): 🟢 no GSAN o consumo é **sobrescrito** — o valor anterior não é versionado; no OpenGSAN a correção passa pela operação da Micromedição, **com motivo e versão**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos das contas — ⚠️ comparar pela **identidade documental** e pela **linhagem**, nunca pela chave
- **Divergência permitida**: **D-14** (observável g)
- **Oráculo**: **1** (a–f) — por mapeamento semântico · **2** (g)
- **Gate que este cenário protege**: 4 → 5 — *retificação altera consumo pela operação da Micromedição*
- **Evidência**: [`modulos/faturamento.md`](../../modulos/faturamento.md) §5 e §31 item 9; [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) §4; [`modulos/atendimento.md`](../../modulos/atendimento.md) §29 item 19; FAT-02, FAT-05; [D-14](../../compatibilidade/divergencias-aprovadas.md)

---

## CEN-FAT-008 — Cancelamento e prescrição

- **Criticidade**: P0
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: cancelamento como estado (C1) · identidade documental (C2)
- **Objetivo**: caracterizar o cancelamento e a prescrição como mudança de **estado**, não exclusão
- **Pré-condições**: DOC-02 (conta vencida); conta elegível à prescrição pela regra vigente
- **Entrada**: V1 — cancelamento com motivo; V2 — prescrição
- **Operação GSAN**: cancelar conta; prescrever
- **Operação conceitual OpenGSAN**: cancelar documento; prescrever
- **Observações semânticas**: situação antes e depois · motivo · a conta **continua existindo** · presença na posição de dívida depois (ver CEN-COB-001) · histórico
- **Localizadores GSAN**: situação da conta
- **Resultado semântico esperado**: 🟢 cancelamento é **estado**; o documento permanece referenciável; sai da posição de dívida
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: timestamps
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 4 → 5
- **Evidência**: [`modulos/faturamento.md`](../../modulos/faturamento.md) §31 item 10; FAT-01

---

## CEN-FAT-009 — Emissão: pré-faturamento, linhas tarifárias e vencimento

- **Criticidade**: P1
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: Conta (C1) · grupo e cronograma (C1)
- **Objetivo**: caracterizar o que o documento emitido contém e como o vencimento é definido
- **Pré-condições**: grupo com cronograma; IMV-01 com dia de vencimento escolhido; IMV-02 sem escolha; referência com vencimento caindo no mês seguinte
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Conta **pré-faturada** em impressão simultânea e depois **consolidada** |
  | V2 | Emissão normal — linhas tarifárias do documento |
  | V3 | 2ª via |
  | V4 | Vencimento pelo dia escolhido pelo imóvel |
  | V5 | Vencimento pelo cronograma do grupo |
  | V6 | Vencimento no mês seguinte |
  | V7 | Alteração de vencimento solicitada por RA |

- **Operação GSAN**: emitir contas; emitir 2ª via; alterar vencimento
- **Operação conceitual OpenGSAN**: emitir documento
- **Observações semânticas**: vencimento · valor pré-faturado × consolidado · **linhas tarifárias** (faixas, volumes, valores unitários, totais) — comparadas pelo *datasource* · situação
- **Localizadores GSAN**: `emitirContas` (🟢 **UP** `:23160`); `gerarLinhasTarifaAgua` (**UP** `:25361/:25412/:25431`); `emitir2ViaContas` (**UP** `:29241/:29247`); `emitirFichaCompensacao` (**UP** `:50440`); `step_icalterarvencimento`
- **Resultado semântico esperado**: 🟢 o documento emitido reproduz o cálculo; as linhas tarifárias usam **UP** — ⚠️ **afastamento do zero sempre**, não arredondamento comercial. A regra de vencimento entre escolha, cronograma e mês seguinte **a capturar**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: metadados, data de geração e paginação do documento. 🔴 **Nunca comparação byte a byte**
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — por *datasource*, ao centavo
- **Gate que este cenário protege**: 4 → 5
- **Evidência**: [`modulos/faturamento.md`](../../modulos/faturamento.md) §31 itens 11 e 12; [`modulos/atendimento.md`](../../modulos/atendimento.md) §29 item 20; cobertura **UP**

---

## CEN-FAT-010 — Referência de faturamento × referência contábil

- **Criticidade**: P1
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: referência (C1 — com a distinção preservada)
- **Objetivo**: caracterizar a conta emitida depois do encerramento da referência
- **Pré-condições**: referência R encerrada contabilmente; IMV-01 ainda por faturar em R
- **Entrada**: faturamento de IMV-01 em R após o encerramento
- **Operação GSAN**: `gerarConta` com referência já encerrada
- **Operação conceitual OpenGSAN**: motor de conta individual
- **Observações semânticas**: referência de faturamento · referência contábil · valores
- **Localizadores GSAN**: referência de faturamento e referência contábil da conta
- **Resultado semântico esperado**: 🟢 a referência contábil **pode diferir** da de faturamento
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 4 → 5
- **Evidência**: [`modulos/faturamento.md`](../../modulos/faturamento.md) §31 item 13; FAT-10

---

## CEN-FAT-011 — Imóvel sem consumo anterior: consumo de reserva

- **Criticidade**: P1
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: consumo de reserva em código (C3)
- **Objetivo**: caracterizar o faturamento de imóvel sem registro de consumo anterior
- **Pré-condições**: IMV-16, sem nenhum `ConsumoHistorico`
- **Entrada**: V1 — faturamento pelo caminho `faturarImovel`; V2 — no OpenGSAN, o mesmo com o parâmetro de reserva alterado
- **Operação GSAN**: `faturarImovel`
- **Operação conceitual OpenGSAN**: motor de conta individual com consumo de reserva **parametrizado**
- **Observações semânticas**: consumo usado · valor da conta · se algum registro de consumo é **persistido** · efeito de alterar o parâmetro (V2)
- **Localizadores GSAN**: `ControladorFaturamentoFINAL:1875/:1893` (`new ConsumoHistorico()` só quando `obterUltimoConsumoImovel` devolve nulo); `setNumeroConsumoFaturadoMes(20)` (`:1880/:1897`)
- **Resultado semântico esperado**: 🟢 no GSAN o consumo de reserva é **20, fixo em código**, usado **em memória e nunca persistido**. 🔴 Para preservar o resultado financeiro, **o valor padrão do parâmetro no OpenGSAN deve ser 20** — do contrário a divergência atingiria cálculo financeiro, o que nenhuma divergência aprovada faz
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: **D-15** — apenas a **configurabilidade**
- **Oráculo**: **1** (V1 — valor com o parâmetro em 20) · **2** (V2 — o GSAN não permite alterar; o OpenGSAN deve permitir)
- **Gate que este cenário protege**: 4 → 5
- **Evidência**: [`modulos/micromedicao.md`](../../modulos/micromedicao.md) §15 dúvida 2; [D-15](../../compatibilidade/divergencias-aprovadas.md) — cenário **derivado** da divergência

⚠️ **Consequência para o registro**: esta leitura de D-15 — *divergência de configurabilidade, com o valor padrão preservado* — é a única compatível com a regra de que nenhuma divergência atinge cálculo financeiro. Deve ser confirmada na aprovação de D-15.
