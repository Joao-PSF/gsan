# Cenários Críticos — Micromedição

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md).
>
> ⚠️ **Nenhum valor desta página foi capturado.** Baseline: `⬜ A CAPTURAR NA FASE 2` em todos os cenários.

🔵 **Leitura da área**: a Micromedição produz a **quantidade** que o Faturamento transforma em dinheiro. Todo cenário aqui é insumo de um cenário financeiro — por isso a maioria é P0, mesmo sem valor monetário próprio.

⚠️ **O consumo é observado com sua origem.** Comparar só o número (m³) esconderia a diferença entre um consumo **real** e um consumo **por média** de mesmo valor — e o Faturamento os trata diferente.

---

## CEN-MIC-001 — Consumo da referência por situação de leitura

- **Criticidade**: P0
- **Etapa OpenGSAN**: 3 — Medição
- **Conceitos relacionados**: Leitura, Consumo, origem do consumo, Média (C1)
- **Objetivo**: caracterizar como o consumo faturável de uma referência é determinado conforme a situação da leitura
- **Pré-condições**: grupo de faturamento com cronograma aberto na referência R; imóveis:

  | Perfil | Situação |
  | ------ | -------- |
  | IMV-01 | Leitura anterior e atual realizadas; histórico ≥ 6 referências |
  | IMV-05 | Hidrômetro instalado na referência anterior — **primeira leitura** |
  | IMV-06 | Leitura **não realizada** em R, e também em R-1 e R-2 (reincidência) |
  | IMV-07 | Leitura não realizada com **histórico insuficiente** para média |
  | IMV-12a | Situação especial PARALISAR_LEITURA_FATURAR_MEDIA |

- **Entrada**: V1 IMV-01 · V2 IMV-05 · V3 IMV-06 em R (1º mês), R+1 (2º), R+2 (3º) · V4 IMV-07 · V5 IMV-12a
- **Operação GSAN**: consistência de leituras e cálculo de consumos da rota na referência
- **Operação conceitual OpenGSAN**: determinar o consumo da referência
- **Observações semânticas**: leitura anterior e atual **de faturamento** · consumo faturado · consumo para cálculo de média · consumo médio · **tipo (origem) do consumo** · anormalidade de leitura e de consumo atribuídas · valor de consumo por arredondamento a m³ inteiro
- **Localizadores GSAN**: `micromedicao.consumo_historico` — `cshi_nnconsumofaturadomes`, `cshi_nnconsumocalculomedia`, `consumoMedio`, `ConsumoTipo`, `cshi_amfaturamento`; `mdhi_nnconsumomedidomes`; `leitura_anormalidade` (`lacs_idconsacobrarsemleit`, `lalt_idleitafaturarsemleit`); `Util.arredondar` (`setScale(0, HALF_UP)`, `Util.java:653–654`)
- **Resultado semântico esperado**:
  - V1 — 🟢 consumo **REAL** = leitura atual − leitura anterior de faturamento
  - V2 — 🟢 a base é a **leitura de instalação**
  - V3 — 🟢 consumo e leitura a faturar vêm das **ações paramétricas da anormalidade** "sem leitura"; o efeito da reincidência (1º, 2º, 3º mês) **a capturar**
  - V4 — ❔ comportamento com histórico insuficiente **a capturar**
  - V5 — 🟢 consumo por **média**, com tipo correspondente
  - Em todas: 🟢 **faturado, para média e medido podem diferir** — os três são observados
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos; ⚠️ **nunca** o consumo, o tipo ou a referência
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 3 → 4 — *consumo com origem declarada; golden master de consumo/média*
- **Evidência**: [`modulos/micromedicao.md`](../../modulos/micromedicao.md) §3.4–3.6 e §13 itens 1, 2, 3 e 8; cobertura **HALF_UP** (arredondamento de consumo)

---

## CEN-MIC-002 — Consumo mínimo e precedência de overrides

- **Criticidade**: P0
- **Etapa OpenGSAN**: 3 — Medição
- **Conceitos relacionados**: consumo mínimo (C1) · economias por categoria (C2)
- **Objetivo**: caracterizar o consumo mínimo e **a ordem em que os overrides prevalecem**
- **Pré-condições**: tarifa vigente com mínimo por categoria; IMV-04 (sem hidrômetro); IMV-03 (várias categorias); imóveis com override de mínimo na **ligação**, na **situação** e por **área**
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | IMV-04 sem override |
  | V2 | IMV-03 sem override |
  | V3 | Override apenas na ligação |
  | V4 | Override apenas na situação |
  | V5 | Override por área |
  | V6 | Overrides simultâneos (ligação + situação + área) |

- **Operação GSAN**: `obterConsumoMinimoLigacao`; `calcularConsumoMinimo`
- **Operação conceitual OpenGSAN**: determinar o consumo mínimo da ligação
- **Observações semânticas**: consumo mínimo resultante · fonte que prevaleceu · tipo de consumo quando o mínimo é faturado
- **Localizadores GSAN**: `obterConsumoMinimoLigacao`; `calcularConsumoMinimo` (🟢 **HALF_UP**, `ControladorFaturamentoFINAL:57367`); `ConsumoTipo` CONSUMO_MINIMO_FIXADO(7)
- **Resultado semântico esperado**: V1/V2 — 🟢 mínimo = **Σ por categoria (mínimo da tarifa vigente × economias)**, calculado pela Micromedição a serviço do Faturamento. V3–V6 — ❔ **a ordem fina entre overrides não está comprovada**: é o que este cenário descobre
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 3 → 4
- **Evidência**: [`modulos/micromedicao.md`](../../modulos/micromedicao.md) §15 dúvida 3; [`modulos/faturamento.md`](../../modulos/faturamento.md) §31 item 5 e §32 dúvida 1

