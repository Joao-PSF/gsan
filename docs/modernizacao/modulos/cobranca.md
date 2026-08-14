# Módulo Cobrança — Mapa Funcional

Elaborado em 2026-08-14 (Fase 0). Fontes: código GSAN (`gcom.cobranca`, `gcom.spcserasa`, fronteiras em faturamento/atendimento), mapeamentos, constantes, DDL; `gsan_comercial` como evidência complementar. Pré-requisitos: [cadastro](cadastro.md), [micromedicao](micromedicao.md), [faturamento](faturamento.md), [glossário](../dominio/glossario.md).

## 1. Responsabilidade

A Cobrança acompanha a vida da obrigação financeira **depois** do faturamento: identifica dívidas elegíveis (contas vencidas, guias, débitos), executa ações escalonadas (avisos, cortes, supressões, fiscalizações, cartas, negativação, terceirização), negocia (parcelamento/reparcelamento com descontos e acréscimos), aciona o braço operacional (OSs de corte/religação/fiscalização) e mantém a rastreabilidade de tudo (documentos, comandos, situações e históricos). **Ela não cria a dívida** — atua sobre obrigações originadas no Faturamento (contas, guias, débitos); cria apenas os débitos derivados da própria negociação (prestações, juros, sanções).

## 2. Principais capacidades

Identificar débitos elegíveis por critérios paramétricos; executar ações de cobrança em sequência (cronograma ou comando manual); emitir documentos de cobrança rastreando cada dívida atingida; comandar corte/supressão/fiscalização via OS e religar após regularização; negociar dívidas (parcelamento com entrada, prestações, juros e descontos parametrizados; contrato de parcelamento); desfazer/cancelar negociações (inclusive automaticamente por entrada não paga); reparcelar com controle de reincidência; negativar e reabilitar clientes em bureaus (SPC/Serasa); terceirizar carteiras (cobrança por resultado); suspender/marcar situações especiais de cobrança por imóvel; acompanhar metas e boletins de recuperação.

## 3. Entrada da dívida na cobrança

Não há "cadastro de dívida": o **estoque nasce por consulta** sobre os documentos do faturamento. O serviço canônico é `ControladorCobranca.obterDebitoImovelOuCliente(indicadorDebito, idImovel, codigoCliente, clienteRelacaoTipo, ...)` — a dívida pode ser consultada **pelo imóvel ou pelo cliente** (com papel da relação). As consultas de conta filtram por situação (`dcst_idatual in (NORMAL, RETIFICADA, INCLUIDA[, PARCELADA])` conforme o propósito) e por vencimento/referência, carregando junto o motivo de revisão (`cmrv_id`). A **elegibilidade para ação** é um recorte adicional sobre esse estoque (§6): dias de atraso, valores e quantidades mínimas parametrizados por critério.

Diferença essencial: **débito existente** (qualquer documento não quitado) ≠ **débito elegível** (o que passa no critério da ação, sem impedimentos — situação especial de cobrança, revisão, parcelamento vigente, perfil protegido).

## 4. Documentos cobrados

A cobrança referencia **identidades estáveis `*Geral`** (nunca a versão física da conta): ContaGeral, DébitoACobrarGeral, GuiaPagamentoGeral, CréditoARealizarGeral e prestações de contrato de parcelamento — como comprovam os itens do documento de cobrança (§5) e do parcelamento (§11). Por isso retificação e arquivamento não quebram o vínculo da dívida.

## 5. Documento de Cobrança

`cobranca.cobranca_documento` (`CobrancaDocumento`) é o **instrumento emitido por uma ação para um imóvel** — não é a dívida nem a ação em si, é o registro materializado da ação sobre um conjunto de dívidas:

- Cabeçalho: imóvel, ação (`cbac_id`), situação da ação (`cast_id`), comando (`cacm_id`) ou cronograma (`caac_id`) que o gerou, tipo/forma de emissão, empresa (quando terceirizada), localização (localidade/quadra), motivo de não entrega.
- **Itens** (`cobranca_documento_item`): um por dívida atingida — `cnta_id` (ContaGeral), `dbac_id`, `gpag_id`, `crar_id`, `cppr_id` (prestação de contrato), com **valor cobrado do item, acréscimos, situação do débito (`CobrancaDebitoSituacao`) e data** — rastreabilidade dívida a dívida.
- Possui versão histórica (`CobrancaDocumentoHistorico`/`ItemHistorico`) e impressão própria.
- **Pagamento pode referenciar o documento** (`Pagamento.cbdo_id`) — ex.: pagamento do total exigido no aviso de corte.

