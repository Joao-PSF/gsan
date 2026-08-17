# Módulo Atendimento — Mapa Funcional

Elaborado em 2026-08-14 (Fase 0). Fontes: código GSAN (`gcom.atendimentopublico` e subpacotes, Actions de execução, fronteiras nos módulos donos), mapeamentos Hibernate, constantes, DDL; `gsan_comercial` apenas como evidência complementar. Pré-requisitos: [cadastro](cadastro.md), [micromedicao](micromedicao.md), [faturamento](faturamento.md), [cobranca](cobranca.md), [arrecadacao](arrecadacao.md), [glossário](../dominio/glossario.md).

**Convenção de confiança**: 🟢 fato comprovado (código/DDL) · 🔵 interpretação funcional sustentada por evidência · 🟡 hipótese · ❔ não compreendido (§32).

## 1. Responsabilidade

O Atendimento é o **domínio da demanda e da sua execução**: recebe solicitações e reclamações (de clientes, de terceiros ou geradas internamente), classifica-as, define quem responde, controla prazo e tramitação, e — quando a demanda exige ação da companhia — gera e acompanha **Ordens de Serviço** até o encerramento. É o **ponto de entrada de mudanças nos outros domínios**: ligações, hidrômetros, situações cadastrais e vários lançamentos financeiros nascem de um RA/OS.

🔵 O encadeamento hipotético do prompt (demanda → RA → classificação → responsabilidade → tramitação → OS → execução → encerramento → efeitos) **se confirma na essência**, com três ressalvas comprovadas: (a) o RA nem sempre gera OS; (b) a OS nem sempre nasce de RA; (c) o efeito nos outros domínios acontece com frequência **na execução do serviço**, não no encerramento formal da OS (§18).

## 2. Principais capacidades

Registrar e classificar solicitações por tipo/especificação; calcular e recalcular prazo; encaminhar e tramitar entre unidades organizacionais com parecer; colocar em espera; reiterar; detectar duplicidade; bloquear; encerrar (manual ou automaticamente) e reativar; gerar OS automaticamente conforme parametrização; priorizar e programar OS; registrar execução e retorno de campo; cobrar (ou isentar) o serviço executado; atualizar o estado cadastral e de medição como efeito da execução; disparar lançamentos financeiros (débito, crédito, guia, retificação de conta); atender canais distintos (presencial, telefone, online, loja virtual) e operar em contingência manual; fornecer dados de reclamação à agência reguladora.

## 3. Registro de Atendimento (RA)

🔵 **Conceito de negócio**: o RA é o **protocolo da demanda** — a evidência de que alguém (cliente, ocupante, terceiro, órgão, ou o próprio sistema) manifestou uma necessidade em determinado momento, e o instrumento pelo qual a companhia assume a responsabilidade de responder dentro de um prazo. Ele não é "a execução"; é o **compromisso de atendimento**.

🟢 Estrutura (`atendimentopublico.registro_atendimento`, id `rgat_id`): momento do registro (`rgat_tmregistroatendimento`), **situação** (`rgat_cdsituacao`), tipo/especificação da solicitação (`step_id`), meio de solicitação (`meso_id`), **unidade atual** (`unid_idatual`), **duas datas de prazo** (`rgat_dtprevistaoriginal`, `rgat_dtprevistaatual`), encerramento (`rgat_tmencerramento` + motivo `amen_id` + `rgat_dsparecerencerramento`), **reiterações** (`rgat_qtreiteracoes`, `rgat_tmultimareiteracao`), **espera** (`rgat_tminicioespera`, `rgat_tmfimespera`), observação, local da ocorrência (descrição, ponto de referência, complemento, número, **coordenadas norte/leste** e `rgat_iccorrdenadassemlogr`), `rgat_icatendimentoonline`, `rgat_idmanual`, e vínculos com imóvel, cliente/solicitante, endereço (logradouro/bairro/CEP, perímetro), localidade/setor/quadra, **bairro-área** (`brar_id`), além de auto-relações de **reativação** (`rgat_idreativacao`) e **duplicidade** (`rgat_idduplicidade`).

🟢 Sobre "RA de referência / atual / anterior": são **códigos de exibição** (`CODIGO_ASSOCIADO_SEM_RA=0`, `RA_REFERENCIA=1`, `RA_ATUAL=2`, `RA_ANTERIOR=3`, com rótulos de tela associados) usados para qualificar em consultas qual RA está sendo mostrado em relação a outro — **não são um mecanismo de versionamento do RA**. Correção de premissa registrada.

## 4. Estados do RA

🟢 Três situações, definidas como constantes: **PENDENTE(1)**, **ENCERRADO(2)**, **BLOQUEADO(3)** (com descrições e abreviações próprias). 🔵 PENDENTE é o estado de trabalho (dentro ou fora do prazo, em tramitação ou em espera — todos continuam pendentes); ENCERRADO é o estado final com data, motivo e parecer; BLOQUEADO é um estado operacional distinto de encerramento (o RA existe, mas não segue o fluxo normal).

🟢 **Reativação e duplicidade são relações entre RAs distintos**, não transições de estado do mesmo registro: `rgat_idreativacao` (com `RaMotivoReativacao`) e `rgat_idduplicidade` ligam um RA a outro. 🔵 Isso significa que a linhagem do atendimento é preservada por **encadeamento entre protocolos** — o mesmo padrão conceitual já visto na retificação de contas (documentos distintos ligados por origem), e não por reescrita do registro original.

❔ Não determinei nesta análise quem exatamente pode bloquear/desbloquear, nem se BLOQUEADO tem motivo próprio parametrizado.

## 5. `SolicitacaoTipo` e `SolicitacaoTipoEspecificacao`

🟢 **`SolicitacaoTipoEspecificacao` é o principal núcleo paramétrico do Atendimento.** Seus campos definem, por especificação, praticamente todo o comportamento do atendimento:

