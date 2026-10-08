-- Delta — contas ANTIGAS de IMV-01, IMV-02 e IMV-03, uma por condição da regra de prescrição (lote 5d: CEN-FAT-008 V2 e
-- V2b). Depende de conta-ciclo-catalogos.sql (situações) e de conta-ciclo-arrecadacao.sql (o pagamento da conta paga).
--
-- A regra executada pelo processo "Gerar Prescrever Débitos de Imóveis" (RepositorioCobrancaHBM.prescreverDebitosDeImoveis
-- e ...ContasInlcuidas) prescreve a conta NORMAL ou RETIFICADA (→ DÉBITO PRESCRITO) e a INCLUÍDA (→ DÉBITO PRESCRITO
-- CONTAS INCLUÍDAS) com vencimento anterior a HOJE MENOS 10 ANOS (TarefaBatchGerarPrescreverDebitosDeImoveis:
-- dataPrescricao.setYear(ano − 10)), referência CONTÁBIL anterior à de faturamento do sistema e SEM pagamento.
-- Por que pela massa: o faturamento gera contas da referência corrente, nunca vencidas há 10 anos; as contas chegam no
-- estado em que o faturamento (e, na RETIFICADA e na INCLUÍDA, a manutenção) as deixaria. Vencimentos LONGE da fronteira
-- móvel de 10 anos (2014 e 2020), para a baseline não depender do dia em que roda por muitos anos.
-- Ids altos (9001+) para não colidirem com a sequência das contas do faturamento. Valores e datas SINTÉTICOS.
INSERT INTO faturamento.conta_geral (cnta_id, cntg_ichistorico, cntg_tmultimaalteracao) VALUES
  (9001, 2, '2014-06-30 00:00:00'), (9002, 2, '2014-07-31 00:00:00'), (9003, 2, '2014-09-15 00:00:00'),
  (9004, 2, '2014-08-31 00:00:00'), (9005, 2, '2020-01-31 00:00:00'), (9006, 2, '2014-10-15 00:00:00'),
  (9007, 2, '2026-05-20 00:00:00');