## 6. Elegibilidade (critérios paramétricos)

`CobrancaCriterio`/`CobrancaCriterioLinha` parametrizam a seleção: valor mínimo/máximo do débito, quantidade mínima/máxima de contas, valores/quantidades específicos para quem tem débito automático, valor mínimo de conta por mês, quantidade mínima de contas para parcelamento. **Cada ação aponta seu critério** (`CobrancaAcao.cbct_id`) e as **situações de ligação a que se aplica** (`last_id`/`lest_id` na ação). Impedimentos: situação especial de cobrança do imóvel (§23), revisão, negociação vigente, e recortes do comando (subcategoria, situação de fiscalização).

## 7. Ações de cobrança

Catálogo parametrizado (`cobranca_acao`) com sequência explícita:

- Constantes centrais: AVISO_CORTE(1), CORTE_ADMINISTRATIVO(2), CORTE_FISICO(3), SUPRESSAO_PARCIAL(4), SUPRESSAO_TOTAL(5), AVISO_TAMPONAMENTO(6), TAMPONAMENTO_ESGOTO(7), FISCALIZACAO_SUPRIMIDO(8)/CORTADO(9), CARTA_COBRANCA_SUPRIMIDO(10)/CORTADO(11) e variantes "a revelia" (21/22/23).
- Cada ação define: **ação predecessora** (`cbac_idacaoprecedente` — encadeamento aviso→corte→supressão...), critério de elegibilidade, **tipo de serviço da OS que gera** (`svtp_id`), situações de ligação alvo, tipo de documento emitido.
- A ação é aplicada **ao imóvel** (documento por imóvel) sobre um conjunto de dívidas (itens); o histórico fica nos documentos + situação da ação (`CobrancaAcaoSituacao`) + comandos.
- Ações operacionais (corte/supressão/fiscalização) viram **OS** (`OrdemServico.cbdo_id` liga a OS ao documento de cobrança) — o encerramento da OS retroalimenta a situação da ligação (cadastro.md §3.6) e a situação da ação.

## 8. Grupos, critérios e comandos

- **Grupo de Cobrança** (`CobrancaGrupo`, na rota — `Rota.cbgr_id`) organiza o território para o calendário de cobrança (`CobrancaGrupoCronogramaMes`).
- **Três formas de disparo**: cronograma da atividade de cobrança (`CobrancaAcaoCronograma`/`CobrancaAcaoAtividadeCronograma` — ciclo regular), **comando** (`CobrancaAcaoAtividadeComando` — execução dirigida com filtros: rotas do comando, subcategorias, situação de fiscalização) e ações eventuais/manuais.
- O comando **registra o resultado**: documentos gerados apontam o comando/cronograma de origem — rastreável e auditável; boletins (`CobrancaBoletim*`) e metas (`CicloMeta*`) acompanham execução e recuperação.
- Batch dedicado (`ControladorBatchCobranca` + deployments por atividade) processa os lotes.

## 9. Cobrança terceirizada (por resultado)

`ComandoEmpresaCobrancaConta` (+`Extensao`, `Gerencia`, recorte por situação de água) entrega **carteiras de contas** a empresas de cobrança; a situação do imóvel é marcada (`CobrancaSituacao.COBRANCA_EMPRESA_TERCEIRIZADA=1`); o acompanhamento de pagamentos repassados/comissão aparece nas estruturas `empr_cobr_conta_pagto` (migrations 2017). Arquivos de OS de cobrança para terceiros existem no lado mobile (`mobile.arq_txt_os_cobranca*`). Papel funcional registrado; protocolo fica para Integrações.

## 10. Parcelamento

