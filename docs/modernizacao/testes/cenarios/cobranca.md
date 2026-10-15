# Cenários Críticos — Cobrança

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md).
>
> ⚠️ Baseline: `⬜ A CAPTURAR NA FASE 2` em todos os cenários, **exceto** 🆕 CEN-COB-001 (Fase 2, lote 7, 2026-10-13).

🔴 **Leitura da área**: a **obrigação** nasce com o documento emitido; a Cobrança atua sobre a **posição em aberto**, que é **derivada** de documentos e recebimentos. Por isso CEN-COB-001 está na Etapa 5 — valida o conceito **antes** de o módulo existir — e todos os demais dependem dele.

⚠️ **Escopo das políticas de arredondamento**: a localização das cinco políticas foi feita no **Faturamento**. Os controladores da Cobrança **não foram varridos** — parcelamento e acréscimos exigem o mesmo levantamento antes da captura (pendência no índice).

---

## CEN-COB-001 — Posição de dívida derivada

- **Criticidade**: P0
- **Etapa OpenGSAN**: 5 — Recebimento
- **Conceitos relacionados**: posição / estoque de dívida (C2 — consulta nomeada, continua derivada)
- **Objetivo**: caracterizar o que está **em aberto** para um imóvel e para um cliente, a partir dos documentos e dos recebimentos
- **Pré-condições**: IMV-01 com: conta vencida em situação normal; conta paga; conta retificada (A→B); conta cancelada; conta prescrita; conta incluída em parcelamento com prestações lançadas; conta **em revisão**; guia não quitada; débito a cobrar pendente; crédito a realizar; situação especial de cobrança vigente
- **Entrada**: V1 — posição do imóvel; V2 — posição do cliente responsável; V3 — mesma consulta após pagamento parcial de um documento
- **Operação GSAN**: `obterDebitoImovelOuCliente`
- **Operação conceitual OpenGSAN**: consultar posição de dívida
- **Observações semânticas**: **conjunto de documentos em aberto**, por identidade · valor de cada um · acréscimos reconhecidos · total · documentos **presentes mas excluídos de ação** · efeito da situação especial de cobrança
- **Localizadores GSAN**: `obterDebitoImovelOuCliente`; identidades `ContaGeral`, `GuiaPagamentoGeral`, `DébitoACobrarGeral`
- **Resultado semântico esperado**: 🟢 a posição é **consulta, não entidade**: contas vencidas exigíveis (retificadas pela versão corrente) + guias não quitadas + débitos a cobrar pendentes (inclusive prestações) + acréscimos − pagamentos classificados − créditos aplicáveis − cancelamentos, prescrições e inclusões em parcelamento. 🟢 Conta **em revisão aparece no débito, mas fica excluída de ação**. 🟢 Situação especial de cobrança **suspende a ação, não o saldo**
- **Baseline concreta do legado**: 🟢 **CAPTURADA EM PARTE** (Fase 2, lote 7, 2026-10-13) — V1, V1b, V1c, V2, V3 em [`golden/cobranca/CEN-COB-001/`](../../../../ambiente-referencia/baselines/golden/cobranca/CEN-COB-001/). 🟢 V1: a posição de IMV-01 é a conta vencida de 05/2026 (R$ 163,73: água R$ 110,40 + débitos R$ 83,33 − crédito R$ 30,00, já na conta) com acréscimos de R$ 6,55, mais os débitos a cobrar **restantes** (serviço R$ 66,67; parcelamento R$ 250,00) — total R$ 480,40, atualizado R$ 486,95; o crédito já realizado não aparece; o acréscimo incide **só na conta**; IMV-02 e IMV-03 com acréscimos de R$ 6,72 e R$ 10,11 — **cada componente arredondado antes da soma** (multa 2%, juros 1% no teto, atualização 1%: 5,05 + 2,53 + 2,53 = 10,11, não 10,10). 🟢 V1b: a conta colocada **em revisão** (com o RA de alteração de conta) **continua na posição**, NORMAL, com os mesmos acréscimos. 🔴 V1c: sem RA, a tela recusa a revisão, mas o POST é **aceito** (**CAND-24**). 🟢 V2: pelo cliente USUÁRIO, as contas dos três imóveis com matrícula e os débitos a cobrar — total R$ 901,09, atualizado R$ 924,47, a soma das posições dos imóveis; igual por todas as relações. 🔴 V3: depois do pagamento a menor (R$ 60,40 de R$ 110,40), IMV-01 sai da posição **com os acréscimos** — posição 0,00, a conta só entre as inconformes (**CAND-29**). ⬜ fora: conta parcelada e guia não quitada na posição (🆕 vistas na posição antes e depois do parcelamento, em CEN-COB-004: a guia em aberto entra sem acréscimos; depois, a conta parcelada sai e entram os débitos do parcelamento e a guia de entrada), situação especial de cobrança, a exclusão da conta em revisão das ações (CEN-COB-002), desconto à vista. Os acréscimos da consulta são calculados com a data de HOJE: os índices da massa os tornam independentes do dia. [relatório §28](../fase2/fase2-caracterizacao-baselines.md#28-lote-7--cobrança-posição-de-dívida-e-acréscimos-por-impontualidade-2026-10-13) — F2-148 a F2-153
- **Normalizações**: ordem de listagem sem semântica; chaves técnicas
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — por mapeamento semântico, **ao centavo** nos valores
- **Gate que este cenário protege**: 5 → 6 — *posição de dívida reflete pagamentos por derivação*
- **Evidência**: [`modulos/cobranca.md`](../../modulos/cobranca.md) §20, §22 e §32 item 13; COB-01

---

## CEN-COB-002 — Ação de cobrança e pagamento antes ou depois do documento

- **Criticidade**: P0
- **Etapa OpenGSAN**: 6 — Cobrança
- **Conceitos relacionados**: elegibilidade, ação, documento de cobrança com itens (C1)
- **Objetivo**: caracterizar a geração do documento de cobrança e o efeito do pagamento em cada momento
- **Pré-condições**: ação "aviso de corte" com critérios e situações-alvo configurados; IMV-01 com duas contas vencidas elegíveis
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Ação executada sobre contas não pagas |
  | V2 | Uma das contas paga **antes** da execução da ação |
  | V3 | Documento emitido e pago **diretamente** |
  | V4 | Documento emitido e **uma das contas** paga por outro canal |

- **Operação GSAN**: executar comando da ação de cobrança; classificação dos pagamentos
- **Operação conceitual OpenGSAN**: executar ação de cobrança
- **Observações semânticas**: documento gerado (sim/não) · itens — um por dívida · valor · situação dos itens depois do pagamento · posição de dívida depois
- **Localizadores GSAN**: documento de cobrança e seus itens; `cbdo_id`; tipo de documento DOCUMENTO_COBRANCA(3)
- **Resultado semântico esperado**: V1 — 🟢 documento com **itens rastreáveis dívida a dívida**. V2 — 🟢 a conta paga **sai da posição** e a ação **não a inclui**. V3/V4 — ❔ **o rateio e a baixa dos itens quando o pagamento é associado ao documento, e o tratamento de item já pago por outro canal, não estão comprovados**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: numeração técnica do documento
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 6 → 7
- **Evidência**: [`modulos/cobranca.md`](../../modulos/cobranca.md) §5–§7 e §32 itens 1–3; [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) §12, §22 item 13 e §23 dúvida 1

---

## CEN-COB-003 — Corte e religação

- **Criticidade**: P1
- **Etapa OpenGSAN**: 6 — Cobrança
- **Conceitos relacionados**: ação com OS (C1) · efeito da OS (C2 — o Cadastro aplica)
- **Objetivo**: caracterizar a jornada aviso → corte → regularização → religação
- **Pré-condições**: sequência de ações configurada (aviso → corte) com tipo de serviço de corte; IMV-01 com débito vencido elegível
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Ação de corte gera OS; OS executada |
  | V2 | Pagamento do exigido **após o corte**; religação solicitada |
  | V3 | Religação solicitada **com débito ainda pendente** |
  | V4 | Regularização por **parcelamento** em vez de pagamento; religação solicitada |

- **Operação GSAN**: ação de corte com OS do tipo de serviço da ação; `religarImovelCortado`
- **Operação conceitual OpenGSAN**: a Cobrança solicita a execução; o Atendimento executa; o Cadastro aplica o efeito
- **Observações semânticas**: OS gerada e vínculo com o documento · 🆕 **ausência de RA** na OS gerada pela ação (ATE-02) · situação da ligação depois do corte · datas registradas na ligação · religação autorizada/negada · situação da ligação depois da religação · débito de taxa de religação
- **Localizadores GSAN**: `orse.cbdo_id`; 🆕 `orse.rgat_id` nulo — OS inserida sem RA (`ControladorCobranca:24135–24142` → `ControladorOrdemServicoSEJB:1032–1086`); `ControladorCobranca.religarImovelCortado(id, situacaoAguaLigado, dataReligacaoAgua)`; `obterDebitoImovelOuCliente`
- **Resultado semântico esperado**: 🟢 a OS da ação nasce **sem RA**, com origem no documento de cobrança — *OS sem RA* é comportamento do GSAN a preservar; 🟢 a execução da OS **atualiza a situação da ligação** (CORTADO/SUPRIMIDO); 🟢 a verificação para religar usa **a mesma posição de dívida**, e **parcelamento vigente conta como regularização**. V3 — ❔ **a capturar**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: numeração técnica da OS
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — por mapeamento semântico
- **Gate que este cenário protege**: 6 → 7
- **Evidência**: [`modulos/cobranca.md`](../../modulos/cobranca.md) §16, §17 e §32 itens 4 e 9; [`modulos/atendimento.md`](../../modulos/atendimento.md) §29 item 12; [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) §22 item 14

---

## CEN-COB-004 — Efetuar parcelamento

- **Criticidade**: P0
- **Etapa OpenGSAN**: 6 — Cobrança
- **Conceitos relacionados**: parcelamento, composição, memória financeira (C1)
- **Objetivo**: caracterizar ao centavo a negociação: o que entra, o que é descontado e o que se passa a dever
- **Pré-condições**: IMV-01 com duas contas vencidas (com acréscimos), uma guia e um débito a cobrar; perfil de parcelamento com faixas de prestação, juros, entrada mínima e descontos por faixa, antiguidade e inatividade
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Duas contas + guia, com entrada e N prestações |
  | V2 | V1 com desconto de acréscimos e desconto por antiguidade |
  | V3 | Débito a cobrar de curto e de longo prazo incluído |
  | V4 | Parcelamento à vista com desconto por inatividade |

- **Operação GSAN**: efetuar parcelamento (fluxo em etapas)
- **Operação conceitual OpenGSAN**: negociar dívida
- **Observações semânticas**:
  - a) itens incluídos — **por identidade** de cada documento original
  - b) memória financeira: valor das contas, serviços, atualização monetária, juros, multa, descontos, entrada, número e valor das prestações
  - c) situação dos documentos originais depois (contas **INCLUIDA**) — 🆕 no legado: **PARCELADA** (conta, guia e débito; lote 7b)
  - d) débitos a cobrar gerados e seus tipos
  - e) créditos de desconto gerados e seus tipos
  - f) guia de entrada
  - g) separação curto × longo prazo
