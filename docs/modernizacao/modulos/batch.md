# Módulo Batch — Mapa Funcional

Elaborado em 2026-08-14 (Fase 0). Objetivo: compreender o **modelo funcional de processamento em lote** — não repetir o inventário técnico já registrado em [arquitetura-legada.md](../arquitetura/arquitetura-legada.md). Fontes: `gcom.batch` (framework + subpacotes por módulo), `gcom.tarefa`, Actions de `gcom.gui.batch`, mapeamentos e DDL.

**Convenção**: 🟢 fato comprovado · 🔵 interpretação funcional sustentada · 🟡 hipótese · ❔ não compreendido (§29).

## 1. Responsabilidade e fronteiras

🔵 O Batch é **infraestrutura de orquestração de processamento**, não dono de regra de negócio: ele decide *quando* um processo roda, *como* é dividido, *em que ordem*, *com que estado* e *o que fazer quando falha* — e delega a regra ao controlador do módulo dono. Comprovação direta: os MDBs de processo apenas recebem a mensagem e chamam o controlador de negócio (ex.: `BatchFaturarGrupoFaturamentoMDB.onMessage` → `ControladorFaturamento.faturarGrupoFaturamento(...)`).

🔵 Quatro camadas que **não devem ser confundidas** (e que no GSAN aparecem separadas):

| Camada | No GSAN | Papel |
| ------ | ------- | ----- |
| Agendador | Quartz (`Tarefa`/`TarefaBatch` implementam `Job`) | decide **quando** iniciar |
| Orquestrador/controle | `ControladorBatchSEJB` + tabelas do schema `batch` | controla **estado, etapas e unidades** |
| Transporte/distribuição | JMS (fila por processo) + MDBs | **distribui** o trabalho |
| Regra de negócio | Controlador do módulo dono | **executa** a regra |

## 2. Modelo conceitual

🟢 Seis conceitos, com **separação explícita entre definição e execução**:

```text
DEFINIÇÃO (catálogo, schema batch)              EXECUÇÃO (instâncias)
────────────────────────────────────            ─────────────────────────────────
Processo                                        ProcessoIniciado
  ├ descrição / abreviada                         ├ processo (proc_id)
  ├ indicadorUso                                  ├ usuário solicitante (usur_id)
  ├ indicadorAutorizacao                          ├ situação (prst_id)
  ├ limite                                        ├ processoIniciadoPrecedente (proi_idprecedente)
  ├ prioridade                                    ├ agendamento / início / término / comando
  └ nomeArquivoBatch                              └ código do grupo de processo
        │                                                  │
ProcessoFuncionalidade  (etapas)                FuncionalidadeIniciada
  ├ funcionalidade → seguranca.Funcionalidade      ├ processoIniciado (proi_id)
  ├ unidadeProcessamento (unpr_id)                 ├ processoFuncionalidade (prfn_id)
  ├ sequencialExecucao                             ├ situação (fnst_id)
  ├ orientação                                     ├ início / término
  └ indicadorUso                                   ├ parâmetros (fuin_parametros)
        │                                          └ descrição da exceção (fuin_dserro)
UnidadeProcessamento (tipo de partição)         UnidadeIniciada
  ├ descrição / abreviada                          ├ unidadeProcessamento (unpr_id)
  └ indicadorUso                                   ├ funcionalidadeIniciada (fuin_id)
                                                   ├ situação (unst_id)
                                                   ├ início / término
                                                   └ codigoRealUnidadeProcessamento
```

🟢 **Achado relevante**: `ProcessoFuncionalidade` referencia **`seguranca.acesso.Funcionalidade`** — as etapas do processo em lote **são as mesmas funcionalidades do modelo de segurança**, não um catálogo paralelo. 🔵 Isso unifica "o que se pode executar" entre tela e batch.

## 3. Processo × execução

🟢 A separação existe e é completa em três níveis (processo, etapa, unidade), cada um com **entidade de definição** e **entidade de execução com estado, tempos e erro próprios**. 🔵 Consequência funcional: o GSAN sabe responder, para cada execução, *quais etapas rodaram*, *quais partições foram concluídas* e *onde falhou* — sem depender de log técnico.

🟢 `ProcessoIniciado.processoIniciadoPrecedente` permite **encadear execuções** (um processo iniciado aponta o anterior) — 🔵 usado em encadeamento mensal/eventual (visto em `InserirProcessoMensalEventualAction`).

## 4. Processo e funcionalidades (etapas)

🟢 `ProcessoFuncionalidade` traz **`sequencialExecucao`** e `orientacao` — 🔵 a **ordem das etapas é dado**, não código. Cada etapa aponta a `UnidadeProcessamento` que define **como aquela etapa é particionada**. 🟢 `FuncionalidadeIniciada` guarda **os parâmetros da execução** (`fuin_parametros`) e a **exceção** (`fuin_dserro`).

