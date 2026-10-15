-- Delta — débito a cobrar de SERVIÇO LONGO do IMV-01: R$ 240,00 em 24 prestações, nenhuma cobrada (lote 7b: CEN-COB-004 —
-- curto × longo prazo). Depende de fat-lancamentos-catalogos.sql e de imoveis-imv-01-02-03.sql.
-- EVIDÊNCIA: o parcelamento separa o que resta do débito a cobrar em CURTO prazo (as prestações dos próximos 12 meses) e
-- LONGO prazo (as demais) — ControladorFaturamentoFINAL.obterValorCurtoELongoPrazo:17915 — e gera um débito de cada
-- (PARCELAMENTO DEB COBRAR CP 45 / LP 47); o débito de 3× da massa só tem curto prazo. Mesmo formato de
-- fat-debito-servico-3x.sql; o faturamento de 05/2026 cobra a 1ª prestação (R$ 10,00) e restam 23. SINTÉTICO; id fora da
-- faixa da sequência (8901).
INSERT INTO faturamento.debito_a_cobrar_geral (dbac_id, dage_ichistorico, dage_tmultimaalteracao)
VALUES (8901, 2, '2026-05-15 10:00:00');
INSERT INTO faturamento.debito_a_cobrar (dbac_id, imov_id, dbtp_id, dbac_tmatudebito, dbac_amreferenciadebito, dbac_amcobrancadebito,
                                         dbac_amreferenciacontabil, dbac_vldebito, dbac_nnprestacaodebito, dbac_nnprestacaocobradas,
                                         loca_id, qdra_id, dbac_cdsetorcomercial, dbac_nnquadra, dbac_nnlote, dbac_nnsublote,
                                         fntp_id, dbac_tmultimaalteracao, lict_id, dcst_idatual, cbfm_id)
VALUES (8901, 100013, 3101, '2026-05-15 10:00:00', 202605, 202605, 202605, 240.00, 24, 0,
        1, 1, 1, 1, 1, 0, 1, '2026-05-15 10:00:00', 6, 0, 1);
INSERT INTO faturamento.deb_a_cobrar_catg (dbac_id, catg_id, dbcg_qteconomia, dbcg_vlcategoria, dbcg_tmultimaalteracao)
VALUES (8901, 1, 1, 240.00, '2026-05-15 10:00:00');
