-- Delta — IMV-M09 100366: hidrômetro INSTALADO no meio do período de leitura de 05/2026 numa ligação que não tinha
-- (lote 5c: CEN-MIC-003 V2). Depende de mic-catalogos.sql e mic-rota-r4-consistir-202605.sql.
--
-- Residencial, 1 economia, água LIGADO, na R4. Até 04/2026 sem hidrômetro: consumos NÃO MEDIDOS de 10 m³ (não entram na
-- média). H7 instalado em 15/05/2026 com leitura 0 (o que "Efetuar Instalação de Hidrômetro" gravaria). Medição de
-- 05/2026 registrada no H7: anterior de faturamento 0 (a de instalação, 15/05/2026), atual informada 9 em 31/05/2026,
-- REALIZADA; não há medição de 04/2026. Matrícula: 10036 + dígito módulo 11. Tudo SINTÉTICO.
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota)
VALUES (100366, 1, 1, 4, 6, 0, '460', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 6);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100366, 101, 1, '2026-01-01 00:00:00');

INSERT INTO micromedicao.hidrometro (hidr_id, hidr_nnhidrometro, hidr_dtaquisicao, hidr_nnanofabricacao, hidr_icmacro, hidr_nnleituraacumulada,
                                     hidr_nndigitosleitura, hicm_id, himc_id, hidm_id, hist_id, hidr_tmultimaalteracao, hicp_id, hitp_id,
                                     hidr_icoperacional)
VALUES (7, 'SINT000007', '2026-04-01', 2026, 2, 0, 5, 1, 1, 1, 1, '2026-05-15 10:00:00', 1, 1, 1);
INSERT INTO atendimentopublico.ligacao_agua (lagu_id, lagu_dtligacaoagua, lagd_id, lagm_id, lapf_id, lagu_tmultimaalteracao)
VALUES (100366, '2025-01-15', 1, 1, 1, '2026-05-15 10:00:00');
INSERT INTO micromedicao.hidrometro_inst_hist (hidi_id, hidr_id, hidi_dtinstalacaohidrometro, medt_id, hili_id, hipr_id, hidi_nnleitinstalacaohidmt,
                                               hidi_dtinstalacaohidmtsistema, hidi_icinstalacaosubstituicao, hidi_ictrocaprotecao,
                                               hidi_ictrocaregistro, hidi_tmultimaalteracao, lagu_id)
VALUES (7, 7, '2026-05-15', 1, 1, 1, 0, '2026-05-15', 1, 2, 2, '2026-05-15 10:00:00', 100366);
UPDATE atendimentopublico.ligacao_agua SET hidi_id = 7 WHERE lagu_id = 100366;

INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_nnconsumocalculomedia,
                                            cshi_icfaturamento, cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (601, 100366, 1, 202511, 10, 10, 1, 5, 4, '2025-12-01 07:00:00'),
  (602, 100366, 1, 202512, 10, 10, 1, 5, 4, '2026-01-01 07:00:00'),
  (603, 100366, 1, 202601, 10, 10, 1, 5, 4, '2026-02-01 07:00:00'),
  (604, 100366, 1, 202602, 10, 10, 1, 5, 4, '2026-03-01 07:00:00'),
  (605, 100366, 1, 202603, 10, 10, 1, 5, 4, '2026-04-01 07:00:00'),
  (606, 100366, 1, 202604, 10, 10, 1, 5, 4, '2026-05-01 07:00:00');
-- Sem medição do mês anterior, a situação ANTERIOR da medição é NÃO REALIZADA e a leitura anterior é a de instalação —
-- como o próprio legado gera a medição nesse caso (ControladorMicromedicao.gerarHistoricoMedicao:19533, :19620-19632).
INSERT INTO micromedicao.medicao_historico (mdhi_id, imov_id, medt_id, mdhi_amleitura, mdhi_dtleitantfatmt, mdhi_nnleitantfatmt, mdhi_nnleitantinformada,
                                            mdhi_dtleituraatualinformada, mdhi_nnleituraatualinformada, mdhi_dtleituraatualfaturamento,
                                            mdhi_nnleituraatualfaturamento, mdhi_nnconsumomedidomes, ltst_idleiturasituacaoatual,
                                            ltst_idleiturasituacaoanterior, mdhi_tmultimaalteracao, hidi_id, lagu_id, mdhi_icanalisado)
VALUES (61, NULL, 1, 202605, '2026-05-15', 0, 0, '2026-05-31', 9, '2026-05-31', 9, NULL, 1, 2, '2026-05-31 18:00:00', 7, 100366, 2);
