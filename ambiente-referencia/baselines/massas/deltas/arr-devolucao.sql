-- Delta — o que o tratamento do pagamento não classificado exige (lote 6b: CEN-ARR-003, CEN-ARR-004): a recuperação de
-- crédito (Pagamentos a Classificar), a manutenção do pagamento, a guia de devolução e a devolução. Depende de
-- arr-arrecadador.sql; os ids não colidem com os de fat-lancamentos-catalogos.sql (lote 5b).
--
-- EVIDÊNCIA (base reconstruída — exploração do lote 6b):
-- · faturamento.credito_tipo não tem DEVOLUÇÃO DE PAGAMENTOS EM DUPLICIDADE (CreditoTipo.DEVOLUCAO_PAGAMENTOS_DUPLICIDADE =
--   5) nem DEVOLUÇÃO DE OUTROS VALORES (7), que a recuperação de crédito grava (ClassificarPagamentosAction.setParametros,
--   ControladorArrecadacao.incluirCreditoPagamentosResolvidos) e a guia de devolução de conta exige — com o item contábil e
--   o valor limite (ControladorArrecadacao.inserirGuiaDevolucao:17503-17518: sem o tipo, NoSuchElementException);
-- · faturamento.credito_origem não tem CONTAS PAGAS EM DUPLICIDADE/EXCESSO (1), RECUPERAÇÃO DE CRÉDITO DE CONTA CANCELADA (12)
--   nem DE CONTA PARCELADA (13) (CreditoOrigem);
-- · arrecadacao.devolucao_situacao está vazia: a classificação grava DevolucaoSituacao 1–5.
-- · a recuperação de crédito grava PAGAMENTO CLASSIFICADO RECUPERAÇÃO DE CRÉDITO CANCELADO (15) e DUPLICIDADE (16)
--   (ControladorArrecadacao.recuperarCredito:51829-51834) — sem elas, violação de chave estrangeira e "Erro ao recuperar
--   credito" (HTTP 500); arr-arrecadador.sql (lote 6) só tem as situações que a classificação atribui.
-- Ids pelas constantes do código; o item contábil é OUTROS SERVIÇOS ÁGUA (6, da base), o que a recuperação de crédito
-- grava (LancamentoItemContabil.OUTROS_SERVICOS_AGUA); descrições e o valor limite (R$ 1.000,00) são SINTÉTICOS.
INSERT INTO faturamento.credito_tipo (crti_id, lict_id, crti_dscreditotipo, crti_dsabreviado, crti_icuso, crti_tmultimaalteracao,
                                      crti_vllimite, crti_icgeracaoautomatica) VALUES
  (5, 6, 'DEVOLUCAO PAGTOS DUPLICIDADE', 'DEVDUP', 1, '2026-01-01 00:00:00', 1000.00, 2),
  (7, 6, 'DEVOLUCAO OUTROS VALORES', 'DEVOUT', 1, '2026-01-01 00:00:00', 1000.00, 2);
INSERT INTO faturamento.credito_origem (crog_id, crog_dscreditoorigem, crog_dsabreviado, crog_icuso, crog_tmultimaalteracao) VALUES
  (1, 'CONTAS PAGAS EM DUPLICIDADE/EXCESSO', 'DUPEXC', 1, '2026-01-01 00:00:00'),
  (12, 'RECUPERACAO CREDITO CONTA CANCELADA', 'RECCAN', 1, '2026-01-01 00:00:00'),
  (13, 'RECUPERACAO CREDITO CONTA PARCELADA', 'RECPAR', 1, '2026-01-01 00:00:00');
INSERT INTO arrecadacao.pagamento_situacao (pgst_id, pgst_dspagamentosituacao, pgst_dsabreviado, pgst_icuso, pgst_tmultimaalteracao) VALUES
  (15, 'CLASS RECUP CANCEL', 'RECCANC', 1, '2026-01-01 00:00:00'),
  (16, 'CLASS RECUP DUPLIC', 'RECDUPL', 1, '2026-01-01 00:00:00');
INSERT INTO arrecadacao.devolucao_situacao (dvst_id, dvst_dsdevolucaosituacao, dvst_dsabreviado, dvst_icuso, dvst_tmultimaalteracao) VALUES
  (1, 'CLASSIFICADA', 'CLASS', 1, '2026-01-01 00:00:00'),
  (2, 'OUTROS VALORES', 'OUTROS', 1, '2026-01-01 00:00:00'),
  (3, 'PAGTO DUP NAO ENCONT', 'DUPNENC', 1, '2026-01-01 00:00:00'),
  (4, 'GUIA NAO INFORMADA', 'GUIANINF', 1, '2026-01-01 00:00:00'),
  (5, 'VALOR NAO CONFERE', 'NCONF', 1, '2026-01-01 00:00:00');

-- Concessões do operador: Recuperar Crédito (16021/15042) com filtrar (16022/15043), devolver (16022/15045) e refaturar
-- (16022/15044 — a URL do botão Refaturar, que a operação chama também de "Devolver Crédito"); Filtrar e
-- Manter Pagamento (146/181, 146/182) e Atualizar Pagamento (141/178); Inserir Guia de Devolução (245/299); Inserir
-- Devoluções (93/126).
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (1001, 15042, 16021, '2026-01-01 00:00:00'),
  (1001, 15043, 16022, '2026-01-01 00:00:00'),
  (1001, 15044, 16022, '2026-01-01 00:00:00'),
  (1001, 15045, 16022, '2026-01-01 00:00:00'),
  (1001, 181, 146, '2026-01-01 00:00:00'),
  (1001, 182, 146, '2026-01-01 00:00:00'),
  (1001, 178, 141, '2026-01-01 00:00:00'),
  (1001, 299, 245, '2026-01-01 00:00:00'),
  (1001, 126, 93, '2026-01-01 00:00:00');