Negociação da dívida do imóvel (cobranca.md do glossário §18): consolida documentos vencidos e cria um plano **entrada + N prestações**, com tipo, perfil e situação (`ParcelamentoSituacao`: NORMAL(1), DESFEITO(2), CONCLUIDO(3), CANCELADO(4)).

- **O que entra**: contas, guias, débitos a cobrar (curto/longo prazo), acréscimos por impontualidade — cada um com `DebitoTipo` próprio na saída (§12).
- **Parametrização por faixa de valor** (`ParcelamentoQuantidadePrestacao`): quantidade máxima de prestações, **taxa de juros**, **percentual mínimo de entrada**, percentual de tarifa mínima; perfis (`ParcelamentoPerfil`) e regras por RD (Resolução de Diretoria) para condições excepcionais.
- **Descontos parametrizados**: por faixa (`ParcelamentoFaixaDesconto`), por antiguidade do débito (`ParcelamentoDescontoAntiguidade`), por inatividade da ligação (`ParcelamentoDescontoInatividade`, inclusive à vista — `ParcDesctoInativVista`) — refletidos em `CreditoTipo` (DESCONTO_ACRESCIMOS_IMPONTUALIDADE(1), DESCONTO_ANTIGUIDADE_DEBITO(2), DESCONTO_INATIVIDADE_LIGACAO_AGUA(3), DESCONTO_TARIFA_SOCIAL(11)...).
- Cartão de crédito para pagamento da negociação (`ParcelamentoPagamentoCartaoCredito`, `GuiaPagamentoParcelamentoCartao`).

## 11. Composição do parcelamento (fotografia da negociação)

`parcelamento_item` liga o parcelamento **a cada documento original pela identidade estável ou pela versão histórica**: ContaGeral/ContaHistorico, DébitoACobrarGeral/Histórico, CréditoARealizarHistorico, GuiaPagamentoGeral + tipo de documento. O cabeçalho guarda a **memória financeira completa da negociação**: `valorConta`, `valorServicosACobrar`, `valorAtualizacaoMonetaria`, `valorJurosMora`, `valorMulta`, `valorDebitoAtualizado`, descontos (faixa, acréscimos, antiguidade, inatividade), `valorEntrada`, `valorJurosParcelamento`, `numeroPrestacoes`, `valorPrestacao`. **Os débitos originais permanecem individualmente identificáveis** — auditoria e desfazimento dependem disso.

## 12. Prestações

O parcelamento **gera débitos a cobrar** tipificados que entram nas contas futuras como qualquer débito (faturamento.md §11): PARCELAMENTO_CONTAS(40), PARCELAMENTO_GUIAS_PAGAMENTO(41), PARCELAMENTO_ACRESCIMOS_IMPONTUALIDADE(43), PARCELAMENTO_DEBITO_A_COBRAR curto/longo (45/47), JUROS_SOBRE_PARCELAMENTO(44), e variantes de dívida ativa (140/142/143/144/150). Cada prestação é uma parcela do débito a cobrar (identidade própria via DébitoACobrarGeral + nº da prestação; baixa via pagamento da conta que a contém ou pagamento direto do débito). A **entrada** é débito próprio (ENTRADA_PARCELAMENTO(33)) pago por **guia** — e o não pagamento da entrada **desfaz automaticamente** o parcelamento (§13).

## 13. Desfazer parcelamento

- **Automático**: batch `desfazerParcelamentosPorEntradaNaoPaga` (entrada vencida e não paga ⇒ desfaz).
- **Manual**: `desfazerParcelamentosDebito(motivo, codigo, usuario)` com `ParcelamentoMotivoDesfazer` e usuário registrado (`usur_iddesfaz`).
- Efeitos: situação → DESFEITO(2); **débitos originais voltam a ser exigíveis** (a composição por item permite reativar exatamente o que foi consolidado — contas voltam de INCLUIDA); prestações futuras são canceladas; **descontos concedidos são estornados** via débitos específicos (CANCELAMENTO_PARCELAMENTO_DESCONTO_ACRESCIMOS(2441), CANCELAMENTO_PARCELAMENTO_DESCONTO_FAIXA(2442)); prestações já pagas permanecem pagas (abatem a dívida reativada). Cancelamento é figura distinta (motivo próprio, `ParcelamentoMotivoCancelamento`, usuário de cancelamento).

