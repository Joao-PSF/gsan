# Cenários Críticos — Arrecadação

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md).
>
> ⚠️ **Nenhum valor desta página foi capturado.** Baseline: `⬜ A CAPTURAR NA FASE 2` em todos os cenários.

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
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
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
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
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
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
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
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
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
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
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
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
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
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
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
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
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
