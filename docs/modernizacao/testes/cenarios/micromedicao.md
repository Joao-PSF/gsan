# Cenários Críticos — Micromedição

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md).
>
> 🆕 **Fase 2**: capturados CEN-MIC-002 (exibição, lote 4), CEN-MIC-001 e CEN-MIC-003 (consistência de leituras, EAR Batch, lote 5c) — ver cada cenário. Os demais: `⬜ A CAPTURAR NA FASE 2`.

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
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (Fase 2, lote 5c, 2026-10-07) — V1, V2, V3, 🆕 V3b, 🆕 V3c e V4 em [`golden/micromedicao/CEN-MIC-001/`](../../../../ambiente-referencia/baselines/golden/micromedicao/CEN-MIC-001/), pela consistência de leituras comandada (EAR Batch), com a medição do mês já registrada pela massa. V1: 1000 → 1027 → consumo **REAL 27**; média do hidrômetro **26** — divisão **inteira** dos 6 meses REAIS (159 / 6). V2: primeira leitura de hidrômetro novo (instalação com 5, leitura 32) → **27**, mas do tipo **ESTIMADO** (a medição nasce com situação anterior "não realizada") e com anormalidade FORA DE FAIXA — sem histórico REAL, a média é o mínimo (10) (CAND-15). V3: sem leitura, anormalidade com ações paramétricas (média; anterior + média) → consumo **21** (média), tipo MÉDIA HIDRÔMETRO, leitura de faturamento 521. V3b/V3c (2º e 3º mês): **não há regra de reincidência** — os meses estimados saem da média, que vira a dos meses REAIS restantes: **20**, depois **21**. V4: sem leitura e sem anormalidade, com 1 mês de histórico → consumo **8** (média de um mês), MÉDIA HIDRÔMETRO, **sem** anormalidade de consumo (a condição que a atribuiria está invertida, F2-82). 🟢 Faturado, para média e médio são gravados separados. [relatório §22](../fase2/fase2-caracterizacao-baselines.md#22-lote-5c--micromedição-consistência-de-leituras-e-cálculo-de-consumos-2026-10-07) — F2-77 a F2-82 🆕 **V5 CAPTURADA** (lote 5e, 2026-10-08): situação especial PARALISAR LEITURA / FATURAR MÉDIA, sem leitura → consumo **26** (média), tipo MÉDIA HIDRÔMETRO, leitura de faturamento 1026 (anterior + média); o consumo registra a situação especial (a conta do mesmo imóvel é FAT-001 V4). [relatório §24](../fase2/fase2-caracterizacao-baselines.md#24-lote-5e--consumo-pela-origem-na-conta-consistir-e-faturar-em-sequência-2026-10-08) — F2-103
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
- **Baseline concreta do legado**: 🟢 **CAPTURADA** nesta superfície (2026-10-06) — V1–V7 em [`golden/micromedicao/CEN-MIC-002/`](../../../../ambiente-referencia/baselines/golden/micromedicao/CEN-MIC-002/), pelo "Valor Obtido" da tela Atualizar Consumo Mínimo da Ligação de Água (`obterConsumoMinimoLigacao`). V1 **10** (residencial 10 × 1); V2 **40** (residencial 10 × 2 + comercial 20 × 1) — 🟢 Σ por categoria do mínimo da tarifa vigente × economias. V3–V6: overrides na ligação (30), na situação (15), por área (25) e os três juntos → **10** em todos — 🔵 **nenhum override entra neste cálculo**; o fixado na ligação aparece em campo separado. V7: fator de economias 3 na categoria → **50** — o fator **substitui** as economias (F2-55). A precedência entre as fontes **ao faturar** (e o tipo de consumo CONSUMO_MINIMO_FIXADO) é do faturamento em grupo — lote 5. [relatório §19](../fase2/fase2-caracterizacao-baselines.md#19-lote-4--atendimento-efeitos-da-os-e-consumo-mínimo-2026-10-06) 🆕 **Ao faturar** (lote 5e, 2026-10-08) — V3c, V4c, V4d, V5c, V6c e V8 em [`golden/micromedicao/CEN-MIC-002/`](../../../../ambiente-referencia/baselines/golden/micromedicao/CEN-MIC-002/), consistindo e faturando em sequência: no **não medido**, a regra da instalação é a **área** (V5c: 25) e o mínimo **fixado na ligação** prevalece (V3c: 30, CONSUMO MÍNIMO FIXADO); no **medido**, o fixado vale quando o consumo é menor (V8: 27 → 30). O mínimo na **situação** é um **limiar**, não um piso: a ligação só fatura com consumo ≥ ao mínimo e o tipo de consumo associado à situação — sem a associação (dado de instalação, vazio na base), o consumo é gravado como 0 e não há conta (V4c; V6c, mesmo com o fixado 30); com o tipo NÃO MEDIDO associado à situação (V4d), 25 ≥ 15 fatura os 25 — o mínimo da situação libera, não eleva. [relatório §24](../fase2/fase2-caracterizacao-baselines.md#24-lote-5e--consumo-pela-origem-na-conta-consistir-e-faturar-em-sequência-2026-10-08) — F2-104, F2-105
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
- **Baseline concreta do legado**: 🟡 **CAPTURADA EM PARTE** (Fase 2, lote 5c, 2026-10-07) — V1, V2 e V3 em [`golden/micromedicao/CEN-MIC-003/`](../../../../ambiente-referencia/baselines/golden/micromedicao/CEN-MIC-003/), pela consistência de leituras; a troca, a instalação e a retirada chegam pela **massa**, no estado em que a operação da OS as deixaria (observáveis a–d e g como contexto; h — o indicador na OS — não exercido). 🔴 **e) consumo do mês da troca — a pergunta em aberto**: a consistência fatura **só o trecho do hidrômetro atual** — V1: H5 com 800 em 30/04 e retirada com 812; H6 instalado com 3 e lido com 15 → consumo **12 = 15 − 3**, REAL, anormalidade **HIDRÔMETRO SUBSTITUÍDO INFORMADO** (f); os 12 m³ do H5 até a retirada **não entram** — nem soma dos trechos, nem regra alternativa (CAND-14). V2: instalação numa ligação sem hidrômetro (0 → 9) → **9**, tipo **ESTIMADO** (CAND-15). V3: retirada sem reposição (400 → retirada com 410) → o mês vira **NÃO MEDIDO 12** (mínimo por área), e os 10 m³ até a retirada também não entram. [relatório §22](../fase2/fase2-caracterizacao-baselines.md#22-lote-5c--micromedição-consistência-de-leituras-e-cálculo-de-consumos-2026-10-07) — F2-83, F2-84
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
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (Fase 2, lote 5e, 2026-10-08) — V1–V5 em [`golden/micromedicao/CEN-MIC-004/`](../../../../ambiente-referencia/baselines/golden/micromedicao/CEN-MIC-004/), pela consistência de leituras. 🔴 V1: a **virada** (9990 → 0015, 4 dígitos) **não é reconhecida** — consumo pela **média** (26), anormalidade LEITURA ATUAL MENOR QUE ANTERIOR, leitura de faturamento 17 (ajuste com 9999) (CAND-25). V2: alto consumo → fatura o real (60), ALTO CONSUMO. V3: estouro → fatura a **média** (26), ESTOURO COBRANÇA MÉDIA; o medido (110) fica na medição. V4: baixo consumo → fatura o real (5), BAIXO CONSUMO. V5: leitura menor sem virada → média. Nenhuma OS gerada. [relatório §24](../fase2/fase2-caracterizacao-baselines.md#24-lote-5e--consumo-pela-origem-na-conta-consistir-e-faturar-em-sequência-2026-10-08) — F2-110, F2-111
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
