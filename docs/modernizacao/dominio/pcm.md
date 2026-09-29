# PCM — Planejamento e Controle da Manutenção

> **Adendo pós-Fase 0 (2026-09-29)** — refinamento arquitetural antes da Fase 1; a Fase 0 continua encerrada em 29/09/2026 ([auditoria final](../auditoria/auditoria-final-fase0.md)). Registro da execução em [`alteracoes/2026-09-29-adendo-pos-fase0.md`](../alteracoes/2026-09-29-adendo-pos-fase0.md).
>
> Complementa a [visão de Gestão de Ativos](gestao-de-ativos.md) (§10 Manutenção e §11 Sem OS paralela), que já fixava *plano → necessidade → OS → resultado → histórico*. Aquilo era a base; não era um PCM.
>
> ⚠️ **Não decide** schema, tabelas, algoritmo de programação, calendário, aplicativo de campo, estoque ou ferramenta. Marcas **[GSAN]** · **[REF]** · **[INF]** · **[PROP]** · **[DEC]** · **[PEND]** como em [`financeiro-contabilizacao.md §1.1`](../modulos/financeiro-contabilizacao.md).

---

## 1. O que é — e o que não é

**[DEC] PCM é uma capacidade da Gestão de Ativos**: transforma necessidades de manutenção em trabalho **planejado, priorizado, programado, acompanhado e medido**.

| O PCM faz | O PCM **não** faz |
| --------- | ----------------- |
| Planeja: define *o que*, *como*, *com quê* e *com quem* | Executar — a execução é da **OS** do Atendimento e Execução |
| Prioriza o backlog | Emitir uma "ordem de trabalho da manutenção" paralela à OS |
| Programa: *quando*, *em que janela*, *com qual equipe* | Decidir a interrupção do abastecimento — a **Parada** é da Gestão Operacional ([paradas](paradas-interrupcoes.md)) |
| Acompanha a execução e controla o resultado | Ser dono de geometria, topologia ou impacto — Redes/GIS |
| Mede e aprende | Contabilizar o custo — o custo técnico é de Ativos; o contábil, do ERP |

**[GSAN]** Não há oráculo: o GSAN público não tem PCM. A "programação de manutenção" do módulo Operacional é **programação por área** consultada pelo atendimento de falta d'água (CEN-OPE-002) — relacionada à [Parada](paradas-interrupcoes.md), não a um PCM. PCM é **requisito nativo** (oráculo N).

---

## 2. Fluxo

```text
necessidade ──► backlog ──► planejamento ──► programação ──► OS ──► execução ──► controle ──► histórico / aprendizado
 (Ativos/PCM)    (PCM)         (PCM)            (PCM)       (emitida   (Atendimento   (PCM)        (Ativos: histórico,
                                                             para o      e Execução)                 condição, custo;
                                                             Atendimento)                            PCM: ajuste de plano)
```

🔴 **Planejar ≠ programar.** Planejar responde *o que precisa ser feito e com quais recursos*; programar responde *quando, em que janela e com qual equipe*. Uma necessidade pode estar planejada e esperar semanas por janela, material ou parada aprovada.

---

## 3. Origem da necessidade

