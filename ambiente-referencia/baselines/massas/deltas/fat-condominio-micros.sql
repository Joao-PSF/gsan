-- Delta — micro-condomínio na rota R1 do comando de FATURAR GRUPO de 05/2026 (lote 5b: CEN-FAT-006 V1, V2). Depende de
-- batch-faturamento-g1-202605.sql e de imoveis-imv-01-02-03.sql (perfil, envio de conta, subcategoria 101).
--
-- IMV-C  100250  condomínio PRINCIPAL (imov_icimovelcondominio = 1): medidor geral, residencial, 2 economias; não é
--                faturado como imóvel (a seleção da rota exclui o principal) — o seu consumo é o que se rateia
-- IMV-M1 100269  micro do IMV-C (imov_idimovelcondominio = 100250, indicador 2), residencial, 1 economia, 20 m³
-- IMV-M2 100277  micro do IMV-C, residencial, 1 economia, 25 m³ — IMV-13 de cenarios-criticos.md §13.1
-- O IMV-C consome 75 m³ em 05/2026: a ratear 75 − (20 + 25) = 30 m³, valorados pela tarifa do principal e divididos
-- pelas economias dos vinculados (2) — CEN-FAT-006 V1 (ControladorMicromedicao.obterConsumoASerRateado,
-- ControladorFaturamentoFINAL.calcularValorRateioPorEconomia).
-- O rateio só existe se o principal tiver LIGAÇÃO DE ÁGUA (ControladorFaturamentoFINAL.obterValorConsumoASerRateado):
-- linha em ligacao_agua, com diâmetro, material e perfil SINTÉTICOS (mesmos ids e textos de atendimento-catalogos.sql).
-- Matrículas: número-base 10025..10027 seguido do dígito módulo 11. Tudo SINTÉTICO.
INSERT INTO atendimentopublico.ligacao_agua_diametro (lagd_id, lagd_dsligacaoaguadiametro, lagd_icuso, lagd_tmultimaalteracao)
VALUES (1, '3/4 POL (SINTETICO)', 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.ligacao_agua_material (lagm_id, lagm_dsligacaoaguamaterial, lagm_icuso, lagm_tmultimaalteracao)
VALUES (1, 'PVC (SINTETICO)', 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.ligacao_agua_perfil (lapf_id, lapf_dsligacaoaguaperfil, lapf_icuso, lapf_tmultimaalteracao)
VALUES (1, 'NORMAL (SINTETICO)', 1, '2026-01-01 00:00:00');

INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             imov_idimovelcondominio, last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao,
                             imov_tmultimaalteracao, cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto,
                             imov_icimovelareacomum, logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota) VALUES
  (100250, 1, 1, 1, 25, 0, '250', 1, NULL, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 1, 101, 25),
  (100269, 1, 1, 1, 25, 1, '250A', 2, 100250, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 26),
  (100277, 1, 1, 1, 25, 2, '250B', 2, 100250, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 27);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao) VALUES
  (100250, 101, 2, '2026-01-01 00:00:00'),
  (100269, 101, 1, '2026-01-01 00:00:00'),
  (100277, 101, 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.ligacao_agua (lagu_id, lagu_dtligacaoagua, lagd_id, lagm_id, lapf_id, lagu_tmultimaalteracao)
VALUES (100250, '2025-01-01', 1, 1, 1, '2026-01-01 00:00:00');

INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_icfaturamento,
                                            cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (11, 100250, 1, 202605, 75, 1, 1, 1, '2026-06-01 07:00:00'),
  (12, 100269, 1, 202605, 20, 1, 1, 1, '2026-06-01 07:00:00'),
  (13, 100277, 1, 202605, 25, 1, 1, 1, '2026-06-01 07:00:00');
