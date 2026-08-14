# Módulo Arrecadação — Mapa Funcional

Elaborado em 2026-08-14 (Fase 0). Fontes: código GSAN (`gcom.arrecadacao` e subpacotes, fronteiras em faturamento/cobrança), mapeamentos Hibernate, constantes, DDL, migrations; `gsan_comercial` usado apenas para identificar evoluções posteriores. Pré-requisitos: [cadastro](cadastro.md), [micromedicao](micromedicao.md), [faturamento](faturamento.md), [cobranca](cobranca.md), [glossário](../dominio/glossario.md).

**Convenção de confiança nesta análise**: 🟢 fato comprovado no código/DDL · 🔵 interpretação funcional a partir de evidência · 🟡 hipótese · ❔ não compreendido (vai para §15).

## 1. Responsabilidade

A Arrecadação **reconhece, classifica e aplica o recebimento**. Recebe movimentos dos arrecadadores (bancos/conveniados), transforma cada registro em Pagamento, descobre a qual obrigação o dinheiro corresponde (classificação), registra o resultado dessa tentativa numa **situação** do próprio pagamento, concilia o total com o aviso bancário, trata devoluções e encerra a competência mensal consolidando totais contábeis.

🔵 A divisão conceitual do prompt **se confirma com uma correção importante**: Faturamento gera a obrigação; Cobrança atua sobre a não paga; Arrecadação reconhece e classifica o recebimento — mas **a Arrecadação não "baixa" a obrigação alterando um campo de quitação nos documentos**. 🟢 O que existe é o vínculo pagamento→documento (`Pagamento` aponta ContaGeral, GuiaPagamentoGeral, DébitoACobrarGeral, Fatura, CobrançaDocumento) e a **situação do pagamento**; quem consulta dívida (Cobrança, §22 daquele mapa) deduz o pagamento do estoque. Essa é uma diferença estrutural relevante para o SISAN.

## 2. Pagamento

🟢 **Identidade própria e independente**: `arrecadacao.pagamento`, id de `arrecadacao.seq_pagamento`. **Não existe `PagamentoGeral`** — o padrão de identidade estável observado em Conta/Guia/Débito **não se repete aqui**. Existe `PagamentoHistorico`, mas com **sequence própria** (`seq_pagamento_historico`): 🔵 ao ser arquivado, o pagamento **recebe novo identificador**, ou seja, a identidade do recebimento não é transversal ao arquivamento como a da conta. Consequência prática: a rastreabilidade pagamento↔documento pós-arquivamento depende das chaves do documento (que são estáveis) e das referências de competência, não de um id de pagamento perene.

🟢 Conteúdo essencial: `valorPagamento`, **`valorExcedente`**, `dataPagamento` (data financeira), `dataProcessamento` (timestamp de processamento — 🔵 distinção explícita entre data do fato e data do processamento), `anoMesReferenciaPagamento` (competência do documento pago) e **`anoMesReferenciaArrecadacao`** (competência em que o dinheiro foi arrecadado — as duas podem divergir), `indicadorExpurgado`.

🟢 Vínculos possíveis (todos opcionais, mapeados em `Pagamento.hbm.xml`): `ContaGeral`, `GuiaPagamentoGeral`, `DébitoACobrarGeral`, `Fatura`, `CobrancaDocumento`, `ArrecadadorMovimentoItem` (origem), `AvisoBancario` (conciliação), `Imovel`, `Cliente`, `ArrecadacaoForma`, `DocumentoTipo` (+ agregador), `PagamentoCartaoDebito`, `DebitoTipo`, e **situação atual/anterior** (`PagamentoSituacao`).

🟢 **Situações do pagamento** (`PagamentoSituacao`) — este é o coração semântico do módulo:

| Código | Situação | Significado funcional |
| ------ | -------- | --------------------- |
| 0 | PAGAMENTO_CLASSIFICADO | Documento identificado e recebimento apropriado |
| 1 | PAGAMENTO_EM_DUPLICIDADE | Documento já tinha pagamento |
| 2 | DOCUMENTO_INEXISTENTE (= FATURA_INEXISTENTE) | Não achou documento correspondente |
| 3 | VALOR_EM_EXCESSO | Pago acima do devido |
| 4 | VALOR_A_BAIXAR | 🔵 Pendente de apropriação/baixa |
| 5 | VALOR_NAO_CONFERE | Divergência de valor |
| 7 | MOVIMENTO_ABERTO | Movimento ainda não fechado |
| 9 | DUPLICIDADE_EXCESSO_DEVOLVIDO | Duplicidade/excesso já devolvido ao cliente |
| 10 | DOCUMENTO_A_CONTABILIZAR | 🟢 Conta cuja referência contábil ainda não fechou |
| 11 | DOCUMENTO_INEXISTENTE_DEBITO_PRESCRITO | Documento existe mas está prescrito |
| 12 | DOCUMENTO_INEXISTENTE_CONTA_PARCELADA | Conta foi incluída em parcelamento |
| 13 | DOCUMENTO_INEXISTENTE_CONTA_CANCELADA | Conta cancelada |
| 14 | DOCUMENTO_INEXISTENTE_ERRO_PROCESSAMENTO | Conta em erro de processamento |

