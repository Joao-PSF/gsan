-- Delta — TAR-01 com uma vigência que começa em 16/05/2026, no MEIO do período de leitura de 05/2026 (30/04 → 31/05) da R4
-- (lote 5e: CEN-FAT-002 na conta). Só a categoria RESIDENCIAL, com os mesmos valores da vigência de 16/07/2026 da massa base
-- (mínimo 10 m³ a 35,10; faixas 4,48 · 5,62 · 7,94 · 10,58). Id 5 (os ids 3 e 4 são de deltas do piloto). SINTÉTICO.
INSERT INTO faturamento.consumo_tarifa_vigencia (cstv_id, cstf_id, cstv_dtvigencia, cstv_tmultimaalteracao) VALUES
  (5, 1, '2026-05-16', '2026-01-01 00:00:00');
INSERT INTO faturamento.consumo_tarifa_categoria
  (cstc_id, cstv_id, catg_id, cstc_nnconsumominimo, cstc_vltarifaminima, cstc_tmultimaalteracao, scat_id) VALUES
  (51, 5, 1, 10, 35.10, '2026-01-01 00:00:00', 0);
INSERT INTO faturamento.consumo_tarifa_faixa
  (ctfx_id, cstc_id, ctfx_nncosumofaixainicio, ctfx_nnconsumofaixafim, ctfx_vlconsumotarifa, ctfx_tmultimaalteracao) VALUES
  (511, 51, 11, 20, 4.48, '2026-01-01 00:00:00'),
  (512, 51, 21, 30, 5.62, '2026-01-01 00:00:00'),
  (513, 51, 31, 50, 7.94, '2026-01-01 00:00:00'),
  (514, 51, 51, 99999, 10.58, '2026-01-01 00:00:00');
