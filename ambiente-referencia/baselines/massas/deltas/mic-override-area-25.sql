-- Delta — CEN-MIC-002 V5/V6: consumo mínimo por ÁREA (micromedicao.consumo_minimo_area): residencial até 999 m², 25 m³, a
-- partir da referência 05/2026; o IMV-01 recebe área construída de 80 m². SINTÉTICO.
INSERT INTO micromedicao.consumo_minimo_area (cmar_id, cmar_amreferencia, catg_id, scat_id, cmar_nnareafinal, cmar_nnconsumo,
                                              cmar_icuso, cmar_tmultimaalteracao)
VALUES (1, 202605, 1, NULL, 999, 25, 1, '2026-01-01 00:00:00');
UPDATE cadastro.imovel SET imov_nnareaconstruida = 80 WHERE imov_id = 100013;
