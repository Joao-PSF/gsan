-- Delta — consumo mínimo FIXADO na LIGAÇÃO de água (lagu_nnconsumominimoagua = 30 m³) dos imóveis da R4 que o lote 5e usa
-- para a precedência do mínimo ao faturar (CEN-MIC-002 V3f, V6f, V3m): o não medido 100447 e o medido 100315 (IMV-M01).
-- O mesmo valor de CEN-MIC-002 V3 (mic-override-ligacao-30.sql). SINTÉTICO.
UPDATE atendimentopublico.ligacao_agua SET lagu_nnconsumominimoagua = 30 WHERE lagu_id IN (100447, 100315);
