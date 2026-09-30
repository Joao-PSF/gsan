-- Delta — TAR-01 com uma 3ª vigência que começa no ÚLTIMO dia de 08/2026 (CEN-FAT-002 V2: "início
-- de V₂ no dia da leitura atual"). Sem cronograma de leitura, a simulação usa como período o mês da
-- referência inteiro (SimularCalculoContaAction): a leitura atual é 2026-08-31.
-- Só a categoria RESIDENCIAL, a única que o cenário usa. Valores SINTÉTICOS.
INSERT INTO faturamento.consumo_tarifa_vigencia (cstv_id, cstf_id, cstv_dtvigencia, cstv_tmultimaalteracao) VALUES
  (3, 1, '2026-08-31', '2026-01-01 00:00:00');
INSERT INTO faturamento.consumo_tarifa_categoria
  (cstc_id, cstv_id, catg_id, cstc_nnconsumominimo, cstc_vltarifaminima, cstc_tmultimaalteracao, scat_id) VALUES
  (31, 3, 1, 10, 37.20, '2026-01-01 00:00:00', 0);
INSERT INTO faturamento.consumo_tarifa_faixa
  (ctfx_id, cstc_id, ctfx_nncosumofaixainicio, ctfx_nnconsumofaixafim, ctfx_vlconsumotarifa, ctfx_tmultimaalteracao) VALUES
  (311, 31, 11, 20, 4.75, '2026-01-01 00:00:00'),
  (312, 31, 21, 30, 5.96, '2026-01-01 00:00:00'),
  (313, 31, 31, 50, 8.42, '2026-01-01 00:00:00'),
  (314, 31, 51, 99999, 11.21, '2026-01-01 00:00:00');