## 14. Reparcelamento

Reparcelar = **novo parcelamento que engloba saldo de parcelamento anterior** (débitos a cobrar de parcelamento entram como itens do novo — tipos REPARCELAMENTOS_CURTO/LONGO_PRAZO 42/50). O imóvel carrega contadores (`imov_nnparcelamento`, `imov_nnreparcelamento`, `imov_nnreparcmtconsec`) e o banco tem funções dedicadas de verificação de cadeia (`verificaseoparcelamentofoireparcelado`, `...debitoacobrar`, `...debitoacobrarhistorico`) — a cadeia `dívida → parcelamento A → desfazimento/reparcelamento → parcelamento B` é **rastreável e limitada por regra** (reincidência controlada, perfis/critérios exigem quantidade mínima de contas para parcelar — `cbcl_qtmincontasparcmt`).

## 15. Descontos e negociações

Descontos incidem sobre acréscimos (juros/multa/atualização), sobre faixas do débito, por antiguidade e por inatividade — todos **parametrizados** e **registrados** (valores antes/depois na memória do parcelamento; créditos tipificados; estornos tipificados no desfazimento). Condições excepcionais via Resolução de Diretoria (`rdir_id`). Campanhas específicas aparecem como extensões por companhia (ex.: cartas de campanha em `descriptors/batchEmitirCartasCampanhaSolidariedade...`).

## 16. Corte

Inadimplência elegível → ação de corte na sequência (aviso→corte administrativo→corte físico→supressão), cada uma gerando **documento** + **OS do tipo de serviço da ação**; critérios e situações-alvo parametrizados na própria ação; a execução da OS (campo/mobile) encerra e **atualiza a situação da ligação** (CORTADO/SUPRIMIDO) e datas/selos na ligação (cadastro.md §3.6). A cobrança sabe do resultado pela OS ligada ao documento (`orse.cbdo_id`) e pela situação da ação. Impedimentos típicos: situação especial de cobrança, revisão, negociação vigente (parametrizados). Débito "tarifa de cortado" existe como tipo (TARIFA_CORTADO(2500) — extensão desta instalação).

## 17. Religação

Após regularização (pagamento do exigido no documento de corte ou parcelamento), a religação é solicitada (RA/OS de religação, com taxa via débito de serviço) e a cobrança participa da atualização: `ControladorCobranca.religarImovelCortado(id, situacaoAguaLigado, dataReligacaoAgua)`. A verificação financeira usa o mesmo estoque (`obterDebitoImovelOuCliente`); parcelamento vigente conta como regularização. Detalhe operacional fica com Atendimento/OS.

## 18. Negativação (SPC/Serasa)

- Módulo dedicado (`gcom.spcserasa` + entidades `Negativacao*` em cobranca): **comando de negativação** (`NegativacaoComando`) com **critérios parametrizados** (`NegativacaoCriterio` + recortes por tipo de cliente, tipo de CPF, gerência regional, elo, unidade de negócio, grupo de cobrança).
- A negativação é **do cliente** (CPF/CNPJ) sobre dívidas do imóvel — o vínculo cliente×imóvel com papel define o negativável; movimentos de inclusão/exclusão são registrados com retorno do negativador (movimento/registro — `negativador_movimento*`).
- A situação de cobrança do imóvel marca o estado: NEGATIVADO_AUTOMATICAMENTE_NO_SPC(11)/NA_SERASA(12), CARTA_ENVIADA(13/14), EM_ANALISE_PARA_NEGATIVACAO(15).
- Exclusão: por pagamento/parcelamento da dívida negativada ou comando manual, gerando movimento de exclusão (retificações/cancelamentos idem). Protocolo do arquivo fica para Integrações.

## 19. Prescrição

Determinada no ciclo de cancelamento de contas (faturamento.md §15): motivo PRESCRICAO/DEBITO_PRESCRITO leva a conta à situação **DEBITO_PRESCRITO(8)** — permanece armazenada, sai do estoque exigível, com motivo e data registrados. A cobrança respeita o estado (não age sobre prescritas); há tipos de parcelamento de "dívida ativa" para débitos judicializados (140–150), indicando tratamento distinto de dívida antiga.

