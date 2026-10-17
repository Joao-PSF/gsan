-- Delta — o que a BAIXA CONTÁBIL de devedores duvidosos exige e as contas dos dois lados de cada limite (lote 9: CEN-FIN-002).
-- Depende de conta-ciclo-catalogos.sql (situações) e da massa base (IMV-01/02/03 na localidade 1, quadra 1, cliente 1).
--
-- EVIDÊNCIA: a tela Gerar Resumo dos Devedores Duvidosos recusa a referência contábil sem parâmetros
-- (ControladorFinanceiro.gerarResumoDevedoresDuvidosos(ProcessoIniciado, ...): "atencao.naocadastrado.referencia_contabil"); a
-- base não tem nenhum (financeiro.param_deved_duvid e param_deved_duvid_item vazias). A regra executada no PostgreSQL
-- (RepositorioFinanceiroPostgresHBM.atualizaContaAnoMesReferenciaContabilDevedoresDuvidosos:517) marca a conta NORMAL,
-- INCLUÍDA ou RETIFICADA, de referência anterior à contábil, ainda sem baixa, de categoria 1–3, cujo imóvel tem uma SITUAÇÃO DE
-- COBRANÇA vigente (cadastro.imovel_cobranca_situacao sem retirada — junção interna: imóvel sem nenhuma não entra) que atende a
-- um item do parâmetro (a situação do item, ou qualquer uma, se nula), com valor (água + esgoto + débitos − créditos −
-- impostos) até o LIMITE do item e "meses de atraso" de pelo menos o NÚMERO DE MESES do item.
-- · Parâmetro SINTÉTICO da referência contábil 06/2026: valor a baixar R$ 1.000,00; um item: limite R$ 120,00, 12 meses,
--   qualquer situação de cobrança. Situação de cobrança SINTÉTICA, vigente para IMV-01 e IMV-02 (IMV-03 sem nenhuma).
-- · Contas SINTÉTICAS de 2025, no estado em que o faturamento as deixaria (NORMAL, sem pagamento, impostos 0,00, com a categoria e
--   o cliente usuário), uma por lado de limite:
--   9201 · IMV-01 · 06/2025 · R$ 120,00 · vencida em 10/06/2025 → no limite do valor (≤) e a 12 meses da referência
--   9202 · IMV-01 · 07/2025 · R$  30,00 · vencida em 10/07/2025 → a 11 meses (abaixo do número de meses)
--   9203 · IMV-02 · 06/2025 · R$ 120,01 · vencida em 10/06/2025 → 1 centavo acima do limite
--   9204 · IMV-03 · 06/2025 · R$  40,00 · vencida em 10/06/2025 → imóvel sem situação de cobrança
--   As contas de 05/2026 do faturamento (vencidas em 10/06/2026, a 0 meses) completam: IMV-01 R$ 110,40 (no limite do valor),
--   IMV-02 e IMV-03 acima dele.
-- Ids altos (9201+, 7101) para não colidirem com as sequências nem com os deltas dos outros lotes. Valores SINTÉTICOS.
INSERT INTO cobranca.cobranca_situacao (cbst_id, cbst_dscobrancasituacao, cbst_icuso, cbst_tmultimaalteracao, cbst_icbloqueioparcel,
                                        cbst_icbloqueioinclusao, cbst_icbloqueioretirada, cbst_icselecaopermesp,
                                        cbst_icprescreveparticular, cbst_icnaocobranca, cbst_iccancelanegativacao)
VALUES (7101, 'COBRANCA ADMINISTRATIVA (SINTETICO)', 1, '2026-01-01 00:00:00', 2, 2, 2, 2, 2, 2, 2);
INSERT INTO cadastro.imovel_cobranca_situacao (iscb_id, imov_id, iscb_dtimplantacaocobranca, iscb_dtretiradacobranca, iscb_tmultimaalteracao,
                                               cbst_id, clie_id) VALUES
  (7101, 100013, '2026-01-01', NULL, '2026-01-01 00:00:00', 7101, 1),
  (7102, 100021, '2026-01-01', NULL, '2026-01-01 00:00:00', 7101, 1);
INSERT INTO financeiro.param_deved_duvid (pded_id, pded_amreferenciacontabil, pded_vlvalorabaixar, pded_amreferenciaarrecadacao,
                                          pded_tmprocessamento, pded_dtintegracaocontabil, pded_tmultimaalteracao, pded_vlbaixado) VALUES
  (7101, 202606, 1000.00, NULL, NULL, NULL, '2026-01-01 00:00:00', 0.00);
