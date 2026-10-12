# [2026-10-12] Fase 2 — lote 6b: Arrecadação — recuperação de crédito, manutenção e devolução

> Décimo segundo lote de baselines da Fase 2, continuação do lote 6, no EAR em modo Batch. **Não implementa o OpenGSAN** e
> **não altera o legado**. A Fase 2 **continua em andamento**.

- **Motivo**: o que acontece com o pagamento que a classificação não apropriou — duplicidade, conta cancelada, documento
  inexistente, conta prescrita, pagamento a maior — pelas telas de tratamento do legado, e o efeito no crédito/saldo e na
  quitação.
- **Impacto**: 12 baselines novas em CEN-ARR-003 e CEN-ARR-004; 3 deltas de massa; o roteiro `faturar_grupo` ganhou os
  passos `recuperar_credito`, `manter_pagamento`, `inserir_guia_devolucao` e `inserir_devolucao` e o bloco `devolucao`;
  as variações novas declaram os próprios campos — as 6 do lote 6 nesses cenários ficam com a definição efetiva
  idêntica. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo.
- **Testes**: seis rodadas de exploração dirigida (9 variações, sem gravar); captura com 2 execuções idênticas; verificação
  independente; regressão dos lotes 6 e 5d; `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert`. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `af0b470` (lote 6). Cobertura: 30 de 42 P0 da classe A; 166 baselines; 40 cenários com baseline.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| 12 baselines — ARR-003 V1b/V2b/V2c/V3/V3b, ARR-004 V2/V2b/V2c/V2d/V2e/V3/V3b | `ambiente-referencia/baselines/golden/arrecadacao/` |
| Tipos e origens de crédito, situações de devolução e da recuperação de crédito, concessões; o RA de devolução; contas antigas prescritas e cancelada | `ambiente-referencia/baselines/massas/deltas/arr-devolucao.sql`, `arr-ra-devolucao.sql`, `arr-contas-antigas.sql` |
| Achados F2-129 a F2-137; candidatos CAND-34 a CAND-37; evidência nova para CAND-32 | [relatório §26](../testes/fase2/fase2-caracterizacao-baselines.md#26-lote-6b--arrecadação-recuperação-de-crédito-manutenção-e-devolução-2026-10-12), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência), [`divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md) |
| Cobertura (gerada; a matriz de caracterização não muda) | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-34** | "Refaturar" o pagamento de conta cancelada ainda não arquivada sempre falha (HTTP 500) | A recuperação por refaturamento funciona para a conta corrente e a arquivada |
| **CAND-35** | O pagamento de conta prescrita/cancelada de referência contábil fechada fica sem situação e sem conta, a cada classificação | Todo pagamento sai da classificação com uma situação |
| **CAND-36** | A devolução confirmada (acima da guia) é somada duas vezes à devolução calculada do aviso | O aviso recebe a devolução uma vez, na gravação |
| **CAND-37** | A devolução sem guia leva o pagamento a DEVOLVIDO; a situação anterior gravada é sempre EM DUPLICIDADE | Só a devolução válida dá o pagamento como devolvido; a anterior é a que ele tinha |

CAND-36 toca **valor** (conciliação): continua no **oráculo 1** até decisão registrada. Nada foi aprovado. Continuam
pendentes, sem decisão automática: D-17, D-19, CAND-02, CAND-11 a CAND-37, a leitura final de D-15 e o alcance de D-14.

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§26, §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) ·
`testes/cenarios/arrecadacao.md` (CEN-ARR-003, CEN-ARR-004) · `testes/cenarios-criticos.md` §11 ·
`testes/estrategia-testes.md` · `compatibilidade/divergencias-aprovadas.md` (estado) · `modulos/arrecadacao.md` ·
`alteracoes/README.md` · `ambiente-referencia/baselines/README.md`. **Código das ferramentas**:
`baselines/ferramentas/roteiros.py`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote 6b capturado: **12/12** variações com as duas execuções idênticas (V2d e V2e
recapturadas depois de a V2d original revelar a guia recusada sem RA), **12/12** conferidas numa verificação independente e
os lotes 6 e 5d de novo **33/33**. **178** baselines em 40 cenários; P0 da classe A **30 de 42** (sem mudança: o lote
aprofunda CEN-ARR-003 e 004). CAND-34 a CAND-37 aguardam decisão — CAND-36 toca valor. Próximo lote: **6c —
Arrecadação: encerramento e arquivamento** (CEN-ARR-010, CEN-ARR-006, ARR-005 V4, ARR-004 V4 — a transferência pelo RA —
e o Refaturar da conta arquivada); MIC-005 (análise de leitura, pela tela) e a baseline de performance seguem pendentes.
