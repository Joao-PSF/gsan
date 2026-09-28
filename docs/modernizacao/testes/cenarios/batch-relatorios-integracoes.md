# Cenários Críticos — Processamento, Relatórios e Integrações

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md).
>
> ⚠️ **Nenhum valor desta página foi capturado.** Baseline: `⬜ A CAPTURAR NA FASE 2` em todos os cenários.

🔵 **Leitura da área**: três capacidades de **plataforma**. No Processamento, a compatibilidade está no **modelo** (processo, etapa, unidade, estado, retomada) e **nunca** na tecnologia — EJB, MDB, JMS e Quartz são `C4`, sem teste de equivalência. Nas Integrações, quase tudo é **oráculo 2**: o legado aceita escrita sem identificar a origem.

---

# Processamento

## CEN-BAT-001 — Execução de processo em três níveis, com autorização

- **Criticidade**: P1
- **Etapa OpenGSAN**: 7 — Escala
- **Conceitos relacionados**: processo · etapa · unidade · execução (C1)
- **Objetivo**: caracterizar o modelo de execução do processamento em lote — o que ele registra e em que ordem
- **Pré-condições**: processo mensal com três etapas e ordem definida por dado; processo com **indicador de autorização**; USR-01 com permissão de disparo; USR-11 (usuário técnico de batch)
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Disparo manual de processo por grupo e referência |
  | V2 | Disparo de processo que exige autorização → autorização concedida |
  | V3 | Processo de relatório disparado pelo mesmo framework |

- **Operação GSAN**: iniciar processo → criar execuções de etapas pela ordem → resolver unidades → executar → consolidar
- **Operação conceitual OpenGSAN**: executar processo
- **Observações semânticas**: solicitante gravado · parâmetros gravados · etapas criadas **e sua ordem** · unidades resolvidas (rota no faturamento, localidade na arrecadação) · estado de cada nível · estado de espera por autorização (V2) · autor das escritas feitas pelo processo
- **Localizadores GSAN**: `batch.processo_iniciado`, `funcionalidade_iniciada`, `unidade_iniciada`; `sequencialExecucao`; `Processo.indicadorAutorizacao`; `AGUARDANDO_AUTORIZACAO`; `Usuario.USUARIO_BATCH`
- **Resultado semântico esperado**: 🟢 definição e execução separadas em **três níveis**, cada um com estado, tempos, parâmetros e erro **persistidos**; 🟢 a ordem das etapas **é dado**; 🟢 processos sensíveis exigem **autorização própria**, distinta da permissão de tela; 🟢 as escritas do processo têm como autor o **usuário de batch**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos de execução; timestamps; ⚠️ **não** a ordem das etapas
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 7 → operação
- **Evidência**: [`modulos/batch.md`](../../modulos/batch.md) §2–§7, §14 e §25 itens 1, 2, 4–6, 14, 16 e 20; BAT-01, BAT-02

⚠️ **Disparo agendado** (Quartz) e **paralelismo** pelo pool de MDBs são `C4` — sem cenário de equivalência (ver índice).

---

## CEN-BAT-002 — Falha de unidade, retomada e reprocessamento

- **Criticidade**: P0
- **Etapa OpenGSAN**: 7 — Escala
- **Conceitos relacionados**: retomada por unidade, reprocessamento por etapa (C1)
- **Objetivo**: caracterizar o que acontece quando uma unidade falha — e provar que reprocessar **não refaz** o que terminou
- **Pré-condições**: faturamento de um grupo com três rotas, onde a rota R2 contém um imóvel que provoca falha controlada
- **Entrada**: V1 — execução com falha em R2; V2 — correção da causa e reprocessamento; V3 — reexecução do processo já concluído
- **Operação GSAN**: faturar grupo; reiniciar etapas
- **Operação conceitual OpenGSAN**: executar, retomar e reprocessar
- **Observações semânticas**: estado de cada unidade · exceção persistida · estado final do processo · unidades executadas no reprocessamento · **contas de R1 e R3 não duplicadas** · contas de R2 geradas uma única vez
- **Localizadores GSAN**: `CONCLUIDA_COM_ERRO`; `CONCLUIDO_COM_ERRO`; `reiniciarFuncionalidadesIniciadas`; `codigoRealUnidadeProcessamento`
- **Resultado semântico esperado**: 🟢 a falha é **por unidade**, com exceção persistida, e **as demais seguem**; 🟢 unidade concluída **não é reexecutada**; 🟢 reprocessamento é **por etapa**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores de execução; timestamps; texto técnico da exceção
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 7 → operação — *retomada por unidade e reprocessamento por etapa comprovados*
- **Evidência**: [`modulos/batch.md`](../../modulos/batch.md) §12, §18 e §25 itens 7–10 e 18; BAT-02

