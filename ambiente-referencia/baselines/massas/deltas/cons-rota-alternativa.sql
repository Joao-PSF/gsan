-- Delta — rota R5 do G1 (quadra 5) e dois imóveis com ROTA ALTERNATIVA (lote 5e: CEN-CAD-005). Depende de mic-catalogos.sql, mic-rota-r4-consistir-202605.sql, cons-comando-faturar-r4-202605.sql e cons-catalogos.sql.
--
-- 100536: na quadra 5 (rota R5, fora dos comandos), com rota ALTERNATIVA R4; 100544: na quadra 4 (rota R4, a dos comandos),
-- com rota ALTERNATIVA R5. Os dois medidos (1000 → 1027 em 05/2026), residenciais, 1 economia, água LIGADO. Os comandos
-- de consistir e de faturar cobrem só a R4: quem a consistência e o faturamento alcançam mostra qual rota prevalece
-- (ControladorMicromedicao.pesquisarImovelParaConsistirLeitura escolhe a consulta pelo indicador de rota alternativa
-- da rota).
-- Matrículas: 10053 e 10054 + dígito módulo 11.
INSERT INTO micromedicao.rota (rota_id, lttp_id, empr_id, rota_icuso, rota_tmultimaalteracao, ftgr_id, stcm_id, cbgr_id, rota_cdrota,
                               empr_idcobranca, rota_icalternativa, rota_ictransmissaooffline, rota_icdividerota,
                               rota_icimpressaotermicafinalgrupo)
VALUES (5, 1, 1, 1, '2026-01-01 00:00:00', 1, 1, 1, 5, 1, 2, 2, 2, 2);
INSERT INTO cadastro.quadra (qdra_id, stcm_id, qdra_nnquadra, rota_id, qdra_icuso, qdra_tmultimaalteracao, qdra_icautoincrementolote,
                             bair_id, qdra_icredeagua, qdra_icredeesgoto)
VALUES (5, 1, 5, 5, 1, '2026-01-01 00:00:00', 2, 1, 2, 2);
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota, ftst_id)
VALUES (100536, 1, 1, 5, 53, 0, '53', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 53, NULL);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100536, 101, 1, '2026-01-01 00:00:00');
INSERT INTO micromedicao.hidrometro (hidr_id, hidr_nnhidrometro, hidr_dtaquisicao, hidr_nnanofabricacao, hidr_icmacro, hidr_nnleituraacumulada,
                                     hidr_nndigitosleitura, hicm_id, himc_id, hidm_id, hist_id, hidr_tmultimaalteracao, hicp_id, hitp_id,
                                     hidr_icoperacional)
VALUES (53, 'SINT000053', '2024-12-01', 2024, 2, 0, 5, 1, 1, 1, 1, '2025-01-15 10:00:00', 1, 1, 1);
INSERT INTO atendimentopublico.ligacao_agua (lagu_id, lagu_dtligacaoagua, lagd_id, lagm_id, lapf_id, lagu_tmultimaalteracao)
VALUES (100536, '2025-01-15', 1, 1, 1, '2025-01-15 10:00:00');
INSERT INTO micromedicao.hidrometro_inst_hist (hidi_id, hidr_id, hidi_dtinstalacaohidrometro, medt_id, hili_id, hipr_id, hidi_nnleitinstalacaohidmt,
                                               hidi_dtinstalacaohidmtsistema, hidi_ictrocaprotecao, hidi_ictrocaregistro, hidi_tmultimaalteracao, lagu_id)
VALUES (53, 53, '2025-01-15', 1, 1, 1, 0, '2025-01-15', 2, 2, '2025-01-15 10:00:00', 100536);
UPDATE atendimentopublico.ligacao_agua SET hidi_id = 53 WHERE lagu_id = 100536;
INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_nnconsumocalculomedia,
                                            cshi_icfaturamento, cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (530, 100536, 1, 202511, 25, 25, 1, 1, 5, '2025-11-01 07:00:00'),
  (531, 100536, 1, 202512, 28, 28, 1, 1, 5, '2025-12-01 07:00:00'),
  (532, 100536, 1, 202601, 26, 26, 1, 1, 5, '2026-01-01 07:00:00'),
  (533, 100536, 1, 202602, 27, 27, 1, 1, 5, '2026-02-01 07:00:00'),
  (534, 100536, 1, 202603, 24, 24, 1, 1, 5, '2026-03-01 07:00:00'),
  (535, 100536, 1, 202604, 29, 29, 1, 1, 5, '2026-04-01 07:00:00');