🔵 Leitura funcional: o pagamento **sempre existe e é preservado**, mesmo quando não pôde ser apropriado — o "não classificado" não é ausência de registro, é um **estado** do pagamento. Situação **atual e anterior** são mantidas (reclassificações são rastreáveis).

## 3. Movimento do arrecadador (recepção)

🟢 Cadeia: `Arrecadador` → `ArrecadadorContrato` (+ convênio, tarifas) → `ArrecadadorMovimento` → `ArrecadadorMovimentoItem`.

🟢 `ArrecadadorMovimento` guarda o **cabeçalho do arquivo**: `dataGeracao`, **`numeroSequencialArquivo` (NSA)**, `codigoConvenio`, `codigoBanco`, `nomeBanco`, **`numeroVersaoLayout`**, `codigoRemessa`, `descricaoIdentificacaoServico`, **`numeroRegistrosMovimento` e `valorTotalMovimento`** (totais do trailer para conferência). 🟢 `ArrecadadorMovimentoItem` preserva **`conteudoRegistro` (a linha original do arquivo)**, `valorDocumento`, `descricaoOcorrencia` e `indicadorAceitacao`.

🔵 Isso significa: o GSAN **guarda o registro bruto recebido**, permitindo auditoria e reprocessamento a partir da origem; a aceitação/rejeição é por item, não só por arquivo.

🟢 **Layouts são versionados e validados por rotinas dedicadas**, não por um parser genérico "CNAB": `validarArquivoMovimentoArrecadador`, `validarArquivoMovimentoArrecadadorArquivosBanco`, `validarArquivoMovimentoArrecadadorFichaCompensacao`, além de rotinas específicas de **cartão de crédito** (header/trailer). 🔵 Ou seja: o suporte é a **layouts posicionais de arrecadação e ficha de compensação (padrão FEBRABAN/convênio), com validação por tipo de registro e versão de layout** — descrever tudo como "CNAB genérico" seria impreciso.

❔ Não localizei nesta análise a verificação explícita de reimportação (idempotência por NSA/convênio) — o NSA é armazenado, mas o ponto de bloqueio de dupla importação não foi comprovado (§15).

## 4. Classificação (identificação da obrigação)

🟢 Processo em lote dedicado: `classificarPagamentosDevolucoes(colecaoIdsLocalidades, idFuncionalidadeIniciada)` (batch `batchClassificarPagamentosDevolucoes`), varrendo **por localidade → imóveis → pagamentos por tipo de documento**, com rotina especializada por tipo (`classificarPagamentosConta` para contas).

🟢 **A recepção é separada da classificação** (o pagamento nasce no processamento do movimento; a classificação é posterior e em lote) — 🔵 propriedade arquitetural relevante: o dinheiro é reconhecido antes de ser apropriado.

🟢 Lógica comprovada em `classificarPagamentosConta` (linha 34147): busca a conta do imóvel/referência **tanto na conta corrente quanto em `ContaHistorico`** e decide pela **situação do documento**:

```text
situação da conta encontrada:
  NORMAL | INCLUIDA | RETIFICADA        → classifica (apropria)
  DEBITO_PRESCRITO(+contas incluídas)   → DOCUMENTO_INEXISTENTE_DEBITO_PRESCRITO (11)
  CANCELADA                              → DOCUMENTO_INEXISTENTE_CONTA_CANCELADA (13)
  PARCELADA                              → DOCUMENTO_INEXISTENTE_CONTA_PARCELADA (12)
  ERRO_PROCESSAMENTO                     → DOCUMENTO_INEXISTENTE_ERRO_PROCESSAMENTO (14)
  (referência contábil ainda não fechada) → DOCUMENTO_A_CONTABILIZAR (10)
```

🔵 Três conclusões funcionais fortes: (a) **pagar uma conta arquivada funciona** — a busca inclui o histórico, confirmando a identidade estável do documento (fronteira do Faturamento resolvida); (b) **conta retificada não invalida o pagamento** — RETIFICADA é situação classificável; (c) o sistema **não descarta** o pagamento quando o documento está prescrito/cancelado/parcelado: registra a razão numa situação específica, preservando o dinheiro para tratamento posterior.

🟢 Tipos de documento pagáveis (`DocumentoTipo`): CONTA(1), ENTRADA_DE_PARCELAMENTO(2), **DOCUMENTO_COBRANCA(3)**, FATURA_CLIENTE(5), DEBITO_A_COBRAR(6), GUIA_PAGAMENTO(7), DEVOLUCAO_VALOR(8), CREDITO_A_REALIZAR(10), EXTRATO_DE_DEBITO(14), cartas de cobrança (21–23). 🟢 Há também entrada por **código de barras** (`inserirPagamentosCodigoBarras(colecaoPagamentos, colecaoDevolucoes, usuario, avisoBancario)`) — 🔵 caminho manual/alternativo que já nasce vinculado a um aviso bancário.

## 5. Pagamento parcial