---

## CEN-BAT-003 — Atomicidade dentro da unidade

- **Criticidade**: P0
- **Etapa OpenGSAN**: 7 — Escala
- **Conceitos relacionados**: atomicidade intra-unidade (C5 — pendente) · **CAND-02**
- **Objetivo**: descobrir **o que permanece aplicado** do trabalho de negócio quando a unidade falha no meio
- **Pré-condições**: rota com N imóveis, onde o imóvel k (1 < k < N) provoca falha controlada
- **Entrada**: execução do faturamento da rota
- **Operação GSAN**: `faturarGrupoFaturamento` para a unidade
- **Operação conceitual OpenGSAN**: executar unidade
- **Observações semânticas**: contas dos imóveis 1…k−1 · efeitos colaterais (lançamentos, consumos) · estado da unidade · o que um reprocessamento faz com o que ficou
- **Localizadores GSAN**: MDB `NotSupported` (`descriptors/batchFaturarGrupoFaturamento/META-INF/ejb-jar.xml`); `faturarGrupoFaturamento` com atributo `Required`
- **Resultado semântico esperado**: 🟢 o estado da unidade é gravado **em transação própria**. ❔ **Se o trabalho de negócio é atômico dentro da unidade não está comprovado** — chamadas aninhadas, `RequiresNew` ou commits explícitos poderiam quebrá-lo
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos
- **Divergência permitida**: nenhuma aprovada — ⚠️ **CAND-02**
- **Oráculo**: ⚠️ **PENDENTE DE CARACTERIZAÇÃO** — 🔴 **não** é oráculo 2: não se constrói teste como se a divergência existisse. Se a baseline mostrar efeitos parciais, garantir atomicidade no OpenGSAN exige divergência **aprovada**; se mostrar atomicidade, o cenário passa a oráculo 1
- **Gate que este cenário protege**: 7 → operação
- **Evidência**: [`modulos/batch.md`](../../modulos/batch.md) §11 e §25 item 11; [compatibilidade §20.3](../../compatibilidade/gsan-opengsan.md)

---

## CEN-BAT-004 — Execução duplicada com os mesmos parâmetros

- **Criticidade**: P0
- **Etapa OpenGSAN**: 7 — Escala
- **Conceitos relacionados**: processamento em lote (C1)
- **Objetivo**: descobrir se o legado impede iniciar duas vezes o mesmo processo com os mesmos parâmetros
- **Pré-condições**: grupo G1, referência R, ainda não faturados
- **Entrada**: V1 — dois disparos de faturamento de G1/R **em sequência**; V2 — **simultâneos**
- **Operação GSAN**: iniciar processo duas vezes
- **Operação conceitual OpenGSAN**: iniciar processo
- **Observações semânticas**: o segundo disparo foi recusado? · contas geradas por imóvel (uma ou duas?) · salvaguarda que atuou (framework ou módulo dono)
- **Localizadores GSAN**: a identificar na Fase 1
- **Resultado semântico esperado**: 🟢 a proteção **no nível da unidade** existe; ❔ **no nível do processo, não comprovada**. 🔵 Salvaguardas de negócio podem existir nos módulos donos (situação da conta, referência já faturada) — são regra do módulo, não do framework
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos
- **Divergência permitida**: nenhuma
- **Oráculo**: ⚠️ **PENDENTE DE CARACTERIZAÇÃO** — se a baseline mostrar **faturamento em dobro**, reproduzi-lo seria absurdo e protegê-lo exige **divergência registrada**; o candidato só é aberto se a evidência aparecer
- **Gate que este cenário protege**: 7 → operação
- **Evidência**: [`modulos/batch.md`](../../modulos/batch.md) §13 e §25 item 12

---

## CEN-BAT-005 — Faturamento em lote igual à soma dos individuais

