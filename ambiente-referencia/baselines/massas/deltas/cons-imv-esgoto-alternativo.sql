-- Delta — imóvel 100463 com ligação de ESGOTO LIGADO, percentual de esgoto 80,00%, coleta 100,00% e percentual ALTERNATIVO
-- 50,00% até 20 m³ por economia (lote 5e: CEN-FAT-003 V2). Depende de mic-catalogos.sql, mic-rota-r4-consistir-202605.sql, cons-comando-faturar-r4-202605.sql e cons-catalogos.sql.
--
-- Água LIGADO medida (1000 → 1027, 27 m³ em 05/2026), residencial, 1 economia. O alternativo vale quando o consumo de
-- esgoto por economia não passa do limite e o alternativo é MENOR que o padrão (ControladorFaturamentoFINAL:53048-53080):
-- aqui 27 > 20 — o consumo está ACIMA do limite. Matrícula: 10046 + dígito módulo 11.
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota, ftst_id)
VALUES (100463, 1, 1, 4, 46, 0, '46', 2, 3, 3, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 46, NULL);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100463, 101, 1, '2026-01-01 00:00:00');
INSERT INTO micromedicao.hidrometro (hidr_id, hidr_nnhidrometro, hidr_dtaquisicao, hidr_nnanofabricacao, hidr_icmacro, hidr_nnleituraacumulada,
                                     hidr_nndigitosleitura, hicm_id, himc_id, hidm_id, hist_id, hidr_tmultimaalteracao, hicp_id, hitp_id,
                                     hidr_icoperacional)
VALUES (46, 'SINT000046', '2024-12-01', 2024, 2, 0, 5, 1, 1, 1, 1, '2025-01-15 10:00:00', 1, 1, 1);
INSERT INTO atendimentopublico.ligacao_agua (lagu_id, lagu_dtligacaoagua, lagd_id, lagm_id, lapf_id, lagu_tmultimaalteracao)
VALUES (100463, '2025-01-15', 1, 1, 1, '2025-01-15 10:00:00');
INSERT INTO micromedicao.hidrometro_inst_hist (hidi_id, hidr_id, hidi_dtinstalacaohidrometro, medt_id, hili_id, hipr_id, hidi_nnleitinstalacaohidmt,
                                               hidi_dtinstalacaohidmtsistema, hidi_ictrocaprotecao, hidi_ictrocaregistro, hidi_tmultimaalteracao, lagu_id)
VALUES (46, 46, '2025-01-15', 1, 1, 1, 0, '2025-01-15', 2, 2, '2025-01-15 10:00:00', 100463);
UPDATE atendimentopublico.ligacao_agua SET hidi_id = 46 WHERE lagu_id = 100463;
INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_nnconsumocalculomedia,
                                            cshi_icfaturamento, cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (460, 100463, 1, 202511, 25, 25, 1, 1, 4, '2025-11-01 07:00:00'),
  (461, 100463, 1, 202512, 28, 28, 1, 1, 4, '2025-12-01 07:00:00'),
  (462, 100463, 1, 202601, 26, 26, 1, 1, 4, '2026-01-01 07:00:00'),
  (463, 100463, 1, 202602, 27, 27, 1, 1, 4, '2026-02-01 07:00:00'),
  (464, 100463, 1, 202603, 24, 24, 1, 1, 4, '2026-03-01 07:00:00'),
  (465, 100463, 1, 202604, 29, 29, 1, 1, 4, '2026-04-01 07:00:00');
INSERT INTO micromedicao.medicao_historico (mdhi_id, imov_id, medt_id, mdhi_amleitura, mdhi_dtleitantfatmt, mdhi_nnleitantfatmt, mdhi_nnleitantinformada,
                                            mdhi_dtleituraatualinformada, mdhi_nnleituraatualinformada, mdhi_dtleituraatualfaturamento,
                                            mdhi_nnleituraatualfaturamento, mdhi_nnconsumomedidomes, ltst_idleiturasituacaoatual,
                                            ltst_idleiturasituacaoanterior, mdhi_tmultimaalteracao, hidi_id, lagu_id, mdhi_icanalisado) VALUES
  (460, NULL, 1, 202604, '2026-03-31', 971, 971, '2026-04-30', 1000, '2026-04-30', 1000, 29, 1, 1, '2026-05-01 07:00:00', 46, 100463, 1),
  (461, NULL, 1, 202605, '2026-04-30', 1000, 1000, '2026-05-31', 1027, '2026-05-31', 1027, NULL, 1, 1, '2026-05-31 18:00:00', 46, 100463, 2);
INSERT INTO atendimentopublico.ligacao_esgoto (lesg_id, lesg_dtligacao, lesg_pcesgoto, lesg_pccoleta, lesg_pcalternativo,
                                              lesg_nnconsumopcalternativo, lesg_tmultimaalteracao)
VALUES (100463, '2025-01-15', 80.00, 100.00, 50.00, 20, '2025-01-15 10:00:00');