🟢 **Correção de premissa**: `PAGAMENTO_PARCIAL_CONTA(409)` **não é uma situação de pagamento** — é um **`DebitoTipo`** usado na emissão de **guia de pagamento** (`obterContasParaPagamentoParcial(idImovel, idDebitoTipo)` em `ControladorFaturamento`; uso em `AdicionarGuiaPagamentoItemPopupAction`, com validação que exige imóvel informado).

🔵 Interpretação: o "pagamento parcial de conta" no GSAN é um **produto do Faturamento/Atendimento** — emite-se uma guia para receber parte de uma conta —, não um comportamento automático da leitura do arquivo bancário. Quando o arquivo traz valor diferente do esperado, o mecanismo é outro: situações **VALOR_NAO_CONFERE(5)** / **VALOR_A_BAIXAR(4)** / **VALOR_EM_EXCESSO(3)**.

❔ Não comprovei nesta análise a regra que decide entre 4 e 5 (limiares/tolerância) nem se há apropriação proporcional automática do valor menor (§15).

## 6. Pagamento a maior / excedente

🟢 O pagamento carrega **`valorExcedente`** próprio e a situação **VALOR_EM_EXCESSO(3)**; existe a situação terminal **DUPLICIDADE_EXCESSO_DEVOLVIDO(9)** e fluxo de atendimento que a aplica (`ControladorRegistroAtendimentoSEJB:15442` seta essa situação; existe Action `TransferirDevolucaoValoresPagosDuplicidade`).

🔵 Resposta a "para onde vai o dinheiro não apropriável": as três saídas evidenciadas são (a) permanecer como **excedente registrado no próprio pagamento**, (b) virar **devolução ao cliente** (com Guia de Devolução — §7/§9), (c) virar **crédito a realizar** para abater conta futura (`Devolucao` aponta `CreditoARealizarGeral`; há geração de crédito por antecipação de parcelas). 🔵 A escolha entre elas passa por atendimento/decisão operacional, não é puramente automática.

## 7. Pagamento não classificado

🟢 Conceito existe e é de primeira classe: classes `DadosPagamentosNaoClassificados` e `DadosDocumentosNaoIdentificados`, batch `batchGerarDadosPagamentosNaoClassificados`, e no encerramento mensal os totais são consolidados **por situação atual e anterior** (mapas separados para duplicidade, documento inexistente, prescrito, parcelada, cancelada, erro de processamento, valor não confere).

🔵 Portanto: o não classificado fica **no mesmo registro de pagamento**, distinguido pela situação; a reclassificação preserva a situação anterior (campo `pgst_idanterior`), mantendo rastreabilidade. 🟢 Há tela de manutenção (`ExibirAtualizarPagamentosAction` trata VALOR_EM_EXCESSO), logo há correção manual sujeita às permissões do módulo de segurança.

## 8. Aviso bancário e conciliação

🟢 `AvisoBancario` (schema arrecadacao) carrega, lado a lado: **`valorArrecadacaoCalculado` × `valorArrecadacaoInformado`**, `valorDevolucaoCalculado`, `valorRealizado`, `valorContabilizado`, `dataPrevista` × `dataRealizada`, `dataLancamento`, `numeroDocumento`, `numeroSequencial`, `indicadorCreditoDebito`, `anoMesReferenciaArrecadacao`. 🟢 Existem `AvisoAcerto` e `AvisoDeducoes`; consulta dedicada `pesquisarAcertosAvisoBancario(idAvisoBancario, indicadorArrecadacaoDevolucao)` e `pesquisarValoresAvisoBancario`.

🔵 Leitura funcional: o aviso bancário representa **o crédito informado pelo banco** e é confrontado com o que o GSAN calculou a partir dos pagamentos/devoluções processados — o par calculado × informado **é** o mecanismo de conciliação, com **acertos** e **deduções** (tarifas/retenções) como instrumentos de ajuste. Pagamentos apontam o aviso (`avbc_id`), e devoluções também.

❔ Não determinei o fluxo de "fechamento" formal do aviso (estados/transições explícitas) — a situação `MOVIMENTO_ABERTO(7)` do pagamento sugere um ciclo aberto/fechado do movimento, mas a máquina de estados não foi comprovada (§15).

## 9. Devolução, estorno e acertos

🟢 `Devolucao` é entidade simétrica ao pagamento: `valorDevolucao`, `dataDevolucao`, **duas competências** (`anoMesReferenciaArrecadacao` e `anoMesReferenciaDevolucao`), **situação atual e anterior** (`DevolucaoSituacao`: DEVOLUCAO_CLASSIFICADA(1), DEVOLUCAO_OUTROS_VALORES(2), PAGAMENTO_DUPLICIDADE_NAO_ENCONTRADO(3), GUIA_DEVOLUCAO_NAO_INFORMADA(4), VALOR_NAO_CONFERE(5)), e vínculos com `Imovel`, `Cliente`, `GuiaDevolucao`, `AvisoBancario`, `ArrecadadorMovimentoItem`, `CobrancaDocumento`, `DebitoTipo` e **`CreditoARealizarGeral`**. 🟢 Há `DevolucaoHistorico` e `transferirDevolucaoParaHistorico`.