❔ Se há **dependência condicional** entre etapas (além da ordem sequencial) e se a falha de uma etapa bloqueia a seguinte **não foi comprovado**.

## 5. Unidades de processamento

🟢 `UnidadeProcessamento` é o **tipo de partição** (definição, com descrição e indicador de uso); `UnidadeIniciada` é a **partição concreta executada**, identificada por **`codigoRealUnidadeProcessamento`** (o identificador real do objeto particionado).

🟢 **Quem decide as unidades é a tarefa do processo**: `TarefaBatch` declara dois métodos abstratos — `pesquisarTodasUnidadeProcessamentoBatch()` e **`pesquisarTodasUnidadeProcessamentoReinicioBatch()`** — implementados por cada tarefa concreta. 🔵 Ou seja: a **estratégia de particionamento é por processo**, e existe uma consulta específica para o caso de **reinício** (unidades que ainda precisam rodar).

🟢 Exemplos comprovados de unidade: **rota** (faturamento — `colecaoRotasParaExecucao`) e **localidade** (encerramento da arrecadação — `colecaoIdsLocalidades`), ambas recebidas pelo parâmetro genérico `ConstantesSistema.COLECAO_UNIDADES_PROCESSAMENTO_BATCH`.

🟢 **Proteção contra reexecução da mesma unidade**: `ControladorBatchSEJB.iniciarUnidadeProcessamentoBatch(idFuncionalidadeIniciada, idUnidadeProcessamento, codigoRealUnidadeProcessamento)` cria a `UnidadeIniciada` em `EM_PROCESSAMENTO`, **mas antes verifica se já existe unidade com o mesmo `codigoRealUnidadeProcessamento` em situação `CONCLUIDA`** — nesse caso chama `encerrarUnidadeIniciadaJaExecutada` e o fluxo trata a exceção `"Unidade já executada"` como **conclusão normal** (não como erro) em `encerrarUnidadeProcessamentoBatch`. 🔵 Este é o mecanismo de **retomada segura**: reprocessar um processo não refaz as unidades já concluídas.

## 6. Formas de disparo

🟢 Caminhos comprovados:

| Caminho | Evidência | Observação |
| ------- | --------- | ---------- |
| **Manual pela interface** | `gui/batch/InserirProcessoMensalEventualAction` (cria `ProcessoIniciado`, define situação, **grava o usuário logado** e opcionalmente o processo precedente); `ExibirInserirProcessoFaturamentoComandadoAction` | Tela dedicada de processo mensal/eventual e de faturamento comandado |
| **Autorização prévia** | `Processo.indicadorAutorizacao` + situações `AGUARDANDO_AUTORIZACAO` + `AutorizarProcessoIniciadoAction` + `ControladorBatchSEJB.autorizarProcessoIniciado(...)` | Há processos que **exigem autorização** antes de executar |
| **Agendamento (Quartz)** | `TarefaBatch extends Tarefa implements Job`: `execute(JobExecutionContext)` lê do **JobDataMap** `idFuncionalidadeIniciada`, `usuario` e `parametroTarefa`; `agendarTarefaBatch()` nas tarefas | O agendador dispara a **tarefa da etapa**, não o processo inteiro |
| **Mensageria (JMS/MDB)** | `TarefaBatch.enviarMensagemControladorBatch(...)` → `ServiceLocator.enviarMensagemJms(queueMDB, parametros)`; MDBs por processo (`Batch*MDB`) | Distribui o trabalho às unidades |
| **Disparo por módulo de negócio** | `ControladorSpcSerasaSEJB` cria `ProcessoIniciado`; `GerarResumoDevedoresDuvidososAction` idem | Fluxos de negócio podem iniciar processos |
| **Encadeamento** | `ProcessoIniciado.processoIniciadoPrecedente` | Execução encadeada a outra |

🟢 **Relatórios usam o mesmo framework** de forma assíncrona: `iniciarRelatoriosAgendados`, `iniciarProcessoRelatorio(TarefaRelatorio)`, `iniciarProcessoRelatorioControleAutorizacao`, `FuncionalidadeIniciadaRelatorio`, entidades `Relatorio`/`RelatorioGerado`, telas de status e de autorização. 🔵 Fronteira registrada: **o framework batch também é infraestrutura de geração pesada assíncrona** — o mapa de Relatórios é atividade seguinte (não executada aqui).

## 7. Ciclo de vida e estados

🟢 Três máquinas de estado distintas, com constantes próprias:

