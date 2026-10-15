-- Passo — RELÓGIO: a guia de entrada do parcelamento passa a ter vencido há mais que a tolerância (lote 7c: CEN-COB-005).
--
-- EVIDÊNCIA: o desfazimento por entrada não paga (ControladorCobranca.desfazerParcelamentosPorEntradaNaoPagaSemAnoMesReferencia
-- :61855) só desfaz quando o vencimento da guia de entrada mais QUANTIDADE_DIAS_VENCIMENTO_GUIA (cobranca.parametro: 7) é
-- anterior ou igual a AGORA (new Date()); a conclusão do parcelamento emite a guia com vencimento em HOJE + 3
-- (parm_nndiasvcmtoentparcmt). O laboratório não espera 10 dias: este passo leva a emissão e o vencimento da guia para o
-- tempo da massa (12/06/2026 e 15/06/2026 — os mesmos 3 dias de prazo), como estariam se o parcelamento tivesse sido feito
-- em junho. É SIMULAÇÃO DO RELÓGIO, não uma operação: só datas da guia de entrada mudam; nenhum valor, situação ou vínculo.
UPDATE faturamento.guia_pagamento SET gpag_dtemissao = DATE '2026-06-12', gpag_dtvencimento = DATE '2026-06-15'
WHERE dotp_id = 2 AND parc_id IS NOT NULL AND dcst_idatual = 0;