- **Criticidade**: P0
- **Etapa OpenGSAN**: 7 — Escala
- **Conceitos relacionados**: cálculo individual × lote (C1)
- **Objetivo**: provar que o lote é **orquestração do mesmo cálculo**, não outra regra
- **Pré-condições**: grupo G1 com as rotas e os imóveis dos cenários CEN-FAT-001 a CEN-FAT-006
- **Entrada**: faturamento do grupo inteiro em lote
- **Operação GSAN**: `FATURAR_GRUPO` — MDB por rota → `faturarGrupoFaturamento` → `gerarConta` por imóvel
- **Operação conceitual OpenGSAN**: faturar grupo
- **Observações semânticas**: para cada imóvel, a conta produzida pelo lote comparada com a produzida individualmente · totais por rota e por grupo
- **Localizadores GSAN**: `descriptors/batchFaturarGrupoFaturamento`; `faturarGrupoFaturamento`; `gerarConta`
- **Resultado semântico esperado**: 🟢 **mesmo cálculo no individual e no lote** — cada conta do lote é **idêntica** à individual correspondente
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos; ordem de processamento das unidades
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 7 → operação — *lote produz resultado idêntico à soma dos individuais*
- **Evidência**: [`modulos/faturamento.md`](../../modulos/faturamento.md) §18; [`modulos/batch.md`](../../modulos/batch.md) §18 e §25 item 17

---

# Relatórios

## CEN-REL-001 — Acesso ao artefato de relatório

- **Criticidade**: P0
- **Etapa OpenGSAN**: 2 — Núcleo operacional
- **Conceitos relacionados**: artefato (C1) · acesso ao artefato (C3)
- **Objetivo**: caracterizar quem consegue recuperar um relatório gerado — e corrigir o acesso indevido confirmado
- **Pré-condições**: relatório gerado **em lote** por USR-01 e persistido; USR-03 autenticado; requisição **sem usuário autenticado**
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | USR-01 consulta seus relatórios e baixa o seu |
  | V2 | USR-03 baixa informando o identificador de execução **de USR-01** |
  | V3 | Requisição **anônima** com o mesmo identificador |

- **Operação GSAN**: consulta de relatórios por usuário; download do artefato
- **Operação conceitual OpenGSAN**: entregar artefato ao solicitante
- **Observações semânticas**: artefato entregue (sim/não) · conteúdo · lista de relatórios de cada usuário
- **Localizadores GSAN**: `RelatorioGerado`; `idFuncionalidadeIniciada`; exceção `relatorio` no filtro (`FiltroSegurancaAcesso:279`, `:451–456`); `urls_sem_usuario_na_sessao.properties:7`
- **Resultado semântico esperado**: V1 — o solicitante obtém o próprio relatório. V2 e V3 — 🟢 **no GSAN o artefato é entregue** (achado **confirmado**, cadeia completa de filtros verificada); **no OpenGSAN deve ser negado**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2 — ⚠️ a falha está **confirmada por análise da cadeia de filtros**, mas a baseline de comportamento em execução ainda precisa ser capturada
- **Normalizações**: metadados do arquivo; data de geração
- **Divergência permitida**: **D-03** (V2, V3)
- **Oráculo**: **1** (V1) · **2** (V2, V3)
- **Gate que este cenário protege**: 2 → 3 — *artefato inacessível a quem não é dono*
- **Evidência**: [`modulos/relatorios.md`](../../modulos/relatorios.md) §15–§17 e §29 itens 10, 12–14; achado 13; [D-03](../../compatibilidade/divergencias-aprovadas.md)

---

## CEN-REL-002 — Resumos de faturamento e de arrecadação por competência

- **Criticidade**: P1
- **Etapa OpenGSAN**: 7 — Escala
- **Conceitos relacionados**: definição · solicitação · artefato (C1) — relatório pertence ao módulo dono do dado
- **Objetivo**: caracterizar os resumos financeiros usados na conferência gerencial
- **Pré-condições**: competência R faturada e arrecadada com a massa dos cenários FAT e ARR
- **Entrada**: V1 — resumo de faturamento de R; V2 — resumo de arrecadação de R; ambos com os mesmos filtros
- **Operação GSAN**: `RelatorioResumoFaturamento`; `RelatorioResumoArrecadacao`
- **Operação conceitual OpenGSAN**: produzir resumo da competência
- **Observações semânticas**: **datasource** — agrupamentos e totais por agrupamento · total geral
- **Localizadores GSAN**: `src/gcom/relatorio/faturamento/RelatorioResumoFaturamento.java`; `src/gcom/relatorio/arrecadacao/RelatorioResumoArrecadacao.java`
- **Resultado semântico esperado**: para a mesma competência e os mesmos filtros, **os mesmos agrupamentos e os mesmos totais**. ❔ **A origem dos dados do resumo não está comprovada** — tabela de resumo pré-calculada ou consulta direta. A caracterização registra qual, porque isso define se o resumo confere com CEN-FAT-001 e CEN-ARR-010 ou com um instantâneo anterior
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: data de geração; paginação; 🔴 **nunca comparação do PDF**
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — pelo *datasource*, **ao centavo**
- **Gate que este cenário protege**: 7 → operação — *encerramento confere com os resumos financeiros*
- **Evidência**: 🟢 classes no **código público** (`src/gcom/relatorio/`), localizadas nesta execução. ⚠️ Substitui os resumos `sp*_gerar_res_*`, que o inventário do banco classifica como **customização da instalação de referência** — cenário **derivado**