```text
ProcessoSituacao:        AGENDADO(4) · EM_ESPERA(3) · INICIO_A_COMANDAR(5) · EM_PROCESSAMENTO(1)
                         CONCLUIDO(2) · CONCLUIDO_COM_ERRO(6) · EXECUCAO_CANCELADA(7) · AGUARDANDO_AUTORIZACAO(8)

FuncionalidadeSituacao:  AGENDADA(5) · EM_ESPERA(3) · EM_PROCESSAMENTO(1)
                         CONCLUIDA(2) · CONCLUIDA_COM_ERRO(4) · EXECUCAO_CANCELADA(6) · AGUARDANDO_AUTORIZACAO(7)

UnidadeSituacao:         EM_ESPERA(3) · EM_PROCESSAMENTO(1) · CONCLUIDA(2) · CONCLUIDA_COM_ERRO(4)
```

🔵 Leituras funcionais: (a) **"concluído com erro" é estado terminal distinto de "cancelado"** — o processo termina, mas registra que houve falha; (b) **`AGUARDANDO_AUTORIZACAO` existe em processo e etapa**, confirmando o workflow de autorização; (c) a unidade tem o conjunto mínimo (sem cancelamento/autorização) — 🔵 o controle de autorização e cancelamento vive nos níveis superiores; (d) `INICIO_A_COMANDAR` sugere um estágio entre agendado e em processamento (comando emitido) — coerente com `proi_tmcomando`.

🟢 Encerramento: `encerrarProcessosIniciados()` e `encerrarFuncionalidadesIniciadas()` no `ControladorBatchSEJB` — 🔵 há rotina de encerramento que consolida os níveis superiores a partir do estado das unidades.

## 8. Parâmetros

🟢 **Mecanismo genérico**, não argumentos por processo: `TarefaBatch` carrega um conjunto de parâmetros (`parametroTarefa`, vindo do JobDataMap) e as tarefas concretas leem por nome — `getParametro("faturamentoGrupo")`, `getParametro("atividade")`, `getParametro(ConstantesSistema.COLECAO_UNIDADES_PROCESSAMENTO_BATCH)`, `getParametro` de coleção de localidades. 🟢 Os parâmetros da execução são **persistidos** em `FuncionalidadeIniciada.fuin_parametros`.

🔵 Isso é um achado importante: o GSAN tem **contexto de execução tipado por nome e persistido**, o que sustenta reinício e auditoria do que foi pedido.

## 9. Orquestração e dependências

🔵 Fluxo comprovado, ponta a ponta:

```text
Action (usuário logado)  ──► ProcessoIniciado (usuário, situação, precedente opcional)
        │
ControladorBatchSEJB  ──►  FuncionalidadeIniciada por ProcessoFuncionalidade (ordem = sequencialExecucao)
        │                    (parâmetros persistidos em fuin_parametros)
        ▼
Quartz agenda TarefaBatch (JobDataMap: idFuncionalidadeIniciada, usuario, parametroTarefa)
        │
TarefaBatch.executar():  resolve UNIDADES (pesquisarTodasUnidadeProcessamentoBatch
        │                 ou ...ReinicioBatch) e envia MENSAGEM JMS por lote/unidade
        ▼
MDB do processo (Batch*MDB.onMessage)
        ├─ ControladorBatch.iniciarUnidadeProcessamentoBatch  → UnidadeIniciada EM_PROCESSAMENTO
        │      └─ se já CONCLUIDA com mesmo codigoReal → encerra como já executada
        ├─ Controlador do MÓDULO DONO executa a regra de negócio
        └─ ControladorBatch.encerrarUnidadeProcessamentoBatch(excecao, id, executouComErro)
               ├─ sem erro → CONCLUIDA
               └─ com erro → CONCLUIDA_COM_ERRO + inserirLogExcecaoFuncionalidadeIniciada
        ▼
encerrarFuncionalidadesIniciadas / encerrarProcessosIniciados  → consolida níveis superiores
```

🟢 A **ordem das etapas** é dada por `sequencialExecucao`. ❔ Dependência condicional e bloqueio da etapa seguinte por falha da anterior não comprovados.

## 10. Paralelismo

🟢 O mecanismo é **mensagem por unidade/lote para MDBs**: cada tarefa envia mensagens JMS para a fila do processo, e o container (JBoss) processa com **múltiplas instâncias de MDB** — 🔵 o paralelismo é do pool de MDBs, não de threads gerenciadas pelo código. 🟢 `Processo.limite` e `Processo.prioridade` existem como parâmetros da definição — 🔵 provavelmente limite de execução/concorrência e prioridade de fila, mas ❔ a semântica exata de `proc_limite` **não foi comprovada**.

