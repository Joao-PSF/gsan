-- Delta — uma conta JÁ ARQUIVADA de IMV-01 (100013), paga e transferida para o histórico num encerramento anterior (lote 6c:
-- CEN-ARR-005 V4). Depende de imoveis-imv-01-02-03.sql e de arr-arrecadador.sql (a forma de arrecadação).
--
-- Por que pela massa: o legado não arquiva conta nesta instalação — Gerar Histórico Conta (Funcionalidade 653) falha
-- sempre em ControladorFaturamentoFINAL.enviarContaCategoriaParaHistorico:37197 ("Found shared references to a collection:
-- ContaCategoria.contaCategoriaConsumoFaixas"; CEN-ARR-010 V4, CAND-38). A conta chega no estado em que o arquivamento a
-- deixaria (transferirContasParaHistorico: a linha sai de faturamento.conta, vai para conta_historico com o mesmo cnta_id
-- e conta_geral.cntg_ichistorico = 1), como numa base em operação que tem contas de meses anteriores no histórico. O
-- pagamento dela também já está no histórico (gerarHistoricoParaEncerrarArrecadacaoPagamento: o CLASSIFICADO do mês
-- encerrado). O objeto é o NOVO pagamento da conta arquivada.
-- EVIDÊNCIA para o que a classificação lê: classificarPagamentosConta:34179-34238 procura a conta do imóvel e referência
-- também em ContaHistorico (selecionarContaPorImovelAnoMesReferencia) e decide pela situação dela.
--
-- conta 9201 · referência 04/2026 · NORMAL · vencimento 10/05/2026 · contábil 04/2026 · baixa contábil 05/2026 · R$ 110,40
-- (água, 27 m³, 1 economia RESIDENCIAL, os mesmos dados da conta de 05/2026 que o faturamento gera); pagamento de
-- 10/05/2026, arrecadação 05/2026, CLASSIFICADO. Ids altos (92xx) para não colidirem com as sequências. Valores SINTÉTICOS.
INSERT INTO faturamento.conta_geral (cnta_id, cntg_ichistorico, cntg_tmultimaalteracao) VALUES (9201, 1, '2026-06-01 00:00:00');
INSERT INTO faturamento.conta_historico (cnta_id, cnhi_amreferenciaconta, cnhi_tmcontahistorico, imov_id, cnhi_nnlote, cnhi_nnsublote,
                                         cnhi_cdsetorcomercial, cnhi_nnquadra, cnhi_dgverificadorconta, cnhi_iccobrancamulta,
                                         cnhi_icalteracaovencimento, cnhi_nnconsumoagua, cnhi_nnconsumoesgoto, cnhi_vlagua, cnhi_vlesgoto,
                                         cnhi_vldebitos, cnhi_vlcreditos, cnhi_pcesgoto, cnhi_dtvencimentoconta, cnhi_dtvalidadeconta,
                                         cnhi_dtemissao, cnhi_amreferenciacontabil, cnhi_amreferenciabaixacontabil, lest_id, last_id,
                                         loca_id, qdra_id, cstf_id, iper_id, ftgr_id, rota_id, cnhi_icdebitoconta, cnhi_tmultimaalteracao,
                                         dcst_idatual, dcst_idanterior, cnhi_dtvencimentooriginal, cnhi_nnretificacao, dotp_id)
VALUES (9201, 202604, '2026-06-01 00:00:00', 100013, 1, 0, 1, 1, 2, 1, 2, 27, 0, 110.40, 0.00, 0.00, 0.00, 0.00, '2026-05-10',
        '2026-08-10', '2026-04-30', 202604, 202605, 1, 3, 1, 1, 1, 5, 1, 1, 2, '2026-06-01 00:00:00', 0, NULL, '2026-05-10', 0, 1);
INSERT INTO faturamento.conta_catg_hist (cnta_id, catg_id, scat_id, ctch_qteconomia, ctch_vlagua, ctch_nnconsumoagua, ctch_vlesgoto,
                                         ctch_vltarifaminimaagua, ctch_nnconsumominimoagua, ctch_tmultimaalteracao)
VALUES (9201, 1, 0, 1, 110.40, 27, 0.00, 32.50, 10, '2026-06-01 00:00:00');
INSERT INTO arrecadacao.pagamento_historico (pghi_id, pghi_vlpagamento, pghi_amreferenciapagamento, pghi_dtpagamento,
                                             pghi_amreferenciaarrecadacao, pgst_idatual, cnta_id, loca_id, dotp_id, imov_id, arfm_id,
                                             pghi_tmultimaalteracao)
VALUES (9201, 110.40, 202604, '2026-05-10', 202605, 0, 9201, 1, 1, 100013, 1, '2026-06-01 00:00:00');
