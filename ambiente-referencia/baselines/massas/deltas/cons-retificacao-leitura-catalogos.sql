-- Delta — o que a retificação por ALTERAÇÃO DA LEITURA FATURADA exige sobre a conta que a consistência e o faturamento em
-- sequência geram (lote 5e: CEN-FAT-007 V2c). Depende de batch-catalogos.sql (situação NORMAL), de mic-imv-medido-real.sql
-- (IMV-M01 100315, hidrometrado) e de seguranca-auditoria.sql.
--
-- Mesma evidência de conta-ciclo-catalogos.sql (lote 5d, F2-87) — situações de conta RETIFICADA e CANCELADA POR
-- RETIFICAÇÃO, motivo de retificação, permissão RETIFICAR CONTA SEM RA, concessões de Manter e Retificar Conta, cliente
-- USUÁRIO do imóvel —, num delta próprio porque aquele também grava o parâmetro CONSUMO_MINIMO_BOLSA_AGUA, que aqui vem de
-- mic-catalogos.sql. O motivo é o do código: ContaMotivoRetificacao.ALTERACAO_DE_LEITURA_FATURADA = 104 — só ele leva a
-- retificação a corrigir a leitura e o consumo FATURADO da Micromedição (ControladorRetificarConta:148-170, :262-273).
-- Descrições SINTÉTICAS.
INSERT INTO faturamento.debito_credito_situacao (dcst_id, dcst_dsdebitocreditosituacao, dcst_dsabreviado, dcst_tmultimaalteracao) VALUES
  (1, 'RETIFICADA', 'RET', '2026-01-01 00:00:00'),
  (4, 'CANCELADA POR RETIFICACAO', 'CRE', '2026-01-01 00:00:00');
INSERT INTO faturamento.conta_motivo_retificacao (cmrt_id, cmrt_dsmotivoretificacaoconta, cmrt_icuso, cmrt_tmultimaalteracao,
                                                  cmrt_nnocorrmesmomotivonoano, cmrt_iccompetenciaconsumo)
VALUES (104, 'ALTERACAO DE LEITURA FATURADA', 1, '2026-01-01 00:00:00', NULL, 2);
INSERT INTO seguranca.permissao_especial (pmep_id, pmep_dspermissaoespecial, pmep_icuso, pmep_tmultimaalteracao, oper_id)
VALUES (48, 'RETIFICAR CONTA SEM RA', 1, '2026-01-01 00:00:00', 261);
INSERT INTO seguranca.usuario_permissao_espec (usur_id, pmep_id, upes_tmultimaalteracao) VALUES (1001, 48, '2026-01-01 00:00:00');
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (1001, 57, 44, '2026-01-01 00:00:00'),
  (1001, 261, 200, '2026-01-01 00:00:00'),
  (1001, 256, 200, '2026-01-01 00:00:00');
INSERT INTO cadastro.cliente_relacao_tipo (crtp_id, crtp_dsclienterelacaotipo, crtp_icuso, crtp_tmultimaalteracao) VALUES
  (1, 'PROPRIETARIO', 1, '2026-01-01 00:00:00'),
  (2, 'USUARIO', 1, '2026-01-01 00:00:00'),
  (3, 'RESPONSAVEL', 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.cliente_imovel (clim_id, clie_id, imov_id, clim_dtrelacaoinicio, clim_dtrelacaofim, clim_tmultimaalteracao,
                                     crtp_id, clim_icnomeconta)
VALUES (5101, 1, 100315, '2026-01-01', NULL, '2026-01-01 00:00:00', 2, 1);
