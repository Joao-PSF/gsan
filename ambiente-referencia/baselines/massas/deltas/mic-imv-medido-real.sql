-- Delta — IMV-M01 100315, perfil IMV-01 MEDIDO (cenarios-criticos.md §13.1): leituras anterior e atual realizadas,
-- histórico de 6 referências (lote 5c: CEN-MIC-001 V1). Depende de mic-catalogos.sql e mic-rota-r4-consistir-202605.sql.
--
-- Residencial, 1 economia, água LIGADO, esgoto POTENCIAL, tarifa TAR-01, na R4. Hidrômetro H1 (5 dígitos) instalado na
-- ligação de água em 15/01/2025 com leitura 0. Consumos REAIS de 11/2025 a 04/2026: 25, 28, 26, 27, 24, 29 (média 26).
-- Medição de 04/2026: 971 → 1000. Medição de 05/2026 já REGISTRADA (o que "Efetuar Leitura" gravaria): anterior de
-- faturamento 1000 (30/04/2026), atual informada 1027 em 31/05/2026, situação REALIZADA; os campos de faturamento da
-- atual (obrigatórios no schema) chegam iguais aos informados e são recalculados pela consistência.
-- Matrícula: número-base 10031 seguido do dígito módulo 11. Tudo SINTÉTICO.
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota)
VALUES (100315, 1, 1, 4, 1, 0, '410', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 1);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100315, 101, 1, '2026-01-01 00:00:00');

INSERT INTO micromedicao.hidrometro (hidr_id, hidr_nnhidrometro, hidr_dtaquisicao, hidr_nnanofabricacao, hidr_icmacro, hidr_nnleituraacumulada,
                                     hidr_nndigitosleitura, hicm_id, himc_id, hidm_id, hist_id, hidr_tmultimaalteracao, hicp_id, hitp_id,
                                     hidr_icoperacional)
VALUES (1, 'SINT000001', '2024-12-01', 2024, 2, 0, 5, 1, 1, 1, 1, '2025-01-15 10:00:00', 1, 1, 1);
INSERT INTO atendimentopublico.ligacao_agua (lagu_id, lagu_dtligacaoagua, lagd_id, lagm_id, lapf_id, lagu_tmultimaalteracao)
VALUES (100315, '2025-01-15', 1, 1, 1, '2025-01-15 10:00:00');
INSERT INTO micromedicao.hidrometro_inst_hist (hidi_id, hidr_id, hidi_dtinstalacaohidrometro, medt_id, hili_id, hipr_id, hidi_nnleitinstalacaohidmt,
                                               hidi_dtinstalacaohidmtsistema, hidi_ictrocaprotecao, hidi_ictrocaregistro, hidi_tmultimaalteracao, lagu_id)
VALUES (1, 1, '2025-01-15', 1, 1, 1, 0, '2025-01-15', 2, 2, '2025-01-15 10:00:00', 100315);
UPDATE atendimentopublico.ligacao_agua SET hidi_id = 1 WHERE lagu_id = 100315;

INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_nnconsumocalculomedia,
                                            cshi_icfaturamento, cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (101, 100315, 1, 202511, 25, 25, 1, 1, 4, '2025-12-01 07:00:00'),
  (102, 100315, 1, 202512, 28, 28, 1, 1, 4, '2026-01-01 07:00:00'),
  (103, 100315, 1, 202601, 26, 26, 1, 1, 4, '2026-02-01 07:00:00'),
  (104, 100315, 1, 202602, 27, 27, 1, 1, 4, '2026-03-01 07:00:00'),
  (105, 100315, 1, 202603, 24, 24, 1, 1, 4, '2026-04-01 07:00:00'),
  (106, 100315, 1, 202604, 29, 29, 1, 1, 4, '2026-05-01 07:00:00');
INSERT INTO micromedicao.medicao_historico (mdhi_id, imov_id, medt_id, mdhi_amleitura, mdhi_dtleitantfatmt, mdhi_nnleitantfatmt, mdhi_nnleitantinformada,
                                            mdhi_dtleituraatualinformada, mdhi_nnleituraatualinformada, mdhi_dtleituraatualfaturamento,
                                            mdhi_nnleituraatualfaturamento, mdhi_nnconsumomedidomes, ltst_idleiturasituacaoatual,
                                            ltst_idleiturasituacaoanterior, mdhi_tmultimaalteracao, hidi_id, lagu_id, mdhi_icanalisado) VALUES
  (11, NULL, 1, 202604, '2026-03-31', 971, 971, '2026-04-30', 1000, '2026-04-30', 1000, 29, 1, 1, '2026-05-01 07:00:00', 1, 100315, 1),
  (12, NULL, 1, 202605, '2026-04-30', 1000, 1000, '2026-05-31', 1027, '2026-05-31', 1027, NULL, 1, 1, '2026-05-31 18:00:00', 1, 100315, 2);
