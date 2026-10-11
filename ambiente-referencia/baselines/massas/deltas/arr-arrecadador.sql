-- Delta — o mínimo da Arrecadação para RECEBER um movimento de arrecadador por código de barras e CLASSIFICAR os
-- pagamentos (lote 6: CEN-ARR-001 a 005). Depende de imoveis-imv-01-02-03.sql (cliente 1). NÃO se combina com
-- conta-ciclo-arrecadacao.sql (lote 5d), que cria os mesmos banco, agência, conta bancária, arrecadador, forma e tipo de
-- documento para um pagamento gravado pela massa.
--
-- EVIDÊNCIA (base reconstruída pelas migrações — exploração do lote 6):
-- · NENHUM banco, agência, conta bancária, arrecadador, contrato de arrecadador, tarifa de contrato, forma de arrecadação,
--   tipo de documento, situação de pagamento nem código de registro; sem o contrato, a tela Registrar Movimento dos
--   Arrecadadores não tem convênio a escolher (RegistrarMovimentoArrecadadoresAction:177-188).
-- · ControladorArrecadacao.registrarMovimentoArrecadadores (:1679) grava cada registro G como item do movimento com o código
--   de registro da tabela registro_codigo (inserirItemMovimentoArrecadador:4972, rgcd_id NOT NULL); o aviso bancário
--   (gerarOcorrenciaAvisoBancario:51975) pega a conta de depósito na TARIFA do contrato para a forma de arrecadação
--   (pesquisarArrecadadorContratoTarifa: .iterator().next() — sem tarifa, NoSuchElementException e o arquivo inteiro volta).
-- · O processamento lê os e-mails REGISTRAR_MOVIMENTO_ARRECADADORES_COM_ERRO (4) e _PDF (5) de cadastro.envio_email
--   (EnvioEmail, :1693 e :3827); a base só tem os ids 1, 54, 56 e 57. O e-mail só é ENVIADO em falha; os endereços são do
--   domínio reservado .invalid (nunca entregáveis).
-- · A classificação grava as situações de PagamentoSituacao (0–5, 7, 9–14) em pgst_idatual/pgst_idanterior (FK); a
--   abreviatura de VALOR NÃO CONFERE é a que Consultar Débitos procura ("NCONF", ConsultarDebitoAction).
-- Ids pelas constantes do código onde ele os fixa (DocumentoTipo.CONTA = 1, ArrecadacaoForma.GUICHE_CAIXA = 1, situações de
-- PagamentoSituacao, envios de EnvioEmail); o resto — banco, agente 901, contrato, convênio, tarifa, float, descrições — é
-- SINTÉTICO. O NSA de retorno do contrato começa em 0: o primeiro arquivo aceito é o de NSA 1
-- (validarArquivoMovimentoArrecadador:4371-4382).
INSERT INTO arrecadacao.banco (bnco_id, bnco_nmbanco, bnco_nmabreviado, bnco_icuso, bnco_tmultimaalteracao, bnco_adere_cnab150)
VALUES (901, 'BANCO SINTETICO', 'BSINT', 1, '2026-01-01 00:00:00', false);
INSERT INTO arrecadacao.agencia (agen_id, agen_cdagencia, bnco_id, agen_nmagencia, agen_nnfone, agen_tmultimaalteracao)
VALUES (901, '00001', 901, 'AGENCIA SINTETICA', '000000000', '2026-01-01 00:00:00');
INSERT INTO arrecadacao.conta_bancaria (ctbc_id, ctbc_nnconta, agen_id, ctbc_tmultimaalteracao)
VALUES (901, '00000001', 901, '2026-01-01 00:00:00');
INSERT INTO arrecadacao.arrecadador (arrc_id, clie_id, arrc_cdagente, arrc_icuso, arrc_tmultimaalteracao)
VALUES (901, 1, 901, 1, '2026-01-01 00:00:00');
INSERT INTO arrecadacao.arrecadador_contrato (arct_id, arct_nncontrato, arrc_id, arct_dtcontratoinicio, arct_cdconvenio,
                                              arct_nnnsaretornocdbarras, arct_nnnsaretornodebaut, arct_nnnsaenviodebaut,
                                              ctbc_iddepositoarrecadacao, ctbc_iddepositotarifa, clie_id,
                                              arct_tmultimaalteracao, arct_nntamidentificarimv)