| Grupo | Campos (`step_*`) |
| ----- | ----------------- |
| Prazo | `nndiaprazo` |
| Obrigatoriedades | `icmatricula` (matrícula), `iccliente`, `icsolicitante`, `icdocumentoobrigatorio`, `icvaldocresponsavel`, `icparecerencerramento` |
| Pré-condições | `icligacaoagua`, `icverificardebito` |
| Efeitos financeiros | `icgeracaodebito`, `icgeracaocredito`, `vldebito`, `icpermitealterarvalor`, `iccobrarjuros`, `iccobrancamaterial` |
| Efeitos operacionais | **`icgeracaoordemservico`**, `icpavimentorua`, `icpavimentocalcada` |
| Fluxo | `icurgencia`, **`icencerramentoautomatico`** |
| Integrações financeiras específicas | `icinformarcontara`, **`icinformarpgtoduplicidade`**, `icalterarvencimento` |
| Canal | `iclojavirtual` |
| Controle | `icuso`, `nncodigoconstante` |

🔵 Leitura funcional da hierarquia: **`SolicitacaoTipo`** = a natureza do que o cliente pede (a "família" da demanda); **`SolicitacaoTipoEspecificacao`** = o refinamento que carrega as regras concretas de tratamento; **`ServicoTipo`** = o que a companhia executa. 🔵 Portanto, o Atendimento do GSAN é **fortemente configurável por dados**: mudar prazo, obrigatoriedade de matrícula, geração de OS, geração de débito, encerramento automático ou disponibilidade na loja virtual é configuração, não código. Esse é um dos achados arquiteturais mais relevantes do módulo.

⚠️ Nota de compatibilidade: preservar essa **semântica configurável** é diferente de copiar a tabela — a decisão de forma fica para a modelagem (§29/§30).

## 6. Matrícula, imóvel e local da ocorrência — resolução da premissa "RA sem imóvel"

Este ponto tinha uma aparente contradição. **Resolução:**

🟢 **Fato 1**: o DDL da instalação de referência declara **`imov_id int4 NULL`** em `atendimentopublico.registro_atendimento` — o banco **permite** RA sem imóvel.
🟢 **Fato 2**: o mapping `RegistroAtendimento.hbm.xml` declara `<many-to-one name="imovel" ... not-null="true">` — mais restritivo que o banco. Em Hibernate 3, isso faz a persistência **pela entidade** falhar se o imóvel for nulo.
🟢 **Fato 3**: a especificação tem `INDICADOR_MATRICULA_OBRIGATORIO=1` / `INDICADOR_MATRICULA_NAO_OBRIGATORIO=2`, e o fluxo que trata "matrícula não obrigatória" no `ControladorRegistroAtendimentoSEJB` (≈ linhas 4866, 5041) é o de **falta d'água generalizada**: verifica RAs abertos **para a mesma área de bairro** (`pesquisarRAAreaBairro(idRegistroAtendimento, idBairroArea, idEspecificacao)`) e, havendo, sinaliza duplicidade com motivo de encerramento.
🟢 **Fato 4**: a consulta correspondente ancora-se em **bairro-área**, não em imóvel (`from RegistroAtendimento rgat left join rgat.bairroArea ... where baiArea.id = :idBairroArea`).
🟢 **Fato 5**: o RA possui campos próprios de **local da ocorrência** independentes do imóvel: descrição do local, ponto de referência, número, complemento, logradouro/bairro/CEP, perímetro (logradouro inicial/final), **coordenadas norte/leste** e o indicador **`rgat_iccorrdenadassemlogr`** (coordenadas sem logradouro).

