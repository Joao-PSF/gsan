-- Delta — IMV-M10 100374: hidrômetro RETIRADO no meio do período de leitura de 05/2026, sem reposição (lote 5c:
-- CEN-MIC-003 V3). Depende de mic-catalogos.sql e mic-rota-r4-consistir-202605.sql.
--
-- Residencial, 1 economia, água LIGADO, na R4. H8 instalado em 15/01/2025 (leitura 0); consumos REAIS de 11/2025 a 04/2026
-- de 20 m³ (média 20); medição de 04/2026: 380 → 400 em 30/04/2026. H8 RETIRADO em 15/05/2026 com leitura de retirada 410
-- (o que "Efetuar Retirada de Hidrômetro" gravaria); a ligação deixa de apontar instalação. Sem medição de 05/2026 —
-- não há hidrômetro a ler. Sem hidrômetro, a consistência calcula o consumo NÃO MEDIDO pela área construída e pelo
-- consumo mínimo por ÁREA (ControladorMicromedicao.obterConsumoNaoMedidoSemTarifa) — a base não tem nenhuma faixa e o
-- cálculo quebra (NPE, F2-80): área construída de 80 m² e mínimo de 12 m³ para residencial até 999 m² desde 05/2026
-- (12, e não o mínimo de 10 da tarifa, para que a fonte usada apareça no resultado).
-- Matrícula: 10037 + dígito módulo 11. Tudo SINTÉTICO.
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota)
VALUES (100374, 1, 1, 4, 7, 0, '470', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 7);
UPDATE cadastro.imovel SET imov_nnareaconstruida = 80 WHERE imov_id = 100374;
INSERT INTO micromedicao.consumo_minimo_area (cmar_id, cmar_amreferencia, catg_id, scat_id, cmar_nnareafinal, cmar_nnconsumo,
                                              cmar_icuso, cmar_tmultimaalteracao)
VALUES (1, 202605, 1, NULL, 999, 12, 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100374, 101, 1, '2026-01-01 00:00:00');

INSERT INTO micromedicao.hidrometro (hidr_id, hidr_nnhidrometro, hidr_dtaquisicao, hidr_nnanofabricacao, hidr_icmacro, hidr_nnleituraacumulada,
                                     hidr_nndigitosleitura, hicm_id, himc_id, hidm_id, hist_id, hidr_tmultimaalteracao, hicp_id, hitp_id,
                                     hidr_icoperacional)
VALUES (8, 'SINT000008', '2024-12-01', 2024, 2, 410, 5, 1, 1, 1, 3, '2026-05-15 10:00:00', 1, 1, 1);
INSERT INTO atendimentopublico.ligacao_agua (lagu_id, lagu_dtligacaoagua, lagd_id, lagm_id, lapf_id, lagu_tmultimaalteracao)
VALUES (100374, '2025-01-15', 1, 1, 1, '2026-05-15 10:00:00');
INSERT INTO micromedicao.hidrometro_inst_hist (hidi_id, hidr_id, hidi_dtinstalacaohidrometro, medt_id, hili_id, hipr_id, hidi_nnleitinstalacaohidmt,
                                               hidi_dtretiradahidrometro, hidi_nnleitretiradahidmt, hidi_dtinstalacaohidmtsistema,
                                               hidi_ictrocaprotecao, hidi_ictrocaregistro, hidi_tmultimaalteracao, lagu_id)
VALUES (8, 8, '2025-01-15', 1, 1, 1, 0, '2026-05-15', 410, '2025-01-15', 2, 2, '2026-05-15 10:00:00', 100374);

INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_nnconsumocalculomedia,
                                            cshi_icfaturamento, cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (701, 100374, 1, 202511, 20, 20, 1, 1, 4, '2025-12-01 07:00:00'),
  (702, 100374, 1, 202512, 20, 20, 1, 1, 4, '2026-01-01 07:00:00'),
  (703, 100374, 1, 202601, 20, 20, 1, 1, 4, '2026-02-01 07:00:00'),
  (704, 100374, 1, 202602, 20, 20, 1, 1, 4, '2026-03-01 07:00:00'),
  (705, 100374, 1, 202603, 20, 20, 1, 1, 4, '2026-04-01 07:00:00'),
  (706, 100374, 1, 202604, 20, 20, 1, 1, 4, '2026-05-01 07:00:00');
INSERT INTO micromedicao.medicao_historico (mdhi_id, imov_id, medt_id, mdhi_amleitura, mdhi_dtleitantfatmt, mdhi_nnleitantfatmt, mdhi_nnleitantinformada,
                                            mdhi_dtleituraatualinformada, mdhi_nnleituraatualinformada, mdhi_dtleituraatualfaturamento,
                                            mdhi_nnleituraatualfaturamento, mdhi_nnconsumomedidomes, ltst_idleiturasituacaoatual,
                                            ltst_idleiturasituacaoanterior, mdhi_tmultimaalteracao, hidi_id, lagu_id, mdhi_icanalisado)
VALUES (71, NULL, 1, 202604, '2026-03-31', 380, 380, '2026-04-30', 400, '2026-04-30', 400, 20, 1, 1, '2026-05-01 07:00:00', 8, 100374, 1);
