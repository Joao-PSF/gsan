-- Delta — o limite do percentual alternativo de esgoto de 100463 passa a 30 m³ por economia (lote 5e: CEN-FAT-003 V2b):
-- 27 ≤ 30 — o consumo fica DENTRO do limite. Depende de cons-imv-esgoto-alternativo.sql. SINTÉTICO.
UPDATE atendimentopublico.ligacao_esgoto SET lesg_nnconsumopcalternativo = 30 WHERE lesg_id = 100463;
