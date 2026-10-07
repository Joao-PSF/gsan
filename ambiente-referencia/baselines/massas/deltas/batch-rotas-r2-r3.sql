-- Delta — o grupo G1 com TRÊS rotas no comando de FATURAR GRUPO de 05/2026 (lote 5: CEN-BAT-002 e CEN-BAT-003).
-- Depende de batch-faturamento-g1-202605.sql (cronograma, comando e R1 com IMV-01, IMV-02 e IMV-03) e de
-- imoveis-imv-01-02-03.sql (perfil, envio de conta e subcategoria 101).
--
-- R2 e R3 no mesmo setor e grupo de R1, cada uma com a sua quadra. Imóveis como o IMV-01 (residencial, 1 economia,
-- água LIGADO, esgoto POTENCIAL, tarifa TAR-01), com o consumo REAL de 05/2026:
--   R2  IMV-R2a 100218 (15 m³) · IMV-R2x 100226 (18 m³) · IMV-R2b 100234 (22 m³) — inseridos nesta ordem
--   R3  IMV-R3a 100242 (33 m³)
-- FALHA CONTROLADA: o IMV-R2x não tem nenhuma linha em cadastro.imovel_subcategoria — inconsistência de cadastro que
-- o legado recusa ao obter as economias do imóvel (ControladorImovelSEJB:1466, "atencao.nao_cadastrado.
-- imovel_subcategoria", com setRollbackOnly), a primeira coisa que o faturamento de cada imóvel faz
-- (ControladorFaturamentoFINAL.determinarFaturamentoImovel:1432). Total, categoria e subcategoria principais
-- gravados como nos demais: o único defeito é a composição ausente.
-- Matrículas: número-base 10021..10024 seguido do dígito módulo 11 (gcom.util.Util.obterDigitoVerificadorModulo11).
-- Tudo SINTÉTICO.
INSERT INTO micromedicao.rota (rota_id, lttp_id, empr_id, rota_icuso, rota_tmultimaalteracao, ftgr_id, stcm_id, cbgr_id, rota_cdrota,
                               empr_idcobranca, rota_icalternativa, rota_ictransmissaooffline, rota_icdividerota,
                               rota_icimpressaotermicafinalgrupo) VALUES
  (2, 1, 1, 1, '2026-01-01 00:00:00', 1, 1, 1, 2, 1, 2, 2, 2, 2),
  (3, 1, 1, 1, '2026-01-01 00:00:00', 1, 1, 1, 3, 1, 2, 2, 2, 2);
INSERT INTO cadastro.quadra (qdra_id, stcm_id, qdra_nnquadra, rota_id, qdra_icuso, qdra_tmultimaalteracao, qdra_icautoincrementolote,
                             bair_id, qdra_icredeagua, qdra_icredeesgoto) VALUES
  (2, 1, 2, 2, 1, '2026-01-01 00:00:00', 2, 1, 1, 1),
  (3, 1, 3, 3, 1, '2026-01-01 00:00:00', 2, 1, 1, 1);

INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota) VALUES
  (100218, 1, 1, 2, 1, 0, '210', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 1),
  (100226, 1, 1, 2, 2, 0, '220', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 2),
  (100234, 1, 1, 2, 3, 0, '230', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 3),
  (100242, 1, 1, 3, 1, 0, '240', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 1);

-- Sem a linha do IMV-R2x (100226): a falha controlada.
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao) VALUES
  (100218, 101, 1, '2026-01-01 00:00:00'),
  (100234, 101, 1, '2026-01-01 00:00:00'),
  (100242, 101, 1, '2026-01-01 00:00:00');

INSERT INTO faturamento.fatur_ativ_cron_rota (ftac_id, rota_id, facr_dtcontavencimento, facr_tmultimaalteracao) VALUES
  (1, 2, '2026-06-10', '2026-06-01 08:00:00'),
  (1, 3, '2026-06-10', '2026-06-01 08:00:00');

INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_icfaturamento,
                                            cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (4, 100218, 1, 202605, 15, 1, 1, 2, '2026-06-01 07:00:00'),
  (5, 100226, 1, 202605, 18, 1, 1, 2, '2026-06-01 07:00:00'),
  (6, 100234, 1, 202605, 22, 1, 1, 2, '2026-06-01 07:00:00'),
  (7, 100242, 1, 202605, 33, 1, 1, 3, '2026-06-01 07:00:00');
