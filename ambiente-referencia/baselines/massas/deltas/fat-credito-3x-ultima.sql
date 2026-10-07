-- Delta — o crédito de fat-credito-30.sql passa a R$ 100,00 em 3 prestações, 2 já realizadas (a última é a desta
-- conta) (lote 5b: CEN-FAT-004 V3c). Depende de fat-credito-30.sql.
-- PERGUNTA: o débito ajusta a última prestação com o resto da divisão (100,00 / 3 → 33,34 na última); o crédito só faz
-- esse ajuste no pré-faturamento (CreditoARealizar.calculaValorParcelaIntermediaria). A prestação anterior foi a de
-- 04/2026. SINTÉTICO.
UPDATE faturamento.credito_a_realizar SET crar_vlcredito = 100.00, crar_nnprestacaocredito = 3, crar_nnprestacaorealizadas = 2,
                                          crar_amreferenciaprestacao = 202604 WHERE crar_id = 9201;
UPDATE faturamento.cred_a_realiz_catg SET cacg_vlcategoria = 100.00 WHERE crar_id = 9201;