🟢 **Proteção contra dupla execução da mesma unidade** existe (§5). ❔ **Não comprovado**: se há bloqueio para duas execuções simultâneas do **mesmo processo** (ex.: mesmo grupo + referência), nem lock explícito.

## 11. Transações e commits

🔵 **A execução não é uma transação única** — a evidência estrutural é forte: cada unidade é uma mensagem processada por um MDB, com transação do container por mensagem; o estado (`UnidadeIniciada`) é gravado no **início** e atualizado no **fim** de cada unidade, o que exige commits intermediários para ser observável. 🟢 O tratamento de exceção por unidade (`encerrarUnidadeProcessamentoBatch(excecao, ...)`) grava situação de erro e log — comportamento incompatível com rollback total.

🔵 Consequência funcional: **falhas deixam trabalho parcialmente aplicado** — e é exatamente por isso que existe a retomada por unidade (unidades `CONCLUIDA` não são refeitas). ❔ Granularidade de commit **dentro** de uma unidade (por lote de N registros) não foi verificada e varia por processo — deve ser tratada caso a caso na caracterização.

## 12. Falha, recuperação e reprocessamento

🟢 Falha de unidade → `CONCLUIDA_COM_ERRO` + `inserirLogExcecaoFuncionalidadeIniciada` (exceção persistida; `FuncionalidadeIniciada.fuin_dserro`); 🔵 as demais unidades seguem, e o nível superior termina como `CONCLUIDO_COM_ERRO`. 🟢 Há tela para consultar a exceção (`ExibirExcecaoFuncionalidadeIniciadaAction`).

🟢 **Reprocessamento é por etapa**: `ControladorBatchSEJB.reiniciarFuncionalidadesIniciadas(String[] idsFuncionalidadesIniciadas, Integer idProcessoIniciado)` — 🔵 o operador seleciona funcionalidades iniciadas para reiniciar dentro do mesmo processo iniciado; a tarefa então usa `pesquisarTodasUnidadeProcessamentoReinicioBatch()` e a proteção da §5 evita refazer unidades concluídas.

❔ Não comprovados: retry **automático**, limite de tentativas, e se o reinício cria nova `FuncionalidadeIniciada` ou reaproveita a existente.

## 13. Duplicidade

🟢 Comprovado **no nível da unidade**: mesma unidade já concluída não é reexecutada (§5). ❔ **Não comprovado** no nível do processo: se o sistema impede iniciar duas vezes o mesmo processo com os mesmos parâmetros (ex.: grupo + referência). 🔵 Salvaguardas de negócio existem nos módulos donos (ex.: situação da conta, referência já faturada), mas isso é regra do módulo, não do framework.

⚠️ Evitar a palavra "idempotência" como propriedade do framework: o que existe é **retomada por unidade**, o que é diferente de garantir efeito único em qualquer reexecução.

## 14. Segurança e identidade

🟢 **Duas identidades distintas, ambas presentes**:
- **Solicitante**: `ProcessoIniciado.usuario` — gravado no disparo manual (`processoIniciado.setUsuario(getUsuarioLogado(request))`). 🔵 O GSAN **sabe quem pediu** o processamento.
- **Executor**: `TarefaBatch` recebe `Usuario` no construtor e do JobDataMap — 🔵 o usuário viaja para a execução; e `Usuario.USUARIO_BATCH` é usado como autor em fluxos automáticos (relatórios batch, OS seletiva/fiscalização — visto no mapa de Segurança).

🔵 **Resolução parcial da dúvida da Segurança**: não é verdade que "o batch roda sem identidade" — o processo **registra o solicitante** e a tarefa **carrega um usuário**. 🟡 Hipótese (não comprovada): `USUARIO_BATCH` é usado quando não há solicitante humano (processos agendados/internos), enquanto o disparo manual propaga o usuário real.

🟢 **Autorização do disparo**: (a) as telas de batch são Actions `*.do` e portanto passam pelo gate de autorização (funcionalidade/operação) como qualquer outra — ⚠️ observando que URLs contendo `pesquisar` estão na lista de exceções do filtro (ex.: `PesquisarProcessoAction`), e (b) existe **autorização própria do processo** (`indicadorAutorizacao` + `AGUARDANDO_AUTORIZACAO` + `AutorizarProcessoIniciadoAction`) — 🔵 dois níveis: permissão para operar a tela e autorização do processo em si.

🟢 **Correção registrada**: a exceção `executarBatch` no filtro **não** se refere a este framework — é a Action `gcom.batch.ExecutarBatch` (`/executarBatch` no struts-config), que apenas chama `ControladorOrdemServico.atualizarOrdemServicoAcompanhamentoServico(...)`. Ver [seguranca.md §7](seguranca.md).

