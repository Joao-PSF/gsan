-- Delta — crédito a realizar do IMV-01: R$ 30,00 em 1 prestação, nenhuma realizada (lote 5b: CEN-FAT-004 V3, V4).
-- Depende de fat-lancamentos-catalogos.sql e de imoveis-imv-01-02-03.sql.
-- Origem VALORES COBRADOS INDEVIDAMENTE (7), situação NORMAL (0), sem resíduo. SINTÉTICO.
INSERT INTO faturamento.credito_a_realizar_geral (crar_id, cage_ichistorico, cage_tmultimaalteracao)
VALUES (9201, 2, '2026-05-15 10:00:00');
INSERT INTO faturamento.credito_a_realizar (crar_id, imov_id, crti_id, crar_tmatucredito, crar_amreferenciacredito, crar_amcobrancacredito,
                                            crar_amreferenciacontabil, crar_vlresidualmesanterior, crar_vlcredito, crar_nnprestacaocredito,
                                            crar_nnprestacaorealizadas, loca_id, qdra_id, crar_cdsetorcomercial, crar_nnquadra, crar_nnlote,
                                            crar_nnsublote, crar_tmultimaalteracao, lict_id, dcst_idatual, crog_id)
VALUES (9201, 100013, 3201, '2026-05-15 10:00:00', 202605, 202605, 202605, 0.00, 30.00, 1, 0, 1, 1, 1, 1, 1, 0,
        '2026-05-15 10:00:00', 6, 0, 7);
INSERT INTO faturamento.cred_a_realiz_catg (crar_id, catg_id, cacg_qteconomia, cacg_vlcategoria, cacg_tmultimaalteracao)
VALUES (9201, 1, 1, 30.00, '2026-05-15 10:00:00');
