-- Delta — imóvel 100420 em situação especial de faturamento PARALISAR EMISSÃO DE CONTAS (1), vigente de 05/2026 a 07/2026 (lote 5e). Depende de mic-catalogos.sql, mic-rota-r4-consistir-202605.sql, cons-comando-faturar-r4-202605.sql e cons-catalogos.sql.
--
-- Residencial, 1 economia, água LIGADO, esgoto POTENCIAL, tarifa TAR-01, na R4; hidrômetro instalado em 15/01/2025;
-- consumos REAIS de 11/2025 a 04/2026: 25, 28, 26, 27, 24, 29 (média 26); 04/2026: 971 → 1000; leitura de 05/2026 realizada: 1000 → 1027.
-- Situação especial pelo histórico (fatur_situacao_hist, início 05/2026, fim 07/2026) e no próprio imóvel (imov.ftst_id),
-- como a operação "Informar Situação Especial de Faturamento" os deixaria. Matrícula: 10042 + dígito módulo 11.
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota, ftst_id)
VALUES (100420, 1, 1, 4, 42, 0, '42', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 42, 1);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100420, 101, 1, '2026-01-01 00:00:00');
INSERT INTO micromedicao.hidrometro (hidr_id, hidr_nnhidrometro, hidr_dtaquisicao, hidr_nnanofabricacao, hidr_icmacro, hidr_nnleituraacumulada,
                                     hidr_nndigitosleitura, hicm_id, himc_id, hidm_id, hist_id, hidr_tmultimaalteracao, hicp_id, hitp_id,
                                     hidr_icoperacional)
VALUES (42, 'SINT000042', '2024-12-01', 2024, 2, 0, 5, 1, 1, 1, 1, '2025-01-15 10:00:00', 1, 1, 1);
INSERT INTO atendimentopublico.ligacao_agua (lagu_id, lagu_dtligacaoagua, lagd_id, lagm_id, lapf_id, lagu_tmultimaalteracao)
VALUES (100420, '2025-01-15', 1, 1, 1, '2025-01-15 10:00:00');
INSERT INTO micromedicao.hidrometro_inst_hist (hidi_id, hidr_id, hidi_dtinstalacaohidrometro, medt_id, hili_id, hipr_id, hidi_nnleitinstalacaohidmt,
                                               hidi_dtinstalacaohidmtsistema, hidi_ictrocaprotecao, hidi_ictrocaregistro, hidi_tmultimaalteracao, lagu_id)
VALUES (42, 42, '2025-01-15', 1, 1, 1, 0, '2025-01-15', 2, 2, '2025-01-15 10:00:00', 100420);
UPDATE atendimentopublico.ligacao_agua SET hidi_id = 42 WHERE lagu_id = 100420;
INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_nnconsumocalculomedia,
                                            cshi_icfaturamento, cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (420, 100420, 1, 202511, 25, 25, 1, 1, 4, '2025-11-01 07:00:00'),
  (421, 100420, 1, 202512, 28, 28, 1, 1, 4, '2025-12-01 07:00:00'),
  (422, 100420, 1, 202601, 26, 26, 1, 1, 4, '2026-01-01 07:00:00'),
  (423, 100420, 1, 202602, 27, 27, 1, 1, 4, '2026-02-01 07:00:00'),
  (424, 100420, 1, 202603, 24, 24, 1, 1, 4, '2026-03-01 07:00:00'),
  (425, 100420, 1, 202604, 29, 29, 1, 1, 4, '2026-04-01 07:00:00');
INSERT INTO micromedicao.medicao_historico (mdhi_id, imov_id, medt_id, mdhi_amleitura, mdhi_dtleitantfatmt, mdhi_nnleitantfatmt, mdhi_nnleitantinformada,
                                            mdhi_dtleituraatualinformada, mdhi_nnleituraatualinformada, mdhi_dtleituraatualfaturamento,
                                            mdhi_nnleituraatualfaturamento, mdhi_nnconsumomedidomes, ltst_idleiturasituacaoatual,
                                            ltst_idleiturasituacaoanterior, mdhi_tmultimaalteracao, hidi_id, lagu_id, mdhi_icanalisado) VALUES
  (420, NULL, 1, 202604, '2026-03-31', 971, 971, '2026-04-30', 1000, '2026-04-30', 1000, 29, 1, 1, '2026-05-01 07:00:00', 42, 100420, 1),
  (421, NULL, 1, 202605, '2026-04-30', 1000, 1000, '2026-05-31', 1027, '2026-05-31', 1027, NULL, 1, 1, '2026-05-31 18:00:00', 42, 100420, 2);
INSERT INTO faturamento.fatur_situacao_hist (ftsh_id, imov_id, ftst_id, ftsm_id, ftsh_tmultimaalteracao, ftsh_amfatmtsitinicio,
                                         ftsh_amfaturamentosituacaofim, usur_id, ftsh_tminclusao)
VALUES (42, 100420, 1, 1, '2026-05-10 10:00:00', 202605, 202607, 1, '2026-05-10 10:00:00');