INSERT INTO financeiro.param_deved_duvid_item (pdit_id, pded_id, pdit_vlvalorlimite, pdit_nnmeses, cbst_id, pdit_tmultimaalteracao) VALUES
  (7101, 7101, 120.00, 12, NULL, '2026-01-01 00:00:00');
INSERT INTO faturamento.conta_geral (cnta_id, cntg_ichistorico, cntg_tmultimaalteracao) VALUES
  (9201, 2, '2025-05-30 00:00:00'), (9202, 2, '2025-06-30 00:00:00'), (9203, 2, '2025-05-30 00:00:00'), (9204, 2, '2025-05-30 00:00:00');
INSERT INTO faturamento.conta (cnta_id, imov_id, cnta_amreferenciaconta, last_id, lest_id, loca_id, qdra_id, cnta_cdsetorcomercial,
                               cnta_nnquadra, cnta_nnlote, cnta_nnsublote, cnta_dgverificadorconta, cnta_iccobrancamulta,
                               cnta_icalteracaovencimento, cnta_nnconsumoagua, cnta_nnconsumoesgoto, cnta_vlagua, cnta_vlesgoto,
                               cnta_vldebitos, cnta_vlcreditos, cnta_vlimpostos, cnta_pcesgoto, cnta_dtvencimentoconta, cnta_dtvencimentooriginal,
                               cnta_dtvalidadeconta, cnta_dtemissao, cnta_dtinclusao, cnta_dtretificacao, cnta_dtcancelamento,
                               cnta_amreferenciacontabil, cstf_id, iper_id, ftgr_id, rota_id, dcst_idatual, dcst_idanterior,
                               cmrt_id, cmcn_id, cnta_nnretificacao, cnta_icdebitoconta, usur_id, cnta_tmultimaalteracao) VALUES
  (9201, 100013, 202506, 3, 1, 1, 1, 1, 1, 1, 0, 0, 2, 2, 20, 0, 120.00, 0.00, 0.00, 0.00, 0.00, 0.00, '2025-06-10', '2025-06-10',
   '2025-09-10', '2025-05-30', NULL, NULL, NULL, 202506, 1, 5, 1, 1, 0, NULL, NULL, NULL, NULL, 2, 1, '2025-05-30 00:00:00'),
  (9202, 100013, 202507, 3, 1, 1, 1, 1, 1, 1, 0, 0, 2, 2, 10, 0, 30.00, 0.00, 0.00, 0.00, 0.00, 0.00, '2025-07-10', '2025-07-10',
   '2025-10-10', '2025-06-30', NULL, NULL, NULL, 202507, 1, 5, 1, 1, 0, NULL, NULL, NULL, NULL, 2, 1, '2025-06-30 00:00:00'),
  (9203, 100021, 202506, 3, 1, 1, 1, 1, 1, 2, 0, 0, 2, 2, 20, 0, 120.01, 0.00, 0.00, 0.00, 0.00, 0.00, '2025-06-10', '2025-06-10',
   '2025-09-10', '2025-05-30', NULL, NULL, NULL, 202506, 1, 5, 1, 1, 0, NULL, NULL, NULL, NULL, 2, 1, '2025-05-30 00:00:00'),
  (9204, 100030, 202506, 3, 1, 1, 1, 1, 1, 3, 0, 0, 2, 2, 10, 0, 40.00, 0.00, 0.00, 0.00, 0.00, 0.00, '2025-06-10', '2025-06-10',
   '2025-09-10', '2025-05-30', NULL, NULL, NULL, 202506, 1, 5, 1, 1, 0, NULL, NULL, NULL, NULL, 2, 1, '2025-05-30 00:00:00');
-- Uma categoria por conta (RESIDENCIAL, 1 economia) e o cliente usuário (cliente 1), como o faturamento grava.
INSERT INTO faturamento.conta_categoria (cnta_id, catg_id, scat_id, ctcg_qteconomia, ctcg_vlagua, ctcg_nnconsumoagua, ctcg_vlesgoto,
                                         ctcg_nnconsumoesgoto, ctcg_tmultimaalteracao)
SELECT cnta_id, 1, 0, 1, cnta_vlagua, cnta_nnconsumoagua, 0.00, 0, cnta_tmultimaalteracao FROM faturamento.conta WHERE cnta_id BETWEEN 9201 AND 9204;
INSERT INTO cadastro.cliente_conta (clct_id, clie_id, cnta_id, crtp_id, clct_icnomeconta, clct_tmultimaalteracao)
SELECT cnta_id, 1, cnta_id, 2, 1, cnta_tmultimaalteracao FROM faturamento.conta WHERE cnta_id BETWEEN 9201 AND 9204;