---

## CEN-MIC-003 — Troca de hidrômetro na referência

- **Criticidade**: P0
- **Etapa OpenGSAN**: 3 — Medição
- **Conceitos relacionados**: equipamento ≠ instalação (C1 — compatibilidade obrigatória) · efeito da OS (C2)
- **Objetivo**: caracterizar a substituição de hidrômetro dentro da referência e seu efeito no consumo
- **Pré-condições**: IMV-08 com hidrômetro H1 instalado e histórico; H2 disponível; OS de substituição gerada
- **Entrada**: V1 — OS de substituição executada **no meio** do período de leitura; V2 — OS de instalação em ligação sem hidrômetro; V3 — OS de retirada
- **Operação GSAN**: operação "Efetuar substituição/instalação/retirada de hidrômetro"; depois, cálculo de consumo da referência
- **Operação conceitual OpenGSAN**: a OS solicita; a Micromedição aplica a troca e determina o consumo
- **Observações semânticas**:
  - a) equipamento anterior e data de retirada
  - b) **leitura de retirada**
  - c) novo equipamento e data de instalação
  - d) **leitura de instalação**
  - e) consumo da referência e seu tipo
  - f) anormalidade atribuída
  - g) continuidade do histórico: H1 mantém seu histórico; a ligação acumula as duas instalações
  - h) indicador na OS de que a atualização ocorreu
- **Localizadores GSAN**: histórico de instalação; `ConsumoAnormalidade` HIDROMETRO_SUBSTITUIDO_INFORMADO(9); `orse_iccomercialatualizado`
- **Resultado semântico esperado**: 🟢 equipamento e instalação são **separados**; a troca registra leituras de **fronteira**. 🔴 **A composição do consumo no mês da troca não está comprovada** (soma dos trechos × regra alternativa) — ⚠️ **nenhuma fórmula é presumida**: a baseline é que a define
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos das instalações
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — por mapeamento semântico nos observáveis a–d, g, h; igualdade exata, em m³, no observável e
- **Gate que este cenário protege**: 3 → 4
- **Evidência**: [`modulos/micromedicao.md`](../../modulos/micromedicao.md) §13 item 4 e §15 dúvida 1; [`modulos/atendimento.md`](../../modulos/atendimento.md) §29 item 14; MIC-01

---

## CEN-MIC-004 — Anormalidades: virada de hidrômetro e limiares de consumo

- **Criticidade**: P1
- **Etapa OpenGSAN**: 3 — Medição
- **Conceitos relacionados**: anormalidade paramétrica (C1)
- **Objetivo**: caracterizar as anormalidades detectadas pelo sistema e suas consequências
- **Pré-condições**: IMV-09 com leitura próxima do máximo de dígitos do hidrômetro; IMV-10 com média conhecida; categoria com limiares configurados (estouro, vezes a média, alto consumo, baixo consumo)
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | IMV-09 com leitura atual menor que a anterior por **virada** |
  | V2 | IMV-10 com consumo acima do limiar de **alto consumo** |
  | V3 | IMV-10 com consumo acima do limiar de **estouro** |
  | V4 | IMV-10 com consumo abaixo do limiar de **baixo consumo** |
  | V5 | Leitura atual menor que a anterior **sem** virada |

- **Operação GSAN**: crítica do consumo calculado
- **Operação conceitual OpenGSAN**: criticar o consumo
- **Observações semânticas**: anormalidade de consumo atribuída · consumo faturado · consumo para média · emissão de OS (sim/não) · carta ou aviso gerado
- **Localizadores GSAN**: `numeroDigitosLeitura`; `ConsumoAnormalidade` (VIRADA_HIDROMETRO, ALTO_CONSUMO(6), ESTOURO_CONSUMO(5), BAIXO_CONSUMO(4), LEITURA_ATUAL_MENOR_ANTERIOR(8)); parâmetros da categoria; `ltan_icemissaoordemservico`
- **Resultado semântico esperado**: V1 — 🟢 consumo corrigido pela virada, com anormalidade VIRADA. V2–V4 — 🟢 anormalidade por **limiares da categoria aplicados sobre a média**. Consequência sobre o consumo faturado e emissão de OS: **a capturar**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 3 → 4
- **Evidência**: [`modulos/micromedicao.md`](../../modulos/micromedicao.md) §3.7 e §13 itens 5 e 6

---

## CEN-MIC-005 — Leitura informada × leitura de faturamento

- **Criticidade**: P1
- **Etapa OpenGSAN**: 3 — Medição
- **Conceitos relacionados**: informado × efetivo (C1 — um dos quatro padrões estruturais do GSAN)
- **Objetivo**: caracterizar a separação entre o que o campo informou e o que o cálculo usou
- **Pré-condições**: IMV-01 com leitura informada em R
- **Entrada**: V1 — leitura **alterada** em análise; V2 — leitura **confirmada** em análise; V3 — anormalidade de faturamento diferente da informada pelo leiturista
- **Operação GSAN**: análise de leitura
- **Operação conceitual OpenGSAN**: analisar leitura
- **Observações semânticas**: leitura informada · leitura de faturamento · situação da leitura · anormalidade informada × de faturamento · usuário que analisou · consumo resultante
- **Localizadores GSAN**: `leituraAtualInformada`, `leituraAtualFaturamento`, `mdhi_nnleituracampo`; `LeituraSituacao` CONFIRMADA(3), LEITURA_ALTERADA(4); `mdhi_icanalisado`
- **Resultado semântico esperado**: 🟢 o valor informado **é preservado** mesmo quando o de faturamento muda; a situação registra a análise
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: timestamps da análise
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 3 → 4
- **Evidência**: [`modulos/micromedicao.md`](../../modulos/micromedicao.md) §3.4 e §13 item 11; MIC-03