🟢 `GuiaDevolucao` é o **instrumento de devolução ao cliente**: emissão, validade, valor, referência contábil e referência própria; ciclo completo de manutenção (`inserirGuiaDevolucao`, `atualizarGuiaDevolucao`, `removerGuiaDevolucao`, `validarExibirInserirGuiaDevolucao(ra, ordemServico)` — 🔵 devolução nasce frequentemente de um atendimento/OS).

🔵 Distinção observada: o GSAN trabalha com **devolução** (saída de dinheiro, com guia, situação e competência próprias) e com **acertos** do aviso bancário (ajuste de conciliação); a classificação de devoluções é feita pelo **mesmo** processo em lote da classificação de pagamentos (`classificarPagamentosDevolucoes`). ❔ Um "estorno" como operação distinta (movimento inverso do pagamento) **não foi comprovado** como conceito próprio — o que se comprovou foi mudança de situação do pagamento + devolução associada (§15).

🔵 Resposta a "como a dívida volta a existir": não por reabertura explícita de um campo no documento, mas porque o **pagamento deixa de contar** (situação alterada; `RepositorioArrecadacaoHBM:18588` mostra consultas que só consideram pagamentos em situações `CLASSIFICADO`, `VALOR_A_BAIXAR`, `DUPLICIDADE_EXCESSO_DEVOLVIDO`) — o estoque de dívida da Cobrança é recalculado por consulta.

## 10. Débito automático

🟢 Três níveis distintos, exatamente como o prompt pedia diferenciar:

1. **Opção do cliente** — `DebitoAutomatico`: `identificacaoClienteBanco`, `dataOpcaoDebitoContaCorrente`, `dataInclusaoNovoDebitoAutomatico`, `dataExclusao` (+ banco/agência/imóvel). O imóvel também guarda `imov_icdebitoconta`/`imov_cddebitoautomatico` (cadastro).
2. **Envio de uma conta ao banco** — `DebitoAutomaticoMovimento`: aponta **`ContaGeral`**, `FaturamentoGrupo`, `dataVencimento`, `valorDebito`, **`envioBanco` / `retornoBanco` / `processamento`**, NSA de envio e de retorno, e **`DebitoAutomaticoRetornoCodigo`** (código de retorno do banco).
3. **Pagamento efetivo** — chega como pagamento normal do movimento do arrecadador (com `ArrecadacaoForma` correspondente).

🔵 Ou seja: aceite/rejeição vivem no movimento de débito automático (código de retorno); a quitação continua sendo reconhecida pelo fluxo padrão de arrecadação. 🟢 Batch dedicado `batchAtualizarCodigoDebitoAutomatico`. 🟢 A Cobrança usa a condição de débito automático nos critérios de elegibilidade (`cbcl_vlmindebdebaut`, `cbcl_qtmincontasdebaut`).

## 11. Guia de pagamento (visão da arrecadação)

🟢 Confirmado como documento pagável próprio (`DocumentoTipo.GUIA_PAGAMENTO(7)` e `ENTRADA_DE_PARCELAMENTO(2)`), com identidade estável (`GuiaPagamentoGeral`) referenciada pelo pagamento. 🔵 Existe justamente porque nem toda obrigação cabe no ciclo mensal da conta: entrada de parcelamento, serviços, pagamento parcial de conta (§5), cobranças avulsas. 🟢 Guias não pagas são canceladas por batch dedicado (`BatchCancelarGuiasPagamentoNaoPagasMDB`) — 🔵 a guia tem validade operacional.

## 12. Documento de Cobrança × Pagamento (fronteira da Cobrança)

🟢 Fatos: `Pagamento` mapeia `cobrancaDocumento` (`cbdo_id`); `DocumentoTipo.DOCUMENTO_COBRANCA(3)` existe como tipo pagável; `Devolucao` também aponta documento de cobrança.

🔵 Redação funcionalmente precisa (corrigindo a formulação anterior da Cobrança): **um pagamento pode ser associado a um Documento de Cobrança**, e o documento de cobrança é um dos tipos de documento reconhecidos na arrecadação. ❔ **Não comprovei** nesta análise o mecanismo de rateio/baixa dos itens internos do documento quando o pagamento chega por ele (se cada item subjacente é apropriado individualmente, se há proporcionalidade, e o comportamento quando um item já foi pago por outro canal). Fica como dúvida explícita (§15) e cenário de caracterização (§14) — **não devemos afirmar rateio automático sem evidência**.

## 13. Parcelamento, retificação/cancelamento e efeitos na Cobrança