---

# Integrações

## CEN-INT-001 — Coleta móvel de leitura

- **Criticidade**: P0
- **Etapa OpenGSAN**: 3 — Medição
- **Conceitos relacionados**: coleta de leitura em campo (C1) · entrada de campo sem identificação (C3)
- **Objetivo**: caracterizar o ciclo do coletor e o efeito das leituras recebidas — e exigir que a origem seja identificada
- **Pré-condições**: rota R1 liberada para leitura; dispositivo **não identificado** (a instância de referência não exige identificação)
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Baixar arquivo da rota |
  | V2 | Enviar movimento com leituras normais e com anormalidade |
  | V3 | Finalizar a leitura da rota |
  | V4 | Enviar movimento **sem qualquer identificação** de dispositivo ou usuário |

- **Operação GSAN**: `ProcessarRequisicaoDipositivoMovelAction` — opcodes `PACOTE_BAIXAR_ARQUIVO`, `ATUALIZAR_MOVIMENTO`, `FINALIZAR_LEITURA`
- **Operação conceitual OpenGSAN**: receber leituras de dispositivo identificado
- **Observações semânticas**: conteúdo do arquivo da rota · leituras gravadas · consumo resultante (ver CEN-MIC-001) · rota liberada para faturamento após V3 · aceitação de V4
- **Localizadores GSAN**: `ProcessarRequisicaoDipositivoMovelAction:67–116`; exceções nos filtros (`FiltroSessaoExpirada:47–53`, `FiltroSegurancaAcesso:186–193`)
- **Resultado semântico esperado**: V1–V3 — leituras gravadas alimentam o consumo e a finalização libera a rota. V4 — 🟢 **no GSAN não há verificação de credencial** antes do despacho; **no OpenGSAN deve ser recusado**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: formato de transporte — comparar o **conteúdo**
- **Divergência permitida**: **D-05** (V4)
- **Oráculo**: **1** (V1–V3) · **2** (V4)
- **Gate que este cenário protege**: 3 → 4 — *leitura de campo rejeitada sem identidade de dispositivo*
- **Evidência**: [`modulos/integracoes.md`](../../modulos/integracoes.md) §3 e §10 itens 1–3; achado 15; [D-05](../../compatibilidade/divergencias-aprovadas.md)

⚠️ **A confirmação de recebimento com variação por código de empresa** fica `A COMPLEMENTAR` (variante por companhia).

---

## CEN-INT-002 — Telemetria

- **Criticidade**: P1
- **Etapa OpenGSAN**: 3 — Medição
- **Conceitos relacionados**: leitura remota (C1) · entrada sem identificação (C3)
- **Objetivo**: caracterizar o processamento de mensagem de telemetria e o tratamento de mensagem inválida
- **Pré-condições**: imóvel com equipamento de telemetria cadastrado
- **Entrada**: V1 — mensagem bem formada; V2 — mensagem malformada; V3 — mensagem sem identificação da origem
- **Operação GSAN**: `ProcessarRequisicaoTelemetriaAction`
- **Operação conceitual OpenGSAN**: receber leitura remota
- **Observações semânticas**: leitura gravada · registro de erro · efeito da mensagem malformada
- **Localizadores GSAN**: `ProcessarRequisicaoTelemetriaAction:50–53`; `telemetria_mov`, `telemetria_mov_reg`, `telemetria_log`, `telemetria_ret_mot`
- **Resultado semântico esperado**: V1 — leitura gravada. V2 — ❔ **comportamento não caracterizado**. V3 — gravada **sem identificar a origem** no GSAN; **recusada** no OpenGSAN
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: timestamps de recepção
- **Divergência permitida**: **D-05** (V3)
- **Oráculo**: **1** (V1, V2) · **2** (V3)
- **Gate que este cenário protege**: 3 → 4
- **Evidência**: [`modulos/integracoes.md`](../../modulos/integracoes.md) §3.2 e §10 itens 6–7; [D-05](../../compatibilidade/divergencias-aprovadas.md)

