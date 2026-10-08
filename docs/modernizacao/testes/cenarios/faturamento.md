# Cenários Críticos — Faturamento

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md).
>
> 🆕 **Fase 2**: capturados em parte CEN-FAT-001, 002 e 003 (simulação, lotes piloto e 3) e CEN-FAT-011 V1 (faturamento em grupo, lote 5) — ver cada cenário. Os demais: `⬜ A CAPTURAR NA FASE 2`.

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
- **Baseline concreta do legado**: 🟡 **CAPTURADA EM PARTE** (Fase 2, lote piloto, 2026-09-30) — V1, V2, V3, V6 e V7 na fronteira [UC0157] Simular Cálculo da Conta, em [`golden/faturamento/CEN-FAT-001/`](../../../../ambiente-referencia/baselines/golden/faturamento/CEN-FAT-001/): observáveis b (por categoria) e d; ⬜ **a capturar** V4 e V5 (origem do consumo) e os observáveis a (por categoria), b (por faixa), c, e, f — fronteira `gerarConta`, lote do faturamento em grupo. 🔵 V2/V3 responderam a dúvida: faixas **por economia individual** ([relatório da Fase 2, F2-01](../fase2/fase2-caracterizacao-baselines.md#11-achados))
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
- **Baseline concreta do legado**: 🟡 **CAPTURADA EM PARTE** (Fase 2, lote piloto, 2026-09-30) — V1, V2 e V3 na fronteira [UC0157] Simular Cálculo da Conta, em [`golden/faturamento/CEN-FAT-002/`](../../../../ambiente-referencia/baselines/golden/faturamento/CEN-FAT-002/): total de água por categoria; ⬜ **a capturar** a parcela por vigência e faixa e o contexto congelado — fronteira `gerarConta`. 🔵 Os três totais são consistentes, ao centavo, com proporção **por dias corridos** ([F2-05](../fase2/fase2-caracterizacao-baselines.md#11-achados))
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
- **Baseline concreta do legado**: 🟡 **CAPTURADA EM PARTE** (2026-10-06) — V1 em [`golden/faturamento/CEN-FAT-003/`](../../../../ambiente-referencia/baselines/golden/faturamento/CEN-FAT-003/), pela simulação, com o percentual **da ligação** informado: IMV-01, 27 m³ — 100,00% → esgoto **110,40** (igual à água; total 220,80); 80,00% (V1b) → esgoto **88,32** (total 198,72), ao centavo. V2 (percentual alternativo acima do limite) e V3 (poço — a simulação recebe o campo e não o usa) e os percentuais **fotografados na conta** dependem de `gerarConta` — lote 5. [relatório §18](../fase2/fase2-caracterizacao-baselines.md#18-lote-3--cadastro-e-faturamento-online-2026-10-06)
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
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (Fase 2, lote 5b, 2026-10-07) — V1, V1b, V2, V2b, V3, V3b, V3c e V4 em [`golden/faturamento/CEN-FAT-004/`](../../../../ambiente-referencia/baselines/golden/faturamento/CEN-FAT-004/), pelo faturamento em grupo (IMV-01, água 110,40). **Débito**: a prestação é o valor ÷ N **truncado**, e a **última leva o resto** — R$ 100,00 em 3: 1ª **33,33** (V1), 3ª **33,34** (V1b); o débito a cobrar registra as cobradas e a referência da prestação. **Parcelamento**: 6 × 50,00 de 09/2014 → a 1ª prestação entra (V2); o mesmo de **04/2026 não entra** (V2b) — a regra [FS0005] compara a referência do parcelamento com a de faturamento do **sistema** (201410 na base), não com a do grupo. **Crédito**: R$ 30,00 → conta 80,40 (V3); R$ 150,00 > conta → realiza **110,40**, a conta fica em **0,00** e o resíduo de **39,60** é guardado (V3b); 🔴 R$ 100,00 em 3, última prestação → realiza **33,33**, não 33,34, e o crédito se encerra (3/3, sem resíduo) — **1 centavo nunca creditado** (V3c; o ajuste da última parcela do crédito só existe no pré-faturamento). V4: os três juntos → 110,40 + 83,33 − 30,00 = **163,73**. ⬜ V5 (taxa de emissão) fora desta fronteira: nasce na emissão das contas. [relatório §21](../fase2/fase2-caracterizacao-baselines.md#21-lote-5b--faturamento-na-conta-lançamentos-impostos-e-rateio-2026-10-07) — F2-69 a F2-72
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
- **Baseline concreta do legado**: 🟢/🔴 **CAPTURADA** (Fase 2, lote 5b, 2026-10-07) — V1, V2 e 🆕 V3 em [`golden/faturamento/CEN-FAT-005/`](../../../../ambiente-referencia/baselines/golden/faturamento/CEN-FAT-005/), pelo faturamento em grupo, com IMV-01, 02 e 03 tendo cliente **responsável** de esfera federal (sem ele, nenhum imposto). A base é água + esgoto + débitos − créditos; cada imposto, **menos o último**, é base × alíquota em **HALF_DOWN**; o **último** (PIS) é o total (soma das alíquotas × base, HALF_DOWN) menos os anteriores, **truncado** — ele absorve o resíduo: IMV-01 (110,40) PIS **0,73**, quando 0,65% isolado daria 0,72 (V1). V2: IR a 2,50% sobre 252,60 = 6,315 exato → **6,31** (HALF_DOWN; HALF_UP daria 6,32). 🔴 V3: com uma alíquota de IR de 01/2010 (1,50%) e a vigente de 01/2026 (1,20%), a conta de 05/2026 usa **1,50%** — `pesquisarAliquotaImposto` ordena da mais antiga para a mais nova e fica com a **primeira**: uma nova alíquota **nunca** entra em vigor enquanto existir a anterior. Truncamento da base: sem efeito nesta fronteira (valores de duas casas). [relatório §21](../fase2/fase2-caracterizacao-baselines.md#21-lote-5b--faturamento-na-conta-lançamentos-impostos-e-rateio-2026-10-07) — F2-73, F2-74; **CAND-13**
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
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (Fase 2, lote 5b, 2026-10-07) — V1 e V2 em [`golden/faturamento/CEN-FAT-006/`](../../../../ambiente-referencia/baselines/golden/faturamento/CEN-FAT-006/), pelo faturamento em grupo: principal IMV-C (residencial, 2 economias, com ligação de água; não é faturado como imóvel), micros IMV-M1 (20 m³) e IMV-M2 (25 m³), 1 economia cada. O consumo a ratear é o do principal menos o dos vinculados, valorado pela tarifa **do principal** e dividido pelas economias dos vinculados. V1: 75 − 45 = **30 m³** → 15 m³ por economia = 32,50 + 5 × 4,15 = 53,25 → cada micro recebe **53,25** (contas de 127,25 e 153,25). V2: **31 m³** → 15,5 m³ por economia valem **55,325** pela tarifa → cada micro recebe **55,33**: o meio centavo vai **para cima**. O valor a ratear não é gravado (só aparece no log); a soma do `+ new BigDecimal(0.005)` com a divisão em FLOOR na escala longa do `double` e o arredondamento do PostgreSQL ao gravar `numeric(13,2)` produzem, aqui, o mesmo que HALF_UP por economia. 🔵 O rateio de **consumo** no histórico do principal não muda: `atualizarConsumosCondominios` só **corrige** um rateio que a consistência de leituras tenha gravado. [relatório §21](../fase2/fase2-caracterizacao-baselines.md#21-lote-5b--faturamento-na-conta-lançamentos-impostos-e-rateio-2026-10-07) — F2-75, F2-76
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
- **Localizadores GSAN**: `cnta_idorigem`; `ContaGeral`; `ControladorRetificarConta:263` (`atualizarLeituraRetificarConta`) e `:267–273` (`corrigirConsumos` — **atualização em lugar** de `ConsumoHistorico`). 🆕 **Corrigido pela baseline**: a retificação **não** grava `cnta_idorigem` (o campo é da transferência de débitos, `ControladorCobranca:34815`); conta NORMAL → `retificarContasReferenciaContabilMenor` (documento novo); conta RETIFICADA/INCLUÍDA com contábil ≥ a do sistema → `retificarContasReferenciaContabilMaiorOuIgual` (**em lugar**); pagamento → `atualizarPagamentoContaRetificada`; RA → `atualizarContaCanceladaOuRetificada` e `encerrarRA`; consumo para média → `atualizarMediaConsumoHistoricoAoRetificarConta` (o caminho `:263–273` é o do motivo ALTERAÇÃO DA LEITURA FATURADA, imóvel hidrometrado — lote 5e)
- **Resultado semântico esperado**: 🟢 retificar **cria documento novo com linhagem**, não edita; 🟢 o pagamento **continua apontando a conta que efetivamente pagou**. (g): 🟢 no GSAN o consumo é **sobrescrito** — o valor anterior não é versionado; no OpenGSAN a correção passa pela operação da Micromedição, **com motivo e versão**
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (Fase 2, lote 5d, 2026-10-08) — V1, V1b, V2, V2b, V3, V4, V4b em [`golden/faturamento/CEN-FAT-007/`](../../../../ambiente-referencia/baselines/golden/faturamento/CEN-FAT-007/), sobre a conta de 05/2026 de IMV-01 gerada pelo faturamento em grupo (27 m³, R$ 110,40). 🟢 (a–d) Retificar conta NORMAL cria **documento novo**: B RETIFICADA (R$ 94,05 com 2 economias), A CANCELADA POR RETIFICAÇÃO com valores preservados e referenciável pela identidade; referência contábil das duas = **mês do relógio**. 🔵 (c) **Linhagem só implícita**: `cnta_idorigem` nulo — mesma matrícula e referência; o RA autorizador fica ligado à conta **antiga** (**CAND-21**). 🔴 V1b: a **segunda** retificação no mesmo mês altera B **em lugar** (R$ 94,05 → 97,50) — o documento anterior deixa de existir; só a auditoria guarda o valor, como texto (**CAND-17**). (e, g) V2: consumo 27 → 20 m³ (B R$ 74,00); "Sim" a substituir a média sobrescreve o consumo **para média** do histórico (27 → 20) e a média (25 → 23), sem trilha; V2b ("Não"): histórico intacto; nos dois, o consumo **faturado** do histórico continua 27 — o valor anterior **não é recuperável** (nota de evidência em D-14). 🔴 (f) V3: o pagamento **não** continua na conta que pagou — o legado o **move** para B (**CAND-19**, toca valor: oráculo 1 até decisão). V4: com RA de ALTERAÇÃO DE CONTA, retifica e **encerra o RA** sozinho (parecer gravado com bytes corrompidos do fonte — **CAND-22**); V4b: sem permissão e sem RA, recusa na exibição. [relatório §23](../fase2/fase2-caracterizacao-baselines.md#23-lote-5d--ciclo-de-vida-da-conta-retificação-cancelamento-e-prescrição-2026-10-08) — F2-88 a F2-94
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
- **Localizadores GSAN**: situação da conta. 🆕 `ControladorFaturamentoFINAL.cancelarConta` (`:8447`; ramos por situação e referência contábil); `verificarPossibilidadePrescricaoConta` (`:61105`); `RepositorioCobrancaHBM.prescreverDebitosDeImoveis` e `…ContasInlcuidas`; `TarefaBatchGerarPrescreverDebitosDeImoveis` (hoje − 10 anos)
- **Resultado semântico esperado**: 🟢 cancelamento é **estado**; o documento permanece referenciável; sai da posição de dívida
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (Fase 2, lote 5d, 2026-10-08) — V1, V1b, V1c, V2, V2b em [`golden/faturamento/CEN-FAT-008/`](../../../../ambiente-referencia/baselines/golden/faturamento/CEN-FAT-008/). 🟢 V1: cancelar a conta NORMAL é **estado** — CANCELADA, motivo, data, situação anterior NORMAL, contábil pelo relógio; o documento permanece. 🔴 V1b: cancelar a conta **retificada** no mesmo mês a **exclui fisicamente** (resta a conta geral com indicador 3) e devolve a original como CANCELADA (**CAND-18**). 🔴 V1c: sem a permissão e sem RA, a tela recusa, mas o POST de cancelamento é **aceito** — registro, não comportamento a reproduzir (achado de segurança 36; **CAND-24**, família de D-19). 🟢 V2: a prescrição em lote prescreve NORMAL/RETIFICADA (→ DÉBITO PRESCRITO) e INCLUÍDA (→ DÉBITO PRESCRITO INCLUÍDAS) vencidas há mais de 10 anos, com contábil anterior à do sistema e sem pagamento; motivo DÉBITO PRESCRITO, contábil = referência do sistema, situação anterior apagada; poupa a paga, a vencida em 2020, a cancelada e a retificada no mês. 🔴 V2b: a prescrição **manual** nunca é aceita — a consulta de elegibilidade é uma HQL quebrada; HTTP 500 com a chave de mensagem sem texto (**CAND-20**). [relatório §23](../fase2/fase2-caracterizacao-baselines.md#23-lote-5d--ciclo-de-vida-da-conta-retificação-cancelamento-e-prescrição-2026-10-08) — F2-91, F2-95 a F2-98
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
- **Localizadores GSAN**: `ControladorFaturamentoFINAL:1875/:1893` (`new ConsumoHistorico()` só quando `obterUltimoConsumoImovel` devolve nulo); `setNumeroConsumoFaturadoMes(20)` (`:1880/:1897`) — 🆕 ⚠️ **corrigido pela Fase 2**: essas linhas são de `obterValoresCreditosBolsaAgua` (crédito Bolsa Água); o faturamento do imóvel (`determinarFaturamentoImovel:1427`) usa o consumo da referência e, sem ele, fatura o mínimo
- **Resultado semântico esperado**: 🟢 no GSAN o consumo de reserva é **20, fixo em código**, usado **em memória e nunca persistido**. 🔴 Para preservar o resultado financeiro, **o valor padrão do parâmetro no OpenGSAN deve ser 20** — do contrário a divergência atingiria cálculo financeiro, o que nenhuma divergência aprovada faz
- **Baseline concreta do legado**: 🔴 **CAPTURADA — contradiz a premissa** (Fase 2, lote 5, 2026-10-07) — V1 em [`golden/faturamento/CEN-FAT-011/`](../../../../ambiente-referencia/baselines/golden/faturamento/CEN-FAT-011/), pelo faturamento em grupo (`faturarImovel`, EAR Batch): IMV-16, sem nenhum consumo registrado, recebe conta de **0 m³** pela **tarifa mínima** (residencial, 1 economia: **R$ 32,50**, sem faixa), e **nenhum** consumo é gravado. 🔴 **Não há consumo de reserva de 20 m³ no faturamento do imóvel**: as linhas citadas abaixo (`setNumeroConsumoFaturadoMes(20)`) estão em `obterValoresCreditosBolsaAgua` — o cálculo do **crédito Bolsa Água** (etapa fora de uso na massa) —, onde o 20 vale **sempre**, com ou sem consumo anterior. A leitura de D-15 abaixo ("o valor padrão deve ser 20") **não se sustenta** para o faturamento: preservar o resultado financeiro é cobrar o mínimo. [relatório §20](../fase2/fase2-caracterizacao-baselines.md#20-lote-5--faturamento-em-grupo-em-modo-batch-2026-10-07) — F2-67
- **Normalizações**: nenhuma
- **Divergência permitida**: **D-15** — apenas a **configurabilidade**
- **Oráculo**: **1** (V1 — valor com o parâmetro em 20) · **2** (V2 — o GSAN não permite alterar; o OpenGSAN deve permitir)
- **Gate que este cenário protege**: 4 → 5
- **Evidência**: [`modulos/micromedicao.md`](../../modulos/micromedicao.md) §15 dúvida 2; [D-15](../../compatibilidade/divergencias-aprovadas.md) — cenário **derivado** da divergência

⚠️ **Consequência para o registro**: esta leitura de D-15 — *divergência de configurabilidade, com o valor padrão preservado* — é a única compatível com a regra de que nenhuma divergência atinge cálculo financeiro. Deve ser confirmada na aprovação de D-15.

🆕 ⚠️ **Fase 2 (2026-10-07) — a baseline muda o problema**: no faturamento do imóvel **não existe** consumo de reserva — sem consumo, o GSAN fatura **0 m³ pela tarifa mínima** (V1). O 20 fixo é do **crédito Bolsa Água**. Preservar o resultado financeiro, portanto, **não** é "parâmetro com padrão 20" no motor de conta: é cobrar o mínimo. D-15 (aprovada) continua valendo para a constante, mas o seu **alvo** (consumo de fallback do faturamento × valor do crédito Bolsa Água) precisa de leitura do responsável — nota no [registro](../../compatibilidade/divergencias-aprovadas.md); V2 fica sem objeto até essa leitura.

---

## CEN-FAT-012 — Tarifa Social: concessão automática, desconto e perda de elegibilidade

- **Criticidade**: P0
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: benefício tarifário (requisito nativo) · estrutura tarifária versionada (C1)
- **Objetivo**: verificar que a Tarifa Social nacional é concedida **automaticamente** a partir das bases oficiais, aplicada pela **regra vigente** e retirada conforme o regulamento, com comunicação e histórico
- **Pré-condições**: IMV-19; regra da Tarifa Social parametrizada com **vigência, contexto institucional e origem normativa**; retorno de base oficial de elegibilidade simulado (CadÚnico/BPC)
- **Entrada**: V1 — unidade usuária passa a constar como elegível → faturamento da referência seguinte; V2 — consumo **abaixo** do limite de volume; V3 — consumo **acima** do limite; V4 — unidade deixa de constar como elegível; V5 — regulador local amplia o benefício (nova vigência do parâmetro)
- **Operação GSAN**: não aplicável — a tarifa social do GSAN é **extensão de companhia** (programas, campos sociais), não a regra nacional; não é oráculo
- **Operação conceitual OpenGSAN**: conceder benefício tarifário por elegibilidade oficial; aplicar no cálculo; revisar
- **Observações semânticas**: concessão sem requerimento · vigência do benefício · valor da conta com e sem benefício · parcela beneficiada × não beneficiada do consumo · origem normativa aplicada · evento de negócio de concessão e de perda · histórico · dado pessoal exposto apenas ao necessário
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — benefício concedido **sem requerimento** e aplicado a partir da vigência. V2 e V3 — desconto conforme a regra vigente (Lei 14.898/2024: redução na tarifa para a parcela de consumo até o limite de volume), **ao centavo** e com a política de arredondamento nomeada. V4 — perda conforme o regulamento; ⚠️ período de permanência ou transição e prazos de comunicação: `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` (regra do regulador). V5 — nova vigência aplicada **sem código novo**. Em todas: evento de negócio emitido; o canal de comunicação é da Notificação
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: identificadores externos da base oficial (pseudonimizados na massa)
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado da Lei 14.898/2024, da NR ANA 13/2025 e do regulamento local parametrizado
- **Gate que este cenário protege**: 4 → 5 — *Tarifa Social aplicada pela regra vigente, com origem normativa*
- **Evidência**: [`modulos/funcionalidades-futuras.md`](../../modulos/funcionalidades-futuras.md) §11.4; [`auditoria/completude-funcional-regulatoria.md`](../../auditoria/completude-funcional-regulatoria.md) §4
