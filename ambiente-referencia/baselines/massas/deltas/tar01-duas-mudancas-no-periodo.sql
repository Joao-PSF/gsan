-- Delta — TAR-01 com mais duas vigências DENTRO de 09/2026 (CEN-FAT-002 V3: "duas mudanças de
-- vigência dentro do período"): 2026-09-10 e 2026-09-20; período da simulação 2026-09-01 a 2026-09-30.
-- Ambas anteriores à primeira captura (2026-09-30) — ver a nota de relógio da massa base.
-- Só a categoria RESIDENCIAL. Valores SINTÉTICOS.
INSERT INTO faturamento.consumo_tarifa_vigencia (cstv_id, cstf_id, cstv_dtvigencia, cstv_tmultimaalteracao) VALUES
  (5, 1, '2026-09-10', '2026-01-01 00:00:00'),
  (6, 1, '2026-09-20', '2026-01-01 00:00:00');
INSERT INTO faturamento.consumo_tarifa_categoria
  (cstc_id, cstv_id, catg_id, cstc_nnconsumominimo, cstc_vltarifaminima, cstc_tmultimaalteracao, scat_id) VALUES
  (51, 5, 1, 10, 36.00, '2026-01-01 00:00:00', 0),
  (61, 6, 1, 10, 37.50, '2026-01-01 00:00:00', 0);
INSERT INTO faturamento.consumo_tarifa_faixa
  (ctfx_id, cstc_id, ctfx_nncosumofaixainicio, ctfx_nnconsumofaixafim, ctfx_vlconsumotarifa, ctfx_tmultimaalteracao) VALUES
  (511, 51, 11, 20, 4.60, '2026-01-01 00:00:00'),
  (512, 51, 21, 30, 5.80, '2026-01-01 00:00:00'),
  (513, 51, 31, 50, 8.10, '2026-01-01 00:00:00'),
  (514, 51, 51, 99999, 10.90, '2026-01-01 00:00:00'),
  (611, 61, 11, 20, 4.80, '2026-01-01 00:00:00'),
  (612, 61, 21, 30, 6.05, '2026-01-01 00:00:00'),
  (613, 61, 31, 50, 8.45, '2026-01-01 00:00:00'),
  (614, 61, 51, 99999, 11.30, '2026-01-01 00:00:00');
