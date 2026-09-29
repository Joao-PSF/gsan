# Gerencial & Analytics

> **Adendo pós-Fase 0 (2026-09-29)** — refinamento arquitetural antes da Fase 1; a Fase 0 continua encerrada em 29/09/2026. Registro em [`alteracoes/2026-09-29-adendo-pos-fase0.md`](../alteracoes/2026-09-29-adendo-pos-fase0.md).
>
> Promove a capacidade até aqui chamada **Analytics** ([catálogo §14](../modulos/funcionalidades-futuras.md#14-bi--analytics)) a **Gerencial & Analytics**. Definições de métrica em [`catalogo-de-metricas.md`](catalogo-de-metricas.md).
>
> ⚠️ **Não decide** armazenamento analítico, modelo dimensional físico, ferramenta de BI, motor de consulta, fila ou biblioteca de gráficos (§11). Marcas como em [`financeiro-contabilizacao.md §1.1`](../modulos/financeiro-contabilizacao.md).

---

## 1. O que é — e para que existe

**[DEC] Capacidade transversal, consumidora dos fatos dos módulos.** Não é domínio transacional e não é dona de fato algum.

| Existe para | **Não** existe para |
| ----------- | ------------------- |
| Operar melhor · acompanhar desempenho · medir · comparar · investigar · decidir | 🔴 **Preencher o SINISA** — o SINISA pode usar seus dados **como referência**; a finalidade do Gerencial é outra ([ADR-0009](../decisoes/0009-sinisa-preenchimento-manual.md)) |
| Série histórica, agregação, comparação entre recortes | Listar registros correntes de um módulo — isso é o módulo **Relatórios** ([catálogo §14.2](../modulos/funcionalidades-futuras.md#142-distinção-necessária)) |

[GSAN] O ecossistema GSAN **já separou** a análise do transacional — base gerencial própria, papel de banco dedicado a OLAP, *matviews* analíticas, relatório OLAP por ano — e o satélite operacional mantinha um **catálogo rudimentar de indicadores** com fórmula e responsável, cujos dois índices centrais eram **degenerados** ([`operacional.md §6.3`](../modulos/operacional.md#63--o-que-a-função-geraindicador-revela)). O que se herda é a **necessidade**; o que se corrige está no [catálogo de métricas §2](catalogo-de-metricas.md#2-o-que-o-ecossistema-gsan-já-tinha--e-o-que-se-corrige).

---

## 2. Arquitetura conceitual

```text
MÓDULOS DONOS ──► fatos e projeções publicados ──► GERENCIAL & ANALYTICS ──► painéis · relatórios gerenciais
(Faturamento,        contrato de dados              ├─ catálogo de métricas       · séries · mapas · alertas
 Arrecadação,        (ADR-0007, canal 9) —          ├─ cálculo versionado
 OS, PCM, Parada…)   nunca tabelas internas          ├─ séries por granularidade   ──► Workspace SINISA:
                                                    └─ metas · limites · alertas       REFERÊNCIA — NÃO É VALOR SINISA
```

| Regra | Origem |
| ----- | ------ |
| Consome **fatos e projeções publicados** — nunca telas nem tabelas internas | [ADR-0007 §7](../decisoes/0007-arquitetura-de-interface.md) · lição do `geraindicador`, que lia tabelas de três módulos |
| O **fato** é do módulo; a **definição** da métrica, do *owner* de negócio; o **cálculo**, a série e o painel, do Gerencial | [Catálogo §3](catalogo-de-metricas.md#3-métrica--o-conceito) |
| Relatório gerencial usa o **motor comum de artefatos** e o controle de acesso de Relatórios (D-03) | Não duplica o módulo |

---

## 3. Uma métrica, várias interfaces

```text
VOL_PRODUCAO_OPERACIONAL
        ├─ painel diário ................... nível operacional
        ├─ relatório mensal ................ nível tático
        ├─ série histórica ................. nível estratégico
        └─ fonte auxiliar do preenchimento regulatório — REFERÊNCIA — NÃO É VALOR SINISA
```

🔴 **A definição é uma só** — a interface muda, o significado não. E nenhuma interface transforma a métrica em outra coisa: no Workspace SINISA ela continua sendo **métrica interna** ([`sinisa.md §10`](../regulatorio/sinisa.md#10-fontes-de-apoio-e-dados-auxiliares)).

---

## 4. Níveis

| Nível | Horizonte | Exemplos | Pergunta típica |
| ----- | --------- | -------- | --------------- |
| **Operacional** | Hoje · últimas horas · últimos dias | Produção · reservatórios · **paradas** · OS · ativos indisponíveis · manutenção · ocorrências | *O que está acontecendo agora e o que exige ação?* |
| **Tático** | Diário · semanal · mensal | Faturamento · arrecadação · inadimplência · perdas · **PCM** · atendimento · produtividade · energia | *Estamos cumprindo o planejado no período?* |
| **Estratégico** | Mensal · anual · série histórica | Cobertura · universalização · receitas · perdas · eficiência · ativos críticos · investimentos · metas · indicadores regulatórios | *Para onde vamos e a que custo?* |

⚠️ *Indicadores regulatórios* no nível estratégico são **métricas internas** que a companhia acompanha — prazos de atendimento da norma do regulador, por exemplo —, **nunca** "valor SINISA". *Perdas* aparece em dois níveis, com horizontes distintos; a metodologia continua **não decidida** ([completude §10](../auditoria/completude-funcional-regulatoria.md#10-operação-qualidade-metrologia-perdas-telemetria-e-energia)).

[INF] O painel operacional precisa dizer **até quando** o dado vai — *atualizado até* — porque nem toda fonte é contínua (telemetria × registro manual).

---

## 5. Interface

**[DEC] A ADR-0007 continua válida**, sem alteração:

```text
server-driven  +  ilhas ricas para  gráficos · mapas · séries · drill-down
```

| Regra | Consequência |
| ----- | ------------ |
| Página server-driven; filtros e recortes como requisições parciais | O backoffice **não vira SPA** |
| Gráfico, mapa e série são **ilhas** com gatilho declarado | Ilha **sem regra de negócio e sem decisão de autorização** — recebe o dado já autorizado |
| Exportação de dados a ferramentas analíticas externas | Pelo **contrato de dados** (canal 9), não por endpoint de tela |

---

## 6. Drill-down

Quando o dado suporta:

```text
companhia → regional → município → localidade → sistema → unidade → registro de origem
```

| Cuidado | Regra |
| ------- | ----- |
| **Duas hierarquias** | Território comercial (regional, localidade, setor) e estrutura operacional (sistema, setor de abastecimento, unidade) **são distintas**; o drill-down atravessa a **correspondência com dono** da Gestão Operacional ([`operacional.md §5.1`](../modulos/operacional.md#51-território-comercial--estrutura-operacional)) — nunca uma coluna copiada |
| **Registro de origem** | O fato no módulo dono — conta, pagamento, OS, parada —, aberto pelo **caso de uso autorizado** do dono, sob o **escopo territorial** do usuário (D-17) |
| **Privacidade** | Agregados não expõem pessoa; descer ao registro exige a mesma autorização da tela do dono. 🔴 O Gerencial **não é porta lateral** para dado pessoal |

---

## 7. Mapa gerencial

Consome a capacidade GIS para **paradas · perdas · OS · ativos · cobertura · atendimento**. 🔴 **A geometria continua de Redes/GIS**; o mapa mostra agregados por área e o recorte respeita o escopo territorial do usuário. Mesmo padrão do [mapa de paradas](../dominio/paradas-interrupcoes.md#13-mapa-de-paradas--interface-conceitual): ilha no canal hospedeiro, sobre a camada de publicação espacial.

---

## 8. Metas, limites e alertas

| Elemento | O que é |
| -------- | ------- |
| **Meta** | Valor-alvo de uma métrica, num recorte e numa vigência |
| **Limite** | Fronteira operacional — acima ou abaixo dela exige ação |
| **Tendência** | Direção desejada |
| **Tolerância** | Faixa aceitável em torno da meta ou do limite |
| **Alerta** | Condição sobre a métrica que gera **evento de negócio** — o canal é da Notificação |

🔴 **[DEC] Tudo versionado e contextual; nada fixo no código.** Cada meta registra **vigência**, **recorte** (companhia, regional, sistema, unidade) e **origem**: decisão da companhia, contrato de programa ou concessão, regulador (parâmetro regulado) ou lei — as metas legais de universalização entram como **dado com origem normativa**. Nenhuma meta universal vem com o produto.

---

## 9. Visões por tema

### 9.1 PCM

Backlog (itens e horas, por idade) · preventivas no prazo · aderência à programação · proporção emergencial · disponibilidade · MTBF · MTTR · custo técnico · tempo parado por manutenção. Conceitos em [`pcm.md §9`](../dominio/pcm.md#9-indicadores).

### 9.2 Paradas

Quantidade · duração · **unidades usuárias afetadas** · população afetada · sistemas · reincidência por área · causas · ativos envolvidos · **previsão × realizado**. ⚠️ População afetada é **estimativa** — rotulada, com o método da companhia; unidades afetadas vêm do snapshot de impacto ([`paradas-interrupcoes.md §5`](../dominio/paradas-interrupcoes.md#5-impacto)).

### 9.3 SINISA — só progresso

```text
SINISA — ciclo 2027
Preenchimento   72%        Campos pendentes      31
Validado        51%        Campos com ressalva    8
Aprovado        20%
```

🔴 **Nunca** um valor calculado apresentado como "valor SINISA". O dado vem do **Workspace SINISA** — progresso do fluxo, não número declarado ([`sinisa.md §12`](../regulatorio/sinisa.md#12-acompanhamento-da-coleta)).

---

## 10. Restrições ao transacional — desde já

Mesmo com o Gerencial implementado depois, o transacional precisa **nascer** com o que torna a análise possível. Estende a restrição que a ordem já impunha desde a Etapa 0 ([`dependencias-e-ordem-implementacao.md §20.3`](../modulos/dependencias-e-ordem-implementacao.md#203-fiscal-sped-analytics-gis)):

| Preservar | Porque |
| --------- | ------ |
| **Identidade** estável | 🟢 O legado destrói a identidade do pagamento ao arquivar — a série perde o elo |
| **Competência** explícita | Referência de faturamento ≠ data do fato ≠ data do registro |
| **Timestamps** — momento do fato e momento do registro | Atraso de registro distorce painel operacional e série |
| **Origem** — usuário, processamento, integração, dispositivo | Distinguir medido × estimado × digitado; atribuir responsabilidade |
| **Histórico relevante** | Estado atual não reconstrói o passado — previsão revisada da parada, versão da conta |
| **Fatos** publicados | Contrato de dados; nada de leitura direta de tabela alheia |
| **Estados** e transições | Backlog, OS, parada — medir tempo em cada estado exige a transição registrada |

---

## 11. O que não se decide

Nada físico: ❌ modelo estrela · ❌ ClickHouse · ❌ Vertica · ❌ BigQuery · ❌ DuckDB · ❌ Kafka · ❌ *lakehouse* · ❌ ferramenta de BI. **Somente arquitetura conceitual.** A escolha virá quando houver volume real e perguntas reais — com ADR.

---

## 12. Ordem

**[DEC] Incremental, sem etapa própria.** Cada métrica entra quando o fato de que depende existe — atendimento e OS a partir da Etapa 2; consumo, da 3; faturamento, da 4; arrecadação, da 5; cobrança, da 6; PCM e paradas, na trilha estrutural. Painéis ricos — mapas, séries longas — vêm quando há série para mostrar. 🔴 **Nenhum gate do núcleo depende do Gerencial**, e o **Workspace SINISA não depende dele** ([`sinisa.md §19`](../regulatorio/sinisa.md#19-ordem)).

---

## 13. Fronteiras

| Com | Atravessa | Dono |
| --- | --------- | ---- |
| Módulos de negócio | Fatos e projeções publicados | O módulo |
| Relatórios | Motor de artefatos e controle de acesso | Relatórios |
| Redes/GIS | Geometria, camada de publicação espacial | Redes/GIS |
| Notificação | Evento de alerta → canal | Notificação |
| Prestação de Informações | Progresso do ciclo (entra) · referência rotulada (sai) | Workspace SINISA |
| Segurança | Autorização e escopo territorial no drill-down | Segurança |

## 14. Pendências

| # | Pendência |
| - | --------- |
| 1 | Tecnologia de armazenamento e consulta analítica — ADR quando houver volume e perguntas reais |
| 2 | Metodologia de perdas (balanço hídrico) — decisão da companhia, não do produto |
| 3 | Método de estimativa de população afetada |
| 4 | Latência aceitável por nível — operacional × tático |
| 5 | Contrato de dados publicado por módulo — forma e versionamento |
