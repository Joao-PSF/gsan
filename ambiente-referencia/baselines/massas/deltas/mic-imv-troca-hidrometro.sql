-- Delta — IMV-M08 100358, perfil IMV-08 (cenarios-criticos.md §13.1): hidrômetro SUBSTITUÍDO no meio do período de leitura
-- de 05/2026 (lote 5c: CEN-MIC-003 V1). Depende de mic-catalogos.sql e mic-rota-r4-consistir-202605.sql.
--
-- Residencial, 1 economia, água LIGADO, na R4. H5 instalado em 15/01/2025 (leitura 0); consumos REAIS de 11/2025 a
-- 04/2026 de 20 m³ (média 20); medição de 04/2026: 780 → 800 em 30/04/2026.
-- A TROCA chega pela massa, como a operação "Efetuar Substituição de Hidrômetro" a deixaria: H5 RETIRADO em 15/05/2026
-- com leitura de retirada 812 (12 m³ desde a última leitura); H6 INSTALADO na mesma data com leitura de instalação 3; a
-- ligação passa a apontar a instalação do H6. A medição de 05/2026 é registrada no H6: anterior de faturamento 800 (a do
-- mês anterior, do H5), atual informada 15 em 31/05/2026, REALIZADA. A pergunta é a da especificação: como a consistência
-- compõe o consumo do mês da troca (12 m³ no H5 + 12 m³ no H6). Matrícula: 10035 + dígito módulo 11. Tudo SINTÉTICO.
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota)
VALUES (100358, 1, 1, 4, 5, 0, '450', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 5);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100358, 101, 1, '2026-01-01 00:00:00');

INSERT INTO micromedicao.hidrometro (hidr_id, hidr_nnhidrometro, hidr_dtaquisicao, hidr_nnanofabricacao, hidr_icmacro, hidr_nnleituraacumulada,
                                     hidr_nndigitosleitura, hicm_id, himc_id, hidm_id, hist_id, hidr_tmultimaalteracao, hicp_id, hitp_id,
                                     hidr_icoperacional) VALUES
  (5, 'SINT000005', '2024-12-01', 2024, 2, 812, 5, 1, 1, 1, 3, '2026-05-15 10:00:00', 1, 1, 1),
  (6, 'SINT000006', '2026-04-01', 2026, 2, 0, 5, 1, 1, 1, 1, '2026-05-15 10:00:00', 1, 1, 1);
INSERT INTO atendimentopublico.ligacao_agua (lagu_id, lagu_dtligacaoagua, lagd_id, lagm_id, lapf_id, lagu_tmultimaalteracao)
VALUES (100358, '2025-01-15', 1, 1, 1, '2026-05-15 10:00:00');
INSERT INTO micromedicao.hidrometro_inst_hist (hidi_id, hidr_id, hidi_dtinstalacaohidrometro, medt_id, hili_id, hipr_id, hidi_nnleitinstalacaohidmt,
                                               hidi_dtretiradahidrometro, hidi_nnleitretiradahidmt, hidi_dtinstalacaohidmtsistema,
                                               hidi_icinstalacaosubstituicao, hidi_ictrocaprotecao, hidi_ictrocaregistro, hidi_tmultimaalteracao,
                                               lagu_id) VALUES
  (5, 5, '2025-01-15', 1, 1, 1, 0, '2026-05-15', 812, '2025-01-15', NULL, 2, 2, '2026-05-15 10:00:00', 100358),
  (6, 6, '2026-05-15', 1, 1, 1, 3, NULL, NULL, '2026-05-15', 2, 2, 2, '2026-05-15 10:00:00', 100358);
UPDATE atendimentopublico.ligacao_agua SET hidi_id = 6 WHERE lagu_id = 100358;

INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_nnconsumocalculomedia,
                                            cshi_icfaturamento, cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (501, 100358, 1, 202511, 20, 20, 1, 1, 4, '2025-12-01 07:00:00'),
  (502, 100358, 1, 202512, 20, 20, 1, 1, 4, '2026-01-01 07:00:00'),
  (503, 100358, 1, 202601, 20, 20, 1, 1, 4, '2026-02-01 07:00:00'),
  (504, 100358, 1, 202602, 20, 20, 1, 1, 4, '2026-03-01 07:00:00'),
  (505, 100358, 1, 202603, 20, 20, 1, 1, 4, '2026-04-01 07:00:00'),
  (506, 100358, 1, 202604, 20, 20, 1, 1, 4, '2026-05-01 07:00:00');
INSERT INTO micromedicao.medicao_historico (mdhi_id, imov_id, medt_id, mdhi_amleitura, mdhi_dtleitantfatmt, mdhi_nnleitantfatmt, mdhi_nnleitantinformada,
                                            mdhi_dtleituraatualinformada, mdhi_nnleituraatualinformada, mdhi_dtleituraatualfaturamento,
                                            mdhi_nnleituraatualfaturamento, mdhi_nnconsumomedidomes, ltst_idleiturasituacaoatual,
                                            ltst_idleiturasituacaoanterior, mdhi_tmultimaalteracao, hidi_id, lagu_id, mdhi_icanalisado) VALUES
  (51, NULL, 1, 202604, '2026-03-31', 780, 780, '2026-04-30', 800, '2026-04-30', 800, 20, 1, 1, '2026-05-01 07:00:00', 5, 100358, 1),
  (52, NULL, 1, 202605, '2026-04-30', 800, 800, '2026-05-31', 15, '2026-05-31', 15, NULL, 1, 1, '2026-05-31 18:00:00', 6, 100358, 2);
