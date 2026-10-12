-- Delta — contas ANTIGAS de IMV-03 (100030) que não aceitam a baixa normal, para serem PAGAS (lote 6b: CEN-ARR-003 V3 e
-- V3b). Depende de conta-ciclo-catalogos.sql (situações e o motivo DÉBITO PRESCRITO).
--
-- Por que pela massa: a prescrição em lote (lote 5d, CEN-FAT-008 V2) só alcança contas vencidas há mais de 10 anos e grava
-- DÉBITO PRESCRITO com o motivo 64, a situação anterior apagada e a referência CONTÁBIL = a de faturamento do sistema no
-- momento em que roda; as contas chegam no estado em que ela (ou o cancelamento) as deixaria. O objeto é o pagamento.
-- EVIDÊNCIA para as duas referências contábeis: a classificação só atribui situação à conta prescrita/cancelada com a
-- referência contábil >= a de faturamento (ControladorArrecadacao.classificarPagamentosConta:34252-34288).
--
-- id · referência · situação · vencimento · referência contábil
-- 9101 · 06/2014 · DÉBITO PRESCRITO (no mês corrente, depois do encerramento de 05/2026) · 10/07/2014 · 06/2026
-- 9102 · 07/2014 · DÉBITO PRESCRITO (num mês já fechado)                               · 10/08/2014 · 05/2026
-- 9103 · 08/2014 · CANCELADA (em 2014)                                                 · 10/09/2014 · 10/2014
-- Ids altos (91xx) para não colidirem com a sequência das contas do faturamento. Valores e datas SINTÉTICOS.
INSERT INTO faturamento.conta_geral (cnta_id, cntg_ichistorico, cntg_tmultimaalteracao) VALUES
  (9101, 2, '2026-06-01 00:00:00'), (9102, 2, '2026-05-01 00:00:00'), (9103, 2, '2014-10-15 00:00:00');
INSERT INTO faturamento.conta (cnta_id, imov_id, cnta_amreferenciaconta, last_id, lest_id, loca_id, qdra_id, cnta_cdsetorcomercial,
                               cnta_nnquadra, cnta_nnlote, cnta_nnsublote, cnta_dgverificadorconta, cnta_iccobrancamulta,
                               cnta_icalteracaovencimento, cnta_nnconsumoagua, cnta_nnconsumoesgoto, cnta_vlagua, cnta_vlesgoto,
                               cnta_vldebitos, cnta_vlcreditos, cnta_pcesgoto, cnta_dtvencimentoconta, cnta_dtvencimentooriginal,
                               cnta_dtvalidadeconta, cnta_dtemissao, cnta_dtinclusao, cnta_dtretificacao, cnta_dtcancelamento,
                               cnta_amreferenciacontabil, cstf_id, iper_id, ftgr_id, rota_id, dcst_idatual, dcst_idanterior,
                               cmrt_id, cmcn_id, cnta_nnretificacao, cnta_icdebitoconta, usur_id, cnta_tmultimaalteracao) VALUES
  (9101, 100030, 201406, 3, 1, 1, 1, 1, 1, 3, 0, 0, 2, 2, 30, 0, 72.00, 0.00, 0.00, 0.00, 0.00, '2014-07-10', '2014-07-10',
   '2014-10-10', '2014-06-30', NULL, NULL, '2026-06-01', 202606, 1, 5, 1, 1, 8, NULL, NULL, 64, NULL, 2, 1, '2026-06-01 00:00:00'),
  (9102, 100030, 201407, 3, 1, 1, 1, 1, 1, 3, 0, 0, 2, 2, 30, 0, 73.00, 0.00, 0.00, 0.00, 0.00, '2014-08-10', '2014-08-10',
   '2014-11-10', '2014-07-31', NULL, NULL, '2026-05-01', 202605, 1, 5, 1, 1, 8, NULL, NULL, 64, NULL, 2, 1, '2026-05-01 00:00:00'),
  (9103, 100030, 201408, 3, 1, 1, 1, 1, 1, 3, 0, 0, 2, 2, 30, 0, 74.00, 0.00, 0.00, 0.00, 0.00, '2014-09-10', '2014-09-10',
   '2014-12-10', '2014-08-31', NULL, NULL, '2014-10-15', 201410, 1, 5, 1, 1, 3, NULL, NULL, 3501, NULL, 2, 1, '2014-10-15 00:00:00');
INSERT INTO faturamento.conta_categoria (cnta_id, catg_id, scat_id, ctcg_qteconomia, ctcg_vlagua, ctcg_nnconsumoagua, ctcg_vlesgoto,
                                         ctcg_nnconsumoesgoto, ctcg_tmultimaalteracao)
SELECT cnta_id, 1, 0, 1, cnta_vlagua, cnta_nnconsumoagua, 0.00, 0, cnta_tmultimaalteracao FROM faturamento.conta WHERE cnta_id BETWEEN 9101 AND 9103;