- 🟢 **Entrada de parcelamento** é tipo de documento próprio (2), pago tipicamente por guia; a Cobrança desfaz o parcelamento quando a entrada não é paga (batch daquele módulo). 🟢 **Prestações** são débitos a cobrar que entram nas contas — o pagamento da conta que as contém é o caminho normal; há também `DébitoACobrarGeral` como alvo direto de pagamento e batch `batchAcompanharPagamentoDoParcelamento` (no controlador de SPC/Serasa — 🔵 acompanhamento de pagamento de parcelamento alimenta a reabilitação em bureaus).
- 🟢 **Conta parcelada** recebendo pagamento → situação **12** (documento inexistente/conta parcelada): 🔵 confirma que, após inclusão em parcelamento, a conta deixa de ser o alvo correto — o pagamento fica registrado e sinalizado, não apropriado à conta.
- 🟢 **Retificação**: conta RETIFICADA é classificável (o pagamento é apropriado normalmente) e a busca inclui histórico → 🔵 **a identidade estável do documento (ContaGeral) é o que sustenta pagamento antes/depois de retificação** — confirmação direta da conclusão do Faturamento.
- 🟢 **Cancelamento/prescrição**: situações 13 e 11 — o dinheiro entra, não é apropriado, e fica visível como não classificado para tratamento (devolução/crédito).
- 🟢 **Efeitos sobre Cobrança**: batch `BatchAtualizarPagamentosContasCobranca` e `ControladorCobrancaPorResultado.atualizarPagamentosContasCobranca(idFuncionalidadeIniciada, idLocalidade, anoMesArrecadacao)` — 🔵 os pagamentos do mês são propagados para as carteiras de cobrança terceirizada (recuperação/comissionamento). 🟡 A exclusão de negativação por pagamento é plausível e coerente com `acompanharPagamentoDoParcelamento`, mas o gatilho exato não foi comprovado aqui (§15).

## 14. Encerramento mensal da arrecadação

🟢 `encerrarArrecadacaoMes(colecaoIdsLocalidades, idFuncionalidadeIniciada)` + batch `batchEncerrarArrecadacaoMes` (e o par `batchGerarHistoricoParaEncerrarArrecadacaoMes` visto no Faturamento).

🟢 O que o método consolida (evidência direta das estruturas internas): totais de pagamentos e devoluções por localidade e **retenções tributárias por competência — IR, CSLL, COFINS, PIS/PASEP** sobre pagamentos classificados de conta; e **totais de pagamentos não classificados discriminados por situação atual e anterior** (duplicidade, documento inexistente, prescrito, parcelada, cancelada, erro de processamento, valor não confere).

🔵 Conclusão: o encerramento **não é arquivamento técnico** — é um **fechamento financeiro/contábil de competência**, que produz os números da arrecadação do mês (inclusive tributários) e classifica o que não pôde ser apropriado. O arquivamento (transferência para `PagamentoHistorico`/`DevolucaoHistorico`) é operação associada, mas distinta. 🟢 A competência é governada por `anoMesReferenciaArrecadacao` (e há `atualizarAnoMesArrecadacao`). ❔ Não comprovei se o encerramento pode ser refeito/revertido (§15).

## 15. PIX, cartão e ficha de compensação

- **PIX** 🟢: nesta branch existe **apenas** `gcom.arrecadacao.GeradorQrCodePIX`, uma classe utilitária que monta a **string do QR Code estático** (método `gerarStringQrCodeConta(valor, nomeCliente, cidade)` + `main` de teste) com **chave PIX hard-coded** (`testqrcode01@bb.com.br`). **Não há** integração com PSP, webhook, conciliação específica ou entidade de pagamento PIX no código. 🟢 Não há migration oficial de PIX em `gsan-migracoes`. 🟢 As tabelas `arrecadacao_pix` e `conta_qrcode_pix` aparecem **somente na instalação de referência** → **Funcionalidade posterior/adicional observada na instalação de referência**; no GSAN base, 🔵 o recebimento PIX (se usado) chega pelo movimento bancário tradicional. ⚠️ A chave de teste hard-coded é achado de segurança/qualidade a registrar.
- **Cartão de crédito** 🟢: há rotinas de **arquivo de movimento de cartão** (validação de header/trailer, `registrarMovimentoCartaoCredito`) e entidades `PagamentoCartaoDebito`/`Item`; a Cobrança tem `ParcelamentoPagamentoCartaoCredito` e `GuiaPagamentoParcelamentoCartao`. 🔵 O cartão entra pela Arrecadação como **mais um layout de movimento de arrecadador**, com o parcelamento por cartão sendo funcionalidade da Cobrança. 🟡 Grau de uso e se é extensão de companhia: não determinado.
- **Ficha de compensação** 🟢: layout próprio validado (`validarArquivoMovimentoArrecadadorFichaCompensacao`, classe `FichaCompensacao`, `BoletoInfo`) — boleto registrado; migrations de 2024 na instalação de referência ampliaram isso (registro de boletos/BB) → evolução posterior.

## 16. Estados (conceituais, derivados das evidências)

```text
PAGAMENTO
  criado no processamento do movimento
      → [não classificado: situações 1,2,3,4,5,7,10,11,12,13,14]  ←→ reclassificação (situação anterior preservada)
      → CLASSIFICADO (0)
      → DUPLICIDADE_EXCESSO_DEVOLVIDO (9)            (após devolução)
      → arquivado em PagamentoHistorico (novo id)     (encerramento/expurgo — indicadorExpurgado)

DEVOLUÇÃO
  classificada (1) | outros valores (2) | pagto duplicidade não encontrado (3)
  | guia de devolução não informada (4) | valor não confere (5)
      → GuiaDevolucao emitida (validade, referência contábil)
      → arquivada em DevolucaoHistorico

DÉBITO AUTOMÁTICO
  opção do cliente (inclusão/exclusão)
      → movimento por conta: envio ao banco → retorno (código de retorno) → aceito/rejeitado
      → quando pago: entra como pagamento do movimento do arrecadador
```