## 20. Contas retidas / em revisão

- **Em revisão**: a conta carrega `cmrv_id` (`ContaMotivoRevisao`) — as consultas de débito da cobrança **carregam o motivo de revisão junto** (colunas `idMotivoRevisao` nas queries) para tratá-la à parte: conta em revisão compõe o débito exibido, mas é **excluída das ações** até a revisão ser resolvida (retificação ou liberação — o vínculo `cmrv_id` também existe no consumo, micromedição).
- **"Retidas"**: termo operacional desta instalação (tabelas `backup_medicao_historico_fat_*_contas_retidas` no `gsan_comercial`) — retenção de emissão/entrega em situações especiais; **não há funcionalidade nomeada "reter conta" no código** — permanece como dúvida a esclarecer com dados/tela (registrada).

## 21. Cliente e responsabilidade pela dívida

**A dívida é do imóvel; a responsabilização é resolvida pela relação cliente×imóvel com papel e vigência** (cadastro.md §3.3): a conta fotografa os clientes da emissão (`cliente_conta`), o estoque pode ser consultado por cliente e papel (`obterDebitoImovelOuCliente(..., codigoCliente, clienteRelacaoTipo, ...)`), e a **negativação atinge o cliente** (CPF/CNPJ) conforme critério (tipo de cliente/CPF). Troca de cliente não move a dívida do imóvel; a responsabilidade de períodos passados é rastreável pelas fotografias. Guias podem ser emitidas diretamente para cliente.

## 22. Estoque de dívida (visão conceitual)

```text
ESTOQUE = Contas (identidade ContaGeral) vencidas em situação exigível (NORMAL; retificadas resolvem-se pela versão corrente)
        + Guias de pagamento não quitadas (GuiaPagamentoGeral)
        + Débitos a cobrar pendentes (DébitoACobrarGeral — inclui prestações de parcelamento)
        + Acréscimos por impontualidade calculados (juros/multa/atualização — tipificados)
        − Pagamentos classificados (via identidades *Geral)
        − Créditos a realizar aplicáveis
        − Cancelamentos / prescrição / inclusões em parcelamento (contas INCLUIDA saem, prestações entram)
        [recortes: revisão em separado; situação especial de cobrança suspende ação, não o saldo]
```

## 23. Estados relevantes (planos distintos — não misturar)

| Plano | Estados estruturais | Fonte |
| ----- | ------------------- | ----- |
| Conta (documento) | NORMAL, RETIFICADA, INCLUIDA, CANCELADA(+POR_RETIFICACAO), DEBITO_PRESCRITO, PRE_FATURADA | `DebitoCreditoSituacao` |
| Débito/crédito lançado | mesmas situações da família débito/crédito | `DebitoCreditoSituacao` (dcst nas entidades) |
| Parcelamento | NORMAL, DESFEITO, CONCLUIDO, CANCELADO | `ParcelamentoSituacao` |
| Situação de cobrança do imóvel | terceirizada(1), cheque devolvido(2), cobrança administrativa(4), negativado SPC/Serasa(11/12), carta enviada(13/14), em análise p/ negativação(15)... com comando, motivo e histórico | `CobrancaSituacao*` (imovel.cbst/cbsp) |
| Ação/documento de cobrança | situação da ação (`CobrancaAcaoSituacao`) e situação do débito no item (`CobrancaDebitoSituacao`), com histórico | `cobranca_documento(_item)(_historico)` |

## 24. Relação com Faturamento

**Recebe**: contas por identidade ContaGeral (com situação, valores, vencimento, imóvel, referência, motivo de revisão), guias e débitos/créditos pelas identidades gerais; acréscimos tipificados. **Devolve**: mudança de situação de contas (INCLUIDA no parcelamento), novos débitos/créditos (prestações, juros, sanções, estornos de desconto — todos `DebitoTipo`/`CreditoTipo` que o faturamento incorpora em contas futuras), guias de entrada. Retificação/cancelamento no faturamento repercutem automaticamente porque a cobrança lê situação pela identidade estável.

