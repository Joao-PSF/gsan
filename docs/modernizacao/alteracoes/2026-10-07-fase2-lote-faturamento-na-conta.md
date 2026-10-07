# [2026-10-07] Fase 2 — lote 5b: faturamento na conta — lançamentos, impostos e rateio

> Sétimo lote de baselines da Fase 2, na fronteira do lote 5 (faturar grupo, EAR em modo Batch). **Não implementa o
> OpenGSAN** e **não altera o legado**. A Fase 2 **continua em andamento**.

- **Motivo**: três P0 de Faturamento que só existem na conta gerada — débitos cobrados e créditos realizados
  (CEN-FAT-004), impostos deduzidos (CEN-FAT-005) e rateio de micro-condomínio (CEN-FAT-006) — e que cabiam no roteiro já
  validado do lote 5. O lote 5b foi **reordenado**: a Micromedição (consistir leituras) passa ao 5c.
- **Impacto**: 3 definições executáveis; 13 deltas de massa; 13 baselines em `golden/faturamento/`; o roteiro
  `faturar_grupo` ganhou blocos de detalhe **opcionais** (`lancamentos`, `impostos`, `rateio`) — as baselines do lote 5
  não mudam de forma. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo.
- **Testes**: captura com 2 execuções idênticas por variação; verificação independente do lote; regressão do lote 5
  (o roteiro mudou) e do piloto; `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert`. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `b6a8810` (lote 5). Cobertura: 19 de 42 P0 da classe A; 88 baselines.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| CEN-FAT-004 (V1–V4, V1b, V2b, V3b, V3c), FAT-005 (V1–V3), FAT-006 (V1, V2) — 13 baselines | `ambiente-referencia/baselines/golden/faturamento/` |
| Blocos de detalhe do roteiro `faturar_grupo` | `ambiente-referencia/baselines/ferramentas/roteiros.py` |
| Achados F2-68 a F2-76; candidatos CAND-12 e CAND-13 | [relatório §21](../testes/fase2/fase2-caracterizacao-baselines.md#21-lote-5b--faturamento-na-conta-lançamentos-impostos-e-rateio-2026-10-07), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência) |
| Cobertura (gerada): **22 de 42** P0 da classe A | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-12** | A última prestação do **crédito** não leva o resto da divisão: 100,00 em 3 realiza 33,33 na última e encerra — 1 centavo nunca creditado (o débito leva o resto) | A soma das prestações realizadas é o crédito |
| **CAND-13** | Entre alíquotas de imposto vigentes, vale a **mais antiga** (2010 em vez de 2026): uma nova alíquota nunca entra em vigor | Vale a alíquota de maior referência ≤ a da conta |

Os dois tocam **valor** — pela regra do registro, continuam no oráculo 1 (reproduzir) até divergência aprovada.
Além disso: **F2-70** — a 1ª prestação de parcelamento depende da referência de faturamento **do sistema**, que o
encerramento mensal avança e que a base reconstruída tem parada em 201410.

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§21, §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) ·
`testes/cenarios/faturamento.md` (FAT-004, 005, 006) · `testes/cenarios/cadastro-atendimento.md` (ATE-008: a prestação
na conta) · `testes/cenarios-criticos.md` §11 · `testes/estrategia-testes.md` · `compatibilidade/divergencias-aprovadas.md`
(estado) · `modulos/faturamento.md` §27 · `alteracoes/README.md` · `ambiente-referencia/baselines/README.md`.
**Código das ferramentas**: `baselines/ferramentas/roteiros.py`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote 5b capturado com determinismo (13/13 idênticas); verificação independente **13/13** e regressão do lote 5 e do piloto **21/21**. P0 da classe A:
19 → **22 de 42**. Próximo lote recomendado: **5c — Micromedição e faturamento pela origem do consumo** (consistir
leituras e calcular consumos; MIC-001 e MIC-003 são P0).