VALUES (901, '901', 901, '2026-01-01', '901', 0, 0, 0, 901, 901, 1, '2026-01-01 00:00:00', 9);
INSERT INTO arrecadacao.arrecadacao_forma (arfm_id, arfm_cdarrecadacaoforma, arfm_dsarrecadacaoforma, arfm_tmultimaalteracao)
VALUES (1, '1', 'GUICHE DE CAIXA (SINTETICO)', '2026-01-01 00:00:00');
INSERT INTO arrecadacao.arrecadador_contrato_tar (arct_id, arfm_id, actf_vltarifa, actf_nndiafloat, actf_tmultimaalteracao,
                                                  ctbc_iddepositoarrecadacao)
VALUES (901, 1, 0.00, 1, '2026-01-01 00:00:00', 901);
INSERT INTO cobranca.documento_tipo (dotp_id, dotp_dsdocumentotipo, dotp_dsabreviado, dotp_icpagavel, dotp_icuso, dotp_tmultimaalteracao)
VALUES (1, 'CONTA', 'CONTA', 1, 1, '2026-01-01 00:00:00');
INSERT INTO arrecadacao.registro_codigo (rgcd_id, rgcd_dsregistrocodigo, rgcd_cdregistrocodigo, rgcd_tmultimaalteracao)
VALUES (907, 'PAGAMENTO POR CODIGO DE BARRAS (SINTETICO)', 'G', '2026-01-01 00:00:00');
INSERT INTO arrecadacao.pagamento_situacao (pgst_id, pgst_dspagamentosituacao, pgst_dsabreviado, pgst_icuso, pgst_tmultimaalteracao) VALUES
  (0, 'CLASSIFICADO', 'CLASS', 1, '2026-01-01 00:00:00'),
  (1, 'EM DUPLICIDADE', 'DUPLIC', 1, '2026-01-01 00:00:00'),
  (2, 'DOC INEXISTENTE', 'DOCINEX', 1, '2026-01-01 00:00:00'),
  (3, 'VALOR EM EXCESSO', 'EXCESSO', 1, '2026-01-01 00:00:00'),
  (4, 'VALOR A BAIXAR', 'ABAIXAR', 1, '2026-01-01 00:00:00'),
  (5, 'VALOR NAO CONFERE', 'NCONF', 1, '2026-01-01 00:00:00'),
  (7, 'MOVIMENTO ABERTO', 'MOVABER', 1, '2026-01-01 00:00:00'),
  (9, 'DUPLIC EXC DEVOLVIDO', 'DEVOLV', 1, '2026-01-01 00:00:00'),
  (10, 'DOC A CONTABILIZAR', 'ACONTAB', 1, '2026-01-01 00:00:00'),
  (11, 'INEX DEB PRESCRITO', 'INEXPRE', 1, '2026-01-01 00:00:00'),
  (12, 'INEX CONTA PARCELADA', 'INEXPAR', 1, '2026-01-01 00:00:00'),
  (13, 'INEX CONTA CANCELADA', 'INEXCAN', 1, '2026-01-01 00:00:00'),
  (14, 'INEX ERRO PROCESSAM', 'INEXERR', 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.envio_email (enem_id, enem_dsemailremetente, enem_dsemailreceptor, enem_dstitulomensagem,
                                  enem_dscorpomensagem, fncd_id, enem_tmultimaalteracao) VALUES
  (4, 'gsan@exemplo.invalid', 'arrecadacao@exemplo.invalid', 'MOVIMENTO DE ARRECADADOR COM ERRO (SINTETICO)',
   'MOVIMENTO DE ARRECADADOR COM ERRO (SINTETICO)', 398, '2026-01-01 00:00:00'),
  (5, 'gsan@exemplo.invalid', 'arrecadacao@exemplo.invalid', 'MOVIMENTO DE ARRECADADOR (SINTETICO)',
   'MOVIMENTO DE ARRECADADOR (SINTETICO)', 398, '2026-01-01 00:00:00');

-- Concessões do operador: Registrar Movimento dos Arrecadadores (funcionalidade 398, operação 505 — a URL do envio) e
-- Consultar Débitos (346, operação 443 — consultarDebitoAction.do), a posição de dívida que a Cobrança calcula.
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (1001, 505, 398, '2026-01-01 00:00:00'),
  (1001, 443, 346, '2026-01-01 00:00:00');
