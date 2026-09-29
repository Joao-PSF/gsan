# Cenários Críticos — PCM e Paradas

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md). Criado no **adendo pós-Fase 0** (2026-09-29) — [registro](../../alteracoes/2026-09-29-adendo-pos-fase0.md).
>
> 🔴 **Requisitos nativos do OpenGSAN — oráculo N.** O GSAN público não tem PCM nem Parada como conceito: a "programação de manutenção" do módulo Operacional é **programação por área**, consultada no RA de falta de água, e continua coberta por CEN-OPE-002 (C1). Não há baseline a capturar: o resultado esperado vem das decisões registradas em [`pcm.md`](../../dominio/pcm.md), [`paradas-interrupcoes.md`](../../dominio/paradas-interrupcoes.md) e na [ADR-0008](../../decisoes/0008-gestao-de-ativos-nativa.md).

🔵 **Leitura da área**: quatro invariantes — *não existe ordem de trabalho além da OS*; *a Parada existe com ou sem GIS*; *impacto comunicado não muda*; *previsão revisada não apaga a anterior*.

---

## CEN-PCM-001 — Necessidade programada gera OS sem duplicar

- **Criticidade**: P1
- **Etapa OpenGSAN**: T — trilha estrutural (Gestão de Ativos + OS da Etapa 2)
- **Conceitos relacionados**: necessidade de manutenção e backlog do PCM (requisito nativo) · OS do Atendimento e Execução · histórico técnico do ativo
- **Objetivo**: verificar que o PCM planeja e programa **sem ordem de trabalho paralela** — toda execução é OS que referencia a necessidade, e o resultado volta ao PCM e aos Ativos
- **Pré-condições**: ATV-01 (bomba com plano preventivo e uma falha no histórico); OPR-01; equipe com capacidade declarada; ciclo da OS da Etapa 2 operante
- **Entrada**: V1 — plano preventivo vence: necessidade → planejada → programada → OS → executada; V2 — necessidade que exige **duas** OS (duas equipes); V3 — OS encerrada **não executada**; V4 — tentativa de alterar o estado da OS a partir do PCM; V5 — falha atendida por OS emergencial aberta pelo Atendimento **sem** necessidade prévia
- **Operação GSAN**: não aplicável — sem PCM no GSAN público
- **Operação conceitual OpenGSAN**: planejar e programar a necessidade; emitir OS; controlar o resultado
- **Observações semânticas**: estado da necessidade (backlog) · estado da OS · referência OS → necessidade → ativo e plano · quantidade de OS por necessidade · entidades de trabalho existentes · resultado técnico aplicado ao histórico do ativo · motivo de retorno ao backlog
- **Localizadores GSAN**: não aplicável — a programação por área do Operacional está em CEN-OPE-002
- **Resultado semântico esperado**: V1 — **uma** OS, referenciando a necessidade; estados da necessidade e da OS **distintos**; resultado aplicado por Ativos ao histórico; necessidade *concluída* só com o resultado aceito. V2 — duas OS, cada uma de **uma** necessidade; a necessidade conclui quando ambas encerram com resultado aceito. V3 — a necessidade **volta ao backlog** (*aguardando programação*), com motivo; a OS permanece encerrada no histórico; nenhuma necessidade nova. V4 — **recusado**: o PCM observa, não altera. V5 — a necessidade corretiva nasce **do resultado** da OS emergencial e se vincula a ela — **sem segunda OS**. 🔴 Invariante: não existe entidade de trabalho além da OS
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: identificadores e datas concretos
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado de [`pcm.md`](../../dominio/pcm.md) §6–§7 e da ADR-0008 (item 5)
- **Gate que este cenário protege**: trilha estrutural — *PCM operante sem ordem de trabalho paralela*
- **Evidência**: [`pcm.md`](../../dominio/pcm.md) §3, §6, §7; [`gestao-de-ativos.md`](../../dominio/gestao-de-ativos.md) §10–§11; [ADR-0008](../../decisoes/0008-gestao-de-ativos-nativa.md)

---

## CEN-PAR-001 — Parada programada: impacto registrado e comunicação prévia