## 25. Relação com Arrecadação (prepara o próximo mapa)

Pagamento aponta as mesmas identidades (`cnta_id`→ContaGeral, `gpag_id`, `dbac_id`, `cbdo_id` — o documento de cobrança **recebe pagamento diretamente**). A baixa reduz o estoque por consulta (não há "baixa de ação" separada — a ação se resolve quando a dívida sai do estoque ou a OS encerra); pagamento da entrada mantém o parcelamento (não pago ⇒ desfazimento automático); pagamento de dívida negativada dispara exclusão; pagamento parcial existe como conceito tipificado (`PAGAMENTO_PARCIAL_CONTA(409)`). Detalhes de retorno bancário/classificação ficam para a Arrecadação.

## 26. Relação com Atendimento/OS

Cobrança → OS: cada ação operacional gera OS do tipo definido na ação, vinculada ao documento (`orse.cbdo_id`); fiscalizações idem. OS → Cobrança: encerramento atualiza situação da ligação e da ação; OSs não aceitas registradas (`CobrancaAcaoOrdemServicoNaoAceitas`). Negociação presencial entra por RA (parcelamento originado no atendimento — `parc.rgat_id`); religação via RA/OS com verificação de débito.

## 27. Parametrização

| Regra | Natureza |
| ----- | -------- |
| Critério de elegibilidade (valores/quantidades/dias) | Parametrizado (`cobranca_criterio_linha`) |
| Sequência de ações e serviço de OS de cada ação | Parametrizado (`cobranca_acao` com predecessora) |
| Situações de ligação alvo por ação | Parametrizado |
| Calendário/comandos | Parametrizado (cronogramas, comandos com filtros) |
| Prestações máximas, juros, entrada mínima | Parametrizado por faixa de valor (`parcelamento_qtde_prestacao`) |
| Descontos (faixa/antiguidade/inatividade) | Parametrizado |
| Tipos de débito/crédito e contabilização | Parametrizado (`debito_tipo`/`credito_tipo` com lançamento contábil) |
| Fluxo de desfazimento/estornos | Código (com tipos parametrizados) |
| Negativação (critérios/recortes) | Parametrizado; protocolo em código |
| Acréscimos (fórmula de juros/multa/atualização) | Código (parâmetros do sistema) |

## 28. Variações por companhia

Mesmo padrão dos demais módulos: subclasses `ControladorCobrancaCAEMA/CAERN/CAER/COMPESA/...SEJB` + `ControladorBatchCobranca`; MDBs de arrecadação/cobrança por companhia nos descriptors; campanhas específicas (cartas de solidariedade) e tipos de débito locais (doações a hospitais, TARIFA_CORTADO) como **customizações**; ações/critérios/descontos são **parametrização**; documento/itens/identidades e sequência de ações são **regra geral**.

## 29. Regras estruturantes

1. **A cobrança referencia identidades estáveis** (`*Geral`) — nunca versões físicas; retificação/arquivamento não quebram a dívida.
2. **Ação materializa-se em documento com itens rastreáveis** (dívida a dívida, com valor e situação) — auditoria completa de cada ação.
3. **Sequência de ações é dado** (ação predecessora + critérios + situações-alvo + serviço de OS) — o workflow de cobrança é parametrizado.
4. **Parcelamento preserva a composição original** (itens por identidade/histórico) e a memória financeira integral — desfazer é possível e exato; descontos estornam por tipos próprios.
5. **Entrada não paga desfaz automaticamente** a negociação (batch) — regra estrutural de proteção.
6. **Reparcelamento é novo parcelamento encadeado** com contadores e verificação de cadeia no próprio banco.
7. **Contas em parcelamento mudam de situação (INCLUIDA)** e saem do estoque exigível; prestações entram como novos débitos tipificados.
8. **A dívida é do imóvel; a responsabilização é por papel/vigência do cliente** — e a negativação atinge o cliente da fotografia conforme critério.
9. **Situação especial de cobrança do imóvel** (com comando, motivo e histórico) suspende/redireciona ações sem apagar o saldo.
10. **Corte/religação são OSs geradas e monitoradas pela cobrança** — o estado físico volta pelo encerramento da OS.

