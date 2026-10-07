-- Delta — catálogos para débitos a cobrar e créditos a realizar entrarem na conta do faturamento em grupo (lote 5b:
-- CEN-FAT-004). Depende de batch-catalogos.sql (situação de débito NORMAL = 0).
--
-- EVIDÊNCIA (base reconstruída): há tipos de débito e de crédito, mas todos de usos especiais (cancelamento de
-- parcelamento, faturamento inferior ao mínimo, descontos, Bolsa Água); não há financiamento de PARCELAMENTO, nem
-- situação ou tipo de parcelamento (cobranca.parcelamento_situacao e parcelamento_tipo VAZIAS), nem forma de cobrança
-- (cobranca.cobranca_forma VAZIA — no lote 4 ela veio de atendimento-catalogos.sql, com o mesmo id e texto).
-- Ids das constantes: FinanciamentoTipo.PARCELAMENTO_SERVICO = 4; CreditoOrigem.VALORES_COBRADOS_INDEVIDAMENTE = 7;
-- ParcelamentoSituacao.NORMAL = 1; ParcelamentoTipo.POR_IMOVEL = 1; CobrancaForma.COBRANCA_EM_CONTA = 1. Tipos de débito
-- e de crédito SINTÉTICOS (ids 31xx, 32xx), com o item contábil 6 (OUTROS SERVICOS AGUA) da base. Descrições SINTÉTICAS.
INSERT INTO cobranca.cobranca_forma (cbfm_id, cbfm_dscobrancaforma, cbfm_dsabreviado, cbfm_icuso, cbfm_tmultimaalteracao)
VALUES (1, 'COBRANCA EM CONTA', 'CONTA', 1, '2026-01-01 00:00:00');
INSERT INTO financeiro.financiamento_tipo (fntp_id, fntp_dsfinanciamentotipo, fntp_dsabreviado, fntp_icuso, fntp_tmultimaalteracao,
                                           fntp_icinclusao)
VALUES (4, 'PARCELAMENTO SERVICO', 'PSV', 1, '2026-01-01 00:00:00', 2);

INSERT INTO faturamento.debito_tipo (dbtp_id, lict_id, dbtp_dsdebitotipo, dbtp_dsabreviado, dbtp_icuso, dbtp_tmultimaalteracao, fntp_id,
                                     dbtp_icgeracaoautomatica, dbtp_icgeracaoconta, dbtp_iccartaocredito, dbtp_icguiajurosctrparcel) VALUES
  (3101, 6, 'SERVICO SINTETICO', 'SVS', 1, '2026-01-01 00:00:00', 1, 2, 1, 2, 2),
  (3102, 6, 'PARCELAMENTO SINTETICO', 'PCS', 1, '2026-01-01 00:00:00', 4, 2, 1, 2, 2);
INSERT INTO faturamento.credito_tipo (crti_id, lict_id, crti_dscreditotipo, crti_dsabreviado, crti_icuso, crti_tmultimaalteracao,
                                      crti_icgeracaoautomatica)
VALUES (3201, 6, 'CREDITO SINTETICO', 'CRS', 1, '2026-01-01 00:00:00', 2);
INSERT INTO faturamento.credito_origem (crog_id, crog_dscreditoorigem, crog_dsabreviado, crog_icuso, crog_tmultimaalteracao)
VALUES (7, 'VALORES COBRADOS INDEVIDAMENTE', 'VCI', 1, '2026-01-01 00:00:00');

INSERT INTO cobranca.parcelamento_situacao (pcst_id, pcst_dsparcelamentosituacao, pcst_dsabreviado, pcst_tmultimaalteracao)
VALUES (1, 'NORMAL', 'NOR', '2026-01-01 00:00:00');
INSERT INTO cobranca.parcelamento_tipo (pctp_id, pctp_dsparcelamentotipo, pctp_icuso, pctp_tmultimaalteracao)
VALUES (1, 'POR IMOVEL', 1, '2026-01-01 00:00:00');
