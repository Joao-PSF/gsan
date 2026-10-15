# Cenários Críticos — Arrecadação

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md).
>
> 🆕 **Fase 2, lote 6 (2026-10-10)**: CEN-ARR-001 a 005 têm baseline capturada (recepção do movimento e classificação, no EAR Batch) — [relatório §25](../fase2/fase2-caracterizacao-baselines.md#25-lote-6--arrecadação-recepção-do-movimento-e-classificação-dos-pagamentos-2026-10-10). Os demais cenários continuam `⬜ A CAPTURAR NA FASE 2`.

🔵 **Leitura da área**: a separação **recepção → classificação → aplicação → conciliação** é compatibilidade obrigatória, e os cenários a respeitam: CEN-ARR-001 só registra o que chegou; os seguintes decidem o que significa.

🔴 **Princípio verificado em todos os cenários**: *nenhum pagamento é descartado* — a situação anterior é preservada, e o dinheiro fica disponível para tratamento posterior.

⚠️ **Comparação de pagamentos**: sempre por **mapeamento semântico** (valor, data, documento alvo, situação) — 🔴 **nunca por identificador**, que no legado muda ao arquivar (CEN-ARR-006).

---

## CEN-ARR-001 — Recepção do movimento do arrecadador

- **Criticidade**: P1
- **Etapa OpenGSAN**: 5 — Recebimento
- **Conceitos relacionados**: movimento do arrecadador, registro bruto preservado (C1)
- **Objetivo**: caracterizar o registro do que chegou, **antes** de qualquer classificação
- **Pré-condições**: arquivo de movimento sintético no layout do arrecadador da instância de referência, com N registros e totais de trailer coerentes; variante com total **incoerente**; variante com registro malformado
- **Entrada**: V1 — arquivo coerente; V2 — total do trailer diverge da soma; V3 — um registro malformado; V4 — mesmo arquivo reenviado (mesmo NSA)
- **Operação GSAN**: recepção e validação do movimento
- **Operação conceitual OpenGSAN**: receber movimento
- **Observações semânticas**: cabeçalho registrado (NSA, convênio, banco, versão de layout) · número de registros e valor total · **linha original preservada** por item · aceitação/rejeição **por item** · tratamento do reenvio
- **Localizadores GSAN**: `ArrecadadorMovimento` (`numeroSequencialArquivo`, `numeroVersaoLayout`, `numeroRegistrosMovimento`, `valorTotalMovimento`); `ArrecadadorMovimentoItem` (`conteudoRegistro`, `indicadorAceitacao`); `validarArquivoMovimentoArrecadador*`
- **Resultado semântico esperado**: 🟢 o GSAN **guarda o registro bruto** e aceita/rejeita **por item**; os totais do trailer servem de conferência. V2–V4: **a capturar**
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (Fase 2, lote 6, 2026-10-10) — V1, V2, V2b, V3, V4, V5 em [`golden/arrecadacao/CEN-ARR-001/`](../../../../ambiente-referencia/baselines/golden/arrecadacao/CEN-ARR-001/). 🟢 V1: retorno de 150 posições (A, G, Z) pela tela Registrar Movimento dos Arrecadadores; o processamento corre **por mensagem, numa transação**: o movimento guarda o cabeçalho (NSA 1, convênio, banco, layout 04, CODIGO DE BARRAS) e os totais do trailer **como vieram**; cada G vira item com o **registro original** (149 posições + `*` quando a linha termina em brancos), ocorrência OK e **aceitação por item**; cada pagamento nasce **sem situação**, com o valor **recebido** do registro (não o do código de barras), referência de arrecadação 06/2026 e o aviso bancário da data prevista — calculado = informado = R$ 531,09; o NSA do contrato vai a 1. 🔵 V2: com a conferência de valor desligada (padrão da base), o trailer com R$ 1,00 a mais é aceito e guardado (R$ 532,09) — o aviso fica com a soma dos registros (R$ 531,09). V2b: com ela ligada, a tela recusa ("O valor dos registros do arquivo é inválido.") e o arquivo certo passa em seguida — só a **tela** confere o valor. 🔵 V3: data inválida → item recusado e **fora** do aviso; código de barras de outra empresa → item recusado ("CÓDIGO DE BARRAS NAO PERTENCE A …"), mas o valor entra no **informado** — calculado R$ 110,40 × informado R$ 363,00. 🟢 V4: o mesmo NSA de novo → "Arquivo de Movimento está fora de sequência." (a idempotência é o NSA sequencial do contrato). 🔴 V5: trailer com a **quantidade** de registros errada — a tela responde "enviado para processamento", o processamento volta **tudo** (nada gravado, NSA não avança) e ninguém é avisado (**CAND-33**); o arquivo certo com o mesmo NSA é aceito depois. [relatório §25](../fase2/fase2-caracterizacao-baselines.md#25-lote-6--arrecadação-recepção-do-movimento-e-classificação-dos-pagamentos-2026-10-10) — F2-115 a F2-119
- **Normalizações**: identificadores técnicos do movimento
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 5 → 6
- **Evidência**: [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) §3; ARR-01, ARR-02 — cenário **derivado** (o inventário partia da classificação)

---

## CEN-ARR-002 — Classificação contra conta vigente, por valor e prazo

- **Criticidade**: P0
- **Etapa OpenGSAN**: 5 — Recebimento
- **Conceitos relacionados**: classificação, catálogo de situações do pagamento (C1)
- **Objetivo**: caracterizar a situação atribuída ao pagamento conforme o valor e a data em relação à conta
- **Pré-condições**: DOC-01 (conta vigente); movimentos recepcionados por CEN-ARR-001
- **Entrada**:

  | Var. | Pagamento |
  | ---- | --------- |
  | V1 | Valor integral, no vencimento |
  | V2 | Em atraso, com acréscimos — valor recebido **maior** que o da conta |
  | V3 | Valor **menor** que o devido |
  | V4 | Valor **maior** que o devido, no prazo |

- **Operação GSAN**: classificação do movimento
- **Operação conceitual OpenGSAN**: classificar recebimento
- **Observações semânticas**: situação atribuída · valor do pagamento · valor excedente · acréscimos reconhecidos · situação da conta depois · posição de dívida depois (CEN-COB-001)
- **Localizadores GSAN**: situações CLASSIFICADO(0), VALOR_EM_EXCESSO(3), VALOR_A_BAIXAR(4), VALOR_NAO_CONFERE(5); `valorExcedente`
- **Resultado semântico esperado**: V1 — 🟢 CLASSIFICADO(0). V4 — 🟢 VALOR_EM_EXCESSO(3) com excedente registrado. V3 — ❔ **a regra que separa VALOR_A_BAIXAR(4) de VALOR_NAO_CONFERE(5) não está comprovada**, nem se há apropriação parcial automática. V2 — ⚠️ o valor dos acréscimos depende de fórmula **não caracterizada**
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (Fase 2, lote 6, 2026-10-10) — V1, V1b, V1c, V2, V3, V4 em [`golden/arrecadacao/CEN-ARR-002/`](../../../../ambiente-referencia/baselines/golden/arrecadacao/CEN-ARR-002/), com a posição de dívida da tela Consultar Débitos. 🟢 V1: R$ 110,40 pagos para a conta de R$ 110,40 → **CLASSIFICADO**, conta vinculada, sem excedente; a conta sai da dívida. 🔵 V1b: R$ 0,03 a menos ou a mais → CLASSIFICADO, **sem registro** da diferença. 🔴 V1c: R$ 2,00 a menos (R$ 108,40) → CLASSIFICADO sem excedente — a falta some; R$ 2,00 a mais → CLASSIFICADO com excedente R$ 2,00; R$ 2,01 a menos → VALOR NÃO CONFERE: a tolerância efetiva é **R$ 2,00** (reclassificação no fim da execução; **CAND-30**). 🟢 V2: em atraso (20/06 para o vencimento de 10/06) → CLASSIFICADO pelo valor da conta; a classificação não cobra acréscimo. 🔴 V3: R$ 10,00 a menos (R$ 158,09 de R$ 168,09) → **VALOR NÃO CONFERE**, sem excedente, conta vinculada — e a conta **sai da dívida** ("conta inconforme", total R$ 0,00): a falta deixa de ser cobrada (**CAND-29**). V4: R$ 10,00 a mais → **VALOR NÃO CONFERE** com excedente R$ 10,00 — ❌ **não** VALOR EM EXCESSO, que a classificação nunca atribui (premissa corrigida); a conta sai da dívida como inconforme. ⚠️ V3 ("VALOR_A_BAIXAR × VALOR_NAO_CONFERE") respondida: VALOR A BAIXAR também nunca é atribuído; não há apropriação parcial. [relatório §25](../fase2/fase2-caracterizacao-baselines.md#25-lote-6--arrecadação-recepção-do-movimento-e-classificação-dos-pagamentos-2026-10-10) — F2-117, F2-120 a F2-123. 🆕 **Lote 7 (2026-10-13)** — V2b, V2c: 🟢 V2b: os **acréscimos do encerramento** (etapa Gerar Débito a Cobrar de Acréscimo por Impontualidade) geram, para a conta de IMV-01 paga 10 dias depois do vencimento, débitos a cobrar de **multa R$ 2,21** (2%) e **juros R$ 0,37** (0,0333% × 10 dias corridos), em conta, cobrança 06/2026, atualização zero; a conta fica marcada "multa já cobrada"; a paga em dia e a paga 2 dias úteis depois (tolerância do sistema) não geram nada. 🔴 V2c: gerar os acréscimos **de novo** cria **outro débito de juros** (a multa tem trava, os juros não) — posição de R$ 2,58 para R$ 2,95 (**CAND-40**, valor). [relatório §28](../fase2/fase2-caracterizacao-baselines.md#28-lote-7--cobrança-posição-de-dívida-e-acréscimos-por-impontualidade-2026-10-13) — F2-154, F2-155
- **Normalizações**: identificador do pagamento
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**. ⚠️ Em V2, a fórmula dos acréscimos tem **representação pendente** (parametrizar ou não), mas o **resultado** é financeiro: oráculo 1 por regra explícita do registro de divergências
- **Gate que este cenário protege**: 5 → 6 — *golden master de baixa de pagamento*
- **Evidência**: [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) §4, §5, §6 e §22 itens 1–4; §23 dúvida 2

---

## CEN-ARR-003 — Classificação em situação especial: nada é descartado

- **Criticidade**: P0
- **Etapa OpenGSAN**: 5 — Recebimento
- **Conceitos relacionados**: catálogo de situações (C1) · classificação pelo histórico (C1)
- **Objetivo**: caracterizar a classificação quando o documento **não pode** receber a baixa normal
- **Pré-condições**: DOC-04 (conta cancelada), DOC-05 (prescrita), conta incluída em parcelamento, referência contábil ainda aberta; pagamento com código de documento inexistente
- **Entrada**:

  | Var. | Pagamento contra |
  | ---- | ---------------- |
  | V1 | Documento inexistente — e depois **reclassificação** manual |
  | V2 | Conta cancelada |
  | V3 | Conta prescrita |
  | V4 | Conta incluída em parcelamento |
  | V5 | Documento de referência contábil ainda aberta |

- **Operação GSAN**: classificação; reclassificação
- **Operação conceitual OpenGSAN**: classificar recebimento
- **Observações semânticas**: situação atribuída · **situação anterior preservada** após reclassificação (V1) · valor mantido · documento alvo · efeito sobre o documento
- **Localizadores GSAN**: DOCUMENTO_INEXISTENTE(2), DOCUMENTO_A_CONTABILIZAR(10), 11 (prescrita), 12 (parcelada), 13 (cancelada)
- **Resultado semântico esperado**: 🟢 o sistema **não descarta**: registra a razão numa situação específica e preserva o dinheiro; 🟢 a reclassificação **preserva a situação anterior**
- **Baseline concreta do legado**: 🟢 **CAPTURADA EM PARTE** (Fase 2, lote 6, 2026-10-10) — V1, V2, V5 em [`golden/arrecadacao/CEN-ARR-003/`](../../../../ambiente-referencia/baselines/golden/arrecadacao/CEN-ARR-003/). 🟢 V1: código de barras de uma referência sem conta (04/2026) → item **aceito** com a ocorrência "CONTA INEXISTENTE", pagamento sem conta → **DOC INEXISTENTE** com excedente = valor (R$ 50,00); a conta de 05/2026 continua na dívida. 🟢 V2: a conta cancelada não é achada na recepção (só NORMAL/RETIFICADA/INCLUÍDA — "CONTA INEXISTENTE"), mas a classificação a acha → **INEX CONTA CANCELADA**, conta vinculada, excedente = valor — o dinheiro fica registrado. 🔴 V5: com a **referência contábil aberta** (sem o encerramento do faturamento de 05/2026), o pagamento integral termina **CLASSIFICADO com excedente = valor pago** (R$ 110,40); o a menor, NÃO CONFERE com excedente = valor; o a maior, com excedente = diferença (**CAND-32**). [relatório §25](../fase2/fase2-caracterizacao-baselines.md#25-lote-6--arrecadação-recepção-do-movimento-e-classificação-dos-pagamentos-2026-10-10) — F2-124, F2-125. 🆕 **Lote 6b (2026-10-12)** — V1b, V2b, V2c, V3, V3b: 🔴 V1b: o documento inexistente corrigido pelo operador em **Manter Pagamento** (04 → 05/2026) passa a apontar a conta, mas a classificação seguinte o deixa CLASSIFICADO com o **excedente = valor** e **sem situação anterior** (a situação anterior só é preservada quando o operador a informa; CAND-32). 🟢 V2b: a conta cancelada paga, pela **Recuperação de Crédito** ("Devolver"), vira crédito a realizar de R$ 110,40 (DEVOLUÇÃO OUTROS VALORES) e o pagamento CLASS RECUP CANCEL; a dívida fica negativa. 🔴 V2c: "Refaturar" a conta cancelada ainda não arquivada — HTTP 500, sempre (**CAND-34**). 🟢 V3: conta **prescrita** no mês corrente → INEX DEB PRESCRITO. 🔴 V3b: prescrita num mês fechado e cancelada antiga → pagamento **sem situação e sem conta** (**CAND-35**). ⬜ **a capturar** V4 (parcelada — Cobrança). [relatório §26](../fase2/fase2-caracterizacao-baselines.md#26-lote-6b--arrecadação-recuperação-de-crédito-manutenção-e-devolução-2026-10-12) — F2-130 a F2-133
- **Normalizações**: identificador do pagamento
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 5 → 6 — *nenhum pagamento descartado*
- **Evidência**: [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) §4, §7 e §22 itens 6, 9, 10 e 18; ARR-03

---

## CEN-ARR-004 — Pagamento em duplicidade e devolução

- **Criticidade**: P0
- **Etapa OpenGSAN**: 5 — Recebimento
- **Conceitos relacionados**: devolução e guia de devolução (C1)
- **Objetivo**: caracterizar o tratamento de pagamento duplicado até a devolução
- **Pré-condições**: DOC-01 já paga uma vez
- **Entrada**: V1 — segundo pagamento da mesma conta; V2 — devolução por guia de devolução; V3 — devolução convertida em **crédito a realizar**; V4 — RA que informa a duplicidade e origina a devolução
- **Operação GSAN**: classificação; efetuar devolução
- **Operação conceitual OpenGSAN**: classificar recebimento; devolver
- **Observações semânticas**: situação do segundo pagamento antes e depois da devolução · guia de devolução (valor, situação) · crédito a realizar gerado (V3) · vínculo com o RA (V4)
- **Localizadores GSAN**: PAGAMENTO_EM_DUPLICIDADE(1); DUPLICIDADE_EXCESSO_DEVOLVIDO(9); guia de devolução; `DevolucaoHistorico`
- **Resultado semântico esperado**: 🟢 duplicado → situação própria → após devolução, **DUPLICIDADE_EXCESSO_DEVOLVIDO(9)**; 🟢 a devolução frequentemente **nasce de um RA**
- **Baseline concreta do legado**: 🟢 **CAPTURADA EM PARTE** (Fase 2, lote 6, 2026-10-10) — V1, V1b, V1c em [`golden/arrecadacao/CEN-ARR-004/`](../../../../ambiente-referencia/baselines/golden/arrecadacao/CEN-ARR-004/). 🟢 V1/V1b: a mesma conta paga duas vezes — no mesmo arquivo ou noutro, depois da primeira classificação — → o pagamento **mais antigo** fica CLASSIFICADO e o outro **EM DUPLICIDADE** com excedente = valor (R$ 110,40); a reclassificação registra CLASSIFICADO como situação anterior do primeiro. 🔴 V1c: o pagamento classificado pela tolerância (R$ 168,06 de R$ 168,09), com a chegada do exato, vira **VALOR NÃO CONFERE sem conta** — perde o vínculo com o documento que pagou — e o exato fica CLASSIFICADO (**CAND-31**). [relatório §25](../fase2/fase2-caracterizacao-baselines.md#25-lote-6--arrecadação-recepção-do-movimento-e-classificação-dos-pagamentos-2026-10-10) — F2-126, F2-127. 🆕 **Lote 6b (2026-10-12)** — V2, V2b, V2c, V2d, V2e, V3, V3b: 🟢 V2: **guia de devolução** a partir do RA (CONTA 05/2026, R$ 110,40) e a **devolução** no aviso → a classificação deixa a devolução CLASSIFICADA e o pagamento **DUPLIC EXC DEVOLVIDO** (anterior EM DUPLICIDADE); o aviso fica com devolução calculada R$ 110,40 × informada 0,00; o RA continua pendente. 🔴 V2b: devolução de R$ 120,00 acima da guia, confirmada — o aviso soma **R$ 240,00** (**CAND-36**); a devolução fica VALOR NÃO CONFERE. 🟢 V2d: o **excedente** de um pagamento a maior (VALOR NÃO CONFERE, R$ 10,00) devolvido por guia e devolução de R$ 10,00 → pagamento DUPLIC EXC DEVOLVIDO — 🔴 com a situação anterior gravada EM DUPLICIDADE. 🔴 V2c/V2e: a devolução **sem guia** (GUIA NÃO INFORMADA) também leva o pagamento a DEVOLVIDO, com a situação anterior sempre EM DUPLICIDADE (**CAND-37**); sem RA pendente do imóvel, a guia é recusada. 🟢 V3: **crédito a realizar** pela Recuperação de Crédito (R$ 110,40, DEVOLUÇÃO PAGTOS DUPLICIDADE), pagamento CLASS RECUP DUPLIC, dívida −R$ 110,40. 🟢 V3b: depois do crédito, a guia da mesma conta é recusada ("já foi devolvida"). ⬜ **a capturar** V4 (o RA que informa a duplicidade — Transferir Devolução de Valores Pagos em Duplicidade). [relatório §26](../fase2/fase2-caracterizacao-baselines.md#26-lote-6b--arrecadação-recuperação-de-crédito-manutenção-e-devolução-2026-10-12) — F2-130, F2-134 a F2-137
- **Normalizações**: identificadores técnicos
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 5 → 6
- **Evidência**: [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) §9 e §22 itens 5 e 15; [`modulos/atendimento.md`](../../modulos/atendimento.md) §29 item 18

---

## CEN-ARR-005 — Pagamento de conta retificada ou arquivada

- **Criticidade**: P0
- **Etapa OpenGSAN**: 5 — Recebimento
- **Conceitos relacionados**: identidade documental (C2)
- **Objetivo**: caracterizar a baixa contra documento que mudou de versão ou foi arquivado — **o teste central da identidade documental**
- **Pré-condições**: DOC-03 (conta A retificada por B); DOC-06 (conta arquivada)
- **Entrada**: V1 — pagamento de A **antes** da retificação, depois retificação; V2 — pagamento de A **depois** da retificação; V3 — pagamento de B; V4 — pagamento da conta arquivada
- **Operação GSAN**: classificação, que busca o documento na versão corrente **e** no histórico
- **Operação conceitual OpenGSAN**: classificar recebimento contra identidade documental
- **Observações semânticas**: documento ao qual o pagamento fica vinculado · situação atribuída · situação do documento depois · posição de dívida depois
- **Localizadores GSAN**: `ContaGeral`; `ContaHistorico`
- **Resultado semântico esperado**: 🟢 **pagar conta arquivada funciona**; 🟢 retificar **não invalida** o pagamento já vinculado — ele continua apontando a conta que pagou; a retificadora é **outro documento**, e o pagamento **não migra** automaticamente para ela. V2 — situação atribuída **a capturar**
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (Fase 2, lotes 6 e 6c, 2026-10-10/13) — V1, V2, V3, V4 em [`golden/arrecadacao/CEN-ARR-005/`](../../../../ambiente-referencia/baselines/golden/arrecadacao/CEN-ARR-005/). 🔴 V1: R$ 110,40 pagos e classificados para a conta A; a retificação (1 → 2 economias, R$ 94,05), confirmando "já está paga", **move** o pagamento para B (lote 5d, CAND-19) e a classificação seguinte o compara com B → **VALOR NÃO CONFERE**, excedente R$ 16,35; a conta fica "inconforme" e fora da dívida. 🔴 V2: retificada antes, a conta é paga com o código de barras de **A** — a recepção já vincula o pagamento a **B** (identificação por imóvel + referência; ❌ "o pagamento não migra" não se sustenta) → VALOR NÃO CONFERE, excedente R$ 16,35. 🔴 V3: pago com o código de barras de B (R$ 94,05) → CLASSIFICADO em B, mas com excedente = **R$ 94,05**: a retificadora tem a referência contábil do mês da execução, "aberta" frente à de faturamento (**CAND-32**). [relatório §25](../fase2/fase2-caracterizacao-baselines.md#25-lote-6--arrecadação-recepção-do-movimento-e-classificação-dos-pagamentos-2026-10-10) — F2-120, F2-128. 🆕 **Lote 6c (2026-10-13)** — V4: a conta de 04/2026 de IMV-01, já paga e **arquivada** (pela massa: o legado não arquiva conta nesta instalação — **CAND-38**), paga de novo pelo código de barras dela: a recepção registra o item como "CONTA INEXISTENTE" (aceito, sem conta — ela procura só a conta atual); a classificação acha a conta no **histórico** e, NORMAL (já paga), deixa o pagamento **EM DUPLICIDADE**, excedente R$ 110,40, ligado à conta arquivada; a tela Consultar Pagamento mostra o pagamento arquivado e o novo sob 04/2026; a conta de 05/2026 continua na dívida (R$ 110,40). 🟢 o pagamento alcança a conta arquivada; ❌ "pagar conta arquivada funciona" só vale como vínculo — a conta arquivada já está paga. [relatório §27](../fase2/fase2-caracterizacao-baselines.md#27-lote-6c--arrecadação-encerramento-e-arquivamento-2026-10-13) — F2-146
- **Normalizações**: chaves técnicas — ⚠️ comparar pela **identidade documental**
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — por mapeamento semântico
- **Gate que este cenário protege**: 5 → 6 — *identidade estável do documento verificada entre versão corrente e histórico*
- **Evidência**: [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) §4 e §22 itens 7 e 8; FAT-02

---

## CEN-ARR-006 — Identidade do pagamento no arquivamento

- **Criticidade**: P0
- **Etapa OpenGSAN**: 5 — Recebimento
- **Conceitos relacionados**: identidade do pagamento (C2 — a única anomalia do padrão de identidade do GSAN)
- **Objetivo**: caracterizar a continuidade funcional do recebimento quando ele é arquivado
- **Pré-condições**: pagamento classificado de DOC-01; encerramento que transfere o pagamento para o histórico
- **Entrada**: consulta do pagamento antes e depois do arquivamento; consulta a partir do documento pago
- **Operação GSAN**: arquivamento do pagamento
- **Operação conceitual OpenGSAN**: consultar recebimento ao longo da vida
- **Observações semânticas**: origem (movimento/arrecadador) · documento liquidado · valor · data de pagamento · situação · histórico de situações · **alcançável a partir do documento** antes e depois
- **Localizadores GSAN**: `arrecadacao.pagamento` (`seq_pagamento`); `PagamentoHistorico` (`seq_pagamento_historico`)
- **Resultado semântico esperado**: 🟢 no GSAN o pagamento **recebe novo identificador** ao ser arquivado; a rastreabilidade depende das chaves do documento. 🔴 **O teste não compara chaves**: compara os observáveis acima, que devem permanecer **iguais** antes e depois — e iguais entre GSAN e OpenGSAN
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (Fase 2, lote 6c, 2026-10-13) — V1, V2 em [`golden/arrecadacao/CEN-ARR-006/`](../../../../ambiente-referencia/baselines/golden/arrecadacao/CEN-ARR-006/). 🟢 V1: o pagamento CLASSIFICADO de IMV-01 (R$ 110,40, 10/06/2026) vai ao histórico com **os mesmos observáveis** — valor, data, referências de pagamento e de arrecadação, situações atual e anterior, conta (05/2026, ordem 1), item do movimento de origem (NSA 1, ordem 1), aviso e forma —, com **outro identificador** (normalizado: nunca sai no resultado); a tela Consultar Pagamento continua listando-o sob o imóvel e a referência, como **arquivado** (totais atual 0 × histórico 1, R$ 110,40) — 🔴 mas **sem o valor da conta**, que a tela lê da conta arquivada e a conta não foi arquivada (**CAND-38**). 🟢 V2: o pagamento devolvido (DUPLIC EXC DEVOLVIDO, anterior EM DUPLICIDADE) e o CLASSIFICADO (anterior CLASSIFICADO) mantêm as duas situações no histórico; a devolução CLASSIFICADA também vai. Pelo esquema, o indicador de recuperação de crédito não existe no histórico (não exercitado). [relatório §27](../fase2/fase2-caracterizacao-baselines.md#27-lote-6c--arrecadação-encerramento-e-arquivamento-2026-10-13) — F2-142, F2-145
- **Normalizações**: 🔴 **identificador do pagamento** — muda no GSAN por construção
- **Divergência permitida**: nenhuma — ⚠️ a identidade estável é **representação corrigida** (C2), não comportamento divergente; nenhum `D-xx` foi criado para ela
- **Oráculo**: **1** — por mapeamento semântico
- **Gate que este cenário protege**: 5 → 6
- **Evidência**: [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) §2; ARR-04; [compatibilidade §10.1](../../compatibilidade/gsan-opengsan.md) — cenário **derivado**

---

## CEN-ARR-007 — Conciliação por aviso bancário

- **Criticidade**: P1
- **Etapa OpenGSAN**: 5 — Recebimento
- **Conceitos relacionados**: conciliação (C1)
- **Objetivo**: caracterizar a conferência entre o calculado e o informado pelo banco
- **Pré-condições**: movimento classificado; aviso bancário com valor informado **diferente** do calculado
- **Entrada**: V1 — calculado = informado; V2 — divergente, com acerto; V3 — com dedução
- **Operação GSAN**: conciliação do aviso bancário
- **Operação conceitual OpenGSAN**: conciliar
- **Observações semânticas**: valor calculado · valor informado · acertos · deduções · situação do aviso
- **Localizadores GSAN**: `AvisoBancario`; acertos e deduções
- **Resultado semântico esperado**: 🟢 o aviso guarda **calculado × informado**, com acertos e deduções
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 5 → 6 — *conciliação fecha calculado × informado*
- **Evidência**: [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) §8 e §22 item 17; ARR-05

---

## CEN-ARR-008 — Pagamento de entrada e de prestação de parcelamento

- **Criticidade**: P0
- **Etapa OpenGSAN**: 6 — Cobrança
- **Conceitos relacionados**: parcelamento (C1) · guia de pagamento (C1)
- **Objetivo**: caracterizar a baixa dos instrumentos de um parcelamento
- **Pré-condições**: DOC-10 — parcelamento com guia de entrada emitida e prestações lançadas em contas futuras
- **Entrada**: V1 — pagamento da guia de entrada; V2 — pagamento de conta que contém prestação
- **Operação GSAN**: classificação
- **Operação conceitual OpenGSAN**: classificar recebimento
- **Observações semânticas**: situação do pagamento · estado do parcelamento depois · prestações cobradas e remanescentes
- **Localizadores GSAN**: tipo de documento ENTRADA_DE_PARCELAMENTO(2); guia de pagamento
- **Resultado semântico esperado**: 🟢 a entrada é paga por **guia**; a prestação é paga **dentro da conta**. ⚠️ A entrada **não paga** leva ao desfazimento — ver CEN-COB-005
- **Baseline concreta do legado**: 🟢 **CAPTURADA EM PARTE** (Fase 2, lote 7c, 2026-10-15) — V1, V2 em [`golden/arrecadacao/CEN-ARR-008/`](../../../../ambiente-referencia/baselines/golden/arrecadacao/CEN-ARR-008/). 🟢 V1: a guia de entrada do parcelamento de CEN-COB-004 V1 (R$ 60,00) paga pelo arrecadador com o código de barras que a emissão da guia imprime (tipo 1, com o número da guia) — a recepção a aceita; a classificação deixa o pagamento **DOC A CONTABILIZAR**, com o valor inteiro como excedente (a referência contábil da guia, tirada do relógio, não é anterior à de faturamento); a guia continua NORMAL e **sai da posição**; o desfazimento automático já não a alcança (CEN-COB-005 V1b). 🟢 V2: a conta de 05/2026 com a 1ª prestação (R$ 50,00) do parcelamento de 09/2014 — R$ 160,40 — paga e **CLASSIFICADA**; a prestação é um débito cobrado da conta; restam 5 × R$ 50,00 = R$ 250,00 a cobrar; o parcelamento continua NORMAL. ⬜ fora: a classificação definitiva do pagamento da entrada e a prestação de um parcelamento feito pelo assistente cobrada na conta (as duas dependem de a referência de faturamento passar a do relógio). [relatório §30](../fase2/fase2-caracterizacao-baselines.md#30-lote-7c--cobrança-depois-do-parcelamento-2026-10-15) — F2-171, F2-172
- **Normalizações**: identificadores técnicos
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 6 → 7
- **Evidência**: [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) §13 e §22 itens 11 e 12

---

## CEN-ARR-009 — Débito automático

- **Criticidade**: P1
- **Etapa OpenGSAN**: 6 — Cobrança
- **Conceitos relacionados**: débito automático em três níveis (C1)
- **Objetivo**: caracterizar o envio e o retorno do débito automático
- **Pré-condições**: IMV-01 com autorização de débito automático ativa; conta emitida
- **Entrada**: V1 — enviado e aceito; V2 — enviado e rejeitado, com código de retorno
- **Operação GSAN**: geração do movimento de débito automático; processamento do retorno
- **Operação conceitual OpenGSAN**: cobrar por débito automático
- **Observações semânticas**: movimento gerado · situação após o retorno · código de retorno · situação da conta
- **Localizadores GSAN**: as três entidades do débito automático
- **Resultado semântico esperado**: 🟢 débito automático em **três níveis**; o retorno determina a situação — detalhe **a capturar**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores e sequenciais de arquivo
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 6 → 7
- **Evidência**: [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) §10 e §22 item 16; ARR-06

---

## CEN-ARR-010 — Encerramento mensal da arrecadação

- **Criticidade**: P0
- **Etapa OpenGSAN**: 7 — Escala
- **Conceitos relacionados**: encerramento como fechamento contábil (C1) · processamento em lote (C1)
- **Objetivo**: caracterizar os números que o fechamento da competência produz
- **Pré-condições**: competência com pagamentos em várias situações (massa dos cenários ARR-002 a ARR-008); pagamentos sujeitos a retenção tributária
- **Entrada**: execução do encerramento da competência
- **Operação GSAN**: `ENCERRAR_ARRECADACAO_MES` — unidade de processamento = **localidade**
- **Operação conceitual OpenGSAN**: encerrar competência de arrecadação
- **Observações semânticas**: totais por situação · retenções tributárias · consolidação do não classificado · pagamentos e devoluções transferidos para o histórico · competência avançada
- **Localizadores GSAN**: `anoMesReferenciaArrecadacao`; `atualizarAnoMesArrecadacao`; `PagamentoHistorico`, `DevolucaoHistorico`
- **Resultado semântico esperado**: 🟢 o encerramento é **fechamento financeiro/contábil**, não arquivamento técnico; o arquivamento é operação **associada, mas distinta**. ❔ Se pode ser refeito ou revertido: **a capturar**
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (Fase 2, lote 6c, 2026-10-13) — V1, V1b, V2, V3, V4, V5 em [`golden/arrecadacao/CEN-ARR-010/`](../../../../ambiente-referencia/baselines/golden/arrecadacao/CEN-ARR-010/). 🟢 V1: o **encerramento** grava o resumo da competência 06/2026 — 23 linhas por tipo de recebimento, tipo e item de lançamento e categoria, ao centavo: classificado R$ 110,40 (água); não classificados por situação — duplicidade R$ 110,40, documento inexistente R$ 50,00 **rateado pelas economias** de IMV-03 (33,34 residencial + 16,66 comercial), valor não confere R$ 158,09 (o valor do pagamento); total recebido R$ 428,89 (412,23 + 16,66); arrecadação líquida igual (sem devolução); os totais gravam 0,00 para as categorias sem valor —, sem mexer nos pagamentos nem na competência; o **arquivamento** leva o CLASSIFICADO ao histórico, deixa os outros três e **avança a competência** para 07/2026 (o faturamento continua em 06/2026); a dívida não muda. 🟢 V1b: a devolução classificada entra no resumo (devoluções R$ 110,40; recebido R$ 220,80; líquida R$ 110,40) e vai ao histórico com o pagamento devolvido. 🟢 V2: arquivar antes de encerrar é **recusado na inserção** do processo ("Não existem dados do resumo da arrecadação para o ano/mês de referencia", HTTP 500, exibido como chave inexistente). 🟢 V3: encerrar de novo antes do arquivamento **regrava o mesmo resumo** — o encerramento pode ser refeito. 🔴 V4: **arquivar as contas pagas falha sempre** (Gerar Histórico Conta: "Found shared references to a collection") — nenhuma conta vai ao histórico (**CAND-38**); o arquivamento dos pagamentos, noutro processo, funciona. 🔴 V5: no mês seguinte, um novo pagamento da conta já paga (o primeiro arquivado, a conta não) sai **CLASSIFICADO, sem excedente** — a duplicidade não é detectada (**CAND-39**, valor). ⬜ fora: acréscimos por impontualidade e retenções tributárias no encerramento; a recusa de encerrar o mês corrente (relógio). [relatório §27](../fase2/fase2-caracterizacao-baselines.md#27-lote-6c--arrecadação-encerramento-e-arquivamento-2026-10-13) — F2-139 a F2-144
- **Normalizações**: identificadores técnicos (inclusive dos pagamentos arquivados — ver CEN-ARR-006)
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 7 → operação — *encerramento confere com os resumos financeiros*
- **Evidência**: [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) §14 e §22 item 19; [`modulos/batch.md`](../../modulos/batch.md) §25 item 19

---

## CEN-ARR-011 — Pagamento de Fatura do cliente responsável

- **Criticidade**: P1
- **Etapa OpenGSAN**: 5 — Recebimento
- **Conceitos relacionados**: Fatura do cliente responsável — documento agregador (C1, resolvido na auditoria final) · identidade documental (C2)
- **Objetivo**: caracterizar o recebimento de um documento **agregador**: o pagamento da Fatura se desdobra em pagamentos **por conta** — antigo BLQ-04, desbloqueado quando a semântica de "Fatura" foi esclarecida
- **Pré-condições**: DOC-12 — Fatura de um cliente responsável agregando contas de pelo menos dois imóveis, numa referência
- **Entrada**: V1 — pagamento pelo código de barras da Fatura com valor **igual** ao débito dela; V2 — valor **diferente** do débito da Fatura; V3 — cliente responsável inexistente no código de barras
- **Operação GSAN**: processamento de pagamento por código de barras do cliente responsável (UC0259)
- **Operação conceitual OpenGSAN**: classificar recebimento de documento agregador
- **Observações semânticas**: aceitação ou recusa do registro · motivo da recusa · quantidade de pagamentos gerados · para cada pagamento: conta alvo, valor, tipo do documento e documento agregador · situação de cada conta depois · posição de dívida de cada imóvel depois
- **Localizadores GSAN**: `ControladorArrecadacao.processarPagamentosCodigoBarrasClienteResponsavel` (`:7217`); `Fatura`/`FaturaItem` (`faturamento.fatura`); tipo de documento CONTA com agregador `FATURA_CLIENTE(5)` (`:7400`, `:7430`)
- **Resultado semântico esperado**: V1 — 🟢 **um pagamento por conta** da Fatura, cada um com o valor da conta, tipo CONTA e a Fatura como **agregador**; a obrigação é quitada **em cada conta**. V2 — 🟢 recusa com o motivo *valor da fatura diferente do valor do pagamento* (`:7289`) — ⚠️ se o dinheiro recusado é preservado para tratamento posterior, como exige o princípio da área: **a capturar**. V3 — 🟢 recusa com motivo *cliente responsável não cadastrado*
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos dos pagamentos
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — por mapeamento semântico
- **Gate que este cenário protege**: 5 → 6
- **Evidência**: [`dominio/glossario.md`](../../dominio/glossario.md) — pontos de aprofundamento, item 5; [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) — adendo da auditoria final; cenário **derivado** do antigo BLQ-04

---

## CEN-ARR-012 — Cobrança Pix vinculada ao documento: confirmação idempotente e conciliação

- **Criticidade**: P1
- **Etapa OpenGSAN**: 5 — Recebimento
- **Conceitos relacionados**: meio de pagamento (requisito nativo) · recebimento em quatro momentos (C1)
- **Objetivo**: verificar que o Pix entra como **mais um meio** do ciclo de recebimento — cobrança vinculada ao documento, confirmação idempotente, conciliação — sem criar uma arrecadação paralela
- **Pré-condições**: DOC-01; contrato com PSP de **teste**; chave Pix configurada por ambiente (nunca constante — achado 10a)
- **Entrada**: V1 — cobrança criada para a conta e paga; V2 — a **mesma** confirmação do PSP recebida duas vezes; V3 — **dois pagamentos distintos** para a mesma conta; V4 — pagamento de cobrança **expirada** ou cancelada; V5 — conciliação do dia contra o extrato do PSP
- **Operação GSAN**: não aplicável — o GSAN público só monta QR estático, sem integração (catálogo §5)
- **Operação conceitual OpenGSAN**: criar cobrança Pix para documento; receber confirmação; classificar; conciliar
- **Observações semânticas**: cobrança (identificador `txid`, valor, vencimento ou expiração, documento alvo) · recebimentos criados · situação atribuída na classificação · recebimento conciliado × extrato · nada descartado
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — **um** recebimento, aplicado ao documento, pelo mesmo ciclo dos demais meios. V2 — 🔴 **idempotência**: a segunda confirmação **não** cria recebimento. V3 — segundo pagamento segue o tratamento de **duplicidade** (mesma regra de CEN-ARR-004, sem regra própria do Pix). V4 — o dinheiro **não é descartado**: fica em situação tratável, como qualquer pagamento sem documento apropriável (CEN-ARR-003). V5 — conciliação fecha recebido × informado pelo PSP
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: identificadores do PSP e horários
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; ⚠️ a classificação posterior **reutiliza** as regras de CEN-ARR-002/003/004 (oráculo 1), que não são duplicadas aqui
- **Gate que este cenário protege**: 5 → 6 — *confirmação idempotente: o mesmo aviso duas vezes gera um recebimento*
- **Evidência**: [`modulos/funcionalidades-futuras.md`](../../modulos/funcionalidades-futuras.md) §5; Banco Central — Manual de Padrões para Iniciação do Pix e API Pix (cobrança imediata e com vencimento)

---

## CEN-ARR-013 — Pix Automático: autorização, cobrança recorrente, retentativa e cancelamento

- **Criticidade**: P1
- **Etapa OpenGSAN**: 6 — Cobrança
- **Conceitos relacionados**: autorização de pagamento recorrente (requisito nativo) · débito automático (C1)
- **Objetivo**: verificar que o Pix Automático é representado como **autorização de pagamento recorrente**, distinta do débito automático, e que falha, retentativa e cancelamento não produzem recebimento duplicado nem perdido
- **Pré-condições**: IMV-01 com autorização de Pix Automático **aprovada** pelo pagador; contas mensais emitidas; PSP de **teste**
- **Entrada**: V1 — cobrança da conta do mês agendada e liquidada; V2 — liquidação falha na primeira tentativa e ocorre na **retentativa**; V3 — pagador **cancela a autorização** depois de uma cobrança já agendada; V4 — conta **retificada** depois do agendamento
- **Operação GSAN**: não aplicável — o GSAN tem débito automático (CEN-ARR-009), não Pix Automático
- **Operação conceitual OpenGSAN**: gerir autorização de pagamento recorrente; agendar cobrança; receber liquidação
- **Observações semânticas**: autorização (unidade/conta, vigência, limite, estado) · recorrência · cobrança agendada por conta · tentativas · liquidação · recebimento gerado · estado da autorização depois do cancelamento
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — **um** recebimento pela conta. V2 — **um** recebimento, no momento da liquidação efetiva; tentativas sem efeito financeiro. V3 — o estado da autorização muda; o efeito sobre a cobrança **já agendada** segue a regra do arranjo vigente, **lida na fonte** e nunca codificada no domínio. V4 — o valor cobrado segue a regra de janela do arranjo; ⚠️ o tratamento de conta alterada depois do agendamento é **decisão de produto a registrar** antes da implementação — não inventado aqui
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: identificadores do PSP e horários
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo
- **Gate que este cenário protege**: 6 → 7
- **Evidência**: [`modulos/funcionalidades-futuras.md`](../../modulos/funcionalidades-futuras.md) §5.5; Banco Central — Guia de implementação e FAQ do Pix Automático; Res. BCB 402/2024, 403/2024 e 506/2025