- **Localizadores GSAN**: `parcelamento_item`; cabeçalho do parcelamento (`valorConta`, `valorServicosACobrar`, `valorAtualizacaoMonetaria`, `valorJurosMora`, `valorMulta`…); `ParcelamentoSituacao`; débitos PARCELAMENTO_CONTAS(40), PARCELAMENTO_GUIAS_PAGAMENTO(41), JUROS_SOBRE_PARCELAMENTO(44), PARCELAMENTO_DEBITO_A_COBRAR curto/longo (45/47); créditos de desconto (1, 2, 3); `obterValorCurtoELongoPrazo` (🟢 **DOWN**, `ControladorFaturamentoFINAL:17915`, chamado pelo passo 3 do parcelamento)
- **Resultado semântico esperado**: 🟢 cada item liga-se ao documento original **pela identidade estável ou pela versão histórica**; 🟢 o cabeçalho guarda a **memória financeira completa**; 🟢 descontos são **parametrizados e registrados**; 🟢 as contas incluídas passam a **INCLUIDA** e **saem da posição**, enquanto as prestações **entram**
- **Baseline concreta do legado**: 🟢 **CAPTURADA EM PARTE** (Fase 2, lote 7b, 2026-10-15) — V1, V1b, V1c, V1d, V2, V3, V4, V5, V6 em [`golden/cobranca/CEN-COB-004/`](../../../../ambiente-referencia/baselines/golden/cobranca/CEN-COB-004/), sobre IMV-01 com a conta de 05/2026 vencida (R$ 113,73 + acréscimos R$ 4,55), uma guia de R$ 50,00 e o débito de serviço restante (R$ 66,67) — atualizado R$ 234,95. 🟢 V1 (entrada informada de R$ 60,00, 3×): prestação R$ 58,32; a entrada abate primeiro as contas; débitos gerados por tipo — PARCELAMENTO DE CONTAS 53,73, GUIAS 50,00, ACRÉSCIMOS 4,55, DEB. A COBRAR CP 66,67 — em 3 prestações; os originais (conta, guia, débito) passam a **PARCELADA** (não INCLUIDA); itens CONTA, DÉBITO A COBRAR e GUIA; guia de entrada de R$ 60,00 com vencimento em 3 dias. 🟢 V1b (6× a 1,00%): prestação R$ 30,95, JUROS SOBRE PARCELAMENTO R$ 10,75 — os juros são compostos sobre o saldo e divididos igualmente (não Price). 🔴 V1c e V1d (a entrada que a tela propõe, R$ 46,99, mas as opções calculadas com a de R$ 23,49): sem juros, o cabeçalho guarda uma prestação (70,49) que não é a dos débitos (62,65); com juros, R$ 36,50 de juros em vez de 11,54 — R$ 24,96 a mais (**CAND-41**). 🟢 V2 (desconto de 50% nos acréscimos): R$ 2,27 concedidos como CRÉDITO A REALIZAR em 3 prestações; os acréscimos parcelados por inteiro; o percentual não fica no cabeçalho. 🟢 V3: curto prazo R$ 186,67 e longo prazo R$ 110,00, cada um no seu tipo de débito (45/47). 🟢 V4 (EP): a conta é a entrada — fica NORMAL, em revisão ENTRADA DE PARCELAMENTO, vencimento em 3 dias; sem guia. 🔴 V5 (NB): a conclusão recusa sem mensagem (**CAND-42**). 🔴 V6 (a configuração da base, com o boleto pela API do banco): "Erro de Sistema" na tela com o parcelamento gravado (**CAND-43**). 🔴 V7 (lote 7c): o POST de conclusão com a multa zerada e os acréscimos e o débito atualizado reduzidos de forma coerente é **aceito** — o parcelamento grava a dívida forjada (R$ 232,68), sem o débito de multa (**CAND-44**, agora com evidência executável). ⬜ fora: desconto por antiguidade (exige duas referências; F2-167), à vista com desconto por inatividade (ligação inativa), duas contas. 🔴 A memória financeira vem do formulário (por leitura de código, **CAND-44**). [relatório §29](../fase2/fase2-caracterizacao-baselines.md#29-lote-7b--cobrança-efetuar-parcelamento-2026-10-15) — F2-158 a F2-168
- **Normalizações**: identificadores técnicos — ⚠️ **nunca** a ordem das prestações, que tem semântica
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 6 → 7 — *golden master de parcelamento: criar*
- **Evidência**: [`modulos/cobranca.md`](../../modulos/cobranca.md) §10–§12, §15 e §32 item 5; COB-05; cobertura **DOWN**

---

## CEN-COB-005 — Desfazimento e reparcelamento

- **Criticidade**: P0
- **Etapa OpenGSAN**: 6 — Cobrança
- **Conceitos relacionados**: desfazimento com estornos tipificados, reparcelamento encadeado (C1)
- **Objetivo**: caracterizar a reversão e o encadeamento de uma negociação
- **Pré-condições**: DOC-11 (parcelamento com entrada **vencida e não paga**); DOC-10 (parcelamento com parte das prestações paga)
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Desfazimento **automático** por entrada não paga |
  | V2 | Desfazimento **manual**, com motivo |
  | V3 | Reparcelamento englobando o saldo de DOC-10 |

- **Operação GSAN**: `desfazerParcelamentosPorEntradaNaoPaga` (batch); `desfazerParcelamentosDebito(motivo, codigo, usuario)`; efetuar parcelamento sobre saldo
- **Operação conceitual OpenGSAN**: desfazer negociação; renegociar
- **Observações semânticas**: situação do parcelamento · **documentos originais reativados** e sua situação · prestações futuras canceladas · **prestações pagas mantidas** · estornos gerados e tipos · motivo e usuário (V2) · itens do novo parcelamento, que referenciam o anterior (V3) · contadores de parcelamento e reparcelamento do imóvel
- **Localizadores GSAN**: `ParcelamentoSituacao` DESFEITO(2); estornos CANCELAMENTO_PARCELAMENTO_DESCONTO_ACRESCIMOS(**2441**) e CANCELAMENTO_PARCELAMENTO_DESCONTO_FAIXA(**2442**); `ParcelamentoMotivoDesfazer`; `usur_iddesfaz`; REPARCELAMENTOS_CURTO/LONGO_PRAZO (42/50); `imov_nnparcelamento`, `imov_nnreparcelamento`, `imov_nnreparcmtconsec`
- **Resultado semântico esperado**: 🟢 desfazer: situação **DESFEITO**, **débitos originais voltam a ser exigíveis** exatamente como consolidados, prestações futuras canceladas, **descontos concedidos estornados** por débitos tipificados; prestações já pagas **permanecem abatidas**. 🟢 Reparcelar é **novo parcelamento que engloba o saldo do anterior**
- **Baseline concreta do legado**: 🟢 **CAPTURADA EM PARTE** (Fase 2, lote 7c, 2026-10-15) — V1, V1b, V1c, V2, V2b, V2c, V3 em [`golden/cobranca/CEN-COB-005/`](../../../../ambiente-referencia/baselines/golden/cobranca/CEN-COB-005/), sobre o parcelamento de CEN-COB-004 V1. 🟢 V1 (automático, entrada vencida além de 7 dias e não paga): **DESFEITO**, motivo ENTRADA NÃO PAGA, usuário de rotina batch; conta, guia e débito originais voltam a **NORMAL**; os débitos do parcelamento (inclusive os de acréscimo) e a guia de entrada são **excluídos**; o contador de parcelamentos do imóvel volta a 0; a posição volta à anterior (R$ 230,40, atualizado R$ 234,95). 🟢 V1b: com a entrada paga, não desfaz. 🔴 V1c: o parcelamento com a conta como entrada (EP), não paga, **não é desfeito** (o desfazimento só olha guias) (**CAND-47**). 🔴 V2 (manual): a tela Consultar Parcelamento **falha** (tenta registrar o boleto da entrada e o cliente não tem CPF/CNPJ — **CAND-45**); a URL do botão desfaz, com o motivo e o usuário da tela. 🔴 V2b: com a entrada paga, a tela não oferece o Desfazer, mas a URL é aceita até a exclusão da guia paga — só a chave estrangeira do item do movimento impede ('Erro de acesso ao banco de dados'), nada desfeito (**CAND-46**). 🔴 V2c: o EP também não tem o Desfazer na tela; pela URL, desfaz — a conta sai da revisão e volta ao vencimento original (**CAND-46**, **CAND-47**). 🟢 V3 (reparcelamento): depois da conta de 05/2026 paga (com a 1ª prestação do parcelamento de 09/2014), o assistente leva o saldo do parcelamento (5 × R$ 50,00) como **REPARCELAMENTO CURTO PRAZO** R$ 250,00, o débito de serviço e a guia; o débito do parcelamento anterior fica PARCELADA, mas o parcelamento anterior continua NORMAL; 🔴 o contador de reparcelamentos do imóvel, nulo, fica **0** (**CAND-48**). 🔴 Nenhum registro de auditoria no parcelamento nem no desfazimento, e o desfazimento apaga o que o parcelamento gerou (**CAND-49**). ⬜ fora: o desfazimento com prestação já cobrada e o estorno de descontos. [relatório §30](../fase2/fase2-caracterizacao-baselines.md#30-lote-7c--cobrança-depois-do-parcelamento-2026-10-15) — F2-173 a F2-179
- **Normalizações**: identificadores técnicos
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 6 → 7 — *golden master de parcelamento: desfazer; memória integral e auditável*
- **Evidência**: [`modulos/cobranca.md`](../../modulos/cobranca.md) §13, §14 e §32 itens 6–8; [`modulos/arrecadacao.md`](../../modulos/arrecadacao.md) §22 item 11

---

## CEN-COB-006 — Negativação e exclusão

- **Criticidade**: P1
- **Etapa OpenGSAN**: 6 — Cobrança
- **Conceitos relacionados**: negativação — decisão (C1) e envio (C2 — contrato de integração)
- **Objetivo**: caracterizar a inclusão e a exclusão do devedor no bureau
- **Pré-condições**: comando de negativação com critérios; cliente responsável de IMV-01 com débito elegível; bureau **simulado**
- **Entrada**: V1 — comando executado; V2 — pagamento após a inclusão; V3 — bureau indisponível
- **Operação GSAN**: comando de negativação; movimento do negativador; exclusão
- **Operação conceitual OpenGSAN**: decidir negativação (Cobrança); enviar (Integrações)
- **Observações semânticas**: clientes selecionados · movimento de inclusão · situação de cobrança do imóvel · movimento de **exclusão** após pagamento · comportamento com bureau indisponível
- **Localizadores GSAN**: `gcom.spcserasa`; movimentos do negativador; situação de cobrança (11–15)
- **Resultado semântico esperado**: 🟢 a negativação é **por cliente**, com critérios; o pagamento gera **exclusão**. V3 — **a capturar**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: formato de transporte do movimento — comparar o **conteúdo**
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 6 → 7
- **Evidência**: [`modulos/cobranca.md`](../../modulos/cobranca.md) §18 e §32 item 10; [`modulos/integracoes.md`](../../modulos/integracoes.md) §10 item 21

---

## CEN-COB-007 — Retificação, cancelamento e prescrição de conta já em cobrança

- **Criticidade**: P0
- **Etapa OpenGSAN**: 6 — Cobrança
- **Conceitos relacionados**: identidade documental (C2)
- **Objetivo**: caracterizar o que acontece com uma cobrança em curso quando o documento cobrado muda
- **Pré-condições**: documento de cobrança emitido com itens de IMV-01 (CEN-COB-002 V1)
- **Entrada**: V1 — retificação de uma conta cobrada; V2 — cancelamento; V3 — prescrição
- **Operação GSAN**: retificar/cancelar/prescrever conta com cobrança em curso
- **Operação conceitual OpenGSAN**: alterar documento cobrado
- **Observações semânticas**: validade do documento de cobrança · item correspondente · posição de dívida · estado da conta
- **Localizadores GSAN**: itens do documento de cobrança; situação da conta (estado 8)
- **Resultado semântico esperado**: 🟢 na retificação a **identidade é preservada** e o documento de cobrança **continua válido**; 🟢 cancelada ou prescrita, a conta **sai da posição de dívida**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: chaves técnicas — comparar pela **identidade documental**
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — por mapeamento semântico
- **Gate que este cenário protege**: 6 → 7
- **Evidência**: [`modulos/cobranca.md`](../../modulos/cobranca.md) §19 e §32 itens 11 e 12