---

## CEN-INT-003 — API de ordem de serviço

- **Criticidade**: P0
- **Etapa OpenGSAN**: 3 — Medição
- **Conceitos relacionados**: API de OS (C3)
- **Objetivo**: registrar que a API de OS aceita escrita sem credencial e compartilha estado entre requisições — e exigir o contrário
- **Pré-condições**: OS programada em estado que permite encerramento
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | `encerrar` **sem credencial** |
  | V2 | `fotos` e `programadas` sem credencial |
  | V3 | Duas requisições **concorrentes** com parâmetros distintos |

- **Operação GSAN**: `OrdemServicoAPI` — despacho por `getRequestURI().contains(...)`
- **Operação conceitual OpenGSAN**: executar operação de OS por dispositivo autenticado
- **Observações semânticas**: operação executada (sim/não) · situação da OS depois · dados devolvidos · **resposta de uma requisição contaminada pela outra** (V3)
- **Localizadores GSAN**: `OrdemServicoAPI:32–34` (`request`, `response`, `resposta` como **campos de instância**); `:36–58`
- **Resultado semântico esperado**: V1/V2 — 🟢 **no GSAN, executadas sem credencial**; no OpenGSAN, **recusadas**. V3 — no GSAN o estado é **compartilhado** (achado de análise estática — a manifestação em execução **a capturar**); no OpenGSAN, cada requisição é **independente**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: **D-04** (V1, V2) · **D-10** (V3)
- **Oráculo**: **2**
- **Gate que este cenário protege**: 3 → 4
- **Evidência**: [`modulos/integracoes.md`](../../modulos/integracoes.md) §4.2, §8.3, §8.5 e §10 itens 17–18; achados 12 e 17

---

## CEN-INT-004 — Integração com sistema parceiro por banco compartilhado (UPA/SAM)

- **Criticidade**: P1
- **Etapa OpenGSAN**: 3 — Medição
- **Conceitos relacionados**: efeito de encerramento de OS (C1) · escrita no banco do parceiro (C3)
- **Objetivo**: caracterizar a exportação e o retorno — e registrar a falha silenciosa que o OpenGSAN deve eliminar
- **Pré-condições**: OS com movimento pendente de exportação; banco do parceiro **simulado**
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Exportação de movimento pendente |
  | V2 | Exportação de registro **já existente** no parceiro |
  | V3 | Retorno com login de usuário **válido** |
  | V4 | Retorno com login **inválido** |
  | V5 | Empresa sem e-mail cadastrado |

- **Operação GSAN**: exportação por **escrita direta** no banco do parceiro; retorno que encerra a OS
- **Operação conceitual OpenGSAN**: entregar e receber por contrato explícito
- **Observações semânticas**: registro no parceiro · indicador de movimento · OS encerrada (sim/não) · **erro registrado e observável** (V2, V4, V5) · continuidade do processo
- **Localizadores GSAN**: `RepositorioIntegracaoHBM:88–108` (`session.insert`, `ConstraintViolationException` engolida); `indicadorMovimento` 1→2
- **Resultado semântico esperado**: V1/V3 — exportado e encerrado. V2 — 🟢 violação **engolida**. V4 — 🟢 OS **não** encerrada e o processo **continua em silêncio** (`continue` + saída de console). No OpenGSAN: idempotência por **chave de negócio** e erro **durável e observável**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos
- **Divergência permitida**: **D-12** (V2, V4, V5)
- **Oráculo**: **1** (V1, V3) · **2** (V2, V4, V5)
- **Gate que este cenário protege**: 3 → 4
- **Evidência**: [`modulos/integracoes.md`](../../modulos/integracoes.md) §6 e §10 itens 11–15; achado 19

---

## CEN-INT-005 — API de pagamento: autenticação do chamador

