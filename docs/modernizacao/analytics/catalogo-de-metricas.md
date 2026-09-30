# Catálogo de Métricas

> **Adendo pós-Fase 0 (2026-09-29)** — refinamento arquitetural antes da Fase 1; a Fase 0 continua encerrada em 29/09/2026. Parte de [Gerencial & Analytics](gerencial-analytics.md).
>
> ⚠️ **Conceito, não implementação.** Não decide schema, linguagem de fórmula, motor de cálculo nem ferramenta. Os códigos e exemplos são **ilustrativos** — o catálogo real nasce com cada métrica, na implementação. Marcas como em [`financeiro-contabilizacao.md §1.1`](../modulos/financeiro-contabilizacao.md).

---

## 1. Para que serve

**Uma definição por métrica**, reconhecida por todas as interfaces — painel, relatório, série, mapa, alerta e referência regulatória. Sem catálogo, cada tela recalcula "inadimplência" a seu modo, e o número muda conforme quem pergunta.

---

## 2. O que o ecossistema GSAN já tinha — e o que se corrige

[GSAN] O satélite operacional guardava `operacao.indicador` (**fórmula, responsável, grupo**) e `operacao.indicador_mensal`, calculados pela função `geraindicador` — **17 indicadores mensais** ([`operacional.md §6.2–§6.3`](../modulos/operacional.md#63--o-que-a-função-geraindicador-revela)). A ideia de catálogo **existia**; a execução ensina o que evitar:

| No satélite | Consequência | No catálogo OpenGSAN |
| ----------- | ------------ | -------------------- |
| Fórmula, responsável e grupo por indicador | ✅ A necessidade é válida | Mantido: **código, owner, fórmula** — agora versionada |
| Só granularidade **mensal** | Nenhum painel operacional possível | **Granularidade declarada** por métrica |
| Leitura **direta** de tabelas de Atendimento, Cadastro e Faturamento | Acoplamento; qualquer mudança de schema quebra o indicador | Consome **fatos publicados** (ADR-0007, canal 9) |
| **31 tipos de serviço**, uma localidade e uma data de corte **fixados por identificador** | Customização institucional escondida na fórmula | **Filtros como dado versionado**, com owner — nunca identificador no código |
| Índice de **perda física** algebricamente **zero**; macromedição sempre **100%** | Número plausível e sempre errado — erro silencioso | Toda fórmula tem **caso de verificação** com massa sintética; resultado constante é suspeito por definição |
| "Precariedade" medida por uma **situação especial de faturamento** | Conceito comercial como *proxy* operacional, sem aviso | *Proxy* permitido **só declarado** — campo *limitações* |
| Conexão a outro banco por `dblink` com credencial em texto claro | 🔴 Achado de segurança nº 20 — segredo comprometido | Nenhuma credencial em fórmula, função ou código |

---

## 3. Métrica — o conceito

```text
Métrica
├─ código interno ......... estável; nunca reutilizado
├─ nome ................... pode mudar sem mudar a identidade
├─ definição .............. o que mede, com inclusões e exclusões
├─ owner .................. área de negócio que responde pela definição
├─ unidade
├─ fórmula ................ sobre fatos publicados
├─ fontes ................. fatos e módulos de origem
├─ granularidade .......... hora · dia · referência · mês · ano
├─ agregação .............. soma · média · último valor · razão de somas…
├─ dimensões .............. tempo/competência · território comercial · estrutura operacional ·
│                           categoria · ativo · …
├─ vigência
├─ versão
├─ 🆕 limitações .......... proxies, estimativas, cobertura parcial — declaradas
└─ 🆕 status .............. rascunho · vigente · descontinuada
```

| Papel | Dono |
| ----- | ---- |
| O **fato** | Módulo de origem |
| A **definição** | *Owner* de negócio — aprova cada versão |
| O **cálculo**, a série, o painel | Gerencial & Analytics |

---

## 4. Regras

1. **Mudou a fórmula, mudou a versão.** A série guarda a versão com que cada ponto foi calculado; comparar versões diferentes é **marcado** na interface, nunca silencioso.
2. **Razão de somas ≠ média de razões** — a agregação é declarada, não deduzida da fórmula.
3. **Valor carrega qualidade** quando a fonte a tem: medido · estimado · incompleto; e o painel diz *atualizado até*.
4. **Filtros e exclusões são dado** — com owner, vigência e motivo.
5. **Toda fórmula tem caso de verificação** com massa sintética antes de ficar *vigente*.
6. **[PROP]** O produto pode trazer **definições de referência** (MTTR, por exemplo) — dado versionado que a companhia **adota, ajusta ou descarta**. Métrica cuja definição vem de norma registra a **origem normativa**.
7. ❌ **Código de métrica não reutiliza código de informação SINISA.** Nomear a métrica com o código oficial seria um mapeamento implícito.

---

## 5. 🔴 Métrica OpenGSAN ≠ informação SINISA

```text
Métrica OpenGSAN   ≠   Informação SINISA        — mesmo quando parecem semanticamente equivalentes
```

| | Métrica OpenGSAN | Informação SINISA |
| - | ---------------- | ----------------- |
| **Quem define** | *Owner* de negócio da companhia | Glossário oficial do ciclo |
| **Para que** | Operar, medir, decidir | Declaração regulatória |
| **Muda quando** | A companhia versiona | O ciclo publica novo glossário |
| **Identidade** | Código interno + versão | Código + versão do glossário |
| **Valor** | Calculado | **Informado pelo usuário** ([ADR-0009](../decisoes/0009-sinisa-preenchimento-manual.md)) |

Relação **opcional e futura**, nunca implícita:

```text
Informação SINISA (código + versão do glossário)
        ▲
        │  mapeamento configurado pela companhia — RASCUNHO → EM VALIDAÇÃO → ATIVO,
        │  desligado por padrão, revalidado a cada glossário
        ▼
Métrica interna (código + versão)
```

Sem mapeamento, a métrica só aparece no Workspace SINISA como `REFERÊNCIA — NÃO É VALOR SINISA` ([`sinisa.md §10`](../regulatorio/sinisa.md#10-fontes-de-apoio-e-dados-auxiliares), [§16](../regulatorio/sinisa.md#16-automação-futura--mapeamento-configurado-pela-companhia)).

---

## 6. Métricas de referência — exemplos conceituais

⚠️ **Sem metas** — metas, limites e tolerâncias são dados versionados e contextuais ([Gerencial §8](gerencial-analytics.md#8-metas-limites-e-alertas)). Códigos **ilustrativos**.

| Código | O que mede | Owner | Fontes | Unidade | Granularidade |
| ------ | ---------- | ----- | ------ | ------- | ------------- |
| `VOL_PRODUCAO_OPERACIONAL` | Volume produzido **pela definição operacional da companhia** — ponto de medição declarado | Gestão Operacional | Macromedição · telemetria · registro de operação | m³ | Hora · dia · mês |
| `NIVEL_RESERVATORIO` | Nível de reservação | Gestão Operacional | Telemetria | % | Minuto · hora |
| `ATIVOS_INDISPONIVEIS` | Ativos fora de condição de operar | Gestão de Ativos | Estado do ativo | Quantidade | Instantâneo · dia |
| `ENERGIA_ESPECIFICA` | Energia por volume produzido | Gestão de Ativos · Gestão Operacional | Energia · volume | kWh/m³ | Mês |
| `VOL_MICROMEDIDO` | Consumo micromedido, **por origem** — real · média · mínimo | Micromedição | Consumo | m³ | Referência |
| `VOL_FATURADO` | Volume faturado | Faturamento | Contas emitidas | m³ | Referência |
| `VAL_FATURADO` | Valor faturado — versão vigente da conta | Faturamento | Contas emitidas | R$ | Referência |
| `VAL_ARRECADADO` | Valor recebido e classificado | Arrecadação | Recebimentos | R$ | Dia · mês |
| `IND_INADIMPLENCIA` | Débito vencido sobre faturado — ⚠️ corte de atraso é **parâmetro da companhia** | Cobrança | Posição de dívida derivada | % | Mês |
| `PRAZO_EXECUCAO_OS` | Tempo da abertura à execução da OS | Atendimento e Execução | Estados da OS | Horas | Dia · mês |
| `ADERENCIA_PROGRAMACAO` | Executado conforme programado ÷ programado | Gestão de Ativos (PCM) | Programação × OS | % | Semana · mês |
| `CUMPRIMENTO_PREVENTIVA` | Preventivas executadas no prazo ÷ previstas | Gestão de Ativos (PCM) | Plano × OS | % | Mês |
| `BACKLOG_HORAS` · `IDADE_BACKLOG` | Carga pendente e sua idade | Gestão de Ativos (PCM) | Necessidades não terminais | Horas · dias | Instantâneo · semana |
| `PCT_EMERGENCIAL` | Trabalho emergencial ÷ total | Gestão de Ativos (PCM) | Necessidades × OS | % | Mês |
| `MTBF` · `MTTR` | Tempo médio entre falhas · de reparo | Gestão de Ativos (PCM) | Falhas · OS corretivas | Horas | Mês · ano |
| `DISPONIBILIDADE_ATIVO` | Tempo em condição de operar ÷ tempo total | Gestão de Ativos | Estado do ativo · resultado da OS | % | Mês |
| `QTD_PARADAS` | Paradas por tipo, motivo e sistema | Gestão Operacional | Paradas | Quantidade | Dia · mês |
| `DURACAO_PARADA` | Do início real à normalização real | Gestão Operacional | Parada | Horas | Por parada · mês |
| `UNIDADES_AFETADAS` | Unidades usuárias no impacto registrado | Gestão Operacional | Snapshot de impacto | Quantidade | Por parada |
| `DESVIO_PREVISAO_PARADA` | Realizado − previsto — primeira e última previsão | Gestão Operacional | Histórico de previsões | Horas | Por parada · mês |
| `SINISA_PCT_PREENCHIDO` · `_VALIDADO` · `_APROVADO` | **Progresso** do ciclo — nunca valor declarado | Prestação de Informações | Estados dos valores declarados | % | Instantâneo |

⚠️ **Perdas** não têm métrica de referência: a metodologia do balanço hídrico **não está decidida** e é decisão da companhia ([completude §10](../auditoria/completude-funcional-regulatoria.md#10-operação-qualidade-metrologia-perdas-telemetria-e-energia)). ⚠️ Fontes de energia — contrato e fatura — são **pendentes**.

---

## 7. Governança

```text
rascunho ──► vigente ──► descontinuada
   │  owner aprova;          │  a série antiga continua legível,
   │  caso de verificação    │  com a versão que a produziu
   ▼  aprovado               ▼
```

Toda mudança de definição, fórmula, filtro ou agregação é **nova versão** com autor, aprovação e motivo — o mesmo rigor do glossário do SINISA, pelo mesmo motivo: o número só significa algo junto com a sua definição.

## 8. Pendências

| # | Pendência |
| - | --------- |
| 1 | Linguagem e motor de fórmula |
| 2 | Contrato de dados publicado por módulo — pré-requisito das fontes |
| 3 | Metodologia de perdas — decisão da companhia |
| 4 | Definições de referência que o produto trará — e como a companhia as adota |
