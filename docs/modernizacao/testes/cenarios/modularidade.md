# Cenários Críticos — Modularidade e Perfis de Implantação

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md). Criado no **segundo adendo pós-Fase 0** (2026-09-29) — [registro](../../alteracoes/2026-09-29-adendo-2-perfis-de-implantacao.md).
>
> 🆕 **Revisão consolidada (2026-09-30)**: o instalável *Services* passou a chamar-se **Atendimento** — textos de MOD-002 e MOD-004 ajustados; o comportamento só mudou em **MOD-004 V4**, pela re-auditoria da obrigatoriedade ([`modulos-e-perfis-de-implantacao.md §15.2`](../../arquitetura/modulos-e-perfis-de-implantacao.md#152--re-auditoria-da-obrigatoriedade--revisão-consolidada-2026-09-30)).
>
> 🔴 **Requisitos nativos arquiteturais — oráculo N.** O GSAN não tem perfis de implantação. O resultado esperado vem da [ADR-0010](../../decisoes/0010-monolito-modular-perfis-de-implantacao.md) e de [`modulos-e-perfis-de-implantacao.md`](../../arquitetura/modulos-e-perfis-de-implantacao.md). Onde o cenário passa por comportamento que o GSAN tem — o cálculo da conta, por exemplo —, **essa parte** continua sob o oráculo 1 no cenário que já a cobre.

🔵 **Leitura da área**: dois cenários provam o **mecanismo** com módulos-fixture já na fundação — ativação e fronteira; cinco provam que cada módulo independente **sobe sem o vizinho**, no momento em que o módulo nasce. Sem eles, dependência acidental só aparece quando alguém tenta instalar um perfil parcial — tarde demais.

---

## CEN-MOD-001 — SINISA inicia somente com a Platform

- **Criticidade**: P1
- **Etapa OpenGSAN**: R — trilha regulatória (Workspace SINISA)
- **Conceitos relacionados**: perfil de implantação SINISA (requisito nativo) · módulo instalável independente · ADR-0009
- **Objetivo**: verificar que o Workspace SINISA sobe e opera o ciclo manual completo tendo a Platform como único outro módulo, sem carregar nada de outro módulo
- **Pré-condições**: PRF-01 (perfil SINISA); SIN-01; USR-12; contexto institucional — prestador e municípios — configurado na Platform
- **Entrada**: V1 — inicializar o perfil; V2 — declarar, validar, aprovar e registrar a submissão de um campo; V3 — anexar evidência; V4 — consultar o inventário do perfil; V5 — abrir a área de dados auxiliares de um campo
- **Operação GSAN**: não aplicável — sem prestação ao SINISA nem perfis no GSAN
- **Operação conceitual OpenGSAN**: inicializar perfil; declarar SINISA
- **Observações semânticas**: módulos ativos · contratos e provedores no inventário · menus, permissões, jobs, endpoints e adapters registrados · fluxo da declaração · guarda da evidência · área de dados auxiliares
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — sobe; o inventário lista Platform e SINISA; **nenhum** menu, permissão, job, endpoint ou adapter de outro módulo — nenhum adapter de NFAg, por exemplo. V2 — fluxo completo, como CEN-REG-001 V1. V3 — evidência guardada pela infraestrutura de documentos da Platform, com a semântica do SINISA. V4 — fontes auxiliares: *nenhuma*. V5 — área vazia, sem erro e sem valor sugerido
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: identificadores e horários
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado da ADR-0010 (itens 2, 6 e 8) e de [`modulos-e-perfis-de-implantacao.md`](../../arquitetura/modulos-e-perfis-de-implantacao.md) §12
- **Gate que este cenário protege**: 1º ciclo SINISA — *o perfil SINISA isolado opera antes do primeiro ciclo declarado pelo OpenGSAN*
- **Evidência**: [`modulos-e-perfis-de-implantacao.md`](../../arquitetura/modulos-e-perfis-de-implantacao.md) §12, §17; [`sinisa.md`](../../regulatorio/sinisa.md) §4, §19; [ADR-0010](../../decisoes/0010-monolito-modular-perfis-de-implantacao.md)

---

## CEN-MOD-002 — Atendimento opera sem Commercial, com referência externa e snapshot

- **Criticidade**: P1
- **Etapa OpenGSAN**: 2 — Atendimento e execução
- **Conceitos relacionados**: OS com origem externa (requisito nativo) · RA ≠ OS (C1) · referência externa e snapshot
- **Objetivo**: verificar que o Atendimento sobe, registra RA e executa OS sem o Commercial, recebendo cliente, unidade e origem de um sistema externo, e que a OS guarda o snapshot mínimo para ser interpretada depois
- **Pré-condições**: PRF-01 (perfil ATENDIMENTO com adapter externo); EXT-01 (sistema comercial externo sintético — cliente, unidade usuária, ligação); ESP-02 (especificação que gera OS)
- **Entrada**: V1 — RA de um cliente externo gera OS; V2 — o sistema externo abre OS diretamente, por contrato permitido, sem RA; V3 — execução e encerramento; V4 — o sistema externo altera o endereço da unidade depois da execução; V5 — tipo de serviço com efeito sobre a ligação; V6 — sistema externo sem autorização tenta abrir OS
- **Operação GSAN**: não aplicável — a origem de OS sem RA existe no GSAN (Localizadores), mas o cenário prova a modularidade, não equivalência
- **Operação conceitual OpenGSAN**: registrar demanda; solicitar execução; executar; encerrar
- **Observações semânticas**: origem da OS — RA ou sistema externo · referência externa — sistema, tipo, identificador · snapshot e momento em que foi tomado · estados da OS · efeito solicitado e a quem · autorização do sistema externo
- **Localizadores GSAN**: OS sem RA gerada pela cobrança — `ControladorCobranca:24135–24142` → `ControladorOrdemServicoSEJB:1032–1086`; `ordem_servico.rgat_id` nulo no DDL (`20160118183224_dump.sql:15708`)
- **Resultado semântico esperado**: V1 — OS vinculada ao RA, com referência externa e snapshot. V2 — OS **sem RA**, com origem *sistema externo* e referência. V3 — ciclo da OS igual ao do perfil completo. V4 — o snapshot da OS **não muda**; nenhuma cópia mestre do cadastro externo. V5 — o efeito é **solicitado** ao dono pelo contrato, via adapter externo; sem provedor configurado, o tipo de serviço com efeito é **recusado na configuração**. V6 — **recusado**: identidade de sistema sem concessão (ADR-0007)
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: identificadores, endereços e horários sintéticos
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado da ADR-0010 (itens 4 e 5) e de [`modulos-e-perfis-de-implantacao.md`](../../arquitetura/modulos-e-perfis-de-implantacao.md) §7–§8
- **Gate que este cenário protege**: 2 → 3 — *o Atendimento sobe sem o Commercial*
- **Evidência**: [`modulos-e-perfis-de-implantacao.md`](../../arquitetura/modulos-e-perfis-de-implantacao.md) §7, §8; [`atendimento.md §12`](../../modulos/atendimento.md#12-ra--os-cardinalidade-real); ATE-02

---

## CEN-MOD-003 — Commercial fatura com medição externa

- **Criticidade**: P0
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: provedor de consumo faturável (requisito nativo) · consumo com origem (C1) · correção de consumo pelo dono da medição (D-14)
- **Objetivo**: verificar que o Commercial fatura com consumo fornecido por sistema externo de leitura, preservando a origem do consumo, e que a correção de consumo continua sendo **pedido** ao dono da medição
- **Pré-condições**: PRF-01 (perfil COMMERCIAL com adapter externo de medição); EXT-01 (sistema de leitura/AMI sintético); IMV-01; IMV-04; TAR-01
- **Entrada**: V1 — consumo real informado pelo provedor externo; V2 — consumo por média, com origem; V3 — imóvel sem medição (mínimo); V4 — retificação que altera o consumo; V5 — provedor indisponível no faturamento; V6 — perfil sem Metering e sem adapter de medição
- **Operação GSAN**: não aplicável — o GSAN não fatura com medição de outro sistema
- **Operação conceitual OpenGSAN**: faturar com provedor externo de consumo; retificar
- **Observações semânticas**: origem do consumo em cada conta · valores · pedido de correção ao provedor e sua resposta · estado das contas quando o provedor falha · validação do perfil na inicialização
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1–V3 — contas calculadas com o consumo e a **origem declarada** pelo provedor; nenhuma leitura do Metering é exigida. V4 — correção **solicitada** ao provedor; o Commercial **não grava consumo**; a conta só é retificada com o consumo corrigido devolvido. V5 — contas afetadas ficam **pendentes e visíveis** — nenhuma conta com consumo inventado. V6 — **inicialização recusada**: contrato obrigatório sem provedor. ⚠️ O cálculo tarifário sobre o consumo continua sob o oráculo 1, em CEN-FAT-001
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: identificadores e valores sintéticos
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado da ADR-0010 (itens 4, 5 e 9) e de [`modulos-e-perfis-de-implantacao.md`](../../arquitetura/modulos-e-perfis-de-implantacao.md) §6
- **Gate que este cenário protege**: 4 → 5 — *o Commercial fatura com medição externa, com origem e sem gravar consumo*
- **Evidência**: [`modulos-e-perfis-de-implantacao.md`](../../arquitetura/modulos-e-perfis-de-implantacao.md) §6, §16; [visão §20.2](../../dominio/visao-conceitual-opengsan.md#202-fronteiras-principais); D-14

---

## CEN-MOD-004 — Assets fecha o ciclo de manutenção com OS externa

- **Criticidade**: P1
- **Etapa OpenGSAN**: T — trilha estrutural
- **Conceitos relacionados**: provedor externo de execução (requisito nativo) · necessidade de manutenção e backlog do PCM
- **Objetivo**: verificar que o Assets sobe sem o Atendimento e fecha o ciclo de manutenção por um sistema externo de OS, sem criar ordem de trabalho própria — e que, sem provedor de execução, só a capacidade de execução falta
- **Pré-condições**: PRF-01 (perfil ASSETS com adapter de OS externa); EXT-01 (OS/CMMS externo sintético); ATV-01
- **Entrada**: V1 — necessidade programada enviada ao sistema externo; V2 — estado e resultado chegam do sistema externo; V3 — OS externa encerrada sem execução; V4 — perfil sem Atendimento e sem adapter de execução
- **Operação GSAN**: não aplicável — sem PCM no GSAN público
- **Operação conceitual OpenGSAN**: programar necessidade; solicitar execução externa; controlar resultado
- **Observações semânticas**: solicitação de execução e sua referência à necessidade · estado da necessidade × estado externo · mapeamento declarado no adapter · resultado aplicado ao histórico do ativo · entidades de trabalho existentes · inventário do perfil e capacidades registradas
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — solicitação enviada com referência à necessidade; **nenhuma** OS interna nem ordem de trabalho paralela. V2 — estado da necessidade derivado do estado externo pelo mapeamento declarado; o **Assets aplica** o resultado ao histórico. V3 — a necessidade volta ao backlog, com motivo. V4 — **sobe**; o inventário mostra a execução *ausente*; ativos, planos, backlog e planejamento operam; a necessidade **não é programada nem enviada** à execução, e **nada** no Assets registra execução — nenhuma ordem paralela (revisão consolidada de 2026-09-30: a execução condiciona a capacidade, não o módulo)
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: identificadores e datas
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado da ADR-0010 e de [`modulos-e-perfis-de-implantacao.md`](../../arquitetura/modulos-e-perfis-de-implantacao.md) §9 e §15.2
- **Gate que este cenário protege**: trilha estrutural — *o Assets opera sem o Atendimento interno*
- **Evidência**: [`pcm.md`](../../dominio/pcm.md) §6–§7; [`modulos-e-perfis-de-implantacao.md`](../../arquitetura/modulos-e-perfis-de-implantacao.md) §9, §15.2

---

## CEN-MOD-005 — Operations opera sem Networks

- **Criticidade**: P1
- **Etapa OpenGSAN**: T — trilha estrutural
- **Conceitos relacionados**: Parada com impacto declarado (requisito nativo) · perfil sem capacidade GIS
- **Objetivo**: verificar que a Operations sobe e registra paradas sem o módulo Networks — sem mapa e sem cálculo — e que nada tenta usar capacidade espacial
- **Pré-condições**: PRF-01 (perfil OPERATIONS); OPR-01
- **Entrada**: V1 — parada programada com impacto declarado por recortes; V2 — parada emergencial; V3 — procurar o mapa de paradas; V4 — acrescentar o Networks ao perfil depois
- **Operação GSAN**: não aplicável — sem Parada no GSAN público
- **Operação conceitual OpenGSAN**: registrar e conduzir paradas sem GIS
- **Observações semânticas**: forma do impacto · telas e menus registrados · lista e linha do tempo · impacto das paradas anteriores depois do acréscimo do Networks
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1–V2 — paradas completas com impacto **declarado**. V3 — mapa **não registrado**: nenhum menu nem tela de mapa; lista e linha do tempo disponíveis. V4 — com o Networks ativo, o impacto passa a poder ser calculado ou misto; as paradas anteriores **mantêm** o impacto declarado — snapshot
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: horários concretos
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado da ADR-0010 (itens 7 e 8) e de [`paradas-interrupcoes.md`](../../dominio/paradas-interrupcoes.md) §5, §13
- **Gate que este cenário protege**: trilha estrutural — *a Operations opera sem GIS*
- **Evidência**: [`paradas-interrupcoes.md`](../../dominio/paradas-interrupcoes.md) §5, §13; [`modulos-e-perfis-de-implantacao.md`](../../arquitetura/modulos-e-perfis-de-implantacao.md) §10–§11

---

## CEN-MOD-006 — Ativação: módulo desligado não registra nada, atualização não ativa módulo, perfil inválido falha cedo

- **Criticidade**: P0
- **Etapa OpenGSAN**: 0 — Fundação
- **Conceitos relacionados**: ativação de módulo instalável (requisito nativo) · autorização no caso de uso (ADR-0007)
- **Objetivo**: verificar que um módulo desligado não expõe menu, permissão, endpoint, job, adapter, relatório nem evento; que ativação e autorização são perguntas distintas; que atualização de versão não liga módulo; e que perfil inválido não inicia
- **Pré-condições**: FXM-01 (módulos-fixture A, B e C); USR-01 com concessões de funcionalidades de C
- **Entrada**: V1 — perfil com A, sem C; V2 — o usuário com concessão de C chama um endpoint de C diretamente; V3 — job agendado de C; V4 — atualização de versão que introduz o módulo D; V5 — perfil com B e sem A; V6 — perfil com A e adapter externo declarado para o contrato que C atenderia
- **Operação GSAN**: não aplicável — sem perfis no GSAN
- **Operação conceitual OpenGSAN**: inicializar perfil; atualizar versão
- **Observações semânticas**: registros de interface, permissão, endpoint, job e adapter · resposta à chamada direta · estado das concessões · estado de D depois da atualização · diagnóstico de perfil inválido · inventário
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — nada de C registrado; o inventário mostra C *ausente*. V2 — recusado por **inexistência**, não por falta de concessão; a concessão fica **dormente**, não é apagada. V3 — o job **não inicia**. V4 — D nasce **desabilitado**; o perfil não muda. V5 — **inicialização recusada**, com diagnóstico. V6 — sobe; o inventário mostra o contrato atendido por **adapter externo**
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: não aplicável
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado da ADR-0010 (itens 8, 9 e 10)
- **Gate que este cenário protege**: 0 → 1 — *ativação provada com módulos-fixture antes do primeiro módulo real*
- **Evidência**: [`modulos-e-perfis-de-implantacao.md`](../../arquitetura/modulos-e-perfis-de-implantacao.md) §19, §22; [ADR-0010](../../decisoes/0010-monolito-modular-perfis-de-implantacao.md)

---

## CEN-MOD-007 — Dependência opcional ausente não é importada nem acessada

- **Criticidade**: P1
- **Etapa OpenGSAN**: 0 — Fundação
- **Conceitos relacionados**: fronteira entre módulos instaláveis (requisito nativo) · contrato do consumidor · nenhum HTTP interno
- **Objetivo**: verificar, por teste arquitetural e de perfil, que o núcleo de um módulo não importa internos de dependência opcional, que a ligação entre módulos passa por contrato e que nenhuma comunicação interna usa HTTP
- **Pré-condições**: FXM-01; regras arquiteturais declaradas
- **Entrada**: V1 — violação deliberada: o núcleo de A importa o repositório de C; V2 — A chama C por HTTP interno; V3 — A usa o contrato com C ausente; V4 — a ponte entre A e C com os dois ativos e com um só
- **Operação GSAN**: não aplicável — sem perfis no GSAN
- **Operação conceitual OpenGSAN**: verificar fronteira; inicializar perfil
- **Observações semânticas**: resultado da verificação arquitetural · comportamento de A sem C · presença da ponte
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — a verificação **reprova** o build. V2 — **reprovado**. V3 — A sobe e a capacidade que dependia de C fica **ausente**, sem erro de classe não encontrada. V4 — a ponte existe **só** com os dois ativos
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: não aplicável
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado da ADR-0010 (item 5) e da ADR-0001 (verificação de fronteira)
- **Gate que este cenário protege**: 0 → 1 — *a fronteira de implantação é verificável*
- **Evidência**: [`modulos-e-perfis-de-implantacao.md`](../../arquitetura/modulos-e-perfis-de-implantacao.md) §16, §21; [ADR-0010](../../decisoes/0010-monolito-modular-perfis-de-implantacao.md); [ADR-0001](../../decisoes/0001-monolito-modular-spring-boot.md)