- **Criticidade**: P0
- **Etapa OpenGSAN**: 5 — Recebimento
- **Conceitos relacionados**: API de pagamento (C3)
- **Objetivo**: registrar que o filtro da API de pagamento não autentica o chamador — e exigir autenticação real
- **Pré-condições**: servlet `/api/pagamentoCredito` ativo
- **Entrada**: V1 — chamada de origem "permitida"; V2 — de origem não permitida; V3 — sem credencial alguma
- **Operação GSAN**: `PagamentoCreditoFilter` → servlet
- **Operação conceitual OpenGSAN**: receber pagamento de parceiro autenticado
- **Observações semânticas**: decisão do filtro · decisão do servlet · efeito produzido · protocolo aceito
- **Localizadores GSAN**: `PagamentoCreditoFilter:18–33` — valida `req.getRequestURL()`, isto é, o **host do próprio servidor**, e **não bloqueia**, só marca atributo
- **Resultado semântico esperado**: 🟢 no GSAN o filtro **não identifica o chamador** e **não recusa**; a recusa (403) ocorre adiante, no servlet, por outro critério. No OpenGSAN: **autenticação real do chamador, com recusa no próprio filtro**, e TLS obrigatório
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: **D-06** · **D-09**
- **Oráculo**: **2**
- **Gate que este cenário protege**: 5 → 6
- **Evidência**: [`modulos/integracoes.md`](../../modulos/integracoes.md) §4.1 e §10 item 16; achado 3

---

## CEN-INT-006 — SMS por tipo de mensagem

- **Criticidade**: P1
- **Etapa OpenGSAN**: 6 — Cobrança
- **Conceitos relacionados**: notificação ao cliente (C1) · SMS por tipo (C3)
- **Objetivo**: registrar o defeito funcional que alcança o cliente — todo SMS envia o mesmo texto — e exigir que cada tipo envie sua mensagem
- **Pré-condições**: provedor de SMS **simulado** que registra o que recebe; cliente com telefone **sintético**
- **Entrada**: um envio para cada tipo de mensagem suportado (vencimento, corte, confirmação de cadastro)
- **Operação GSAN**: `ServicoSMS` — `getJson(...)`
- **Operação conceitual OpenGSAN**: notificar o cliente
- **Observações semânticas**: texto enviado por tipo · protocolo de transporte · origem da credencial usada
- **Localizadores GSAN**: `ServicoSMS` — `getJson` **ignora `tipoMensagem`**; URL `http://` fixa (`:35`); `inicializarPropriedades()` devolve nulo
- **Resultado semântico esperado**: 🟢 no GSAN **todos os tipos enviam o texto de cadastro no portal**, por **HTTP sem TLS**. No OpenGSAN: **cada tipo envia sua mensagem**, sempre com TLS
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificador da mensagem no provedor
- **Divergência permitida**: **D-13** · **D-09**
- **Oráculo**: **2** — ⚠️ a única divergência que corrige **defeito funcional**, não de segurança
- **Gate que este cenário protege**: 6 → 7
- **Evidência**: [`modulos/integracoes.md`](../../modulos/integracoes.md) §7 (padrão G) e §10 item 20; [D-13](../../compatibilidade/divergencias-aprovadas.md)

🔴 **Nenhum telefone real** — o `main()` do legado contém um número verdadeiro; ele **não** é reutilizado.

---

## CEN-INT-007 — Requisição GIS assinada

- **Criticidade**: P1
- **Etapa OpenGSAN**: 8 — Canais e evoluções
- **Conceitos relacionados**: integração GIS (C3)
- **Objetivo**: registrar que a assinatura da integração GIS não tem frescor nem cobre a requisição — e exigir assinatura com escopo e expiração
- **Pré-condições**: par de chaves de teste; usuário existente e usuário inexistente
- **Entrada**: V1 — assinatura válida; V2 — assinatura inválida; V3 — válida com usuário inexistente; V4 — **reenvio** de requisição válida capturada anteriormente
- **Operação GSAN**: `ProcessarRequisicaoGisAction`, `ProcessarCoordenadasGisAction`
- **Operação conceitual OpenGSAN**: atender requisição geográfica autenticada
- **Observações semânticas**: aceitação · mensagem de erro · **aceitação do reenvio** (V4) · dados devolvidos ou alterados
- **Localizadores GSAN**: assinatura `SHA1withDSA` sobre **apenas o login**; mensagem `atencao.assinatura.invalida`
- **Resultado semântico esperado**: 🟢 no GSAN a assinatura cobre **só o login**, sem corpo, nonce ou timestamp — funciona como **portador estático**, e V4 **deve ser aceito**. No OpenGSAN, V4 é **recusado**. ❔ Se a integração **altera** dado ou só consulta: **a capturar**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: **D-11**
- **Oráculo**: **2** (V4) · **1** (V1–V3, quanto aos dados devolvidos)
- **Gate que este cenário protege**: etapa 8 — ⚠️ GIS é evolução futura, **não** dependência do núcleo comercial
- **Evidência**: [`modulos/integracoes.md`](../../modulos/integracoes.md) §3.2, §8.4 e §10 itens 8–10; achado 16