## 17. Parametrização × código

| Regra | Natureza |
| ----- | -------- |
| Arrecadadores, contratos, convênios, tarifas | Parametrizada (`arrecadador*`) |
| Formas de arrecadação, tipos de documento, tipos de débito/crédito | Parametrizadas (tabelas de domínio com contabilização) |
| Códigos de retorno de débito automático | Parametrizados (`debito_automatico_retorno_codigo`) |
| Situações de pagamento/devolução | **Constantes no código** (catálogo fixo) + tabelas de domínio |
| Layouts bancários (posições, versões, tipos de registro) | **Código** (rotinas de validação por layout/versão) |
| Retenções tributárias no encerramento | **Código** (com parâmetros do sistema) |
| Competência de arrecadação | Parâmetro do sistema (ano/mês de arrecadação) |

## 18. Variações por companhia

🟢 Sete subclasses `ControladorArrecadacao{CAEMA,CAER,CAERN,COMPESA,COSAMA,COSANPA,JUAZEIRO}SEJB` + deployments EJB por companhia (`descriptors/arrecadacaoCAEMA`, `arrecadacaoCAER`, ...). 🔵 Classificação: **regra base GSAN** = ciclo movimento→pagamento→classificação→conciliação→encerramento e o catálogo de situações; **customização de companhia** = layouts bancários específicos e as subclasses; **evolução posterior** = PIX, boleto registrado/ficha de compensação ampliada, cartão (a confirmar).

## 19. Regras estruturantes

1. 🟢 **Recepção e classificação são etapas separadas** — o recebimento é reconhecido antes de saber a que obrigação pertence.
2. 🟢 **O registro bruto do arquivo é preservado** (`amit_cnregistro`), com totais de conferência do arquivo (registros e valor).
3. 🟢 **Nenhum pagamento é descartado**: impossibilidade de apropriação vira **situação**, não exclusão — com situação anterior preservada.
4. 🟢 **A classificação busca o documento na versão corrente e no histórico** — a identidade estável do documento (ContaGeral etc.) é o que torna isso possível.
5. 🟢 **Situação do documento decide a apropriação** (normal/incluída/retificada apropriam; prescrita/cancelada/parcelada/erro geram situações específicas).
6. 🟢 **Duas competências convivem**: a do documento pago e a da arrecadação — e o encerramento fecha a segunda.
7. 🟢 **A conciliação é calculado × informado** no aviso bancário, com acertos e deduções.
8. 🟢 **Devolução é entidade própria com guia, situações e competência** — a saída de dinheiro é rastreada como o recebimento.
9. 🟢 **O encerramento mensal é fechamento financeiro/contábil** (inclui retenções tributárias e a consolidação do não classificado), distinto do arquivamento.
10. 🟢 **O pagamento não tem identidade transversal ao arquivamento** (`PagamentoHistorico` com sequence própria) — assimetria em relação aos documentos de dívida.

## 20. Compatibilidade GSAN → SISAN

| Conceito | Classificação | Motivo |
| -------- | ------------- | ------ |
| Separação recepção × classificação | PRESERVAR CONCEITO | Permite reconhecer dinheiro sem perder o que não casa |
| Preservação do registro bruto do arquivo + totais de conferência | PRESERVAR CONCEITO | Auditoria e reprocessamento |
| Catálogo de situações de pagamento (com situação anterior) | PRESERVAR CONCEITO | É a semântica do módulo; migrar significados, não só códigos |
| Classificação por situação do documento (busca corrente+histórico) | PRESERVAR CONCEITO | Sustenta pagamento após retificação/arquivamento |
| Duas competências (documento × arrecadação) | PRESERVAR CONCEITO | Base do fechamento e das comparações financeiras |
| Conciliação calculado × informado (aviso, acertos, deduções) | PRESERVAR CONCEITO | Controle bancário real |
| Devolução com guia, situações e competência | PRESERVAR CONCEITO | Saída de dinheiro rastreada |
| Encerramento como fechamento contábil (retenções + não classificado) | PRESERVAR CONCEITO | Números oficiais do mês |
| Débito automático em três níveis (opção / envio por conta / pagamento) | PRESERVAR CONCEITO | Distinção correta e necessária |
| Identidade do pagamento perdida no arquivamento (novo id no histórico) | **REESTRUTURAR** | Assimetria injustificada: o SISAN deve manter identidade estável do recebimento como faz com os documentos (impacto direto em auditoria e migração) |
| Situações fixas em constantes de código | POSSÍVEL MODERNIZAÇÃO | Semântica preservada; forma pode virar catálogo governado |
| Parsers de layout embutidos no controlador | POSSÍVEL MODERNIZAÇÃO | Adapters por layout/versão, mantendo comportamento |
| Rateio/baixa de itens em pagamento de Documento de Cobrança | EXIGE APROFUNDAMENTO | Comportamento não comprovado (§21) |
| Regra VALOR_A_BAIXAR × VALOR_NAO_CONFERE e apropriação parcial | EXIGE APROFUNDAMENTO | Limiares e efeito no saldo não comprovados |
| Idempotência de reimportação de arquivo | EXIGE APROFUNDAMENTO | NSA armazenado, bloqueio não comprovado |
| Chave PIX hard-coded no gerador de QR Code | **NÃO TRANSPORTAR** | Segredo em código; PIX deve nascer como integração parametrizada |

