# [2026-10-07] Fase 2 — lote 5c: Micromedição — consistência de leituras e cálculo de consumos

> Oitavo lote de baselines da Fase 2, no EAR em modo Batch. **Não implementa o OpenGSAN** e **não altera o legado**. A
> Fase 2 **continua em andamento**.

- **Motivo**: os dois P0 de Micromedição que faltavam — consumo da referência por situação de leitura (CEN-MIC-001) e
  troca de hidrômetro (CEN-MIC-003) — saem do processo **Consistir Leituras e Calcular Consumos**, que roda pelo mesmo
  caminho de comando do faturamento em grupo.
- **Impacto**: 2 definições executáveis; 12 deltas de massa; 9 baselines em `golden/micromedicao/`; 🆕 a sessão `psql`
  das ferramentas passou a usar o fuso do legado (`PGTZ`, F2-86 — o banco roda em UTC e o JBoss em America/Belem); o roteiro
  `faturar_grupo` lê a realização do comando da entrada, ganhou o bloco opcional `micromedicao` e guarda o texto técnico
  das exceções **só nas evidências**. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo.
- **Testes**: captura com 2 execuções idênticas por variação; verificação independente do lote; regressão de todas as outras
  baselines (o roteiro e o relógio da observação mudaram); `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert`. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `b0760c2` (lote 5b). Cobertura: 22 de 42 P0 da classe A; 101 baselines.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| CEN-MIC-001 (V1–V4, V3b, V3c), MIC-003 (V1–V3) — 9 baselines | `ambiente-referencia/baselines/golden/micromedicao/` |
| Catálogos da Micromedição, rota R4 e o comando de consistência; um imóvel por perfil de leitura e de troca | `ambiente-referencia/baselines/massas/deltas/mic-*.sql` |
| Achados F2-77 a F2-85; candidatos CAND-14, CAND-15, CAND-16 | [relatório §22](../testes/fase2/fase2-caracterizacao-baselines.md#22-lote-5c--micromedição-consistência-de-leituras-e-cálculo-de-consumos-2026-10-07), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência) |
| Cobertura (gerada): **24 de 42** P0 da classe A | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-14** | Na troca e na retirada de hidrômetro, o consumo entre a última leitura e a retirada **não é faturado** (12 m³ e 10 m³ nas baselines) | O consumo do mês soma os trechos dos dois equipamentos |
| **CAND-15** | A primeira leitura de hidrômetro novo gera consumo medido do tipo **ESTIMADO**, que não entra na média | Consumo medido desde a leitura de instalação é REAL |
| **CAND-16** | Partes do faturamento e da consistência releem a referência de faturamento **do sistema** em vez da do cronograma | Cada processamento usa a referência do seu cronograma |

CAND-14 e CAND-15 tocam consumo (e, portanto, valor): continuam no **oráculo 1** até decisão registrada. Nada foi aprovado.
Continuam pendentes, sem decisão automática: D-19, CAND-02, CAND-11, CAND-12, CAND-13 e a leitura final de D-15.

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§22, §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) ·
`testes/cenarios/micromedicao.md` (MIC-001, MIC-003) · `testes/cenarios-criticos.md` §11 · `testes/estrategia-testes.md` ·
`compatibilidade/divergencias-aprovadas.md` (estado) · `alteracoes/README.md` · `ambiente-referencia/baselines/README.md`.
**Código das ferramentas**: `baselines/ferramentas/roteiros.py`, `docker-compose.yml` (serviço `ferramentas`).

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote 5c capturado com determinismo (9/9 idênticas); verificação independente **9/9**; regressão de **todas** as outras
baselines — lotes 5, 5b e piloto 34/34 e Online 67/67, a maior parte à noite, depois da correção do relógio da observação
(F2-86) — as 110 conferem. P0 da classe A: 22 → **24 de 42**. Próximo lote recomendado: **5d — ciclo de vida
da conta** (FAT-007 retificação e FAT-008 cancelamento e prescrição, P0, sobre contas geradas pelo faturamento em grupo).
