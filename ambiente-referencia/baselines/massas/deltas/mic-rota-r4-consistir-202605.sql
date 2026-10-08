-- Delta — rota R4 do grupo G1 só para a consistência de leituras de 05/2026 (lote 5c). Depende de territorio-l1.sql e
-- de mic-catalogos.sql.
--
-- R4 (quadra 4, setor 1) recebe um imóvel por perfil de leitura, conforme a variação; o comando de CONSISTIR LEITURAS
-- (atividade 9) de 05/2026 cobre só a R4 — os imóveis IMV-01…03 da R1 não são consistidos. O cronograma traz também a
-- atividade EFETUAR LEITURA (2) de 04/2026 e de 05/2026, de onde a consistência tira as datas previstas de leitura
-- (ControladorMicromedicao.obterDataPrevistaRealizadaFaturamentoAtividadeCronograma): sem elas, usaria a data do dia.
-- Datas e ids SINTÉTICOS.
INSERT INTO micromedicao.rota (rota_id, lttp_id, empr_id, rota_icuso, rota_tmultimaalteracao, ftgr_id, stcm_id, cbgr_id, rota_cdrota,
                               empr_idcobranca, rota_icalternativa, rota_ictransmissaooffline, rota_icdividerota,
                               rota_icimpressaotermicafinalgrupo)
VALUES (4, 1, 1, 1, '2026-01-01 00:00:00', 1, 1, 1, 4, 1, 2, 2, 2, 2);
INSERT INTO cadastro.quadra (qdra_id, stcm_id, qdra_nnquadra, rota_id, qdra_icuso, qdra_tmultimaalteracao, qdra_icautoincrementolote,
                             bair_id, qdra_icredeagua, qdra_icredeesgoto)
VALUES (4, 1, 4, 4, 1, '2026-01-01 00:00:00', 2, 1, 2, 2);

INSERT INTO faturamento.fatur_grupo_crg_mensal (ftcm_id, ftgr_id, ftcm_amreferencia, ftcm_tmultimaalteracao) VALUES
  (2, 1, 202604, '2026-01-01 00:00:00'),
  (1, 1, 202605, '2026-01-01 00:00:00');
INSERT INTO faturamento.fatur_ativ_cronograma (ftac_id, ftat_id, ftcm_id, ftac_dtprevista, ftac_tmrealizacao, ftac_tmcomando, ftac_tmultimaalteracao) VALUES
  (4, 2, 2, '2026-04-30', '2026-04-30 18:00:00', NULL, '2026-04-30 18:00:00'),
  (3, 2, 1, '2026-05-31', '2026-05-31 18:00:00', NULL, '2026-05-31 18:00:00'),
  (2, 9, 1, '2026-06-01', NULL, '2026-06-01 07:00:00', '2026-06-01 07:00:00');
INSERT INTO faturamento.fatur_ativ_cron_rota (ftac_id, rota_id, facr_dtcontavencimento, facr_tmultimaalteracao)
VALUES (2, 4, '2026-06-10', '2026-06-01 07:00:00');

-- Referência de faturamento do SISTEMA alinhada ao mês do comando, como numa instalação em operação (o encerramento mensal
-- a avança): a base parou em 201410. Parte da consistência relê o parâmetro do banco em vez de usar a referência do
-- cronograma — o consumo NÃO MEDIDO por área, por exemplo (ControladorMicromedicao.obterConsumoNaoMedido:37743-37747) —,
-- e com 201410 procuraria faixas de 2014 (F2-80).
UPDATE cadastro.sistema_parametros SET parm_amreferenciafaturamento = 202605;
