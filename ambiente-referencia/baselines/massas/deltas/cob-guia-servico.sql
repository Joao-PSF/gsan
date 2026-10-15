-- Delta — GUIA DE PAGAMENTO de serviço em aberto do IMV-01 (lote 7b: CEN-COB-004 — "contas + guia"). Depende de
-- fat-lancamentos-catalogos.sql (tipo de débito SERVICO SINTETICO 3101, financiamento SERVIÇO NORMAL, item contábil),
-- de imoveis-imv-01-02-03.sql e de cob-parcelamento-catalogos.sql (tipo de documento GUIA DE PAGAMENTO = 7).
-- EVIDÊNCIA: a base não tem guia de pagamento (faturamento.guia_pagamento vazia; sequência no início); o passo 1 do
-- parcelamento lista as guias do imóvel em débito (situação NORMAL, não paga) e a pergunta "considerar guias de
-- pagamento" as inclui (concluirParcelamentoDebitos:15935 marca cada uma PARCELADA; gerarDebitosACobrarParcelamento:11520
-- gera o débito PARCELAMENTO GUIAS PAGAMENTO). Valores SINTÉTICOS: R$ 50,00, emitida em 20/05/2026, vencida em
-- 20/06/2026, uma prestação, multa não cobrada; id fora da faixa da sequência (8901).
INSERT INTO faturamento.guia_pagamento_geral (gpag_id, gpge_ichistorico, gpge_tmultimaalteracao) VALUES (8901, 2, '2026-05-20 10:00:00');
INSERT INTO faturamento.guia_pagamento (gpag_id, loca_id, imov_id, gpag_amreferenciacontabil, gpag_dtemissao, gpag_dtvencimento,
                                        gpag_vldebito, gpag_tmultimaalteracao, fntp_id, dbtp_id, lict_id, dcst_idatual, dotp_id,
                                        gpag_iccobrancamulta, gpag_nnprestacaodebito, gpag_nnprestacaototal, gpag_icemitirobservacao)
VALUES (8901, 1, 100013, 202605, '2026-05-20', '2026-06-20', 50.00, '2026-05-20 10:00:00', 1, 3101, 6, 0, 7, 2, 1, 1, 2);
INSERT INTO faturamento.guia_pagamento_categoria (gpag_id, catg_id, gpcg_qteconomia, gpcg_vlcategoria, gpcg_tmultimaalteracao)
VALUES (8901, 1, 1, 50.00, '2026-05-20 10:00:00');
