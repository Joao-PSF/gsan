-- Delta — IMV-16 (cenarios-criticos.md §13.1: "sem nenhum registro de consumo anterior") na rota R1 do comando de
-- FATURAR GRUPO de 05/2026 (lote 5: CEN-FAT-011). Depende de batch-faturamento-g1-202605.sql e de
-- imoveis-imv-01-02-03.sql.
--
-- Como o IMV-01 (residencial, 1 economia, água LIGADO, esgoto POTENCIAL, tarifa TAR-01, quadra 1 de R1), mas SEM
-- NENHUMA linha em micromedicao.consumo_historico — nem da referência faturada, nem de qualquer outra.
-- Matrícula: número-base 10016 seguido do dígito módulo 11 (gcom.util.Util.obterDigitoVerificadorModulo11).
-- Tudo SINTÉTICO.
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota)
VALUES (100161, 1, 1, 1, 16, 0, '160', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 16);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100161, 101, 1, '2026-01-01 00:00:00');
