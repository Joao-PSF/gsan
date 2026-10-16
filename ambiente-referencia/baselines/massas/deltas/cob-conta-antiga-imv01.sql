-- Delta — uma conta ANTIGA de IMV-01 ainda em aberto (lote 8: CEN-COB-002, CEN-COB-007). Depende de conta-ciclo-catalogos.sql
-- (situações) e da massa base (IMV-01 na rota 1, localidade 1, perfil 5). Não se combina com conta-ciclo-contas-antigas.sql
-- (lote 5d), que traz contas antigas dos três imóveis para a regra de prescrição.
--
-- Por que pela massa: o cenário pede IMV-01 com DUAS contas vencidas elegíveis — o aviso de corte com um item por dívida,
-- uma das contas paga antes da ação (V2) ou por outro canal depois do documento (V4) — e a prescrição de uma conta em
-- cobrança (CEN-COB-007 V3). O faturamento gera só a conta da referência corrente (05/2026); a conta de 06/2014 chega no
-- estado em que o faturamento a deixaria: NORMAL, sem pagamento, vencida em 10/07/2014 — longe da fronteira móvel de 10
-- anos da prescrição (TarefaBatchGerarPrescreverDebitosDeImoveis: hoje menos 10 anos), para a baseline não depender do dia.
-- Id alto (9101) para não colidir com a sequência das contas do faturamento nem com as do lote 5d. Valores SINTÉTICOS.
INSERT INTO faturamento.conta_geral (cnta_id, cntg_ichistorico, cntg_tmultimaalteracao) VALUES (9101, 2, '2014-06-30 00:00:00');
INSERT INTO faturamento.conta (cnta_id, imov_id, cnta_amreferenciaconta, last_id, lest_id, loca_id, qdra_id, cnta_cdsetorcomercial,
                               cnta_nnquadra, cnta_nnlote, cnta_nnsublote, cnta_dgverificadorconta, cnta_iccobrancamulta,
                               cnta_icalteracaovencimento, cnta_nnconsumoagua, cnta_nnconsumoesgoto, cnta_vlagua, cnta_vlesgoto,
                               cnta_vldebitos, cnta_vlcreditos, cnta_pcesgoto, cnta_dtvencimentoconta, cnta_dtvencimentooriginal,
                               cnta_dtvalidadeconta, cnta_dtemissao, cnta_dtinclusao, cnta_dtretificacao, cnta_dtcancelamento,
                               cnta_amreferenciacontabil, cstf_id, iper_id, ftgr_id, rota_id, dcst_idatual, dcst_idanterior,
                               cmrt_id, cmcn_id, cnta_nnretificacao, cnta_icdebitoconta, usur_id, cnta_tmultimaalteracao) VALUES
  (9101, 100013, 201406, 3, 1, 1, 1, 1, 1, 1, 0, 0, 2, 2, 20, 0, 50.00, 0.00, 0.00, 0.00, 0.00, '2014-07-10', '2014-07-10',
   '2014-10-10', '2014-06-30', NULL, NULL, NULL, 201406, 1, 5, 1, 1, 0, NULL, NULL, NULL, NULL, 2, 1, '2014-06-30 00:00:00');
-- Uma categoria (RESIDENCIAL, 1 economia), como o faturamento grava.
INSERT INTO faturamento.conta_categoria (cnta_id, catg_id, scat_id, ctcg_qteconomia, ctcg_vlagua, ctcg_nnconsumoagua, ctcg_vlesgoto,
                                         ctcg_nnconsumoesgoto, ctcg_tmultimaalteracao)
VALUES (9101, 1, 0, 1, 50.00, 20, 0.00, 0, '2014-06-30 00:00:00');
-- O cliente USUÁRIO da conta (cliente_conta), como o faturamento grava: a posição de débito e a seleção da ação partem dele
-- (RepositorioCobrancaHBM.pesquisarContasImovel:295 — cliente_conta INNER JOIN conta, relação USUÁRIO); sem ele, a conta não
-- aparece em nenhuma das duas. O cliente 1 é o usuário de IMV-01 na massa base.
INSERT INTO cadastro.cliente_conta (clct_id, clie_id, cnta_id, crtp_id, clct_icnomeconta, clct_tmultimaalteracao)
VALUES (9101, 1, 9101, 2, 1, '2014-06-30 00:00:00');
