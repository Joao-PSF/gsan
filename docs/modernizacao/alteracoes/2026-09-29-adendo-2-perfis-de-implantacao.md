# [2026-09-29] Segundo adendo pós-Fase 0 — monólito modular e suíte modular

> **SEGUNDO ADENDO PÓS-FASE 0 — refinamento arquitetural antes da Fase 1.** A Fase 0 foi encerrada em 29/09/2026 e **continua encerrada**. PCM, Paradas, SINISA e Analytics **não foram refeitos**; a ADR-0001 **não foi alterada** — a ADR-0010 a especializa.

- **Motivo**: o OpenGSAN tinha fronteiras de módulo de domínio, mas nenhuma de **implantação**. Uma companhia que já tem ERP, sistema comercial, CMMS ou GIS não conseguiria adotar parte da suíte, e dependência acidental entre módulos só apareceria quando alguém tentasse — tarde, e caro.
- **Impacto**: nove **módulos instaláveis** sobre o mesmo monólito; **perfis de implantação**; dependências REQUIRED/OPTIONAL/EXTERNALIZABLE, a opcional só por contrato; Commercial coeso; **OS não exige RA**; capacidade GIS no Networks; restrição transversal na ordem e decisões técnicas na Etapa 0; sete cenários arquiteturais.
- **Dependências**: nenhuma nova. **Testes**: nenhum executado. **Risco**: baixo (documental). **Rollback**: `git revert` do commit. **Migration**: nenhuma.

## 0. Verificação de continuidade

| Verificação | Resultado |
| ----------- | --------- |
| HEAD real | `fbef914` — primeiro adendo pós-Fase 0; local = remoto; árvore limpa |
| `fbef914` no histórico | Sim |
| Commits posteriores | Nenhum |
| Implantação modular já tratada? | Não — nenhuma ocorrência de *perfil de implantação* ou *módulo instalável*; a ADR-0001 só menciona *feature flags* por funcionalidade como mitigação de deploy |

## 1. Achados que mudaram o desenho

| Achado | Evidência | Efeito |
| ------ | --------- | ------ |
| 🟢 **OS sem RA** — a ação de cobrança gera a OS a partir do documento de cobrança e a insere sem associar RA; a versão com RA técnico está comentada | `ControladorCobranca:24127–24142` → `ControladorOrdemServicoSEJB:1032–1086`; `rgat_id` nulo no DDL | O RA fica no Services como **uma** das origens da OS; sistema externo pode abrir OS por contrato — sem destruir a semântica mapeada. Dúvida 1b do mapa do Atendimento **parcialmente resolvida** |
| **Rota é conceito de junção** — setor comercial, grupo de faturamento, leiturista, tipo de leitura | `gcom.micromedicao.Rota`; quadra → rota; CAD-10 | Separar rota de leitura × agrupamento do ciclo nos perfis parciais — **Etapa 3** |
| **A conta precisa da qualidade da água** — Decreto 5.440/2005 | CEN-OPE-003; `operacional.md §5.4` | Provedor **obrigatório** para o Commercial — Operations ou fonte externa |
| **Escopo territorial depende do Cadastro** — oitavo ciclo | Dependência #15; §4.4 da ordem | Resolvido por **inversão**: mecanismo na Platform, dimensão registrada pelo módulo |
| **Os exemplos do roteiro punham consumidores como dependências** | Ownership e fronteiras | SINISA e Analytics saem do OPTIONAL de Commercial, Metering, Services e Assets |
| **Pequeno prestador sem Operations** perderia qualidade na conta, roteamento e falta de água × programação | CEN-OPE-001 a 003 | Operations **acrescentada** ao perfil |
| **GIS na Platform** obrigaria o perfil SINISA a carregar infraestrutura espacial | Critério da visão §8 | Capacidade GIS vai para o **Networks** |

## 2. Decisões

