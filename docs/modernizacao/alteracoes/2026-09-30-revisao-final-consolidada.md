# [2026-09-30] Ajuste do módulo Atendimento e revisão final consolidada da arquitetura

> **Revisão, não descoberta.** A Fase 0 continua encerrada em 29/09/2026; os dois adendos pós-Fase 0 foram incorporados, não refeitos. Nenhuma ADR nova; a ADR-0010 ganhou uma seção de revisão, sem decisão revertida.

- **Motivo**: o instalável *Services* escondia o RA e deixava a demanda do cliente parecer assunto do Commercial; e a arquitetura, depois de dois adendos no mesmo dia, precisava de uma leitura de conjunto — ownership, dependências, perfis, ADRs, interfaces, regulação e cenários — antes das próximas fases.
- **Impacto**: *Services* → **Atendimento** (RA · OS · Campo); estrutura organizacional da Platform para o Atendimento; contexto institucional justificado na Platform; provedores obrigatórios de Metering e Assets rebaixados a condição de capacidade; adapters no módulo dono; CEN-MOD-004 V4 revisto; observável novo em CEN-COB-003; glossário reordenado.
- **Dependências**: nenhuma nova. **Testes**: nenhum executado. **Risco**: baixo (documental). **Rollback**: `git revert` do commit. **Migration**: nenhuma.

## 0. Verificação de continuidade

| Verificação | Resultado |
| ----------- | --------- |
| HEAD real | `83a3195` — segundo adendo pós-Fase 0; local = remoto; árvore limpa |
| `83a3195` no histórico | Sim |
| Commits posteriores | Nenhum |

## 1. Achados

| Achado | Evidência | Efeito |
| ------ | --------- | ------ |
| A unidade organizacional do GSAN é posicionamento de fluxo do RA e da OS — atributos de abertura de RA, tramitação, central de atendimento, esgoto, repavimentadora | `UnidadeOrganizacional.java:26–76`; usos fora do atendimento ainda posicionam RA ou OS — `UC0870GerarMovimentoContasEmCobrancaPorEmpresa:212`, `ControladorRetificarConta:479–483`; indicador de tarifa social da unidade lido só na tramitação e no encerramento do RA | Sai da Platform: nem todo perfil a usa, e ela tem dono melhor |
| Metering e Assets **existem** sem os provedores marcados 🔴 — parque de hidrômetros; ativos, planos e backlog | Mapas da Micromedição e de Gestão de Ativos | Rebaixados a condição de capacidade; só o Commercial mantém 🔴 |
| A OS da ação de cobrança nasce **sem RA** — o cenário de corte não observava isso | `ControladorCobranca:24135–24142`; CEN-COB-003 | Observável e localizador acrescentados |
| Adapters descritos "em Integrações" | Arquitetura alvo; `sinisa.md` §14 e §18 | Infraestrutura na Platform; adapter no módulo dono |
| Tabelas de terminologia inseridas no meio da lista numerada do glossário | `glossario.md` — itens 1–5 e 6–9 separados | Lista reunida; terminologia depois dela |

## 2. Documentos

**Criados**: [`auditoria/revisao-final-consolidada-pos-adendos.md`](../auditoria/revisao-final-consolidada-pos-adendos.md) · este registro.

**Alterados, pontualmente**: [`modulos-e-perfis-de-implantacao.md`](../arquitetura/modulos-e-perfis-de-implantacao.md) (cabeçalho, §1–§5, §7 reescrita com a nova §7.2, §8–§11, §12, §14, §15 com a nova §15.2, §16–§19, §21, §22, §24) · [ADR-0010](../decisoes/0010-monolito-modular-perfis-de-implantacao.md) (itens 2 e 12, consequências, seção *Revisão de 2026-09-30*) · [`decisoes/README.md`](../decisoes/README.md) · visão conceitual (§8, nota no §27.2, §27.5) · mapa de domínio · glossário · arquitetura alvo · [`atendimento.md`](../modulos/atendimento.md) (cabeçalho) · [`operacional.md`](../modulos/operacional.md) (§5.2, adendo) · [`integracoes.md`](../modulos/integracoes.md) · [`fiscal.md`](../modulos/fiscal.md) · [`sinisa.md`](../regulatorio/sinisa.md) (§14, §18) · [`pcm.md`](../dominio/pcm.md) (§4, §5, §7) · gestão de ativos (§15) · catálogo (cabeçalho) · dependências e ordem (gate 2 → 3) · cenários — [`modularidade.md`](../testes/cenarios/modularidade.md) (MOD-002, MOD-004), [`cobranca.md`](../testes/cenarios/cobranca.md) (COB-003), [`cenarios-criticos.md`](../testes/cenarios-criticos.md) (gates, PRF-01, blocos gerados) · estratégia de testes (camada 6) · [`procedencia.md`](../procedencia.md) (três correções registradas) · READMEs · [`MODERNIZACAO_GSAN.md`](../../../MODERNIZACAO_GSAN.md).

**Não alterados de propósito**: ADR-0001 — sua lista de módulos é histórica, e a nota está na arquitetura alvo; a auditoria final e os registros dos adendos — o de 29/09 do segundo adendo ganhou só a nota de supersessão; a seção *FASE 0 — CONCLUÍDA*.

## 3. Números (por script)

| | Antes | Depois |
| - | ----: | -----: |
| ADRs aceitas | 10 | **10** — nenhuma nova |
| Especificações de cenário | 103 (55 P0 · 48 P1; 22 N) | **103** (55 P0 · 48 P1; 22 N) — nenhuma nova |
| Especificações derivadas · perfis de massa usados | 36 · 69 | **36 · 69** |
| Módulos instaláveis · perfis de referência · contratos | 9 · 13 · 13 | **9 · 13 · 13** |
| Provedores obrigatórios (🔴) na matriz | 4 | **2** — consumo e qualidade da água, ambos do Commercial |
| Catálogo (26) · compatibilidade (145) · estruturas (64) · completude (50) · relações entre módulos (33) | — | **Inalterados** |

## 4. Estado depois da revisão

**Veredito: SIM** — arquitetura consolidada e revisada. **Fase 0: concluída** (inalterado). **Fase 1: não iniciada.** Próximo estágio inalterado: Fase 1 → Fase 2 → Fase 3 → Fase 4 = Etapa 0.