❔ **Não comprovado**: se os MDBs/JMS possuem autenticação própria, e se a execução interna revalida permissões (indício forte de que **não** revalida — o MDB chama o controlador de negócio diretamente).

## 15. Abrangência

❔ **Não encontrei** verificação de abrangência nas Actions de batch nem no `ControladorBatchSEJB` (busca por `abrangencia`/`Abrangencia` nesses arquivos não retornou ocorrências). 🔵 Isso torna mais provável o cenário em que **a abrangência atua na seleção de parâmetros** (a tela restringe/valida o que o usuário escolhe) **ou simplesmente não é aplicada no batch** — mas **nenhuma das duas está comprovada**. Como as unidades vêm de coleções de localidades/rotas informadas como parâmetro, o risco funcional é claro: **um usuário poderia disparar processamento sobre território fora de sua abrangência** se a tela não restringir.

⚠️ Este ponto **permanece dúvida aberta** e é candidato prioritário de caracterização — a pergunta herdada da Segurança **não** foi respondida em definitivo.

## 16. Auditoria e rastreabilidade

🟢 O estado funcional é **persistido no banco** (não apenas em log): processo iniciado (com solicitante, situação, tempos, agendamento, comando), etapa iniciada (situação, tempos, **parâmetros**, **erro**), unidade iniciada (situação, tempos, **código real da partição**). 🟢 A exceção é persistida (`inserirLogExcecaoFuncionalidadeIniciada`) e consultável em tela.

🔵 Portanto o GSAN consegue responder: *quem iniciou*, *quando*, *com quais parâmetros*, *quais etapas rodaram*, *qual unidade falhou*, *qual foi o erro* e *o que já foi concluído* — sem depender de log técnico. 🟢 Complementarmente, o Quartz `VerificadorProcessosIniciados` é um **job de monitoramento** que reporta processo/funcionalidade em execução e o **percentual de memória da JVM** — 🔵 observabilidade operacional rudimentar (saída em `System.out`), distinta do estado funcional.

## 17. Acompanhamento operacional

🟢 Telas identificadas: pesquisar/filtrar processos (`ExibirPesquisarProcessoAction`, `ExibirFiltrarProcessoAction`, `PesquisarProcessoAction`), exceção de funcionalidade iniciada, autorizar processo iniciado, status de geração de relatórios (inclusive por usuário) e autorizar relatórios batch. 🔵 O operador consegue: acompanhar execuções e situações, ver o erro de uma etapa, autorizar processos/relatórios pendentes e **reiniciar funcionalidades** (§12).

## 18. Estudo de caso — FATURAR_GRUPO_FATURAMENTO

🔵 Orquestração (sem repetir as regras de cálculo, que são do [faturamento.md](faturamento.md)):

```text
1. Disparo: tela de processo mensal/eventual ou faturamento comandado
            → ProcessoIniciado (processo = faturar grupo; usuário solicitante; situação inicial)
2. Etapas:  FuncionalidadeIniciada por ProcessoFuncionalidade, na ordem de sequencialExecucao
3. Tarefa:  TarefaBatchFaturarGrupoFaturamento (Job Quartz) recebe do JobDataMap
            idFuncionalidadeIniciada + usuario + parametroTarefa, e lê:
              • getParametro("faturamentoGrupo")   → o grupo
              • getParametro("atividade")          → a atividade do cronograma
              • getParametro(COLECAO_UNIDADES_PROCESSAMENTO_BATCH) → ROTAS a processar
4. Unidades: a UNIDADE DE PROCESSAMENTO é a ROTA (confirma micromedicao/faturamento:
            "unidade = rota do cronograma")
5. Distribuição: enviarMensagemControladorBatch → JMS → BatchFaturarGrupoFaturamentoMDB
6. Execução: MDB.onMessage → ControladorFaturamento.faturarGrupoFaturamento(...)
            com iniciarUnidadeProcessamentoBatch/encerrarUnidadeProcessamentoBatch em volta
7. Controle: unidade concluída ou concluída com erro; unidades já concluídas não repetem;
            reinício via reiniciarFuncionalidadesIniciadas + pesquisarTodasUnidadeProcessamentoReinicioBatch
```

🔵 Conclusão do caso: o faturamento **não tem orquestração própria** — usa o framework padrão, com a rota como partição. Isso confirma a fronteira: *o Batch orquestra, o Faturamento calcula*.

## 19. Segundo caso — ENCERRAR_ARRECADACAO_MES

