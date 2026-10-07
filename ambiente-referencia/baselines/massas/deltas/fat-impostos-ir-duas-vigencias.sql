-- Delta — o IR com uma alíquota ANTERIOR, de 01/2010 a 1,50%, além da vigente desde 01/2026 a 1,20% (lote 5b:
-- CEN-FAT-005 V3). Depende de fat-impostos-orgao-federal.sql.
-- PERGUNTA: qual vigência a conta de 05/2026 usa? A consulta (RepositorioFaturamentoHBM.pesquisarAliquotaImposto) filtra
-- referência ≤ a da conta, ORDENA da mais antiga para a mais nova e fica com a PRIMEIRA. SINTÉTICO.
INSERT INTO faturamento.imposto_tipo_aliquota (imta_id, imtp_id, imta_amreferencia, imta_pcaliquota, imta_tmultimaalteracao)
VALUES (5, 1, 201001, 1.50, '2010-01-01 00:00:00');