## 21. Hipóteses para avaliação futura (não são decisões)

1. **Ledger de recebimentos com identidade estável** — motivado pela assimetria comprovada (`PagamentoHistorico` com id novo) frente à identidade preservada dos documentos.
2. **Motor de apropriação explícito** (dinheiro → obrigação, com resultado tipificado) — motivado por a apropriação hoje estar embutida em rotinas de lote por tipo de documento e localidade.
3. **Conciliação separada da classificação** — motivada pela coexistência de dois eixos já hoje (aviso calculado × informado vs. situação do pagamento).
4. **Adapters bancários por layout/versão** — motivados pelas rotinas de validação por tipo de registro/versão embutidas no controlador.
5. **Importação idempotente por convênio+NSA** — motivada pela existência do NSA sem bloqueio comprovado.
6. **Obrigação financeira unificada** (conta/guia/débito/documento de cobrança como alvos de apropriação) — motivada pelos 5–6 alvos opcionais no mesmo registro de pagamento.

## 22. Cenários financeiros críticos para caracterização

1. Conta normal paga integralmente no vencimento → situação CLASSIFICADO(0).
2. Pagamento em atraso com acréscimos (juros/multa/atualização) — valor recebido > valor da conta.
3. Pagamento com valor divergente → VALOR_NAO_CONFERE(5) / VALOR_A_BAIXAR(4) (comportamento a caracterizar).
4. Pagamento maior que o devido → VALOR_EM_EXCESSO(3) e `valorExcedente`.
5. Pagamento duplicado → PAGAMENTO_EM_DUPLICIDADE(1) → devolução → DUPLICIDADE_EXCESSO_DEVOLVIDO(9).
6. Pagamento sem documento correspondente → DOCUMENTO_INEXISTENTE(2) e posterior reclassificação (situação anterior preservada).
7. **Conta retificada antes do pagamento** e **retificada depois do pagamento** (identidade ContaGeral).
8. Pagamento de **conta já arquivada** (classificação via histórico).
9. Conta cancelada / prescrita recebendo pagamento → situações 13 / 11.
10. Conta incluída em parcelamento recebendo pagamento na conta → situação 12.
11. Entrada de parcelamento paga por guia; e entrada não paga (desfazimento na Cobrança).
12. Prestação de parcelamento paga dentro da conta.
13. **Pagamento associado a Documento de Cobrança** (comportamento dos itens a caracterizar).
14. Pagamento após emissão de aviso de corte / após corte (efeito sobre ações e religação).
15. Devolução com Guia de Devolução (e devolução virando crédito a realizar).
16. Débito automático: enviado e aceito; enviado e rejeitado (código de retorno).
17. Divergência arquivo × aviso bancário (calculado × informado, com acerto).
18. Pagamento com referência contábil ainda aberta → DOCUMENTO_A_CONTABILIZAR(10).
19. Encerramento mensal: totais por situação + retenções tributárias.
20. Pagamento que alimenta carteira de cobrança terceirizada (`atualizarPagamentosContasCobranca`).

## 23. Dúvidas que permanecem

1. ❔ **Rateio/baixa dos itens** quando o pagamento é associado a um Documento de Cobrança; comportamento com item já pago por outro canal.
2. ❔ Regra que separa **VALOR_A_BAIXAR(4)** de **VALOR_NAO_CONFERE(5)** e se há apropriação parcial automática do valor recebido a menor.
3. ❔ **Idempotência de reimportação** de arquivo (bloqueio por convênio+NSA).
4. ❔ Existência de **estorno como operação própria** (movimento inverso) vs. apenas mudança de situação + devolução.
5. ❔ Máquina de estados formal do **aviso bancário/movimento** (abertura, fechamento, reabertura) — sugerida por MOVIMENTO_ABERTO(7).
6. ❔ Se o **encerramento mensal pode ser refeito** e o que acontece com a competência.
7. ❔ Gatilho exato da **exclusão de negativação por pagamento** (plausível via acompanhamento de parcelamento, não comprovado).
8. ❔ Fórmulas de **acréscimos** (juros/multa/atualização) atravessando Faturamento/Cobrança/Arrecadação — permanece aberto desde a Cobrança.
9. ❔ Uso real de **cartão de crédito/débito** e se é extensão de companhia.
10. ❔ Diferenças concretas entre as sete subclasses de companhia.

## 24. Evidências principais

