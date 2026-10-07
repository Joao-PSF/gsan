-- Delta — o crédito de fat-credito-30.sql passa a R$ 150,00 — maior que a conta do IMV-01 (R$ 110,40) (lote 5b:
-- CEN-FAT-004 V3b). Depende de fat-credito-30.sql. O que sobra fica como resíduo para a conta seguinte? SINTÉTICO.
UPDATE faturamento.credito_a_realizar SET crar_vlcredito = 150.00 WHERE crar_id = 9201;
UPDATE faturamento.cred_a_realiz_catg SET cacg_vlcategoria = 150.00 WHERE crar_id = 9201;