🟢 `TarefaBatchEncerrarArrecadacaoMes extends TarefaBatch`, lê `getParametro(COLECAO_UNIDADES_PROCESSAMENTO_BATCH)` como **coleção de localidades**, implementa os mesmos métodos de unidades (normal e reinício) e envia mensagem ao `BatchEncerrarArrecadacaoMesMDB`, que chama `ControladorArrecadacao.encerrarArrecadacaoMes(colecaoIdsLocalidades, idFuncionalidadeIniciada)`.

🔵 **Resultado do teste de generalidade**: o padrão observado no faturamento **pertence ao framework**, não ao processo — muda apenas *o que é a unidade* (rota × localidade) e *qual controlador de negócio é chamado*. Isso sustenta tratar o modelo como infraestrutura reutilizável.

## 20. Fronteiras com os módulos

```text
                    ┌─────────────── Batch (orquestração) ───────────────┐
Quartz (quando) ──► │ ProcessoIniciado → FuncionalidadeIniciada → Unidade │ ──► JMS/MDB
                    └────────────────────────────────────────────────────┘
                                              │ chama
                                              ▼
        Cadastro · Micromedição · Faturamento · Cobrança · Arrecadação · Atendimento · Relatórios
                              (donos das regras de negócio)
```

🔵 Não identifiquei regra de negócio de domínio dentro do `ControladorBatchSEJB` — ele trata de estado, unidades, autorização e encerramento. A exceção parcial é o **suporte a relatórios** (métodos de relatório dentro do controlador batch), 🔵 que é infraestrutura assíncrona, não regra de negócio.

## 21. Variações por companhia

🟢 Não foram identificadas subclasses por companhia do `ControladorBatchSEJB`. 🔵 A variabilidade é de **dados** (catálogo de processos, etapas, unidades por instalação) e de **conjunto de processos implantados**. ⚠️ Sem comprovação de exclusividade paramétrica; classificação REGRA BASE / PARAMETRIZAÇÃO / CUSTOMIZAÇÃO / EVOLUÇÃO POSTERIOR deve ser mantida na análise futura. **Não** foi feita contagem de deployments/MDBs nesta atividade (e o número citado em documentos anteriores não é reproduzido aqui por falta de fonte verificada).

## 22. Regras estruturantes

1. 🟢 **Definição e execução são separadas em três níveis** (processo/etapa/unidade), cada um com estado, tempos e erro persistidos.
2. 🟢 **A ordem das etapas é dado** (`sequencialExecucao`), não código.
3. 🟢 **As etapas do batch são as funcionalidades do modelo de segurança** — catálogo único.
4. 🟢 **A partição é definida por processo** (métodos de unidades normal e de reinício) e identificada por `codigoRealUnidadeProcessamento`.
5. 🟢 **Unidade já concluída não é reexecutada** — retomada segura em reprocessamento.
6. 🟢 **Falha é por unidade**, com exceção persistida; o processo termina como "concluído com erro" sem perder o que foi feito.
7. 🟢 **Reprocessamento é operação de primeira classe**, por etapa, dentro da mesma execução.
8. 🟢 **Parâmetros são genéricos, nomeados e persistidos** na etapa iniciada.
9. 🟢 **O solicitante é registrado** na execução; a tarefa carrega um usuário para o processamento.
10. 🟢 **Existe autorização de processo** (`indicadorAutorizacao` + estado + tela), distinta da permissão de operar a tela.
11. 🔵 **Agendador, orquestrador, transporte e regra de negócio são camadas separadas** — o MDB é ponte, não dono da regra.
12. 🔵 **O estado funcional vive no banco**, permitindo acompanhamento operacional sem log técnico.

## 23. Compatibilidade GSAN → SISAN

