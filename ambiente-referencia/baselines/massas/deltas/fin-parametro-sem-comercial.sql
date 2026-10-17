-- Delta — a parametrização contábil do faturamento SEM a linha da categoria COMERCIAL (lote 9: CEN-FIN-001 V1b). Depende de
-- fin-plano-contas.sql. Uma companhia que não parametrizou uma combinação que o resumo do mês tem: o parâmetro da água
-- comercial (7102) sai; o resto da massa é o de V1.
DELETE FROM faturamento.fatur_contb_parametros WHERE plcf_id = 7102;