## 30. Compatibilidade GSAN → SISAN

| Conceito | Classificação | Motivo |
| -------- | ------------- | ------ |
| Identidade da dívida pelas entidades `*Geral` | PRESERVAR CONCEITO | É o que mantém a dívida "a mesma" através de retificação, cobrança, parcelamento e pagamento (§33 do prompt): a resposta é a identidade estável + fotografias — semântica obrigatória |
| Documento de cobrança com itens rastreáveis | PRESERVAR CONCEITO | Auditoria da ação dívida a dívida; alvo de pagamento |
| Sequência de ações parametrizada (predecessora/critério/situações/OS) | PRESERVAR CONCEITO | Workflow como dado — força do GSAN |
| Parcelamento com composição por item + memória financeira | PRESERVAR CONCEITO | Auditoria, desfazimento exato, migração |
| Desfazimento com estorno tipificado e reativação dos originais | PRESERVAR CONCEITO | Regra financeira central |
| Reparcelamento encadeado com controle de reincidência | PRESERVAR CONCEITO | Identidade histórica da negociação |
| Situação especial de cobrança com histórico/motivo/comando | PRESERVAR CONCEITO | Suspensões auditáveis (judicial etc.) |
| Negativação por cliente com critérios e movimentos | PRESERVAR CONCEITO | Obrigação legal; adapter moderno é forma, não semântica |
| Estoque como consulta (não como tabela de dívida) | POSSÍVEL MODERNIZAÇÃO | Semântica preservada; materializações/projeções podem melhorar desempenho |
| Acréscimos calculados em código | EXIGE APROFUNDAMENTO | Fórmulas de juros/multa/atualização precisam de caracterização ao centavo |
| Contrato de parcelamento (2º mecanismo) | EXIGE APROFUNDAMENTO | Sobreposição com parcelamento clássico; inventariar uso real |
| "Contas retidas" | EXIGE APROFUNDAMENTO | Conceito operacional sem funcionalidade nomeada — confirmar com dados/tela |

## 31. Hipóteses para avaliação futura (não são decisões)

1. **Abstração explícita de "obrigação financeira"** (conta/guia/débito/prestação) unificando o que hoje são 4–5 alvos de item/pagamento — preservando o mapeamento 1:1 com as identidades `*Geral` na migração.
2. **Motor de elegibilidade** isolado (critérios como dados versionados, hoje já paramétricos) com simulação prévia de comandos.
3. **Workflow de ações declarativo** (a sequência já é dado; formalizar estados e transições com histórico imutável).
4. **Negociação (parcelamento) como agregado com eventos imutáveis** (criação, desfazimento, reparcelamento) — a memória financeira atual já aponta esse desenho.
5. **Adapter único para bureaus de crédito** (SPC/Serasa hoje acoplados por movimento/arquivo).

## 32. Cenários críticos para futura caracterização

1. Cobrança simples: conta vencida → elegibilidade → aviso de corte (documento + itens).
2. Pagamento antes da ação (sai do estoque; ação não gera documento).
3. Pagamento após emissão do documento (documento pago diretamente — `cbdo_id`).
4. Sequência completa aviso → corte (OS gerada, encerrada, situação da ligação atualizada).
5. Parcelamento de 2+ contas + guia de entrada + descontos (memória financeira conferida ao centavo).
6. Entrada não paga → desfazimento automático (reativação dos originais + estornos 2441/2442).
7. Desfazimento manual com motivo; prestações pagas permanecem abatidas.
8. Reparcelamento englobando saldo (tipos 42/50; contadores e funções de cadeia).
9. Corte → pagamento → religação (verificação de débito; `religarImovelCortado`).
10. Negativação por comando/critério → pagamento → movimento de exclusão; situação de cobrança 11–15.
11. Retificação de conta já em cobrança (identidade preservada; documento continua válido).
12. Cancelamento e prescrição de conta em cobrança (sai do estoque; estado 8).
13. Conta em revisão (cmrv) exibida no débito mas excluída de ação.
14. Cobrança terceirizada: comando de carteira + situação 1 + pagamento repassado.