| Conceito | Classificação | Motivo |
| -------- | ------------- | ------ |
| Separação definição × execução em três níveis | PRESERVAR CONCEITO | É o que dá observabilidade e retomada; migrável independentemente de tecnologia |
| Unidade de processamento com identificador real da partição | PRESERVAR CONCEITO | Base da retomada e do reprocessamento seletivo |
| Retomada: unidade concluída não se repete | PRESERVAR CONCEITO | Propriedade funcional essencial em processamento financeiro |
| Estado, tempos, parâmetros e erro persistidos | PRESERVAR CONCEITO | Auditoria e acompanhamento operacional |
| Reprocessamento por etapa | PRESERVAR CONCEITO | Operação real do dia a dia |
| Registro do solicitante + identidade de execução | PRESERVAR CONCEITO | Rastreabilidade de quem pediu o processamento |
| Autorização de processo (workflow) | PRESERVAR CONCEITO | Governança de processos sensíveis |
| Ordem das etapas como dado | PRESERVAR CONCEITO | Configurabilidade sem código |
| Etapas ancoradas no catálogo de funcionalidades da segurança | MODERNIZAR MANTENDO COMPATIBILIDADE | O vínculo é útil; a forma (mesma tabela de funcionalidade de tela) pode evoluir |
| Estados em três máquinas paralelas com códigos próprios | MODERNIZAR MANTENDO COMPATIBILIDADE | Semântica preservada; nomenclatura e transições podem ser explicitadas |
| Quartz + JMS + MDB (EJB 2.x) como implementação | **NÃO TRANSPORTAR** (a tecnologia) | A **capacidade** (agendar, distribuir, paralelizar) é preservada; a tecnologia é substituída |
| `Processo.limite` / `prioridade` | EXIGE APROFUNDAMENTO | Semântica não comprovada; afeta desenho de concorrência |
| Proteção contra dupla execução do mesmo processo | EXIGE APROFUNDAMENTO | Não comprovada; decisiva para processos financeiros |
| Granularidade de commit dentro da unidade | EXIGE APROFUNDAMENTO | Varia por processo; precisa de caracterização |
| Abrangência no disparo de batch | EXIGE APROFUNDAMENTO | Não localizada; risco funcional em aberto |
| Monitoramento via `System.out` (memória JVM) | **NÃO TRANSPORTAR** | Substituível por observabilidade real |

## 24. Hipóteses para avaliação futura (não são decisões, nenhuma tecnologia escolhida)

1. **Job/execução como agregado explícito** com etapas e partições, preservando os três níveis atuais.
2. **Partição como contrato do processo** (a estratégia de particionamento declarada por processo, como hoje nos métodos de unidades).
3. **Retomada baseada em partições concluídas** como propriedade de plataforma, não de cada processo.
4. **Contexto de execução tipado e versionado** (evolução dos parâmetros nomeados persistidos).
5. **Separação explícita entre agendamento, orquestração e execução distribuída** — mantendo as camadas que o legado já separa.
6. **Governança de processos sensíveis** (autorização) como recurso de plataforma.
7. **Escopo territorial no disparo** — caso a caracterização confirme a lacuna da §15.

## 25. Cenários de caracterização identificados (sustentados por evidência)

> Cenário sustentado por evidência de que o fluxo existe; o **resultado esperado** de vários será estabelecido na caracterização.

1. Disparo manual de processo mensal/eventual (verificar gravação de solicitante e situação inicial).
2. Processo com `indicadorAutorizacao` → estado `AGUARDANDO_AUTORIZACAO` → autorização → execução.
3. Disparo agendado via Quartz (tarefa recebendo `idFuncionalidadeIniciada`, usuário e parâmetros do JobDataMap).
4. Criação das `FuncionalidadeIniciada` na ordem de `sequencialExecucao`.
5. Resolução de unidades: rota (faturamento) e localidade (arrecadação).
6. Todas as unidades concluídas → consolidação do processo.
7. Uma unidade falha → `CONCLUIDA_COM_ERRO` + exceção persistida; demais seguem.
8. Processo termina como `CONCLUIDO_COM_ERRO`.
9. **Reprocessamento**: `reiniciarFuncionalidadesIniciadas` + unidades de reinício.
10. **Reexecução de unidade já concluída** (esperado: tratada como já executada, sem refazer).
11. Falha após commits parciais (verificar o que permanece aplicado).
12. Duas execuções do mesmo processo com os mesmos parâmetros (verificar se há proteção).
13. Execução paralela de unidades pelo pool de MDBs.
14. Processo com referência AAAAMM e por grupo (faturamento).
15. Usuário fora da abrangência disparando processamento de outro território (**verificar se há restrição** — §15).
16. Rastreabilidade: identificar solicitante, parâmetros, etapa e unidade que falhou.
17. FATURAR_GRUPO completo (orquestração ponta a ponta).
18. FATURAR_GRUPO com falha intermediária em uma rota.
19. ENCERRAR_ARRECADACAO_MES (segundo padrão, unidade = localidade).
20. Processo de relatório pelo mesmo framework (com autorização, quando aplicável).

## 26. Dúvidas abertas

1. ❔ **Abrangência no batch** — não localizada nas telas nem no controlador; pergunta herdada da Segurança **permanece aberta** (§15).
2. ❔ Proteção contra **duas execuções do mesmo processo** com os mesmos parâmetros.
3. ❔ Semântica exata de `Processo.limite` e `prioridade`.
4. ❔ Granularidade de **commit dentro da unidade** (por lote de N registros?) — varia por processo.
5. ❔ Se o **reinício** cria nova `FuncionalidadeIniciada` ou reaproveita a existente.
6. ❔ Existência de **retry automático** e limite de tentativas.
7. ❔ **Dependência condicional** entre etapas e bloqueio da seguinte em caso de falha.
8. ❔ Se MDB/JMS possuem autenticação própria e se a execução **revalida permissões** (indício forte de que não).
9. ❔ Quando exatamente `USUARIO_BATCH` substitui o usuário solicitante.
10. ❔ Significado operacional de `INICIO_A_COMANDAR` e do campo `proi_tmcomando`.

