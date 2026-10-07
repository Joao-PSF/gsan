-- Delta — parcelamento do IMV-01 em 6 prestações de R$ 50,00, com o débito a cobrar das prestações (nenhuma cobrada)
-- (lote 5b: CEN-FAT-004 V2, V2b, V4). Depende de fat-lancamentos-catalogos.sql e de imoveis-imv-01-02-03.sql.
--
-- REGRA SOB TESTE ([FS0005], ControladorFaturamentoFINAL.obterDebitoACobrarImovel:18195): a prestação de um
-- parcelamento com nenhuma cobrada só entra na conta se a referência de faturamento do PARCELAMENTO for ANTERIOR à
-- referência de faturamento do SISTEMA (sistema_parametros.parm_amreferenciafaturamento — 201410 na base reconstruída,
-- não a do grupo). Aqui o parcelamento é de 09/2014 — anterior. Datas antigas e valores SINTÉTICOS.
INSERT INTO cobranca.parcelamento (parc_id, imov_id, parc_tmparcelamento, parc_amreferenciafaturamento, parc_nnprestacoes, parc_vlprestacao,
                                   parc_vldebitoatualizado, parc_vlentrada, parc_icdebitoacobrar, last_id, lest_id, loca_id, qdra_id,
                                   parc_cdsetorcomercial, parc_nnquadra, iper_id, pctp_id, cbfm_id, pcst_id, parc_icconfirmacao,
                                   parc_tmultimaalteracao)
VALUES (9101, 100013, '2014-09-20 10:00:00', 201409, 6, 50.00, 300.00, 0.00, 1, 3, 1, 1, 1, 1, 1, 5, 1, 1, 1, 1,
        '2014-09-20 10:00:00');
INSERT INTO faturamento.debito_a_cobrar_geral (dbac_id, dage_ichistorico, dage_tmultimaalteracao)
VALUES (9102, 2, '2014-09-20 10:00:00');
INSERT INTO faturamento.debito_a_cobrar (dbac_id, imov_id, dbtp_id, dbac_tmatudebito, dbac_amreferenciadebito, dbac_amcobrancadebito,
                                         dbac_amreferenciacontabil, dbac_vldebito, dbac_nnprestacaodebito, dbac_nnprestacaocobradas,
                                         loca_id, qdra_id, dbac_cdsetorcomercial, dbac_nnquadra, dbac_nnlote, dbac_nnsublote,
                                         fntp_id, dbac_tmultimaalteracao, lict_id, dcst_idatual, cbfm_id, parc_id)
VALUES (9102, 100013, 3102, '2014-09-20 10:00:00', 201409, 201409, 201409, 300.00, 6, 0,
        1, 1, 1, 1, 1, 0, 4, '2014-09-20 10:00:00', 6, 0, 1, 9101);
INSERT INTO faturamento.deb_a_cobrar_catg (dbac_id, catg_id, dbcg_qteconomia, dbcg_vlcategoria, dbcg_tmultimaalteracao)
VALUES (9102, 1, 1, 300.00, '2014-09-20 10:00:00');
