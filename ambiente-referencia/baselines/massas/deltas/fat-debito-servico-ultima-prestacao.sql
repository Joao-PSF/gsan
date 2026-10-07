-- Delta — o débito de serviço de fat-debito-servico-3x.sql com 2 das 3 prestações já cobradas (a última é a desta
-- conta) (lote 5b: CEN-FAT-004 V1b). Depende de fat-debito-servico-3x.sql.
-- A prestação anterior foi a de 04/2026. SINTÉTICO.
UPDATE faturamento.debito_a_cobrar SET dbac_nnprestacaocobradas = 2, dbac_amreferenciaprestacao = 202604 WHERE dbac_id = 9001;
