-- Delta — IMV-M06 100331, perfil IMV-06 (cenarios-criticos.md §13.1): leitura NÃO REALIZADA em 05/2026, com a anormalidade
-- de leitura SINTÉTICA 101 "imóvel fechado" (sem leitura: cobra a MÉDIA, fatura a leitura ANTERIOR + MÉDIA) — 1º mês
-- (lote 5c: CEN-MIC-001 V3). Depende de mic-catalogos.sql e mic-rota-r4-consistir-202605.sql.
--
-- Residencial, 1 economia, água LIGADO, na R4. Hidrômetro H3 instalado em 15/01/2025. Consumos REAIS de 11/2025 a 04/2026:
-- 18, 22, 20, 24, 16, 30 — média 130 / 6 = 21 (divisão inteira). Medição de 04/2026: 470 → 500 (REALIZADA). Medição de
-- 05/2026 registrada SEM leitura: anterior de faturamento 500, atual informada nula, anormalidade informada 101, situação
-- NÃO REALIZADA; os campos obrigatórios de faturamento da atual chegam com a anterior (500, 31/05/2026).
-- Matrícula: 10033 + dígito módulo 11. Tudo SINTÉTICO.
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota)
VALUES (100331, 1, 1, 4, 3, 0, '430', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 3);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100331, 101, 1, '2026-01-01 00:00:00');

INSERT INTO micromedicao.hidrometro (hidr_id, hidr_nnhidrometro, hidr_dtaquisicao, hidr_nnanofabricacao, hidr_icmacro, hidr_nnleituraacumulada,
                                     hidr_nndigitosleitura, hicm_id, himc_id, hidm_id, hist_id, hidr_tmultimaalteracao, hicp_id, hitp_id,
                                     hidr_icoperacional)
VALUES (3, 'SINT000003', '2024-12-01', 2024, 2, 0, 5, 1, 1, 1, 1, '2025-01-15 10:00:00', 1, 1, 1);
INSERT INTO atendimentopublico.ligacao_agua (lagu_id, lagu_dtligacaoagua, lagd_id, lagm_id, lapf_id, lagu_tmultimaalteracao)
VALUES (100331, '2025-01-15', 1, 1, 1, '2025-01-15 10:00:00');
INSERT INTO micromedicao.hidrometro_inst_hist (hidi_id, hidr_id, hidi_dtinstalacaohidrometro, medt_id, hili_id, hipr_id, hidi_nnleitinstalacaohidmt,
                                               hidi_dtinstalacaohidmtsistema, hidi_ictrocaprotecao, hidi_ictrocaregistro, hidi_tmultimaalteracao, lagu_id)
VALUES (3, 3, '2025-01-15', 1, 1, 1, 0, '2025-01-15', 2, 2, '2025-01-15 10:00:00', 100331);
UPDATE atendimentopublico.ligacao_agua SET hidi_id = 3 WHERE lagu_id = 100331;

INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_nnconsumocalculomedia,
                                            cshi_icfaturamento, cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (301, 100331, 1, 202511, 18, 18, 1, 1, 4, '2025-12-01 07:00:00'),
  (302, 100331, 1, 202512, 22, 22, 1, 1, 4, '2026-01-01 07:00:00'),
  (303, 100331, 1, 202601, 20, 20, 1, 1, 4, '2026-02-01 07:00:00'),
  (304, 100331, 1, 202602, 24, 24, 1, 1, 4, '2026-03-01 07:00:00'),
  (305, 100331, 1, 202603, 16, 16, 1, 1, 4, '2026-04-01 07:00:00'),
  (306, 100331, 1, 202604, 30, 30, 1, 1, 4, '2026-05-01 07:00:00');
INSERT INTO micromedicao.medicao_historico (mdhi_id, imov_id, medt_id, mdhi_amleitura, mdhi_dtleitantfatmt, mdhi_nnleitantfatmt, mdhi_nnleitantinformada,
                                            mdhi_dtleituraatualinformada, mdhi_nnleituraatualinformada, mdhi_dtleituraatualfaturamento,
                                            mdhi_nnleituraatualfaturamento, mdhi_nnconsumomedidomes, ltan_idleitanorminformada, ltan_idleitanormfatmt,
                                            ltst_idleiturasituacaoatual, ltst_idleiturasituacaoanterior, mdhi_tmultimaalteracao, hidi_id, lagu_id,
                                            mdhi_icanalisado) VALUES
  (31, NULL, 1, 202604, '2026-03-31', 470, 470, '2026-04-30', 500, '2026-04-30', 500, 30, NULL, NULL, 1, 1, '2026-05-01 07:00:00', 3, 100331, 1),
  (32, NULL, 1, 202605, '2026-04-30', 500, 500, NULL, NULL, '2026-05-31', 500, NULL, 101, 101, 2, 1, '2026-05-31 18:00:00', 3, 100331, 2);