## 27. Evidências principais

```text
Modelo:        batch.Processo (batch.processo: proc_icautorizacao, proc_limite, proc_prioridade, proc_nmarquivobatch)
               batch.ProcessoIniciado (batch.processo_iniciado: proi_tmagendamento/tminicio/tmtermino/tmcomando,
                 proi_nngrupo; FKs proc_id, usur_id, prst_id, proi_idprecedente)
               batch.ProcessoFuncionalidade (prfn_nnsequencialexecucao, prfn_dsorientacao;
                 FKs proc_id, unpr_id e **fncd_id → seguranca.acesso.Funcionalidade**)
               batch.FuncionalidadeIniciada (fuin_parametros, fuin_dserro; FKs proi_id, prfn_id, fnst_id)
               batch.UnidadeProcessamento / batch.UnidadeIniciada (undi_cdidunidadeprocessamento;
                 FKs unpr_id, fuin_id, unst_id)
Estados:       ProcessoSituacao (1,2,3,4,5,6,7,8) · FuncionalidadeSituacao (1,2,3,4,5,6,7) · UnidadeSituacao (1,2,3,4)
Controle:      ControladorBatchSEJB.iniciarUnidadeProcessamentoBatch (cria UnidadeIniciada EM_PROCESSAMENTO;
                 detecta unidade já CONCLUIDA com mesmo codigoReal → encerrarUnidadeIniciadaJaExecutada)
               .encerrarUnidadeProcessamentoBatch(excecao, idUnidadeIniciada, executouComErro)
                 → CONCLUIDA | CONCLUIDA_COM_ERRO + inserirLogExcecaoFuncionalidadeIniciada
               .encerrarFuncionalidadesIniciadas / .encerrarProcessosIniciados
               .reiniciarFuncionalidadesIniciadas(ids, idProcessoIniciado)
               .autorizarProcessoIniciado(processoIniciado, processoSituacao, funcionalidadeSituacao)
               .iniciarRelatoriosAgendados / .iniciarProcessoRelatorio(TarefaRelatorio) /
                 .iniciarProcessoRelatorioControleAutorizacao
Agendamento:   gcom.tarefa.TarefaBatch extends Tarefa (implements Job): execute(JobExecutionContext) lê do JobDataMap
                 idFuncionalidadeIniciada, usuario, parametroTarefa; métodos abstratos
                 pesquisarTodasUnidadeProcessamentoBatch / pesquisarTodasUnidadeProcessamentoReinicioBatch;
                 enviarMensagemControladorBatch → ServiceLocator.enviarMensagemJms(queueMDB, parametros)
               gcom.batch.VerificadorProcessosIniciados implements Job (MONITORAMENTO: processo/funcionalidade em
                 execução + percentual de memória da JVM via System.out)
Disparo:       gui/batch/InserirProcessoMensalEventualAction (new ProcessoIniciado; setUsuario(getUsuarioLogado);
                 setProcessoIniciadoPrecedente); ExibirInserirProcessoFaturamentoComandadoAction;
                 AutorizarProcessoIniciadoAction; ExibirExcecaoFuncionalidadeIniciadaAction;
                 Exibir/Pesquisar/FiltrarProcessoAction; relatorio/ExibirStatusGeracao(Usuario)Action,
                 ExibirAutorizarRelatoriosBatchAction
               Módulos também criam ProcessoIniciado (ControladorSpcSerasaSEJB; GerarResumoDevedoresDuvidososAction)
Caso 1:        batch/faturamento/TarefaBatchFaturarGrupoFaturamento (getParametro "faturamentoGrupo", "atividade",
                 COLECAO_UNIDADES_PROCESSAMENTO_BATCH = rotas) → BatchFaturarGrupoFaturamentoMDB.onMessage
                 → ControladorFaturamento.faturarGrupoFaturamento(...)
Caso 2:        batch/arrecadacao/TarefaBatchEncerrarArrecadacaoMes (unidades = localidades)
                 → BatchEncerrarArrecadacaoMesMDB → ControladorArrecadacao.encerrarArrecadacaoMes(...)
Fronteira Seg: gcom.batch.ExecutarBatch = Action Struts (/executarBatch) que chama
                 ControladorOrdemServico.atualizarOrdemServicoAcompanhamentoServico — NÃO é o framework batch
```