INSERT INTO micromedicao.medicao_historico (mdhi_id, imov_id, medt_id, mdhi_amleitura, mdhi_dtleitantfatmt, mdhi_nnleitantfatmt, mdhi_nnleitantinformada,
                                            mdhi_dtleituraatualinformada, mdhi_nnleituraatualinformada, mdhi_dtleituraatualfaturamento,
                                            mdhi_nnleituraatualfaturamento, mdhi_nnconsumomedidomes, ltst_idleiturasituacaoatual,
                                            ltst_idleiturasituacaoanterior, mdhi_tmultimaalteracao, hidi_id, lagu_id, mdhi_icanalisado) VALUES
  (530, NULL, 1, 202604, '2026-03-31', 971, 971, '2026-04-30', 1000, '2026-04-30', 1000, 29, 1, 1, '2026-05-01 07:00:00', 53, 100536, 1),
  (531, NULL, 1, 202605, '2026-04-30', 1000, 1000, '2026-05-31', 1027, '2026-05-31', 1027, NULL, 1, 1, '2026-05-31 18:00:00', 53, 100536, 2);
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota, ftst_id)
VALUES (100544, 1, 1, 4, 54, 0, '54', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 54, NULL);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100544, 101, 1, '2026-01-01 00:00:00');
INSERT INTO micromedicao.hidrometro (hidr_id, hidr_nnhidrometro, hidr_dtaquisicao, hidr_nnanofabricacao, hidr_icmacro, hidr_nnleituraacumulada,
                                     hidr_nndigitosleitura, hicm_id, himc_id, hidm_id, hist_id, hidr_tmultimaalteracao, hicp_id, hitp_id,
                                     hidr_icoperacional)
VALUES (54, 'SINT000054', '2024-12-01', 2024, 2, 0, 5, 1, 1, 1, 1, '2025-01-15 10:00:00', 1, 1, 1);
INSERT INTO atendimentopublico.ligacao_agua (lagu_id, lagu_dtligacaoagua, lagd_id, lagm_id, lapf_id, lagu_tmultimaalteracao)
VALUES (100544, '2025-01-15', 1, 1, 1, '2025-01-15 10:00:00');
INSERT INTO micromedicao.hidrometro_inst_hist (hidi_id, hidr_id, hidi_dtinstalacaohidrometro, medt_id, hili_id, hipr_id, hidi_nnleitinstalacaohidmt,
                                               hidi_dtinstalacaohidmtsistema, hidi_ictrocaprotecao, hidi_ictrocaregistro, hidi_tmultimaalteracao, lagu_id)
VALUES (54, 54, '2025-01-15', 1, 1, 1, 0, '2025-01-15', 2, 2, '2025-01-15 10:00:00', 100544);
UPDATE atendimentopublico.ligacao_agua SET hidi_id = 54 WHERE lagu_id = 100544;
INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_nnconsumocalculomedia,
                                            cshi_icfaturamento, cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (540, 100544, 1, 202511, 25, 25, 1, 1, 4, '2025-11-01 07:00:00'),
  (541, 100544, 1, 202512, 28, 28, 1, 1, 4, '2025-12-01 07:00:00'),
  (542, 100544, 1, 202601, 26, 26, 1, 1, 4, '2026-01-01 07:00:00'),
  (543, 100544, 1, 202602, 27, 27, 1, 1, 4, '2026-02-01 07:00:00'),
  (544, 100544, 1, 202603, 24, 24, 1, 1, 4, '2026-03-01 07:00:00'),
  (545, 100544, 1, 202604, 29, 29, 1, 1, 4, '2026-04-01 07:00:00');
INSERT INTO micromedicao.medicao_historico (mdhi_id, imov_id, medt_id, mdhi_amleitura, mdhi_dtleitantfatmt, mdhi_nnleitantfatmt, mdhi_nnleitantinformada,
                                            mdhi_dtleituraatualinformada, mdhi_nnleituraatualinformada, mdhi_dtleituraatualfaturamento,
                                            mdhi_nnleituraatualfaturamento, mdhi_nnconsumomedidomes, ltst_idleiturasituacaoatual,
                                            ltst_idleiturasituacaoanterior, mdhi_tmultimaalteracao, hidi_id, lagu_id, mdhi_icanalisado) VALUES
  (540, NULL, 1, 202604, '2026-03-31', 971, 971, '2026-04-30', 1000, '2026-04-30', 1000, 29, 1, 1, '2026-05-01 07:00:00', 54, 100544, 1),
  (541, NULL, 1, 202605, '2026-04-30', 1000, 1000, '2026-05-31', 1027, '2026-05-31', 1027, NULL, 1, 1, '2026-05-31 18:00:00', 54, 100544, 2);
UPDATE cadastro.imovel SET rota_idalternativa = 4 WHERE imov_id = 100536;
UPDATE cadastro.imovel SET rota_idalternativa = 5 WHERE imov_id = 100544;
