-- Delta — um PLANO DE CONTAS e a PARAMETRIZAÇÃO CONTÁBIL mínimos (lote 9: CEN-FIN-001, CEN-FIN-002). Depende de
-- fin-lancamento-catalogos.sql (tipos e itens) e de categorias-com-tipo.sql (categorias).
--
-- EVIDÊNCIA: financeiro.conta_contabil, faturamento.fatur_contb_parametros, arrecadacao.arrec_contb_parametros e
-- financeiro.deved_duvid_contb_param estão VAZIAS na base. Cada linha de resumo só vira lançamento se houver o parâmetro da
-- sua combinação (categoria × item contábil × item × tipo, e o tipo de recebimento na arrecadação — RepositorioFinanceiroHBM.
-- obterParametrosContabilFaturamento:1008, obterParametrosContabilArrecadacao:1116); a linha sem parâmetro é pulada, sem aviso
-- (ControladorFinanceiro.inserirLancamentoContabilItemFaturamento:515). Os lançamentos dos avisos bancários não usam parâmetro:
-- procuram as contas pelo NOME — "BANCO" e "ARRECADACAO A DISCRIMINAR" (gerarLancamentosContabeisAvisosBancarios:12471).
-- Plano e parâmetros SINTÉTICOS (não são o plano de nenhuma companhia), escolhidos para que cada parâmetro se distinga no
-- resultado: só as linhas de DETALHE do resumo são parametrizadas — as de total (receita bruta e líquida, totais dos
-- recebimentos, arrecadação líquida) não.
-- · Faturamento: ÁGUA (tipo 1, item 1) por categoria — residencial e comercial: débito CONTAS A RECEBER, crédito RECEITA DE ÁGUA.
-- · Arrecadação: em fin-parametros-arrecadacao.sql (depende dos tipos de recebimento do lote 6c).
INSERT INTO financeiro.conta_contabil (cnct_id, cnct_nnprefixocontabil, cnct_tmultimaalteracao, cnct_nndigito, cnct_iclinha, cnct_nnterceiros,
                                       cnct_nnconta, cnct_nmconta, cnct_iccusto) VALUES
  (7101, '1', '2026-01-01 00:00:00', '0', 1, '0000000', '1.1.1.01.001', 'BANCO', 2),
  (7102, '1', '2026-01-01 00:00:00', '0', 1, '0000000', '1.1.2.01.001', 'CONTAS A RECEBER DE USUARIOS', 2),
  (7103, '2', '2026-01-01 00:00:00', '0', 1, '0000000', '2.1.9.01.001', 'ARRECADACAO A DISCRIMINAR', 2),
  (7104, '2', '2026-01-01 00:00:00', '0', 1, '0000000', '2.1.9.01.002', 'RECEBIMENTOS NAO CLASSIFICADOS', 2),
  (7105, '3', '2026-01-01 00:00:00', '0', 1, '0000000', '3.1.1.01.001', 'RECEITA DE AGUA', 2),
  (7106, '4', '2026-01-01 00:00:00', '0', 1, '0000000', '4.1.9.01.001', 'PERDAS COM DEVEDORES DUVIDOSOS', 2);
INSERT INTO faturamento.fatur_contb_parametros (plcf_id, lctp_id, lcit_id, lict_id, catg_id, cnct_iddebito, cnct_idcredito, plcf_tmultimaalteracao,
                                                plcf_dshistoricodeb, plcf_dshistoricocre) VALUES
  (7101, 1, 1, NULL, 1, 7102, 7105, '2026-01-01 00:00:00', 'FATURAMENTO AGUA RESIDENCIAL', 'RECEITA AGUA RESIDENCIAL'),
  (7102, 1, 1, NULL, 2, 7102, 7105, '2026-01-01 00:00:00', 'FATURAMENTO AGUA COMERCIAL', 'RECEITA AGUA COMERCIAL');
-- · Devedores duvidosos: a ÁGUA baixada (tipo 1, item 1), residencial: débito PERDAS COM DEVEDORES DUVIDOSOS, crédito CONTAS A
--   RECEBER.
INSERT INTO financeiro.deved_duvid_contb_param (ddcp_id, lctp_id, lcit_id, lict_id, catg_id, cnct_iddebito, cnct_idcredito, ddcp_tmultimaalteracao,
                                                ddcp_dshistoricodeb, ddcp_dshistoricocre) VALUES
  (7101, 1, 1, NULL, 1, 7106, 7102, '2026-01-01 00:00:00', 'BAIXA DEVEDORES DUVIDOSOS AGUA RESIDENCIAL', 'BAIXA CONTAS A RECEBER AGUA RESIDENCIAL');
