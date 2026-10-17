-- Delta — a PARAMETRIZAÇÃO CONTÁBIL da arrecadação (lote 9: CEN-FIN-001 V2, V3). Depende de fin-plano-contas.sql (contas),
-- fin-lancamento-catalogos.sql e arr-encerramento-catalogos.sql (lote 6c: os tipos de recebimento).
--
-- EVIDÊNCIA: arrecadacao.arrec_contb_parametros está VAZIA na base; cada linha do resumo da arrecadação só vira lançamento se
-- houver o parâmetro da sua combinação — tipo de recebimento × categoria × item contábil × item × tipo
-- (RepositorioFinanceiroHBM.obterParametrosContabilArrecadacao:1116). Parâmetros SINTÉTICOS, só para as linhas de DETALHE do
-- resumo do mês de CEN-ARR-010 V1 (as de total — totais dos recebimentos, arrecadação líquida, resumos — não): recebimentos
-- CLASSIFICADOS de conta (tipo de recebimento 1, tipo 27 CONTAS, item 1 ÁGUA): débito ARRECADAÇÃO A DISCRIMINAR, crédito CONTAS
-- A RECEBER; recebimentos NÃO CLASSIFICADOS (tipo de recebimento 2) — em duplicidade (33/32), documento inexistente (35/33, por
-- categoria) e valor que não confere (36/29): débito ARRECADAÇÃO A DISCRIMINAR, crédito RECEBIMENTOS NÃO CLASSIFICADOS.
INSERT INTO arrecadacao.arrec_contb_parametros (plca_id, rctp_id, lctp_id, lcit_id, lict_id, catg_id, cnct_iddebito, cnct_idcredito,
                                                plca_dshistoricodeb, plca_dshistoricocre, plca_tmultimaalteracao) VALUES
  (7101, 1, 27, 1, NULL, 1, 7103, 7102, 'ARRECADACAO CONTAS RESIDENCIAL', 'BAIXA CONTAS A RECEBER RESIDENCIAL', '2026-01-01 00:00:00'),
  (7102, 2, 33, 32, NULL, 1, 7103, 7104, 'ARRECADACAO DUPLICIDADE RESIDENCIAL', 'NAO CLASSIFICADO DUPLICIDADE RESIDENCIAL', '2026-01-01 00:00:00'),
  (7103, 2, 35, 33, NULL, 1, 7103, 7104, 'ARRECADACAO DOC INEXISTENTE RESIDENCIAL', 'NAO CLASSIFICADO DOC INEXISTENTE RESID', '2026-01-01 00:00:00'),
  (7104, 2, 35, 33, NULL, 2, 7103, 7104, 'ARRECADACAO DOC INEXISTENTE COMERCIAL', 'NAO CLASSIFICADO DOC INEXISTENTE COMERC', '2026-01-01 00:00:00'),
  (7105, 2, 36, 29, NULL, 1, 7103, 7104, 'ARRECADACAO VALOR NAO CONFERE RESIDENCIAL', 'NAO CLASSIFICADO VALOR NAO CONFERE RESID', '2026-01-01 00:00:00');
