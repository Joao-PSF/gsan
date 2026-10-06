-- Delta — clientes do IMV-01 (100013) em papéis distintos, com uma troca de cliente-usuário no meio de uma
-- referência (CEN-CAD-002). Depende de clientes-imovel-imv03.sql (tipos de relação PROPRIETARIO = 1, USUARIO = 2,
-- RESPONSAVEL = 3, gcom.cadastro.cliente.ClienteRelacaoTipo) e de imoveis-imv-01-02-03.sql.
--
-- EVIDÊNCIA: cadastro.clim_fim_relacao_motivo está VAZIA na base reconstruída; um vínculo encerrado precisa de
-- motivo (ClienteImovel.clienteImovelFimRelacaoMotivo). Motivo 1 SINTÉTICO — as constantes do código
-- (ClienteImovelFimRelacaoMotivo: EXCLUSAO_IMOVEL = 6, EXCLUSAO_PROGRAMA_ESPECIAL = 8, POR_ATU_CADASTRAL = 10) são de
-- encerramentos automáticos, não de troca de usuário.
-- Clientes como o de verificação da Fase 1 (tipo 1, pessoa física SINTÉTICA). Nomes, datas e ids SINTÉTICOS.
--
--   usuário anterior  2025-01-01 → 2026-05-15 (encerrado, motivo 1)
--   usuário atual     2026-05-16 → (ativo)        — a troca cai no meio da referência 05/2026
--   proprietário      2024-03-01 → (ativo)
--   responsável       2026-01-01 → (ativo)
INSERT INTO cadastro.clim_fim_relacao_motivo (cifr_id, cifr_dsfimrelacaomotivo, cifr_icuso, cifr_tmultimaalteracao)
VALUES (1, 'MUDANCA DE USUARIO', 1, '2026-01-01 00:00:00');

INSERT INTO cadastro.cliente (clie_id, clie_nmcliente, cltp_id, clie_icuso, clie_tmultimaalteracao) VALUES
  (2, 'CLIENTE USUARIO ANTERIOR (SINTETICO)', 1, 1, '2026-01-01 00:00:00'),
  (3, 'CLIENTE USUARIO ATUAL (SINTETICO)', 1, 1, '2026-01-01 00:00:00'),
  (4, 'CLIENTE PROPRIETARIO (SINTETICO)', 1, 1, '2026-01-01 00:00:00'),
  (5, 'CLIENTE RESPONSAVEL (SINTETICO)', 1, 1, '2026-01-01 00:00:00');

INSERT INTO cadastro.cliente_imovel (clim_id, clie_id, imov_id, clim_dtrelacaoinicio, clim_dtrelacaofim, clim_tmultimaalteracao,
                                     crtp_id, clim_icnomeconta, cifr_id) VALUES
  (11, 2, 100013, '2025-01-01', '2026-05-15', '2026-05-15 00:00:00', 2, 1, 1),
  (12, 3, 100013, '2026-05-16', NULL, '2026-05-16 00:00:00', 2, 1, NULL),
  (13, 4, 100013, '2024-03-01', NULL, '2026-01-01 00:00:00', 1, 2, NULL),
  (14, 5, 100013, '2026-01-01', NULL, '2026-01-01 00:00:00', 3, 2, NULL);