| # | Decisão | Onde |
| - | ------- | ---- |
| 1 | **Monólito modular continua** — um código, uma versão, um processo por instalação; nada de microserviço, HTTP interno, banco por serviço ou fila obrigatória | [ADR-0010](../decisoes/0010-monolito-modular-perfis-de-implantacao.md) |
| 2 | *Módulo de domínio ≠ módulo instalável ≠ microserviço*; **perfil de implantação** = módulos habilitados + provedores externos | [`modulos-e-perfis-de-implantacao.md §1`](../arquitetura/modulos-e-perfis-de-implantacao.md#1-três-coisas-que-não-se-confundem) |
| 3 | Nove módulos instaláveis — Platform, Commercial, Metering, Services, Assets, Operations, Networks, SINISA, Analytics; nomes de produto para instaláveis, nomes do domínio para módulos de domínio | §3 |
| 4 | **Commercial coeso**; PCM no Assets; Paradas na Operations; Fiscal no Commercial | §4, §9, §10 |
| 5 | Matriz REQUIRED/OPTIONAL/EXTERNALIZABLE, com provedor obrigatório marcado; REQUIRED dos funcionais = **só a Platform** | §15 |
| 6 | Dependência opcional **só por contrato do consumidor**; ponte só com os dois módulos ativos; contrato interno em Java, nunca HTTP | §16 |
| 7 | **Referência externa** com snapshot mínimo — snapshot não é cadastro mestre | §8 |
| 8 | **Platform pequena** por critério; capacidade GIS no Networks; escopo por inversão | §14 |
| 9 | Treze **perfis de referência**, testados; combinação válida fora da lista é permitida, não garantida | §17 |
| 10 | Módulo desligado não registra nada; ativação ≠ autorização; perfil inválido falha cedo; **atualização não ativa módulo** | §19 |
| 11 | Coexistência = integração por contrato — **não** migração | §18 |
| 12 | Restrição transversal na ordem; item 14 do dia 1; decisões técnicas na **Etapa 0** | [`dependencias-e-ordem-implementacao.md`](../modulos/dependencias-e-ordem-implementacao.md) §4.1, §24, §25 |

## 3. Números (por script)

| | Antes | Depois |
| - | ----: | -----: |
| ADRs aceitas | 9 | **10** |
| Especificações de cenário | 96 (53 P0 · 43 P1; 15 com oráculo N) | **103** (55 P0 · 48 P1; **22** com oráculo N) |
| Especificações derivadas (fora do inventário) | 29 | **36** |
| Perfis de massa usados | 66 | **69** |
| Módulos instaláveis · perfis de referência · contratos externalizáveis | — | **9 · 13 · 13** |
| Relações entre módulos de domínio (ordem §5) | 33 | **33** — inalterado |
| Catálogo · compatibilidade (145) · estruturas (64) · completude (50) | — | **Inalterados** |

## 4. Documentos

**Criados**: [`arquitetura/modulos-e-perfis-de-implantacao.md`](../arquitetura/modulos-e-perfis-de-implantacao.md) · [ADR-0010](../decisoes/0010-monolito-modular-perfis-de-implantacao.md) · [`testes/cenarios/modularidade.md`](../testes/cenarios/modularidade.md) · este registro.

**Alterados, pontualmente**: visão conceitual (§8, §19, §27.2, §27.3, §27.5, §29) · mapa de domínio (cabeçalho) · glossário · arquitetura alvo · plano de trabalho (Fase 4) · dependências e ordem (cabeçalho, §4.1, §24, §25, §28, §30, §31.2) · Redes/GIS/Ativos (§9) · Paradas (§5, §13) · PCM (§7) · Gestão de Ativos (§15) · Gerencial & Analytics (§1, §7) · SINISA (§4) · Operacional (adendo) · Atendimento (§12, §30) · estruturas centrais (ATE-02, nota) · catálogo (cabeçalho) · cenários críticos (índice, perfis, gates, pendências) · estratégia de testes (camada 6) · READMEs · [`MODERNIZACAO_GSAN.md`](../../../MODERNIZACAO_GSAN.md).

**Não alterados de propósito**: [ADR-0001](../decisoes/0001-monolito-modular-spring-boot.md) — especializada, não reescrita; a auditoria final e o registro de encerramento; a seção *FASE 0 — CONCLUÍDA*.

## 5. O que ficou deliberadamente de fora

`pom.xml` · Spring · *profiles* · *feature flags* · migrations · adapters · classes · API · Spring Modulith · formato de configuração · tabelas · mensageria · ETL ou sincronização com ERP, GSAN ou OpenGSAN parcial — migração continua outro projeto.

## 6. Estado depois do adendo

**Fase 0: concluída** (inalterado). **Fase 1: não iniciada.** Próximo estágio inalterado: Fase 1 → Fase 2 → Fase 3 → Fase 4 = Etapa 0 — que agora abre com as decisões técnicas de modularidade.
