-- Delta — débito a cobrar de SERVIÇO do IMV-01: R$ 100,00 em 3 prestações, nenhuma cobrada (lote 5b: CEN-FAT-004 V1,
-- V4). Depende de fat-lancamentos-catalogos.sql e de imoveis-imv-01-02-03.sql.
-- O mesmo valor e as mesmas prestações do débito que CEN-ATE-008 V1 viu nascer (R$ 100,00 em 3): o que a conta cobra
-- de cada prestação é a pergunta que ficou aberta no lote 4 (F2-52). Situação NORMAL (0), cobrança EM CONTA (1),
-- referência 05/2026. SINTÉTICO.
INSERT INTO faturamento.debito_a_cobrar_geral (dbac_id, dage_ichistorico, dage_tmultimaalteracao)
VALUES (9001, 2, '2026-05-15 10:00:00');
INSERT INTO faturamento.debito_a_cobrar (dbac_id, imov_id, dbtp_id, dbac_tmatudebito, dbac_amreferenciadebito, dbac_amcobrancadebito,
                                         dbac_amreferenciacontabil, dbac_vldebito, dbac_nnprestacaodebito, dbac_nnprestacaocobradas,
                                         loca_id, qdra_id, dbac_cdsetorcomercial, dbac_nnquadra, dbac_nnlote, dbac_nnsublote,
                                         fntp_id, dbac_tmultimaalteracao, lict_id, dcst_idatual, cbfm_id)
VALUES (9001, 100013, 3101, '2026-05-15 10:00:00', 202605, 202605, 202605, 100.00, 3, 0,
        1, 1, 1, 1, 1, 0, 1, '2026-05-15 10:00:00', 6, 0, 1);
INSERT INTO faturamento.deb_a_cobrar_catg (dbac_id, catg_id, dbcg_qteconomia, dbcg_vlcategoria, dbcg_tmultimaalteracao)
VALUES (9001, 1, 1, 100.00, '2026-05-15 10:00:00');
