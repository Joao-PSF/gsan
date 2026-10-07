# [2026-10-07] Fase 2 — lote 5: faturamento em grupo em modo Batch

> Sexto lote de baselines da Fase 2, o primeiro de **processos**. **Não implementa o OpenGSAN** e **não altera o
> legado**. A Fase 2 **continua em andamento**.

- **Motivo**: os P0 que faltam são quase todos processos; o faturamento em grupo é o processo representativo do
  framework (CEN-BAT-001…005) e a única fronteira de `faturarImovel` (CEN-FAT-011). Exigiu preparar e validar o EAR em
  **modo Batch**.
- **Impacto**: modo Batch na infraestrutura do ambiente (um EAR por modo, em volumes próprios; o cenário declara o modo e
  o executor confere o rodapé); roteiro `faturar_grupo`; 6 definições executáveis; 8 deltas de massa e 1 arquivo de
  correção aplicado no meio da execução (`massas/passos/`); 10 baselines em `golden/processamento/` e
  `golden/faturamento/`. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo. O EAR Batch é construído do mesmo commit fixado, num contêiner sem rede.
- **Testes**: captura com 2 execuções idênticas por variação; verificação independente do lote; regressão de **todas** as
  baselines Online (a guarda de modo passa por todas); `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert` (o volume `ear-batch` pode ser removido
  sem afetar o Online). **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `4ed65cf` (CAND-10 registrada como D-19, proposta). Cobertura: 15 de 42 P0 da classe A; 78
baselines, todas no EAR Online.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| Modo Batch: `GSAN_TIPO` escolhe o EAR (`ear` / `ear-batch`) no build e na subida; saída do build Batch em `.saida/build-batch/`; `"modo"` na definição do cenário; o executor recusa EAR de outro modo | `ambiente-referencia/docker-compose.yml`, `scripts/referencia.sh`, `scripts/baseline.sh`, `baselines/ferramentas/executor.py`, READMEs |
| Roteiro `faturar_grupo` (disparar, aguardar, observar, autorizar, aplicar, reiniciar) | `baselines/ferramentas/roteiros.py` |
| CEN-BAT-001 (V1, V2), BAT-002 (V1–V3), BAT-003 (V1), BAT-004 (V1, V1b), BAT-005 (V1), FAT-011 (V1) — 10 baselines | `ambiente-referencia/baselines/golden/` |
| Achados F2-56 a F2-67; achado de segurança 35; CAND-02 caracterizado; CAND-11; nota de evidência sobre D-15 | [relatório §20](../testes/fase2/fase2-caracterizacao-baselines.md#20-lote-5--faturamento-em-grupo-em-modo-batch-2026-10-07), [`riscos-identificados.md`](../seguranca/riscos-identificados.md), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência), [`divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md) |
| Cobertura (gerada): **19 de 42** P0 da classe A | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-02** (caracterizado) | A unidade de faturamento **não é atômica**: na variante ativa, `faturarGrupoFaturamento`/`faturarImovel` são `NotSupported` e a conta do imóvel anterior à falha fica gravada | Unidade atômica, ou reprocessamento idempotente **declarado** — exige divergência aprovada |
| **CAND-11** | Novo disparo de um comando **já realizado** é aceito pelo servidor e fatura a **referência seguinte** (sem comando, sem consumo) pela tarifa mínima, avançando o grupo | O disparo confere, no servidor, comando existente, não realizado e da referência do grupo (mesma família de D-19) |
| **D-15** (aprovada — nota) | Sem consumo, o faturamento cobra o **mínimo** (0 m³); o 20 fixo que D-15 cita é do **crédito Bolsa Água** | Leitura do responsável: o alvo de D-15 é o crédito Bolsa Água, e "padrão 20 no motor de conta" mudaria o valor cobrado |

Além disso: **F2-56/F2-57** — a base reconstruída não tem catálogos do framework nem os meses de validade da conta:
itens obrigatórios do checklist de instalação.

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§20, §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) ·
`testes/cenarios/batch-relatorios-integracoes.md` (BAT-001…005) · `testes/cenarios/faturamento.md` (FAT-011) ·
`testes/cenarios-criticos.md` §10.2 e §11 · `testes/estrategia-testes.md` · `compatibilidade/divergencias-aprovadas.md`
(nota D-15, estado) · `seguranca/riscos-identificados.md` (achado 35) · `modulos/batch.md` §10–§12 · `alteracoes/README.md` ·
`ambiente-referencia/README.md` · `ambiente-referencia/baselines/README.md`.
**Código das ferramentas**: `baselines/ferramentas/executor.py`, `baselines/ferramentas/roteiros.py`, `scripts/baseline.sh`,
`scripts/referencia.sh`, `docker-compose.yml`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Modo Batch preparado e validado; lote 5 capturado com determinismo (10/10 idênticas);
verificação independente **10/10** e regressão de **todas** as baselines Online **78/78** — as 88 conferem. P0 da classe A: 15 → **19 de 42**. Próximo lote recomendado: **5b — Micromedição e faturamento na conta**
(leituras, hidrômetros e históricos no mesmo processo).
