-- Delta — imóvel 100498: consumo de 60 m³ com média 26 (acima do ALTO CONSUMO: 50 e 2 × a média) (lote 5e: CEN-MIC-004). Depende de mic-catalogos.sql, mic-rota-r4-consistir-202605.sql, cons-comando-faturar-r4-202605.sql e cons-catalogos.sql.
--
-- Residencial, 1 economia, água LIGADO, esgoto POTENCIAL, na R4; hidrômetro de 5 dígitos; consumos REAIS de 11/2025 a
-- 04/2026: 25, 28, 26, 27, 24, 29 (média 26). Limites da categoria RESIDENCIAL: os de mic-catalogos.sql (alto 50 m³ e 2 ×
-- a média; estouro 100 m³ e 3 × a média; baixo: 50% da média, com média acima de 10). Matrícula: 10049 + dígito módulo 11.
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota, ftst_id)
VALUES (100498, 1, 1, 4, 49, 0, '49', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 49, NULL);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100498, 101, 1, '2026-01-01 00:00:00');
INSERT INTO micromedicao.hidrometro (hidr_id, hidr_nnhidrometro, hidr_dtaquisicao, hidr_nnanofabricacao, hidr_icmacro, hidr_nnleituraacumulada,
                                     hidr_nndigitosleitura, hicm_id, himc_id, hidm_id, hist_id, hidr_tmultimaalteracao, hicp_id, hitp_id,
                                     hidr_icoperacional)
VALUES (49, 'SINT000049', '2024-12-01', 2024, 2, 0, 5, 1, 1, 1, 1, '2025-01-15 10:00:00', 1, 1, 1);
INSERT INTO atendimentopublico.ligacao_agua (lagu_id, lagu_dtligacaoagua, lagd_id, lagm_id, lapf_id, lagu_tmultimaalteracao)
VALUES (100498, '2025-01-15', 1, 1, 1, '2025-01-15 10:00:00');
INSERT INTO micromedicao.hidrometro_inst_hist (hidi_id, hidr_id, hidi_dtinstalacaohidrometro, medt_id, hili_id, hipr_id, hidi_nnleitinstalacaohidmt,
                                               hidi_dtinstalacaohidmtsistema, hidi_ictrocaprotecao, hidi_ictrocaregistro, hidi_tmultimaalteracao, lagu_id)
VALUES (49, 49, '2025-01-15', 1, 1, 1, 0, '2025-01-15', 2, 2, '2025-01-15 10:00:00', 100498);
UPDATE atendimentopublico.ligacao_agua SET hidi_id = 49 WHERE lagu_id = 100498;
INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_nnconsumocalculomedia,
                                            cshi_icfaturamento, cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (490, 100498, 1, 202511, 25, 25, 1, 1, 4, '2025-11-01 07:00:00'),
  (491, 100498, 1, 202512, 28, 28, 1, 1, 4, '2025-12-01 07:00:00'),
  (492, 100498, 1, 202601, 26, 26, 1, 1, 4, '2026-01-01 07:00:00'),
  (493, 100498, 1, 202602, 27, 27, 1, 1, 4, '2026-02-01 07:00:00'),
  (494, 100498, 1, 202603, 24, 24, 1, 1, 4, '2026-03-01 07:00:00'),
  (495, 100498, 1, 202604, 29, 29, 1, 1, 4, '2026-04-01 07:00:00');
INSERT INTO micromedicao.medicao_historico (mdhi_id, imov_id, medt_id, mdhi_amleitura, mdhi_dtleitantfatmt, mdhi_nnleitantfatmt, mdhi_nnleitantinformada,
                                            mdhi_dtleituraatualinformada, mdhi_nnleituraatualinformada, mdhi_dtleituraatualfaturamento,
                                            mdhi_nnleituraatualfaturamento, mdhi_nnconsumomedidomes, ltst_idleiturasituacaoatual,
                                            ltst_idleiturasituacaoanterior, mdhi_tmultimaalteracao, hidi_id, lagu_id, mdhi_icanalisado) VALUES
  (490, NULL, 1, 202604, '2026-03-31', 971, 971, '2026-04-30', 1000, '2026-04-30', 1000, 29, 1, 1, '2026-05-01 07:00:00', 49, 100498, 1),
  (491, NULL, 1, 202605, '2026-04-30', 1000, 1000, '2026-05-31', 1060, '2026-05-31', 1060, NULL, 1, 1, '2026-05-31 18:00:00', 49, 100498, 2);