🔵 **Conclusão (parcialmente confirmada, com precisão)**: existem **demandas legitimamente não vinculadas a uma matrícula** — ocorrências de rede/área (falta d'água generalizada, ocorrências em via pública), ancoradas em **bairro-área, endereço ou coordenadas**, e o **banco suporta `imov_id` nulo**. Porém, **a persistência pelo mapping atual exige imóvel**, o que indica uma de duas situações: (a) o fluxo resolve/atribui um imóvel de referência antes de gravar, ou (b) o mapping está mais restritivo que o comportamento pretendido (dívida técnica), com registros nulos vindos de outros caminhos.

❔ **O que falta para fechar**: verificar em dados reais se existem RAs com `imov_id IS NULL` e, se sim, por qual caminho foram gravados. **Não afirmo** "RA sem imóvel existe no fluxo padrão" nem o contrário — a evidência sustenta a **necessidade de negócio** e a **permissão no banco**, mas não a gravação nula pela entidade. Classificação: **INDÍCIO FORTE** para a necessidade de negócio; **DÚVIDA ABERTA** para a forma de persistência.

## 7. Prazo, espera e reiteração

🟢 **Duas datas de prazo**: `dataPrevistaOriginal` e `dataPrevistaAtual` — 🔵 a original preserva o compromisso assumido na abertura (base para indicadores de cumprimento), a atual reflete recálculos ao longo da vida do RA. 🟢 A base do cálculo é `step_nndiaprazo` da especificação. 🟢 O sistema dispõe de utilitários de **dias úteis** (`Util.addBusinessDays`/`countBusinessDays` e funções equivalentes no banco: `addbusinessdays`, `countbusinessdays`), o que 🔵 indica prazos em dias úteis para parte dos fluxos.

🟢 **Espera**: par `dataInicioEspera`/`dataFimEspera` **no próprio RA** — 🔵 modela **um** intervalo de espera corrente, não um histórico de múltiplas esperas; se houver mais de uma, o registro anterior é sobrescrito (característica/limitação do legado a considerar na modernização). ❔ Se a espera suspende formalmente a contagem do prazo (recalculando `dataPrevistaAtual`) não foi comprovado nesta análise.

🟢 **Reiteração**: contador (`quantidadeReiteracao`) + data da última — 🔵 registra que o solicitante voltou a cobrar a mesma demanda; é um **sinal de insatisfação/urgência** mantido de forma agregada (sem histórico individual de cada reiteração). ❔ Não comprovei se a reiteração altera prazo, prioridade ou unidade automaticamente.

## 8. Tramitação e unidades

🟢 **`Tramite`** (por RA) registra: **unidade de origem**, **unidade de destino**, **usuário responsável**, **usuário que registrou**, data e **parecer** — todos obrigatórios exceto o parecer. 🟢 O RA mantém `unid_idatual`. 🟢 Existe também `RegistroAtendimentoUnidade`.

🔵 Interpretação: `unid_idatual` é o **estado corrente** de responsabilidade (para consultas e caixa de trabalho), enquanto `Tramite` é o **histórico completo e auditável** de transferências, com parecer e dupla identificação de usuário (quem é responsável × quem registrou o trâmite) — 🔵 distinção deliberada, valiosa para auditoria. A unidade inicial 🔵 deriva da configuração ligada à especificação/serviço (a especificação referencia unidade organizacional no modelo do atendimento). ❔ O papel exato de `RegistroAtendimentoUnidade` frente a `Tramite` (histórico alternativo? vínculo N:N? controle de caixa por unidade?) **não ficou claro** — dúvida aberta.

## 9. Encerramento, reativação e duplicidade

🟢 Encerramento do RA: data (`rgat_tmencerramento`), **motivo** (`AtendimentoMotivoEncerramento`) e **parecer** (obrigatório ou não conforme `step_icparecerencerramento`). 🟢 **Encerramento automático** é parametrizado na especificação (`step_icencerramentoautomatico`) — e a OS tem indicador análogo próprio (`orse_icencerramentoautomatico`), 🔵 ou seja, são dois mecanismos independentes que podem coexistir.
🟢 Encerramento por duplicidade: o fluxo de falta d'água generalizada busca motivo de encerramento e sinaliza a existência de RA equivalente na mesma área (§6) — 🔵 duplicidade encerra o RA novo mantendo o vínculo ao original.
🟢 Reativação: `rgat_idreativacao` + `RaMotivoReativacao` — 🔵 novo RA ligado ao anterior, preservando os dois protocolos (não há sobrescrita).

❔ Se o encerramento do RA exige que todas as OS associadas estejam encerradas não foi comprovado (dúvida aberta, com impacto em caracterização).

## 10. Ordem de Serviço (OS)

🔵 **Conceito**: a OS é a **unidade de execução** — o que a companhia precisa fazer (em campo ou internamente) para atender a demanda, com custo, prioridade, responsável e resultado próprios. Enquanto o RA é o *compromisso*, a OS é o *trabalho*.

🟢 Estrutura (`atendimentopublico.ordem_servico`, id `orse_id`): **situação** (`orse_cdsituacao`), **três marcos temporais distintos** — `dataGeracao`, `dataEmissao`, `dataEncerramento` —, RA de origem (`rgat_id`, opcional), imóvel, **serviço** (`svtp_id`), serviço de referência, **OS de referência** (`orse_idreferencia`) e tipo de retorno da OS referida, **prioridade original e atual** (`stpr_idoriginal`/`stpr_idatual`) + `orse_nnfatorprioridade`, unidade atual, **valores** (`orse_vlservicooriginal`, `orse_vlservicoatual`, `orse_pcvalorcobranca`) e motivo de não cobrança (`sncm_id`), parecer/observação, **`orse_icprogramada`**, `orse_icencerramentoautomatico`, **`orse_icatualizaagua`**, **`orse_icatualizaesgoto`**, **`orse_iccomercialatualizado`**, `orse_icboletim`, `orse_icdiagnostico`, dados de fiscalização (situação, retorno, parecer, fiscalização coletiva), documento de cobrança (`cbdo_id`), projeto e comando de ordem seletiva.

## 11. Estados da OS

🟢 **PENDENTE(1)**, **ENCERRADO(2)** — com a descrição explícita **"encerrada porém não foi executada"** —, **EXECUÇÃO_EM_ANDAMENTO(3)**, **AGUARDANDO_LIBERAÇÃO(4)**.

🔵 Leituras funcionais: (a) **encerrar ≠ executar** — o sistema distingue explicitamente a OS encerrada com execução da encerrada sem execução, informação essencial para indicadores e para a decisão de cobrar o serviço; (b) **AGUARDANDO_LIBERAÇÃO** mostra que há serviços que precisam de autorização antes de ir a campo; (c) **geração ≠ emissão ≠ execução** (três datas separadas) — a OS é criada, depois impressa/despachada, depois executada. 🟢 Há encerramento em massa de OS vencidas (`encerrarOrdemServicoVencida(idServicoTipo, quantidadeDias, usuario)`), 🔵 mecanismo de higiene operacional por tipo de serviço.

## 12. RA → OS (cardinalidade real)

🟢 A especificação tem `step_icgeracaoordemservico`, e no DDL da instalação de referência **`ordem_servico.rgat_id` é `NULL`-able** (com FK `fk1_ordem_servico` para `registro_atendimento`), enquanto o **mapping declara `registroAtendimento` com `not-null="true"`** — a mesma divergência mapping × banco observada no caso do imóvel do RA (§6).

- 🔵 **RA sem OS**: existe (demandas informativas, encerradas com parecer, ou com encerramento automático).
- 🔵 **RA com uma ou várias OS**: suportado (a OS referencia o RA; nada limita a uma).
- 🟢 **Origens funcionais de OS independentes de uma demanda individual convencional**: **Cobrança** (OS de corte/supressão/fiscalização geradas por ação, com `cbdo_id`), **fiscalização coletiva** (`fzcl_id`) e **comando de ordem seletiva** (`coss_id`). 🟢 O código também mostra que RA nulo é explicitamente aceito em **outras** entidades originadas por processos sistêmicos (`ControladorCobranca` faz `setRegistroAtendimento(null)` em débito a cobrar, crédito a realizar e parcelamento).
- ❔ **Persistência de OS efetivamente sem RA permanece a confirmar**: as origens acima comprovam a **regra de negócio** (OS pode nascer de processo interno/sistêmico), mas não comprovam, isoladamente, que essas OS sejam gravadas com `rgat_id IS NULL` — elas poderiam associar um RA técnico, reutilizar um RA existente ou usar outro caminho de persistência. Até que DDL + fluxo de inserção **ou** dados reais confirmem `rgat_id` nulo, a **cardinalidade física permanece dúvida aberta** (§30). Distinção a manter: *regra de negócio* (OS originada por processo sistêmico) ≠ *questão de persistência* (essa OS tem ou não RA associado).
- 🟢 **OS que referencia outra OS**: `orse_idreferencia` + `servicoTipoReferencia` + `OsReferidaRetornoTipo`; combinado com `orse_icdiagnostico` (serviço diagnosticado), 🔵 o padrão é **diagnóstico/vistoria → serviço definitivo** e **OS de retorno/complementar** — encadeamento de trabalho, **não versionamento**.

## 13. Serviço e prioridade

🟢 `ServicoTipo` é o **modelo do serviço**, com regras próprias (independentes da especificação da solicitação): `valor`, `tempoMedioExecucao`, `indicadorAtualizaComercial`, `indicadorTerceirizado`, `indicadorPermiteAlterarValor`, `indicadorIncluirDebito`, `indicadorCobrarJuros`, `indicadorFiscalizacaoInfracao`, `indicadorVistoria`, `indicadorProgramacaoAutomatica`, `indicadorEmpresaCobranca`, pavimento (rua/calçada), código e constante de funcionalidade; e relações com **`ServicoTipoPrioridade`**, `ServicoTipoSubgrupo`, `ServicoPerfilTipo`, `ServicoTipoReferencia`, **`DebitoTipo`** e **`CreditoTipo`**.

🔵 Consequência importante: **as regras financeiras e de efeito cadastral vivem em dois níveis** — na especificação da solicitação (o que o cliente pediu) e no tipo de serviço (o que se executa) —, e o tipo de serviço já traz o **tipo de débito/crédito** a lançar. 🟢 A prioridade tem par original/atual + fator numérico (`orse_nnfatorprioridade`), 🔵 sugerindo priorização recalculável (envelhecimento/urgência). ❔ A fórmula do fator de prioridade e o que a recalcula não foram comprovados.

## 14. Programação e execução

🟢 `orse_icprogramada` (programada/não programada) e `indicadorProgramacaoAutomatica` no tipo de serviço; 🟢 `orse_icboletim` (inclusão em boletim de medição) e, na micromedição, boletins (`micro_boletim_*`); 🟢 execução de campo em `mobile.exe_os_*` (corte, fiscalização, cliente) e arquivos de OS para terceiros (`mobile.arq_txt_os_cobranca*`) — 🔵 fronteira com operacional/mobile: a **programação e o despacho** pertencem ao operacional; o Atendimento mantém o estado da OS e recebe o retorno. Detalhes ficam para os mapas de Integrações/Batch (evoluções na instalação de referência: fotos, releitura, telemetria).

## 15. Encerramento da OS

🟢 Requisitos e registros: data, **motivo de encerramento** (`AtendimentoMotivoEncerramento`, compartilhado com o RA), parecer, e a distinção executada × **não executada**. 🟢 Encerramento automático parametrizado (`orse_icencerramentoautomatico`) e em massa para OS vencidas por tipo de serviço.

🟢 **Efeitos financeiros na execução/encerramento**: `ControladorOrdemServicoSEJB.gerarDebitoOrdemServico(ordemServicoId, idDebitoTipo, valorDebito, qtdeParcelas, ...)` — 🔵 o débito do serviço é gerado **a partir da OS**, com tipo de débito e parcelamento do valor, alimentando o Faturamento (débito a cobrar → conta) ou uma guia.

## 16. Atualização do Cadastro — o mecanismo real (fronteira resolvida)

Esta era uma dúvida herdada do Cadastro e da Micromedição. 🟢 Evidência decisiva: `orse_iccomercialatualizado` é setado nas **Actions que efetivam o serviço no sistema** — `EfetuarLigacaoEsgotoAction`, `EfetuarInstalacaoHidrometroAction`, `EfetuarSubstituicaoHidrometroAction`, `EfetuarRetiradaHidrometroAction`, `EfetuarRemanejamentoHidrometroAction` (todas marcam a OS com "comercial atualizado" = SIM ao concluir a operação). 🟢 `orse_icatualizaagua`/`orse_icatualizaesgoto` são lidos/gravados no `ControladorOrdemServicoSEJB`, no repositório e nas Actions de retorno de fiscalização (`InformarRetornoOSFiscalizacaoAction`).

🔵 **Interpretação (resolve as dúvidas anteriores)**: o efeito cadastral **não é um gatilho automático do encerramento**, e sim o resultado de **operações de negócio específicas** ("Efetuar ligação", "Efetuar religação", "Efetuar substituição de hidrômetro"...), cada uma executada por seu próprio fluxo, que atualiza o domínio dono (ligação/imóvel no Cadastro, instalação na Micromedição) **e marca a OS** com os indicadores. Os indicadores funcionam como **registro de que o efeito já foi aplicado** — 🔵 papel de controle/idempotência e rastreabilidade ("esta OS já produziu sua atualização comercial"), permitindo consultas de OS executadas sem atualização.

🟡 Hipótese (não comprovada): os indicadores também servem para reprocessamento/conciliação de OS executadas em campo cujo efeito comercial ainda não foi aplicado.

## 17. Relação com Micromedição

🟢 As Actions de hidrômetro (instalação, substituição, retirada, remanejamento) são **do Atendimento** e disparam o efeito na Micromedição — que é onde a **instalação vigente** (`hidrometro_inst_hist` com leituras de fronteira) é efetivamente mantida (micromedicao.md §3.2/§3.3). 🔵 Fronteira: **o Atendimento origina e registra o evento; a Micromedição é a dona do dado de medição**. 🟢 Fiscalização de leitura também transita por OS (`leitura_fiscalizacao`, retorno de fiscalização), e anormalidade de leitura pode **emitir OS automaticamente** (`ltan_icemissaoordemservico`) — 🔵 o ciclo é bidirecional.

## 18. Relação com Faturamento

🟢 Comprovado: (a) **débito de serviço** gerado a partir da OS (`gerarDebitoOrdemServico`, com tipo e parcelas); (b) especificação com `icgeracaodebito`/`icgeracaocredito`/`vldebito`/`icpermitealterarvalor`/`iccobrarjuros` — 🔵 o RA pode gerar lançamento financeiro **mesmo sem OS**, quando a especificação assim define; (c) **crédito a realizar** manipulado no fluxo do RA (`ControladorRegistroAtendimentoSEJB` ≈ 15162–15197, com coleções de crédito a realizar e crédito a ser transferido); (d) **retificação de conta disparada pelo atendimento** — `getControladorRetificarConta().retificarConta(...)` na linha ≈ 15294 (evidência já usada no mapa de Faturamento); (e) `icinformarcontara` e `icalterarvencimento` na especificação — 🔵 há especificações cuja função é justamente informar conta no RA e alterar vencimento.

🔵 Fronteira: o Atendimento **decide e dispara**; o Faturamento **executa e é dono** dos documentos (conta, débito, crédito, guia) e das suas regras.

## 19. Relação com Cobrança

🟢 Ciclo confirmado nos dois sentidos: ação de cobrança → **documento de cobrança** → **OS** (`orse.cbdo_id`, tipo de serviço definido na própria ação — cobranca.md §7/§16) → execução → **atualização da situação da ligação** (§16 acima) → retorno para a Cobrança (situação da ação; `CobrancaAcaoOrdemServicoNaoAceitas` para OS não aceitas). 🟢 A religação é operada com participação da Cobrança (`ControladorCobranca.religarImovelCortado`) e verificação de débito. ❔ Se o pagamento **cancela ou impede** a execução de uma OS de corte já gerada não foi comprovado — dúvida relevante (candidato a caracterização, §31).

## 20. Relação com Arrecadação

🟢 A especificação tem **`step_icinformarpgtoduplicidade`** — 🔵 existe classe de solicitação cuja função é registrar **pagamento em duplicidade**; e há Action dedicada `TransferirDevolucaoValoresPagosDuplicidade`, com o fluxo que aplica a situação `DUPLICIDADE_EXCESSO_DEVOLVIDO` no `ControladorRegistroAtendimentoSEJB` (≈ 15442) e a validação `validarExibirInserirGuiaDevolucao(ra, ordemServico)` na Arrecadação. 🔵 Fronteira confirmada: **devolução ao cliente costuma nascer de um RA** (com OS quando há execução associada), e a Arrecadação é dona da devolução, da guia de devolução e da situação do pagamento (arrecadacao.md §9).

## 21. Atendimento manual / online e canais

🟢 `MeioSolicitacao` (canal), `rgat_icatendimentoonline`, `rgat_idmanual`, e `step_iclojavirtual`. 🔵 Interpretação: o GSAN distingue **canal da solicitação** (como chegou), **atendimento online × manual** (registro imediato no sistema × registro em contingência com número manual, depois conciliado) e **disponibilidade do serviço na loja virtual** (autoatendimento). 🟡 O "manual" tem forte cheiro de **contingência tecnológica do legado** (operação sem sistema disponível) mais que de regra de negócio — mas isso é hipótese; a decisão de transportar ou não fica para a modelagem. ❔ Como a numeração manual é conciliada com o RA definitivo não foi comprovado.

## 22. Agência reguladora

🟢 Existem `RaDadosAgenciaReguladora` e telas de filtro/consulta dedicadas (`ExibirFiltrarRaDadosAgenciaReguladoraAction`, `FiltrarRaDadosAgenciaReguladoraAction`), além de relatório correlato. 🔵 Papel funcional: **dados complementares do RA para prestação de contas/reclamações no âmbito regulatório**. Periférico para esta fase; 🔵 provável obrigação regulatória a preservar como conceito. ❔ Prazos regulatórios próprios e integração externa não investigados.

## 23. Coordenadas e ocorrência fora de imóvel

🟢 `rgat_nncoordenadanorte`, `rgat_nncoordenadaleste` e `rgat_iccorrdenadassemlogr`, além de perímetro por logradouro inicial/final e `rgat_nndiametro`. 🔵 Isso sustenta o atendimento de **ocorrências de rede/via pública** (vazamento em rua, falta d'água em área), onde o objeto da demanda não é uma matrícula — reforçando a leitura do §6 e explicando por que o banco admite `imov_id` nulo.

## 24. Parametrização × código

| Regra | Natureza |
| ----- | -------- |
| Prazo do atendimento | **Parametrizada** (`step_nndiaprazo`); cálculo (dias úteis/feriados) em código |
| Geração de OS a partir do RA | **Parametrizada** (`step_icgeracaoordemservico`) |
| Geração de débito/crédito e valor | **Parametrizada** (especificação: `icgeracaodebito`, `icgeracaocredito`, `vldebito`, `icpermitealterarvalor`, `iccobrarjuros`) + tipo de serviço (`indicadorIncluirDebito`, `valor`, `DebitoTipo`/`CreditoTipo`) |
| Obrigatoriedade de matrícula/cliente/solicitante/documento | **Parametrizada** (`step_ic*`) |
| Encerramento automático (RA e OS) | **Parametrizado** (`step_icencerramentoautomatico`, `orse_icencerramentoautomatico`) |
| Prioridade | **Parametrizada** (`ServicoTipoPrioridade`) + fator em código |
| Atualização cadastral | **Código** (Actions "Efetuar…") + indicadores de controle na OS; `indicadorAtualizaComercial` no tipo de serviço |
| Unidade inicial e roteamento | **Misto** (configuração ligada à especificação/serviço + regras de tramitação em código) |
| Duplicidade (ex.: falta d'água por área) | **Código** (com parâmetros da especificação) |
| Motivos (encerramento, reativação, não cobrança) | **Parametrizados** (tabelas de domínio) |

## 25. Variações por companhia

🟢 **Descoberta relevante**: diferentemente de Micromedição, Faturamento, Cobrança e Arrecadação, **não foram identificadas subclasses de controlador por companhia** em `registroatendimento`/`ordemservico` — apenas o conjunto padrão (`ControladorRegistroAtendimentoSEJB`, `ControladorOrdemServicoSEJB` + Home/Local/Remote).

🔵 A **parametrização é uma fonte importante de variabilidade** neste módulo, em especial `SolicitacaoTipoEspecificacao` e `ServicoTipo` (além de motivos, unidades e prioridades). ⚠️ **Não foi comprovado, porém, que toda diferença entre companhias esteja representada exclusivamente por parâmetros**: a ausência de subclasses não prova isso, e podem existir condicionais dentro dos controladores, Actions/telas específicas, constantes, integrações próprias, diferenças de schema e funcionalidades adicionais da instalação. A classificação em **REGRA BASE / PARAMETRIZAÇÃO / CUSTOMIZAÇÃO / EVOLUÇÃO POSTERIOR** deve ser mantida separada na análise futura de diferenças por companhia (inventário não realizado nesta fase).

## 26. Regras estruturantes (comprovadas)

1. 🟢 **RA e OS são conceitos distintos com identidades próprias**: o RA é o protocolo da demanda; a OS é a unidade de execução. 🟢 RA sem OS existe; 🟢 existem origens de OS independentes de demanda individual (cobrança, fiscalização coletiva, ordem seletiva) — ❔ mas a persistência de OS **sem RA associado** permanece a confirmar (§12).
2. 🟢 **A especificação da solicitação parametriza o comportamento do atendimento** (prazo, obrigatoriedades, geração de OS, efeitos financeiros, encerramento automático, canal).
3. 🟢 **As regras de serviço vivem em dois níveis** (especificação da solicitação + tipo de serviço), incluindo os tipos de débito/crédito a lançar.
4. 🟢 **Tramitação é histórico auditável** (origem, destino, responsável, quem registrou, parecer), com `unid_idatual` como estado corrente.
5. 🟢 **Prazo tem memória**: data prevista original preservada ao lado da atual.
6. 🟢 **Encerrar não é executar**: a OS distingue explicitamente encerrada executada × não executada.
7. 🟢 **Geração, emissão e execução são marcos distintos** da OS.
8. 🟢 **O efeito cadastral/medição é produzido pela operação de negócio específica**, com indicadores na OS registrando que a atualização já ocorreu.
9. 🟢 **Reativação e duplicidade encadeiam protocolos distintos** (não sobrescrevem o RA original) — mesmo princípio de linhagem visto na retificação de contas.
10. 🟢 **A demanda pode não ter matrícula** como objeto (ocorrência de rede/área), e o RA carrega local da ocorrência próprio (endereço, perímetro, bairro-área, coordenadas).
11. 🟢 **O Atendimento é a porta de entrada de lançamentos financeiros** (débito de serviço, crédito, devolução, retificação de conta, alteração de vencimento), sempre delegando ao módulo dono.
12. 🟢 **Não foram identificadas subclasses por companhia** nos controladores centrais de RA/OS, e 🔵 a parametrização (especialmente especificação e tipo de serviço) é fonte importante de variabilidade — ⚠️ sem que se tenha comprovado que **toda** diferença entre companhias seja apenas paramétrica (§25).

## 27. Compatibilidade GSAN → SISAN

| Conceito | Classificação | Motivo |
| -------- | ------------- | ------ |
| Identidade do RA (protocolo) e da OS (execução), separadas | PRESERVAR CONCEITO | Base do domínio e da comunicação com o cliente; identidades reconhecíveis são requisito de migração |
| Vínculo opcional RA↔OS (0..N nos dois sentidos) | PRESERVAR CONCEITO | Reflete a realidade operacional; simplificar quebraria fluxos (OS de cobrança/coletiva) |
| Especificação da solicitação como **núcleo paramétrico** | PRESERVAR CONCEITO (a semântica) / MODERNIZAR MANTENDO COMPATIBILIDADE (a forma) | É a força do módulo; o SISAN deve manter a configurabilidade, com forma a definir na modelagem |
| Dois níveis de regra (especificação + tipo de serviço) | PRESERVAR CONCEITO | Distinção real entre "o que foi pedido" e "o que se executa" |
| Tramitação com histórico (origem/destino/responsável/registrou/parecer) | PRESERVAR CONCEITO | Auditoria de responsabilidade |
| Prazo original × atual | PRESERVAR CONCEITO | Indicadores de cumprimento dependem disso |
| Estados do RA (pendente/encerrado/bloqueado) e da OS (incl. encerrada-não-executada) | PRESERVAR CONCEITO | Semântica operacional e financeira |
| Marcos geração/emissão/execução/encerramento | PRESERVAR CONCEITO | Indicadores e cobrança de serviço |
| Reativação e duplicidade por encadeamento | PRESERVAR CONCEITO | Linhagem do atendimento |
| Local da ocorrência independente do imóvel (endereço, área, coordenadas) | PRESERVAR CONCEITO | Ocorrências de rede existem |
| Indicadores de atualização comercial/água/esgoto na OS | MODERNIZAR MANTENDO COMPATIBILIDADE | A necessidade (saber se o efeito foi aplicado) é real; a forma (flags) pode evoluir para efeito/evento explícito |
| Espera como par único de datas no RA | REESTRUTURAR | Não suporta histórico de múltiplas esperas nem motivo — limitação do legado |
| Reiteração como contador agregado | REESTRUTURAR | Perde o histórico de cada reiteração (quem, quando, por qual canal) |
| `not-null` do imóvel no mapping × `NULL` no banco | EXIGE APROFUNDAMENTO | Precisa de dados reais para decidir o modelo (matrícula opcional vs. obrigatória) |
| `RegistroAtendimentoUnidade` (papel frente a `Tramite`) | EXIGE APROFUNDAMENTO | Semântica não esclarecida |
| Fator numérico de prioridade | EXIGE APROFUNDAMENTO | Fórmula e recálculo desconhecidos |
| Atendimento "manual" com numeração própria | EXIGE APROFUNDAMENTO (provável NÃO TRANSPORTAR como mecanismo) | Aparenta contingência tecnológica; a necessidade (registrar atendimento offline) pode ser resolvida de outra forma |
| Códigos de exibição RA referência/atual/anterior | NÃO TRANSPORTAR | São rótulos de tela do legado, não conceito de domínio |

## 28. Hipóteses para avaliação futura (não são decisões)

1. **RA como "caso/protocolo" e OS como "execução"**, formalizados como agregados distintos com ciclo de vida próprio — motivado pela independência comprovada entre eles.
2. **Workflow explícito de atendimento** (estados + transições + responsáveis + prazos), motivado pela tramitação já ser histórica e pelos estados serem poucos e bem definidos.
3. **Regras por especificação como configuração versionada e governada**, motivado pelo volume de comportamento hoje em flags (`step_ic*`) sem versionamento aparente.
4. **Efeitos de execução como eventos publicados aos módulos donos** (cadastro/medição/financeiro), motivado pelo padrão atual de Actions que atualizam o domínio dono e marcam a OS.
5. **Histórico rico de espera e reiteração** (múltiplas ocorrências com motivo, autor e data), motivado pelas limitações do modelo atual.
6. **Adapter de campo/mobile** para despacho e retorno de OS, motivado pela existência de execução externa (`mobile.exe_os_*`, boletins, fotos).

## 29. Cenários de caracterização identificados (sustentados por evidência)

> Cada cenário abaixo está **sustentado por evidência de que o fluxo existe**. Isso é diferente de afirmar que o **resultado esperado** já está comprovado — vários existem justamente para descobrir o comportamento (ex.: se a espera altera `dataPrevistaAtual`). O resultado de cada um será estabelecido na caracterização (Fase 2).


1. RA encerrado sem OS (parecer + motivo).
2. RA com encerramento automático parametrizado pela especificação.
3. RA que gera OS automaticamente (`step_icgeracaoordemservico`), com serviço, prioridade e valor definidos.
4. RA com tramitação entre duas ou mais unidades (histórico de trâmites + `unid_idatual`).
5. RA em espera (início/fim) e efeito — ou não — sobre `dataPrevistaAtual`.
6. RA reiterado (contador e data).
7. RA de falta d'água generalizada com **duplicidade por bairro-área** (encerramento com motivo e vínculo).
8. RA reativado (novo protocolo ligado ao anterior).
9. RA de ocorrência em via pública (coordenadas / sem logradouro).
10. OS pendente → aguardando liberação → execução em andamento → encerrada executada.
11. OS **encerrada não executada** (com motivo) e efeito na cobrança do serviço.
12. OS de corte originada de ação de Cobrança (`cbdo_id`) e retorno da execução.
13. OS de religação após regularização.
14. OS de instalação/substituição/retirada de hidrômetro (efeito na Micromedição + `iccomercialatualizado`).
15. OS de ligação de água/esgoto (efeito na situação da ligação no Cadastro).
16. Serviço cobrado gerando débito (`gerarDebitoOrdemServico`, com parcelas) × serviço não cobrado (motivo de não cobrança / percentual).
17. Alteração do valor do serviço quando permitido (`indicadorPermiteAlterarValor`).
18. RA que informa **pagamento em duplicidade** → devolução/crédito (fronteira com Arrecadação).
19. RA que dispara **retificação de conta**.
20. RA que **altera vencimento** (`step_icalterarvencimento`).
21. OS referenciada: diagnóstico/vistoria → OS definitiva / OS de retorno.
22. Encerramento em massa de OS vencidas por tipo de serviço.

## 30. Dúvidas abertas

1. ❔ **Persistência de RA sem imóvel**: o banco permite `NULL`, o mapping não. Existem registros nulos? Por qual caminho? (§6 — resolve o modelo de matrícula opcional).
1b. ❔ **Persistência de OS sem RA**: mesma divergência (DDL `rgat_id NULL` × mapping `not-null`). As OS originadas por cobrança/fiscalização coletiva/ordem seletiva gravam RA nulo, associam RA técnico ou reutilizam RA existente? (§12 — define a cardinalidade física RA↔OS no SISAN).
2. ❔ Papel de **`RegistroAtendimentoUnidade`** frente a `Tramite`.
3. ❔ Se a **espera suspende formalmente o prazo** (recálculo de `dataPrevistaAtual`).
4. ❔ Se a **reiteração** altera prazo/prioridade/unidade automaticamente.
5. ❔ Se o **encerramento do RA exige** todas as OS encerradas.
6. ❔ Fórmula e gatilhos do **fator de prioridade**.
7. ❔ Se **pagamento impede/cancela** a execução de OS de corte já gerada.
8. ❔ Conciliação da **numeração manual** com o RA definitivo; quem/quando.
9. ❔ Quem pode **bloquear/desbloquear** RA e se há motivo parametrizado.
10. ❔ Prazos e integração da **agência reguladora**.
11. ❔ Regras de autorização (quem abre, tramita, encerra, reativa, altera valor, autoriza devolução) — mapear no **módulo de Segurança** (fronteira registrada, §31).

## 31. Fronteira com Segurança — **resolvida em 2026-08-14**

Ver [seguranca.md §16](seguranca.md) para o quadro completo. Resumo do que ficou comprovado:

- **Acesso às ações do RA/OS** (abrir, atualizar, tramitar, encerrar, reativar, gerar OS) passa pelo **gate transversal** `FiltroSegurancaAcesso` (`*.do`), que classifica a URL como funcionalidade **ou** operação e verifica concessão em `GrupoFuncionalidadeOperacao` pelos grupos do usuário (união) — para rotas protegidas, o controle não depende do menu. ⚠️ O gate tem **lista de exceções** (inclusive URLs contendo `pesquisar`/`relatorio`) e a abrangência é verificada **condicionalmente** — ver [seguranca.md §7](seguranca.md).
- **Exceções são permissões especiais nomeadas**, verificadas dentro da Action — comprovadas para: `ATUALIZAR_INSTALACAO_DO_HIDROMETRO`, `ATUALIZAR_LIGACAO_DE_ESGOTO_SEM_RA`, `REPLICAR_VALOR_COBRANCA_SERVICO`, `ENCERRAR_COMANDO_COBRANCA_EMPRESA`.
- **Alterar valor de serviço** combina permissão especial + regra paramétrica (`indicadorPermiteAlterarValor`).
- **Abrangência** (gerência regional / unidade de negócio / elo-polo / localidade) atua como segundo eixo, mas **depende de verificações explícitas** em Actions/controladores além do filtro.
- ❔ **Unidade organizacional não apareceu como controle de autorização**: tramitar/encerrar RA de outra unidade não teve bloqueio central identificado — a unidade é dado de roteamento/estado. Permanece dúvida.
- ❔ Sem permissão especial nomeada identificada para: aplicar motivo de não cobrança, liberar OS em "aguardando liberação", alterar prioridade — provável regra na Action.

Pontos que o mapa de Segurança cobriu/deve seguir aprofundando: permissão para abrir/atualizar RA; **tramitar** (e para quais unidades); **encerrar** RA e OS (e encerrar sem execução); **reativar**; **bloquear**; **alterar valor do serviço** e aplicar motivo de não cobrança; **liberar** OS que aguarda liberação; autorizar **devolução/crédito**; disparar **retificação** e **alteração de vencimento**. 🟢 Há sinais de que a **unidade organizacional do usuário** participa do roteamento (RA/OS têm unidade atual; `Tramite` tem usuário responsável e usuário que registrou), e o Cadastro já mostrou **abrangência por localidade/gerência** no usuário — a interação entre abrangência, unidade e permissão por funcionalidade é o ponto central a esclarecer lá.

## 32. Evidências principais

```text
RA:              atendimentopublico/registroatendimento/RegistroAtendimento.hbm.xml → atendimentopublico.registro_atendimento
                 (rgat_cdsituacao, rgat_dtprevistaoriginal/atual, rgat_tmencerramento, rgat_qtreiteracoes,
                  rgat_tminicioespera/tmfimespera, rgat_dsparecerencerramento, rgat_icatendimentoonline, rgat_idmanual,
                  rgat_nncoordenadanorte/leste, rgat_iccorrdenadassemlogr, rgat_nndiametro, brar_id, unid_idatual,
                  rgat_idreativacao, rgat_idduplicidade)
                 RegistroAtendimento.java: SITUACAO_PENDENTE(1)/ENCERRADO(2)/BLOQUEADO(3);
                 CODIGO_ASSOCIADO_SEM_RA/RA_REFERENCIA/RA_ATUAL/RA_ANTERIOR (rótulos de tela, não versionamento)
Especificação:   SolicitacaoTipoEspecificacao.hbm.xml (step_nndiaprazo, icmatricula, iccliente, icsolicitante,
                 icdocumentoobrigatorio, icvaldocresponsavel, icparecerencerramento, icligacaoagua, icverificardebito,
                 icgeracaodebito, icgeracaocredito, vldebito, icpermitealterarvalor, iccobrarjuros, iccobrancamaterial,
                 icgeracaoordemservico, icurgencia, icencerramentoautomatico, icinformarcontara,
                 icinformarpgtoduplicidade, icalterarvencimento, iclojavirtual, nncodigoconstante)
                 SolicitacaoTipoEspecificacao.java:172/176 INDICADOR_MATRICULA_OBRIGATORIO=1 / NAO_OBRIGATORIO=2
Matrícula/imóvel: DDL registro_atendimento: "imov_id int4 NULL" (banco permite) × mapping many-to-one imovel not-null="true";
                 ControladorRegistroAtendimentoSEJB ≈4866/5041 (fluxo de falta d'água generalizada com matrícula não
                 obrigatória; verificarRegistroAtendimentoFaltaAgua:4835);
                 RepositorioRegistroAtendimentoHBM ≈3987 (HQL "left join rgat.bairroArea ... where baiArea.id = :idBairroArea")
Tramitação:      Tramite.hbm.xml (tram_dsparecertramite, tram_tmtramite; unid_idorigem, unid_iddestino,
                 usur_idresponsavel, usur_idregistro, rgat_id); RegistroAtendimentoUnidade.hbm.xml (papel a esclarecer)
OS:              ordemservico/OrdemServico.hbm.xml → atendimentopublico.ordem_servico (orse_cdsituacao, orse_tmgeracao,
                 orse_tmemissao, orse_tmencerramento, orse_vlservicooriginal/atual, orse_pcvalorcobranca, sncm_id,
                 orse_icprogramada, orse_icencerramentoautomatico, orse_icatualizaagua, orse_icatualizaesgoto,
                 orse_iccomercialatualizado, orse_icboletim, orse_icdiagnostico, orse_nnfatorprioridade,
                 stpr_idoriginal/idatual, orse_idreferencia, svtp_id/svtp_idreferencia, rgat_id (opcional), cbdo_id,
                 fzcl_id, coss_id, proj_id)
                 OrdemServico.java: SITUACAO_PENDENTE(1), SITUACAO_ENCERRADO(2) + "encerrada porém não foi executada",
                 SITUACAO_EXECUCAO_EM_ANDAMENTO(3); OrdemServicoSituacao.java: ENCERRADO(2), EXECUCAO_EM_ANDAMENTO(3),
                 AGUARDANDO_LIBERACAO(4)
Serviço:         ServicoTipo.hbm.xml (valor, tempoMedioExecucao, indicadorAtualizaComercial, indicadorTerceirizado,
                 indicadorPermiteAlterarValor, indicadorIncluirDebito, indicadorCobrarJuros, indicadorVistoria,
                 indicadorFiscalizacaoInfracao, indicadorProgramacaoAutomatica, indicadorEmpresaCobranca;
                 FKs ServicoTipoPrioridade, ServicoTipoSubgrupo, ServicoPerfilTipo, ServicoTipoReferencia,
                 DebitoTipo, CreditoTipo)
Efeito cadastral: gui/atendimentopublico/EfetuarLigacaoEsgotoAction:444; hidrometro/EfetuarInstalacaoHidrometroAction:127;
                 EfetuarSubstituicaoHidrometroAction:157; EfetuarRetiradaHidrometroAction:160;
                 EfetuarRemanejamentoHidrometroAction:213 (todas setam indicadorComercialAtualizado);
                 leitura de atualizaAgua/atualizaEsgoto em ControladorOrdemServicoSEJB, RepositorioOrdemServicoHBM,
                 InformarRetornoOSFiscalizacaoAction
Financeiro:      ControladorOrdemServicoSEJB.gerarDebitoOrdemServico:1889 (idDebitoTipo, valorDebito, qtdeParcelas);
                 ControladorRegistroAtendimentoSEJB ≈15162–15197 (CreditoARealizar / crédito a ser transferido),
                 ≈15294 (getControladorRetificarConta().retificarConta), ≈15442 (PagamentoSituacao.DUPLICIDADE_EXCESSO_DEVOLVIDO);
                 Arrecadação: validarExibirInserirGuiaDevolucao(ra, ordemServico)
Higiene:         ControladorOrdemServicoSEJB.encerrarOrdemServicoVencida:10279 (por tipo de serviço e nº de dias)
Companhia:       ausência de subclasses por companhia em registroatendimento/ordemservico (apenas Home/Local/Remote/SEJB)
Reg. agência:    RaDadosAgenciaReguladora + ExibirFiltrarRaDadosAgenciaReguladoraAction / FiltrarRaDadosAgenciaReguladoraAction
Campo/mobile:    mobile.exe_os_* , micro_boletim_* , mobile.arq_txt_os_cobranca* (instalação de referência — evoluções)
```