-- id · imóvel · referência · situação · vencimento · referência contábil — o que se espera da regra:
-- 9001 · IMV-01 · 06/2014 · NORMAL                     · 10/07/2014 · 06/2014 → prescreve
-- 9002 · IMV-01 · 07/2014 · RETIFICADA                 · 10/08/2014 · 08/2014 → prescreve
-- 9003 · IMV-02 · 06/2014 · INCLUÍDA                   · 10/07/2014 · 09/2014 → prescreve (contas incluídas)
-- 9004 · IMV-02 · 08/2014 · NORMAL, PAGA               · 10/09/2014 · 08/2014 → não (há pagamento)
-- 9005 · IMV-03 · 01/2020 · NORMAL                     · 10/02/2020 · 01/2020 → não (vencida há menos de 10 anos)
-- 9006 · IMV-03 · 06/2014 · CANCELADA                  · 10/07/2014 · 10/2014 → não (situação)
-- 9007 · IMV-01 · 09/2014 · RETIFICADA no mês corrente · 10/10/2014 · 05/2026 → não (contábil não é anterior)
INSERT INTO faturamento.conta (cnta_id, imov_id, cnta_amreferenciaconta, last_id, lest_id, loca_id, qdra_id, cnta_cdsetorcomercial,
                               cnta_nnquadra, cnta_nnlote, cnta_nnsublote, cnta_dgverificadorconta, cnta_iccobrancamulta,
                               cnta_icalteracaovencimento, cnta_nnconsumoagua, cnta_nnconsumoesgoto, cnta_vlagua, cnta_vlesgoto,
                               cnta_vldebitos, cnta_vlcreditos, cnta_pcesgoto, cnta_dtvencimentoconta, cnta_dtvencimentooriginal,
                               cnta_dtvalidadeconta, cnta_dtemissao, cnta_dtinclusao, cnta_dtretificacao, cnta_dtcancelamento,
                               cnta_amreferenciacontabil, cstf_id, iper_id, ftgr_id, rota_id, dcst_idatual, dcst_idanterior,
                               cmrt_id, cmcn_id, cnta_nnretificacao, cnta_icdebitoconta, usur_id, cnta_tmultimaalteracao) VALUES
  (9001, 100013, 201406, 3, 1, 1, 1, 1, 1, 1, 0, 0, 2, 2, 20, 0, 50.00, 0.00, 0.00, 0.00, 0.00, '2014-07-10', '2014-07-10',
   '2014-10-10', '2014-06-30', NULL, NULL, NULL, 201406, 1, 5, 1, 1, 0, NULL, NULL, NULL, NULL, 2, 1, '2014-06-30 00:00:00'),
  (9002, 100013, 201407, 3, 1, 1, 1, 1, 1, 1, 0, 0, 2, 2, 20, 0, 52.00, 0.00, 0.00, 0.00, 0.00, '2014-08-10', '2014-08-10',
   '2014-11-10', '2014-08-05', NULL, '2014-08-05', NULL, 201408, 1, 5, 1, 1, 1, NULL, 3401, NULL, 1, 2, 1, '2014-08-05 00:00:00'),
  (9003, 100021, 201406, 3, 1, 1, 1, 1, 1, 2, 0, 0, 2, 2, 25, 0, 60.00, 0.00, 0.00, 0.00, 0.00, '2014-07-10', '2014-07-10',
   '2014-10-10', '2014-09-15', '2014-09-15', NULL, NULL, 201409, 1, 5, 1, 1, 2, NULL, NULL, NULL, NULL, 2, 1, '2014-09-15 00:00:00'),
  (9004, 100021, 201408, 3, 1, 1, 1, 1, 1, 2, 0, 0, 2, 2, 25, 0, 61.00, 0.00, 0.00, 0.00, 0.00, '2014-09-10', '2014-09-10',
   '2014-12-10', '2014-08-31', NULL, NULL, NULL, 201408, 1, 5, 1, 1, 0, NULL, NULL, NULL, NULL, 2, 1, '2014-08-31 00:00:00'),
  (9005, 100030, 202001, 3, 1, 1, 1, 1, 1, 3, 0, 0, 2, 2, 30, 0, 70.00, 0.00, 0.00, 0.00, 0.00, '2020-02-10', '2020-02-10',
   '2020-05-10', '2020-01-31', NULL, NULL, NULL, 202001, 1, 5, 1, 1, 0, NULL, NULL, NULL, NULL, 2, 1, '2020-01-31 00:00:00'),
  (9006, 100030, 201406, 3, 1, 1, 1, 1, 1, 3, 0, 0, 2, 2, 30, 0, 72.00, 0.00, 0.00, 0.00, 0.00, '2014-07-10', '2014-07-10',
   '2014-10-10', '2014-06-30', NULL, NULL, '2014-10-15', 201410, 1, 5, 1, 1, 3, NULL, NULL, 3501, NULL, 2, 1, '2014-10-15 00:00:00'),
  (9007, 100013, 201409, 3, 1, 1, 1, 1, 1, 1, 0, 0, 2, 2, 20, 0, 54.00, 0.00, 0.00, 0.00, 0.00, '2014-10-10', '2014-10-10',
   '2015-01-10', '2026-05-20', NULL, '2026-05-20', NULL, 202605, 1, 5, 1, 1, 1, NULL, 3401, NULL, 1, 2, 1, '2026-05-20 00:00:00');

-- Uma categoria por conta (RESIDENCIAL, 1 economia), como o faturamento grava: a manutenção de conta lê as economias da
-- conta, não as do imóvel.
INSERT INTO faturamento.conta_categoria (cnta_id, catg_id, scat_id, ctcg_qteconomia, ctcg_vlagua, ctcg_nnconsumoagua, ctcg_vlesgoto,
                                         ctcg_nnconsumoesgoto, ctcg_tmultimaalteracao)
SELECT cnta_id, 1, 0, 1, cnta_vlagua, cnta_nnconsumoagua, 0.00, 0, cnta_tmultimaalteracao FROM faturamento.conta WHERE cnta_id BETWEEN 9001 AND 9007;

-- O pagamento CLASSIFICADO da conta 9004, no valor dela.
INSERT INTO arrecadacao.pagamento (pgmt_id, pgmt_vlpagamento, pgmt_amreferenciapagamento, pgmt_dtpagamento, pgmt_amreferenciaarrecadacao,
                                   pgst_idatual, cnta_id, loca_id, dotp_id, avbc_id, imov_id, arfm_id, pgmt_tmultimaalteracao)
VALUES (902, 61.00, 201408, '2014-09-05', 202606, 0, 9004, 1, 1, 901, 100021, 1, '2014-09-05 12:00:00');