- **Criticidade**: P1
- **Etapa OpenGSAN**: T — trilha estrutural (Gestão Operacional mínima da Etapa 2; cálculo de impacto quando houver Redes/GIS)
- **Conceitos relacionados**: Parada / interrupção operacional (requisito nativo) · impacto versionado · necessidade do PCM · OS
- **Objetivo**: verificar que a parada programada é conceito da Gestão Operacional, **independente do GIS**: o impacto é calculado **ou** declarado, guardado como snapshot, e a comunicação prévia sai antes da execução
- **Pré-condições**: OPR-01; ATV-01 com necessidade que exige indisponibilidade; RED-01 (área com topologia íntegra e área sem topologia); IMV-01 e IMV-02 na área afetada; antecedência de comunicação como parâmetro regulado
- **Entrada**: V1 — com cálculo de isolamento (Giswater): proposta → em análise → planejada → ativa → em normalização → encerrada; V2 — **sem** Giswater: impacto declarado pelo operador; V3 — recálculo do impacto depois da comunicação; V4 — análise de isolamento cancelada ou recalculada na ferramenta; V5 — outra parada sobreposta na mesma área
- **Operação GSAN**: não aplicável — sem Parada no GSAN público
- **Operação conceitual OpenGSAN**: propor, analisar, aprovar e executar a parada programada
- **Observações semânticas**: estado da parada · forma do impacto (calculado · declarado · misto) · snapshot com data do cálculo e versão da topologia · unidades usuárias afetadas · eventos de comunicação e o momento de cada um × antecedência exigida · OS de manobra e de serviço · referência à necessidade do PCM · estado da análise de isolamento **separado** do estado da parada
- **Localizadores GSAN**: não aplicável — a programação consultada pelo Atendimento está em CEN-OPE-002
- **Resultado semântico esperado**: V1 — estados percorridos em ordem; impacto calculado guardado com data e versão da topologia; comunicação prévia **antes** de *ativa*, com antecedência ≥ parâmetro; OS programada na janela aprovada. V2 — a parada é **completa** com impacto declarado e responsável registrado. V3 — **nova versão** do impacto; o snapshot comunicado **não muda**. V4 — o estado da parada **não muda** com o estado da análise; só a análise é marcada. V5 — sobreposição **detectada** em *em análise* e exposta à decisão — nunca resolvida automaticamente
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: identificadores de elementos de rede e horários concretos
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado de [`paradas-interrupcoes.md`](../../dominio/paradas-interrupcoes.md) §4–§7, §10, §12
- **Gate que este cenário protege**: trilha estrutural — *parada programada operante, com ou sem cálculo de impacto*
- **Evidência**: [`paradas-interrupcoes.md`](../../dominio/paradas-interrupcoes.md) §4–§7, §10, §12; NR ANA 11/2024 ([completude §3.1](../../auditoria/completude-funcional-regulatoria.md#31-matriz-de-conformidade-funcional--nr-ana-112024)); API oficial do Giswater — estados do *mincut*

---

## CEN-PAR-002 — Parada emergencial até a normalização

- **Criticidade**: P1
- **Etapa OpenGSAN**: T — trilha estrutural
- **Conceitos relacionados**: Parada emergencial (requisito nativo) · impacto declarado e misto · OS · necessidade corretiva do PCM
- **Objetivo**: verificar que a emergência **não exige planejamento prévio**: a parada nasce ativa, o impacto pode começar declarado, e a necessidade corretiva nasce do resultado da execução
- **Pré-condições**: OPR-01; RED-01; ATV-01; IMV-01 e IMV-02 na área afetada
- **Entrada**: V1 — rompimento de adutora: parada nasce ativa com impacto declarado; depois o cálculo é acrescentado, com justificativa; V2 — emergência numa área **sem** topologia; V3 — o reparo revela válvula **inacessível**
- **Operação GSAN**: não aplicável — sem Parada no GSAN público
- **Operação conceitual OpenGSAN**: registrar a parada emergencial; executar, comunicar e normalizar
- **Observações semânticas**: estado inicial · ausência de estados de planejamento · versões do impacto (declarado → misto) com justificativa · OS de manobra e de reparo · eventos de comunicação (iniciada, previsão revisada, normalizada) · necessidade corretiva criada e vinculada
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — nasce **ativa**, sem passar por *proposta* nem *planejada*; impacto declarado (v1) e misto (v2, com justificativa) **ambos preservados**; comunicação *iniciada* emitida; *encerrada* só depois da normalização confirmada. V2 — completa só com impacto declarado. V3 — necessidade de manutenção da válvula criada no PCM, vinculada à parada e à OS; a Parada **não** cria OS por conta própria
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: horários concretos
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado de [`paradas-interrupcoes.md`](../../dominio/paradas-interrupcoes.md) §2, §4, §5, §8, §11
- **Gate que este cenário protege**: trilha estrutural — *parada emergencial registrada sem planejamento prévio*
- **Evidência**: [`paradas-interrupcoes.md`](../../dominio/paradas-interrupcoes.md) §2, §4, §5, §8, §11; [`pcm.md`](../../dominio/pcm.md) §3

---

## CEN-PAR-003 — Normalização: previsões revisadas e realizado

- **Criticidade**: P1
- **Etapa OpenGSAN**: T — trilha estrutural
- **Conceitos relacionados**: Parada — normalização e histórico de previsões (requisito nativo)
- **Objetivo**: verificar que a normalização é estado próprio, que o encerramento exige confirmação e que previsão revisada **nunca sobrescreve** a anterior — base do previsto × realizado
- **Pré-condições**: parada planejada de CEN-PAR-001 em estado *ativa*
- **Entrada**: V1 — duas revisões da previsão de normalização; V2 — normalização em curso e depois confirmada; V3 — tentativa de encerrar sem confirmar a normalização; V4 — cancelamento de outra parada planejada que não ocorreu
- **Operação GSAN**: não aplicável — sem Parada no GSAN público
- **Operação conceitual OpenGSAN**: revisar previsão; normalizar; encerrar; cancelar
- **Observações semânticas**: histórico de previsões · evento de comunicação por revisão · início e normalização reais · desvio contra a primeira e contra a última previsão · motivo do cancelamento · comunicação de cancelamento
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — as **três** previsões preservadas, cada revisão com seu evento de comunicação. V2 — *em normalização* → *encerrada*, com a normalização real registrada; desvio calculável contra a primeira e contra a última previsão. V3 — **recusado**. V4 — *cancelada*, com motivo e comunicação; nunca *encerrada*
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: horários concretos
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado de [`paradas-interrupcoes.md`](../../dominio/paradas-interrupcoes.md) §3, §4, §14
- **Gate que este cenário protege**: trilha estrutural — *previsto × realizado mensurável*
- **Evidência**: [`paradas-interrupcoes.md`](../../dominio/paradas-interrupcoes.md) §3, §4, §12, §14; [`gerencial-analytics.md`](../../analytics/gerencial-analytics.md) §9.2; [catálogo de métricas](../../analytics/catalogo-de-metricas.md) — `DESVIO_PREVISAO_PARADA`
