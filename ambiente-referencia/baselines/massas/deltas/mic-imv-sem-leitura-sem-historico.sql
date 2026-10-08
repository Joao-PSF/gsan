-- Delta — IMV-M07 100340, perfil IMV-07 (cenarios-criticos.md §13.1): leitura NÃO REALIZADA em 05/2026, SEM anormalidade, com
-- histórico INSUFICIENTE para a média — só 04/2026 (lote 5c: CEN-MIC-001 V4). Depende de mic-catalogos.sql e
-- mic-rota-r4-consistir-202605.sql.
--
-- Residencial, 1 economia, água LIGADO, na R4. Hidrômetro H4 instalado em 15/03/2026 com leitura 0; único consumo
-- registrado: 04/2026, REAL, 8 m³ (medição 0 → 8). Medição de 05/2026 registrada sem leitura e sem anormalidade,
-- situação NÃO REALIZADA. Matrícula: 10034 + dígito módulo 11. Tudo SINTÉTICO.
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota)
VALUES (100340, 1, 1, 4, 4, 0, '440', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 4);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100340, 101, 1, '2026-01-01 00:00:00');

INSERT INTO micromedicao.hidrometro (hidr_id, hidr_nnhidrometro, hidr_dtaquisicao, hidr_nnanofabricacao, hidr_icmacro, hidr_nnleituraacumulada,
                                     hidr_nndigitosleitura, hicm_id, himc_id, hidm_id, hist_id, hidr_tmultimaalteracao, hicp_id, hitp_id,
                                     hidr_icoperacional)
VALUES (4, 'SINT000004', '2026-02-01', 2026, 2, 0, 5, 1, 1, 1, 1, '2026-03-15 10:00:00', 1, 1, 1);
INSERT INTO atendimentopublico.ligacao_agua (lagu_id, lagu_dtligacaoagua, lagd_id, lagm_id, lapf_id, lagu_tmultimaalteracao)
VALUES (100340, '2026-03-15', 1, 1, 1, '2026-03-15 10:00:00');
INSERT INTO micromedicao.hidrometro_inst_hist (hidi_id, hidr_id, hidi_dtinstalacaohidrometro, medt_id, hili_id, hipr_id, hidi_nnleitinstalacaohidmt,
                                               hidi_dtinstalacaohidmtsistema, hidi_ictrocaprotecao, hidi_ictrocaregistro, hidi_tmultimaalteracao, lagu_id)
VALUES (4, 4, '2026-03-15', 1, 1, 1, 0, '2026-03-15', 2, 2, '2026-03-15 10:00:00', 100340);
UPDATE atendimentopublico.ligacao_agua SET hidi_id = 4 WHERE lagu_id = 100340;

INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_nnconsumocalculomedia,
                                            cshi_icfaturamento, cstp_id, rota_id, cshi_tmultimaalteracao)
VALUES (401, 100340, 1, 202604, 8, 8, 1, 1, 4, '2026-05-01 07:00:00');
INSERT INTO micromedicao.medicao_historico (mdhi_id, imov_id, medt_id, mdhi_amleitura, mdhi_dtleitantfatmt, mdhi_nnleitantfatmt, mdhi_nnleitantinformada,
                                            mdhi_dtleituraatualinformada, mdhi_nnleituraatualinformada, mdhi_dtleituraatualfaturamento,
                                            mdhi_nnleituraatualfaturamento, mdhi_nnconsumomedidomes, ltst_idleiturasituacaoatual,
                                            ltst_idleiturasituacaoanterior, mdhi_tmultimaalteracao, hidi_id, lagu_id, mdhi_icanalisado) VALUES
  (41, NULL, 1, 202604, '2026-03-15', 0, 0, '2026-04-30', 8, '2026-04-30', 8, 8, 1, NULL, '2026-05-01 07:00:00', 4, 100340, 1),
  (42, NULL, 1, 202605, '2026-04-30', 8, 8, NULL, NULL, '2026-05-31', 8, NULL, 2, 1, '2026-05-31 18:00:00', 4, 100340, 2);