```text
Pagamento:        arrecadacao/pagamento/Pagamento.hbm.xml → arrecadacao.pagamento (id seq_pagamento; pgmt_vlpagamento,
                  pgmt_vlexcedente, pgmt_dtpagamento, pgmt_tmprocessamento, pgmt_amreferenciapagamento/arrecadacao,
                  pgmt_icexpurgado; FKs cnta_id/gpag_id/dbac_id/fatu_id/cbdo_id/amit_id/avbc_id/pgst_idatual+idanterior)
                  PagamentoSituacao.java (0–14); PagamentoHistorico.hbm.xml (id seq_pagamento_historico — identidade NÃO preservada)
Movimento:        ArrecadadorMovimento.hbm.xml (armv_nnnsa, armv_cdconvenio, armv_nnversaolayout, armv_nnregistrosmovimento,
                  armv_vltotalmovimento); ArrecadadorMovimentoItem.hbm.xml (amit_cnregistro, amit_vldocumento, amit_icaceitacao)
Layouts:          ControladorArrecadacao.validarArquivoMovimentoArrecadador:4236 / ...ArquivosBanco:4392 /
                  ...FichaCompensacao:4567; validarArquivoMovimentoCartaoCredito{Header:45537,Trailler:45671};
                  registrarMovimentoCartaoCredito:44911; FichaCompensacao.java, BoletoInfo.java
Classificação:    ControladorArrecadacao.classificarPagamentosDevolucoes:14185 (por localidade→imóvel→tipo de documento);
                  classificarPagamentosConta:34147 (busca em Conta e ContaHistorico; decide por DebitoCreditoSituacao:
                  NORMAL/INCLUIDA/RETIFICADA → classifica; DEBITO_PRESCRITO→11; CANCELADA→13; PARCELADA→12;
                  ERRO_PROCESSAMENTO→14; referência contábil aberta→10); inserirPagamentosCodigoBarras:39020
                  DocumentoTipo.java (1 conta, 2 entrada parcelamento, 3 documento cobrança, 5 fatura, 6 débito, 7 guia, 8 devolução, 10 crédito)
Pagto parcial:    DebitoTipo.PAGAMENTO_PARCIAL_CONTA(409) usado em ControladorFaturamento.obterContasParaPagamentoParcial:3229
                  e AdicionarGuiaPagamentoItemPopupAction:188 — é tipo de débito de guia, não situação de pagamento
Excesso/devol.:   Pagamento.pgmt_vlexcedente; PagamentoSituacao 3/9; ControladorRegistroAtendimentoSEJB:15442;
                  Devolucao.hbm.xml (devl_vldevolucao, duas competências, dvst_idatual/anterior, FKs gdev_id/avbc_id/amit_id/
                  cbdo_id/crar_id); DevolucaoSituacao (1–5); GuiaDevolucao.hbm.xml; transferirDevolucaoParaHistorico
Não classificado: DadosPagamentosNaoClassificados.java, DadosDocumentosNaoIdentificados.java,
                  descriptors/batchGerarDadosPagamentosNaoClassificados; RepositorioArrecadacaoHBM:18588/27682
                  (consultas que consideram apenas situações CLASSIFICADO/VALOR_A_BAIXAR/DUPLICIDADE_EXCESSO_DEVOLVIDO)
Conciliação:      AvisoBancario.hbm.xml (avbc_vlarrecadacaocalculado × avbc_vlarrecadacaoinformado, avbc_vldevolucaocalculado,
                  avbc_vlrealizado, avbc_vlcontabilizado, avbc_dtprevista/dtrealizada); AvisoAcerto.java, AvisoDeducoes.java;
                  pesquisarAcertosAvisoBancario, pesquisarValoresAvisoBancario
Débito automático: DebitoAutomatico.hbm.xml (deba_dsidentificacaoclientebco, dtopcao/dtinclusao/dtexclusao);
                  DebitoAutomaticoMovimento.hbm.xml (cnta_id→ContaGeral, ftgr_id, damv_tmenviobanco/tmretornobanco,
                  damv_nnnsaenvio/nnnsaretorno, durc_id); DebitoAutomaticoRetornoCodigo; descriptors/batchAtualizarCodigoDebitoAutomatico
Encerramento:     ControladorArrecadacao.encerrarArrecadacaoMes:19363 (totais de IR/CSLL/COFINS/PIS-PASEP sobre pagamentos
                  classificados de conta + mapas de não classificados por situação atual e anterior);
                  descriptors/batchEncerrarArrecadacaoMes, batchClassificarPagamentosDevolucoes; atualizarAnoMesArrecadacao:35238
Cobrança:         descriptors/BatchAtualizarPagamentosContasCobranca; ControladorCobrancaPorResultado.atualizarPagamentosContasCobranca:774;
                  ControladorSpcSerasaSEJB.acompanharPagamentoDoParcelamento:12456
PIX:              gcom/arrecadacao/GeradorQrCodePIX.java (apenas string de QR Code estático; chave hard-coded
                  "testqrcode01@bb.com.br"); sem migration oficial; tabelas arrecadacao_pix/conta_qrcode_pix só na instalação de referência
Companhia:        ControladorArrecadacao{CAEMA,CAER,CAERN,COMPESA,COSAMA,COSANPA,JUAZEIRO}SEJB; descriptors/arrecadacao<COMPANHIA>
```