| Tipo de manutenção | Gatilho típico | Origem |
| ------------------ | -------------- | ------ |
| **Preventiva** | Plano por tempo, horas de operação ou uso | Plano |
| **Corretiva** | Falha detectada — OS, RA, **parada emergencial** | Falha |
| **Preditiva** | Condição medida (vibração, temperatura, telemetria) | Condição |
| **Inspeção** | Plano de inspeção; campanha | Plano |
| **Calibração** | Plano de verificação de instrumento — ⚠️ obrigações metrológicas do prestador **pendentes por fonte** ([completude §10](../auditoria/completude-funcional-regulatoria.md#10-operação-qualidade-metrologia-perdas-telemetria-e-energia)) | Plano |
| **Substituição** | Fim de vida, reincidência, decisão de custo | Condição · decisão |

**[DEC]** Plano, falha e condição **geram necessidade** — nunca OS diretamente. [INF] Uma válvula marcada como *inacessível* num cálculo de isolamento (Giswater) é uma necessidade corretiva natural ([paradas §8](paradas-interrupcoes.md#8-manobras-e-válvulas)).

---

## 4. Planejamento

Cada necessidade planejada vira um **pacote de trabalho planejado** — conceito do PCM, **não** uma ordem de trabalho:

| Conceito | Significado | Dono |
| -------- | ----------- | ---- |
| **Ativo / localização funcional** | Onde e em quê | Gestão de Ativos |
| **Criticidade** | Do **ativo** — consequência de sua falha | Gestão de Ativos |
| **Prioridade** | Da **necessidade** — urgência relativa no backlog | PCM |
| **Escopo** | O que será feito | PCM |
| **Procedimento** | Plano, *checklist*, instrução | PCM |
| **Duração estimada** | Horas e duração de calendário | PCM |
| **Materiais · peças · ferramentas** | Recursos necessários — ⚠️ estoque é **pendente** (módulo futuro ou ERP) | PCM declara; estoque fornece |
| **Competências · equipe necessária** | Especialidades e quantidade | PCM |
| **Riscos · permissões** | Trabalho em altura, espaço confinado, eletricidade — permissão de trabalho | PCM |
| **Bloqueios** | Bloqueio e etiquetagem de energia; isolamento hidráulico | PCM planeja; a manobra é OS |
| **Necessidade de parada** | Se a execução interrompe ou restringe o serviço | PCM **solicita** janela; a **Parada** é da Gestão Operacional |
| **Dependências** | Outra necessidade, material, contrato, parada aprovada | PCM |

🔴 **Criticidade ≠ prioridade.** Uma bomba crítica pode ter uma necessidade de baixa prioridade (lubrificação em dia); um ativo pouco crítico pode ter uma necessidade urgente (vazamento em via pública).

---

## 5. Programação

| Representa | Observação |
| ---------- | ---------- |
| Data · turno · janela | A janela pode depender de **parada aprovada** |
| Equipe · capacidade · disponibilidade | Capacidade em horas por equipe e período |
| Sequência · dependências | Ordem entre trabalhos do mesmo ativo ou da mesma área |
| **Conflito** | Mesma equipe, mesmo ativo, janelas sobrepostas, **paradas sobrepostas na mesma área** |
| Ativo · parada necessária | Referências — não cópias |
| **OS correspondente** | Emitida ao **programar/liberar** o trabalho, com referência à necessidade |

🔴 **Programação do PCM ≠ programação da OS.** [GSAN] O Atendimento já programa OS em **roteiro de equipe**, com o distrito operacional como critério (`ControladorOrdemServicoSEJB:1293`; [`operacional.md §4`](../modulos/operacional.md#4-conceitos--e-a-pergunta-que-separa-domínio-de-crud)). O PCM decide **janela, data-alvo e prioridade** da manutenção; o Atendimento **distribui e sequencia** as OS dentro dela. Reprogramar fora da janela é **evento** que o PCM vê — e que a aderência mede.

[INF] O Giswater marca cálculos de isolamento **em conflito** (estado *Conflict* do *mincut*, API oficial) — insumo para detectar paradas sobrepostas, não decisão.

---

## 6. Backlog — estados da necessidade

🔴 **Estes estados são do PCM, não da OS.** A OS tem ciclo próprio no Atendimento e Execução.

```text
necessidade identificada
        ↓
aguardando planejamento
        ↓
planejada
        ↓
aguardando programação   ◄── espera material, janela, parada, equipe
        ↓
programada ──────────────► OS emitida
        ↓
em execução              ◄── derivado do estado da OS
        ↓
concluída                ◄── resultado recebido e aceito pelo controle do PCM
```

| Além do fluxo | Natureza |
| ------------- | -------- |
| **Atrasada** | **Condição derivada** — prazo vencido em qualquer estado não terminal; não é estado |
| **Suspensa** | Estado, com motivo; volta ao estado anterior |
| **Cancelada** | Terminal, com motivo |

| PCM (necessidade) | OS (Atendimento e Execução) |
| ----------------- | --------------------------- |
| *programada* | OS emitida e programada |
| *em execução* | OS em execução |
| *concluída* | OS encerrada **e** resultado aceito — uma OS encerrada **não executada** devolve a necessidade ao backlog, com motivo |

---

## 7. Sem ordem de trabalho paralela

```text
PCM ──programa──► OS ──► Atendimento e Execução ──► resultado ──► PCM (controle) + Ativos (histórico)
```

**[DEC]** Não existe `PCMWorkOrder`, "ordem de manutenção" ou equivalente. Regras:

1. Toda execução de manutenção é **OS**, e a OS **referencia** a necessidade (e, por ela, o ativo e o plano).
2. Uma necessidade pode gerar **uma ou mais** OS (equipes, etapas); cada OS pertence a **uma** necessidade.
3. O estado da OS é do Atendimento; o PCM o **observa** — nunca o altera.
4. O resultado técnico (falha, causa, componente, material, horas, tempo parado, custo) volta: **Ativos aplica** ao histórico do ativo; **o PCM** fecha a necessidade e alimenta o controle.

Mesmo contrato da [visão conceitual §14.3](visao-conceitual-opengsan.md) — *solicita × aplica* — já fixado na [ADR-0008](../decisoes/0008-gestao-de-ativos-nativa.md).

🆕 **Perfis (ADR-0010)**: a execução é **contrato**. Com o módulo *Services*, a OS é a do OpenGSAN — caminho preferencial. Sem ele, a solicitação vai a um **sistema externo de OS ou CMMS**; o estado da necessidade deriva do estado externo por **mapeamento declarado no adapter**, e o resultado volta para o Assets aplicar. Continua valendo: nenhuma ordem de trabalho paralela ([`modulos-e-perfis-de-implantacao.md §9`](../arquitetura/modulos-e-perfis-de-implantacao.md#9-assets--pcm); CEN-MOD-004).

---

## 8. Controle e aprendizado

Reincidência ajusta o plano; necessidade corretiva repetida sugere revisão de preventiva ou substituição; backlog envelhecido revela falta de capacidade. [DEC] O PCM **mede e recomenda**; a decisão de substituir ou investir é da companhia.

---

## 9. Indicadores

⚠️ **Conceitos, não metas.** Metas, limites e tolerâncias são **dados versionados e contextuais** do [Gerencial & Analytics](../analytics/gerencial-analytics.md) — nenhuma meta universal é fixada.

| Indicador | Ideia | Fonte |
| --------- | ----- | ----- |
| **Aderência à programação** | Trabalho executado conforme programado ÷ programado no período | Programação × OS |
| **Cumprimento da preventiva** | Preventivas executadas no prazo ÷ previstas | Plano × OS |
| **Backlog** | Carga pendente — em itens e em horas | Necessidades não terminais |
| **Idade do backlog** | Tempo desde a identificação | Necessidades |
| **Planejada × emergencial** | Proporção do trabalho por origem | Necessidades × OS |
| **MTBF** | Tempo médio entre falhas, por ativo ou classe | Falhas registradas |
| **MTTR** | Tempo médio de reparo | OS corretivas |
| **Disponibilidade · indisponibilidade** | Tempo em condição de operar × fora de operação | Ativos + resultado |
| **Reincidência** | Falha repetida no mesmo ativo em janela definida | Histórico |
| **Custo** | Custo técnico por ativo, classe, localização | Ativos |
| **Tempo parado** | Indisponibilidade atribuível à manutenção | Resultado da OS · paradas |

Definições completas no [catálogo de métricas](../analytics/catalogo-de-metricas.md).

---

## 10. Fronteiras

| Com | Atravessa | Dono |
| --- | --------- | ---- |
| **Gestão de Ativos** | Ativo, criticidade, plano, histórico | Ativos — o PCM é capacidade dela |
| **Atendimento e Execução** | OS emitida → estado → resultado | Atendimento (OS) · PCM (necessidade) |
| **Gestão Operacional** | Pedido de janela → **Parada** aprovada | Gestão Operacional |
| **Redes/GIS** | Localização, isolamento, impacto calculado | Redes/GIS |
| **Estoque · contratos** | Materiais; empresa de campo | ⚠️ Pendentes — módulo futuro ou ERP; catálogo 19 |
| **Gerencial & Analytics** | Indicadores | Gerencial consome |

---

## 11. Cenário

**CEN-PCM-001** — necessidade programada gera OS **sem duplicar**; o resultado volta ao PCM e aos Ativos ([`testes/cenarios/pcm-paradas.md`](../testes/cenarios/pcm-paradas.md)).

## 12. Pendências

| # | Pendência |
| - | --------- |
| 1 | Unidade de capacidade (horas × equipe × turno) e calendário de trabalho |
| 2 | Estoque de peças e reserva de material — módulo futuro ou ERP |
| 3 | Contratos de manutenção — catálogo 19 |
| 4 | Escala de prioridade — padrão do produto ou da companhia |
| 5 | Obrigações metrológicas do prestador para calibração — pendente por fonte |
