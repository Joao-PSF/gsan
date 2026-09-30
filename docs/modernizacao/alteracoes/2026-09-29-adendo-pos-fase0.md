# [2026-09-29] Adendo pós-Fase 0 — PCM, Paradas, SINISA e Gerencial

> **ADENDO PÓS-FASE 0 — refinamento arquitetural antes da Fase 1.** A Fase 0 foi encerrada em 29/09/2026 ([auditoria final](../auditoria/auditoria-final-fase0.md)) e **continua encerrada**: este adendo não a reabre, não reescreve a auditoria e atualiza documentos vigentes só onde acrescenta decisão.

- **Motivo**: quatro capacidades estavam subespecificadas — a manutenção de Ativos tinha a base *plano → necessidade → OS → resultado*, mas não um PCM; a interrupção era um *evento operacional* registrado, sem conceito; o SINISA dependia de uma **premissa perigosa** — métrica interna consolidada virando informação oficial —; e o Analytics era candidato H3 sem finalidade separada da regulatória.
- **Impacto**: PCM como capacidade da Gestão de Ativos; **Parada** nativa da Gestão Operacional; 🔴 **SINISA manual por padrão** ([ADR-0009](../decisoes/0009-sinisa-preenchimento-manual.md)) e módulo *Prestação de Informações*; **Gerencial & Analytics** com catálogo de métricas; trilha **regulatória** e Gerencial **incremental** na ordem; nove requisitos nativos especificados.
- **Dependências**: nenhuma nova. **Testes**: nenhum executado. **Risco**: baixo (documental). **Rollback**: `git revert` do commit. **Migration**: nenhuma.

## 0. Verificação de continuidade

| Verificação | Resultado |
| ----------- | --------- |
| HEAD real | `388816d` — registro do encerramento da Fase 0; local = remoto; árvore limpa |
| `e360716` e `388816d` no histórico | Sim |
| Commits posteriores | Nenhum |
| Os quatro temas já aprofundados depois? | Não — busca na documentação: PCM em **nenhum** arquivo; *mincut* só como função do Giswater; SINISA só como capacidade transversal da auditoria; Analytics só como consumidor e candidato H3 |

## 1. Pesquisa

