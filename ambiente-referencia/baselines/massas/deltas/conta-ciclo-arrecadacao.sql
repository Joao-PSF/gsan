-- Delta — o mínimo da Arrecadação para uma conta PAGA (lote 5d: CEN-FAT-007 V3). O pagamento em si nasce no meio da
-- execução (massas/passos/pagamento-conta-imv01-202605.sql), porque só pode apontar a conta depois que o faturamento a
-- gera. Depende de conta-ciclo-catalogos.sql.
--
-- EVIDÊNCIA: a base reconstruída não tem NENHUM banco, agência, conta bancária, arrecadador, aviso bancário, forma de
-- arrecadação, tipo de documento nem situação de pagamento; arrecadacao.pagamento exige aviso bancário (avbc_id) e tipo de
-- documento (dotp_id) não nulos, e o aviso exige arrecadador e conta bancária. Por que pela massa: o objeto do cenário é
-- a RETIFICAÇÃO de uma conta paga, não a recepção do movimento do arrecadador nem a classificação do pagamento (lote 6).
-- Ids pelas constantes do código onde ele os fixa (DocumentoTipo.CONTA = 1, PagamentoSituacao.PAGAMENTO_CLASSIFICADO =
-- 0, ArrecadacaoForma.GUICHE_CAIXA = 1); o resto e as descrições são SINTÉTICOS.
INSERT INTO arrecadacao.banco (bnco_id, bnco_nmbanco, bnco_nmabreviado, bnco_icuso, bnco_tmultimaalteracao, bnco_adere_cnab150)
VALUES (901, 'BANCO SINTETICO', 'BSINT', 1, '2026-01-01 00:00:00', false);
INSERT INTO arrecadacao.agencia (agen_id, agen_cdagencia, bnco_id, agen_nmagencia, agen_nnfone, agen_tmultimaalteracao)
VALUES (901, '00001', 901, 'AGENCIA SINTETICA', '000000000', '2026-01-01 00:00:00');
INSERT INTO arrecadacao.conta_bancaria (ctbc_id, ctbc_nnconta, agen_id, ctbc_tmultimaalteracao)
VALUES (901, '00000001', 901, '2026-01-01 00:00:00');
INSERT INTO arrecadacao.arrecadador (arrc_id, clie_id, arrc_cdagente, arrc_icuso, arrc_tmultimaalteracao)
VALUES (901, 1, 901, 1, '2026-01-01 00:00:00');
INSERT INTO arrecadacao.arrecadacao_forma (arfm_id, arfm_cdarrecadacaoforma, arfm_dsarrecadacaoforma, arfm_tmultimaalteracao)
VALUES (1, '1', 'GUICHE DE CAIXA (SINTETICO)', '2026-01-01 00:00:00');
INSERT INTO cobranca.documento_tipo (dotp_id, dotp_dsdocumentotipo, dotp_dsabreviado, dotp_icpagavel, dotp_icuso, dotp_tmultimaalteracao)
VALUES (1, 'CONTA', 'CONTA', 1, 1, '2026-01-01 00:00:00');
INSERT INTO arrecadacao.pagamento_situacao (pgst_id, pgst_dspagamentosituacao, pgst_dsabreviado, pgst_icuso, pgst_tmultimaalteracao)
VALUES (0, 'CLASSIFICADO', 'CLASS', 1, '2026-01-01 00:00:00');
INSERT INTO arrecadacao.aviso_bancario (avbc_id, avbc_dtlancamento, avbc_vlcontabilizado, avbc_amreferenciaarrecadacao, avbc_iccreditodebito,
                                        arrc_id, avbc_nndocumento, ctbc_id, avbc_tmultimaalteracao, avbc_vlarrecadacaocalculado,
                                        avbc_vldevolucaocalculado, avbc_vlarrecadacaoinformado, avbc_vldevolucaoinformado, arfm_id)
VALUES (901, '2026-06-08', 0.00, 202606, 1, 901, 1, 901, '2026-06-08 12:00:00', 0.00, 0.00, 0.00, 0.00, 1);
