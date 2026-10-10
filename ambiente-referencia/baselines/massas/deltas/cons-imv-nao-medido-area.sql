-- Delta — imóvel 100447 NÃO MEDIDO (ligação de água sem hidrômetro), com área construída de 80 m² e o consumo mínimo por
-- ÁREA da instalação (residencial até 999 m², 25 m³ desde 05/2026) (lote 5e: CEN-MIC-002 ao faturar). Depende de mic-catalogos.sql, mic-rota-r4-consistir-202605.sql, cons-comando-faturar-r4-202605.sql e cons-catalogos.sql.
--
-- Na base, parm_icnaomedidotarifa = 2 e parm_cdtipocalcnaomedido = 1: o não medido é calculado pela ÁREA
-- (ControladorMicromedicao.obterConsumoNaoMedido), não pelo mínimo da tarifa — o mesmo valor 25 de CEN-MIC-002 V5
-- (mic-override-area-25.sql), num imóvel próprio da R4. Residencial, 1 economia, água LIGADO, esgoto POTENCIAL; consumos
-- NÃO MEDIDOS de 25 m³ de 11/2025 a 04/2026. Matrícula: 10044 + dígito módulo 11.
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota, ftst_id)
VALUES (100447, 1, 1, 4, 44, 0, '44', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 44, NULL);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100447, 101, 1, '2026-01-01 00:00:00');
UPDATE cadastro.imovel SET imov_nnareaconstruida = 80 WHERE imov_id = 100447;
INSERT INTO atendimentopublico.ligacao_agua (lagu_id, lagu_dtligacaoagua, lagd_id, lagm_id, lapf_id, lagu_tmultimaalteracao)
VALUES (100447, '2025-01-15', 1, 1, 1, '2025-01-15 10:00:00');
INSERT INTO micromedicao.consumo_minimo_area (cmar_id, cmar_amreferencia, catg_id, scat_id, cmar_nnareafinal, cmar_nnconsumo,
                                              cmar_icuso, cmar_tmultimaalteracao)
VALUES (44, 202605, 1, NULL, 999, 25, 1, '2026-01-01 00:00:00');
INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_nnconsumocalculomedia,
                                            cshi_icfaturamento, cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (440, 100447, 1, 202511, 25, 25, 1, 5, 4, '2025-11-01 07:00:00'),
  (441, 100447, 1, 202512, 25, 25, 1, 5, 4, '2025-12-01 07:00:00'),
  (442, 100447, 1, 202601, 25, 25, 1, 5, 4, '2026-01-01 07:00:00'),
  (443, 100447, 1, 202602, 25, 25, 1, 5, 4, '2026-02-01 07:00:00'),
  (444, 100447, 1, 202603, 25, 25, 1, 5, 4, '2026-03-01 07:00:00'),
  (445, 100447, 1, 202604, 25, 25, 1, 5, 4, '2026-04-01 07:00:00');