| Tema | Fonte | Leitura |
| ---- | ----- | ------- |
| Giswater — *mincut* | Repositórios oficiais [`Giswater/api`](https://github.com/Giswater/api) e [`Giswater/docs`](https://github.com/Giswater/docs) (protocolo P16) | **Direta** — estados, operações, válvulas, elementos afetados, pré-requisitos. ⚠️ `docs.giswater.org` **bloqueado** pela política de rede |
| SINISA | Página oficial, Área do Prestador, glossários e manuais — Ministério das Cidades | Por **resumo de busca** — `www.gov.br` **bloqueado**; prorrogações da coleta só por fonte secundária |
| Legado | `gsan`, `gsan-migracoes`, `SISAN` | Nenhuma referência a SNIS ou SINISA no código e nos dumps (`grep -rIo -i -w snis`, `grep -rIl -i sinisa`) — **zero**; *produção de água* registrada por **localidade**, sem consumidor |

## 2. Decisões

| # | Decisão | Onde |
| - | ------- | ---- |
| 1 | **PCM é capacidade da Gestão de Ativos** — planeja, prioriza, programa, acompanha e mede; planejar ≠ programar; backlog com estados próprios; 🔴 **nenhuma ordem de trabalho além da OS** | [`pcm.md`](../dominio/pcm.md) |
| 2 | **Programação do PCM ≠ programação da OS**: janela e prioridade × distribuição no roteiro das equipes | [`pcm.md §5`](../dominio/pcm.md#5-programação) |
| 3 | **Parada / interrupção operacional**, dona Gestão Operacional; **Parada ≠ polígono ≠ *mincut***; impacto calculado **ou** declarado, em snapshot versionado | [`paradas-interrupcoes.md`](../dominio/paradas-interrupcoes.md) |
| 4 | **O estado do *mincut* é estado da análise**; o adaptador o comanda a partir da Parada, nunca o inverso | [`paradas-interrupcoes.md §7`](../dominio/paradas-interrupcoes.md#7-giswater--o-que-o-mincut-faz) |
| 5 | 🔴 **SINISA manual por padrão — e só manual na V1**; métrica interna ≠ informação SINISA; sem mapeamento universal; automação futura só por mapeamento da companhia, **desligada por padrão**; glossário novo → **REVALIDAÇÃO NECESSÁRIA** | [ADR-0009](../decisoes/0009-sinisa-preenchimento-manual.md) · [`sinisa.md`](../regulatorio/sinisa.md) |
| 6 | **Prestação de Informações vira módulo** — passou no critério da auditoria (ciclo próprio e obrigatório) quando a declaração deixou de ser derivada; ❌ continua sem módulo *Regulação* | [`sinisa.md §4`](../regulatorio/sinisa.md#4-workspace-sinisa--dono-da-declaração) |
| 7 | **Gerencial & Analytics**: consumidor de fatos, **não construído para o SINISA**; métrica versionada com *owner*; níveis operacional, tático e estratégico; ADR-0007 inalterada; nenhum *data warehouse* decidido | [`gerencial-analytics.md`](../analytics/gerencial-analytics.md) · [`catalogo-de-metricas.md`](../analytics/catalogo-de-metricas.md) |
| 8 | **Ordem**: PCM depois de Ativos + OS; Parada depois da Gestão Operacional mínima; **trilha regulatória** para o Workspace SINISA, **sem depender do Analytics**; Gerencial **incremental**; automação **fora** da ordem inicial | [`dependencias-e-ordem-implementacao.md §24.2–§24.4`](../modulos/dependencias-e-ordem-implementacao.md) |
| 9 | Regra permanente 9: **equivalência semântica não se presume pelo nome** | [`procedencia.md §5`](../procedencia.md#5-regra-permanente) |

## 3. Números (por script)

| | Antes | Depois |
| - | ----: | -----: |
| ADRs aceitas | 8 | **9** |
| Especificações de cenário | 87 (49 P0 · 38 P1; 6 com oráculo N) | **96** (53 P0 · 43 P1; **15** com oráculo N) |
| Especificações derivadas (fora do inventário) | 20 | **29** |
| Perfis de massa usados | 61 | **66** |
| Relações na matriz de dependências | 29 | **33** |
| Capacidades sem origem no legado (catálogo §28) | 3 | **5** |
| Catálogo — 26 capacidades, três eixos | 11 · 6 · 6 · 2 · 1 / 12 · 10 · 4 / 10 · 10 · 5 · 1 | **Inalterado** |
| Compatibilidade — 145 conceitos | 91 · 25 · 17 · 5 · 1 · 6 | **Inalterado** |
| Completude — 50 temas | 10 · 20 · 10 · 5 · 3 · 2 | **Inalterado** — notas datadas, sem reclassificação |

## 4. Documentos

**Criados**: [`dominio/pcm.md`](../dominio/pcm.md) · [`dominio/paradas-interrupcoes.md`](../dominio/paradas-interrupcoes.md) · [`regulatorio/sinisa.md`](../regulatorio/sinisa.md) · [`analytics/gerencial-analytics.md`](../analytics/gerencial-analytics.md) · [`analytics/catalogo-de-metricas.md`](../analytics/catalogo-de-metricas.md) · [ADR-0009](../decisoes/0009-sinisa-preenchimento-manual.md) · [`testes/cenarios/pcm-paradas.md`](../testes/cenarios/pcm-paradas.md) · [`testes/cenarios/regulatorio.md`](../testes/cenarios/regulatorio.md) · este registro.

**Alterados, pontualmente**: visão conceitual (§19, §27.2, §27.4, §29) · mapa de domínio (cabeçalho, §3) · glossário · Gestão de Ativos (§10, §11, §15, §17) · Operacional (adendo) · Redes/GIS/Ativos (§6, §8, §12, §13) · catálogo de funcionalidades futuras (22, 23, §20, §28) · dependências e ordem (#26, #29–#33, §5.1, §18, §20.3, §24, §25, §28, §30, §31) · matriz de completude (notas datadas) · compatibilidade (§21) · integrações (adapters) · cenários críticos (índice, perfis, gates, pendências) · procedência (fontes, §4, regra 9) · READMEs (documentação, módulos, decisões, alterações) · [`MODERNIZACAO_GSAN.md`](../../../MODERNIZACAO_GSAN.md).

**Não alterados de propósito**: [`auditoria-final-fase0.md`](../auditoria/auditoria-final-fase0.md) e o [registro da auditoria](2026-09-29-auditoria-final-fase0.md) — são o registro histórico do encerramento.

## 5. O que ficou deliberadamente de fora

Código, migration, API, banco, schema, tabela · algoritmo de programação, calendário, estoque · protocolo com o Giswater · leiaute ou formato de exportação do SINISA · lista de campos ou códigos oficiais · qualquer mapeamento SINISA · submissão automática · armazenamento analítico, modelo estrela, ClickHouse, Vertica, BigQuery, DuckDB, Kafka, *lakehouse* ou ferramenta de BI · metas universais · extensão do princípio da ADR-0009 ao SISAGUA e ao regulador local.

## 6. Estado depois do adendo

**Fase 0: concluída** (inalterado). **Fase 1: não iniciada.** O próximo estágio continua o do [encerramento](../../../MODERNIZACAO_GSAN.md): Fase 1 → Fase 2 → Fase 3 → Fase 4 = Etapa 0.
