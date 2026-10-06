# [2026-10-06] Fase 2 — lote 4: Atendimento — efeitos da OS e consumo mínimo

> Quinto lote de baselines da Fase 2. **Não implementa o OpenGSAN** e **não altera o legado**. A Fase 2 **continua em
> andamento**.

- **Motivo**: os P0 do Atendimento e da Micromedição que rodam online — o efeito cadastral (CEN-ATE-007) e financeiro
  (CEN-ATE-008) da execução de uma OS, e o consumo mínimo (CEN-MIC-002) — mais a permissão especial que a mesma tela
  consulta (CEN-SEG-008).
- **Impacto**: 4 definições executáveis, 12 deltas de massa (catálogos de Atendimento que a base não tem; RA e OS
  encerradas; variações de dado do tipo de serviço; permissões especiais; overrides de consumo mínimo), 17 baselines em
  `golden/atendimento/`, `golden/micromedicao/` e `golden/seguranca/`; dois roteiros novos (efetuar ligação de água
  enviando o formulário como o navegador e lendo o efeito no banco; exibição do consumo mínimo); `baseline.sh` sobe o
  banco quando a instância está parada. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo.
- **Testes**: captura com 2 execuções idênticas por variação; verificação independente do lote e regressão do piloto;
  `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert`. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `f3b3d7f` (lote 3). Cobertura: 12 de 42 P0 da classe A; 61 baselines.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| CEN-ATE-007 (V1), CEN-ATE-008 (V1–V5, V1b, V3b), CEN-MIC-002 (V1–V7), CEN-SEG-008 (V1, V2) — 17 baselines | `ambiente-referencia/baselines/golden/` |
| Achados F2-44 a F2-55; achados de segurança 33–34; candidato CAND-10 | [relatório §19](../testes/fase2/fase2-caracterizacao-baselines.md#19-lote-4--atendimento-efeitos-da-os-e-consumo-mínimo-2026-10-06), [`riscos-identificados.md`](../seguranca/riscos-identificados.md), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência) |
| Cobertura (gerada): **15 de 42** P0 da classe A | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-10** | Permissão especial (ligação sem RA) e regras de cobrança do serviço (parcelas, valor, percentual, motivo) só na tela — o servidor aceita o POST | Toda permissão e regra avaliadas no servidor, no caso de uso |

Além disso: **F2-51** — um serviço que cobra juros, numa instalação sem taxa de financiamento configurada (como a base
reconstruída), gera débito de **R$ 0,00**: parametrização obrigatória no checklist de instalação.

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§19, §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) ·
`testes/cenarios/cadastro-atendimento.md` (ATE-007, ATE-008) · `testes/cenarios/micromedicao.md` (MIC-002) ·
`testes/cenarios/seguranca.md` (SEG-008) · `testes/cenarios-criticos.md` §11 · `testes/estrategia-testes.md` ·
`compatibilidade/divergencias-aprovadas.md` · `seguranca/riscos-identificados.md` (achados 33–34) · `alteracoes/README.md`.
**Código das ferramentas**: `baselines/ferramentas/roteiros.py`, `scripts/baseline.sh`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote 4 capturado com determinismo (17/17 idênticas); verificação independente **17/17** e regressão do piloto **11/11**. P0 da classe A: 12 → **15 de 42**.
Próximo lote recomendado: **5 — faturamento em grupo e Micromedição em modo Batch** — os P0 que faltam (faturamento,
micromedição, arrecadação, cobrança, batch) são processos: exige construir o EAR em modo Batch.