## 33. Dúvidas que permanecem

1. Fórmulas exatas de **acréscimos por impontualidade** (juros de mora, multa, atualização monetária) — caracterizar ao centavo (parâmetros do sistema × código).
2. **Contrato de parcelamento** (`contratoparcelamento.*`): escopo real e relação com o parcelamento clássico — inventário próprio.
3. **"Contas retidas"**: processo exato nesta instalação (sem funcionalidade nomeada no código).
4. Regra fina de **exclusão de revisão das ações** (onde cada ação filtra `cmrv`) — confirmar na caracterização.
5. Diferenças reais entre subclasses de companhia da cobrança — inventário junto com os demais módulos.
6. Semântica completa de `CobrancaDebitoSituacao` (situações do item) — catálogo é dado da instalação.

## 34. Evidências principais

```text
Estoque/consulta: IControladorCobranca.obterDebitoImovelOuCliente:98 (imóvel OU cliente + papel); RepositorioCobrancaHBM:328/401 (dcst_idatual in NORMAL/RETIFICADA/INCLUIDA[/PARCELADA]); cmrv_id carregado (:311/347/478)
Documento:       CobrancaDocumento.hbm → cobranca.cobranca_documento (cbac, cast, cacm/caac, empr, imov); CobrancaDocumentoItem.hbm → cobranca_documento_item (cnta_id→ContaGeral, dbac_id, gpag_id, crar_id, cppr_id, cdit_vlitemcobrado, cdit_vlacrescimos, cdst); históricos próprios
Ações:           CobrancaAcao constantes (1–11, 21–23); CobrancaAcao.hbm (cbac_idacaoprecedente, cbct_id, svtp_id, last_id, lest_id); CobrancaAcaoSituacao; comandos/cronogramas (CobrancaAcaoAtividadeComando/Cronograma, CobrancaAtividadeComandoRota, filtros por subcategoria/fiscalização)
Critérios:       CobrancaCriterioLinha.hbm (vl/qt mín/máx, débito automático, cbcl_qtmincontasparcmt)
Parcelamento:    Parcelamento.hbm (memória financeira: parc_vl*); ParcelamentoItem.hbm → parcelamento_item (ContaGeral/ContaHistorico, DebitoACobrarGeral/Historico, CreditoARealizarHistorico, GuiaPagamentoGeral); ParcelamentoSituacao (1–4); ParcelamentoQuantidadePrestacao (qtmax, txjuros, pcminimoentrada); descontos (ParcelamentoFaixaDesconto/DescontoAntiguidade/DescontoInatividade/ParcDesctoInativVista)
Prestações:      DebitoTipo (33 entrada; 40/41/43/45/47 parcelamento; 42/50 reparcelamento; 44 juros; 140–150 dívida ativa; 2441/2442 estorno de descontos; 91/80/94/100 acréscimos; 2500 tarifa cortado); CreditoTipo (descontos 1/2/3/8/10/11)
Desfazer:        IControladorCobranca.desfazerParcelamentosPorEntradaNaoPaga:350; desfazerParcelamentosDebito:352; ParcelamentoMotivoDesfazer/Cancelamento; funções banco verificaseoparcelamentofoireparcelado*
Corte/religação: OrdemServico.cbdo_id; CobrancaAcao.svtp_id; ControladorCobranca.religarImovelCortado:3352; CobrancaAcaoOrdemServicoNaoAceitas
Negativação:     gcom.spcserasa (Controlador/Repositorio); NegativacaoComando/Criterio (+ClienteTipo/CpfTipo/recortes); CobrancaSituacao (1/2/4/11–15)
Terceirizada:    ComandoEmpresaCobrancaConta(+Extensao/Gerencia); CmdEmpresaCobrancaContaLigacaoAguaSituacao; empr_cobr_conta_pagto (migrations)
Companhia:       ControladorCobranca{CAEMA,CAERN,CAER,COMPESA,...}SEJB; ControladorBatchCobranca
Contrato parc.:  cobranca.contratoparcelamento (ContratoParcelamento, ContratoParcelamentoCliente, PrestacaoContratoParcelamento — item cppr_id no documento de cobrança)
```
