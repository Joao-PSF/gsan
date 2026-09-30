-- Delta — TAR-04: tarifa com tipo de cálculo 4 (CALCULO_DIRETO_NA_FAIXA,
-- gcom.faturamento.TarifaTipoCalculo), para CEN-FAT-001 V7 ("só se o tipo existir na instância de
-- referência": o tipo existe no código e na massa base, 010-parametrizacao-faturamento.sql).
-- Mesmos mínimo e faixas RESIDENCIAIS da 1ª vigência da TAR-01: a diferença para V1 é só o tipo de
-- cálculo. Uma vigência, anterior à referência usada. Valores SINTÉTICOS.
INSERT INTO faturamento.consumo_tarifa
  (cstf_id, cstf_dsconsumotarifa, cstf_icuso, cstf_tmultimaalteracao, lapf_id, ttpc_id) VALUES
  (4, 'TAR-04 (SINTETICA)', 1, '2026-01-01 00:00:00', NULL, 4);
INSERT INTO faturamento.consumo_tarifa_vigencia (cstv_id, cstf_id, cstv_dtvigencia, cstv_tmultimaalteracao) VALUES
  (41, 4, '2025-01-01', '2026-01-01 00:00:00');
INSERT INTO faturamento.consumo_tarifa_categoria
  (cstc_id, cstv_id, catg_id, cstc_nnconsumominimo, cstc_vltarifaminima, cstc_tmultimaalteracao, scat_id) VALUES
  (411, 41, 1, 10, 32.50, '2026-01-01 00:00:00', 0);
INSERT INTO faturamento.consumo_tarifa_faixa
  (ctfx_id, cstc_id, ctfx_nncosumofaixainicio, ctfx_nnconsumofaixafim, ctfx_vlconsumotarifa, ctfx_tmultimaalteracao) VALUES
  (4111, 411, 11, 20, 4.15, '2026-01-01 00:00:00'),
  (4112, 411, 21, 30, 5.20, '2026-01-01 00:00:00'),
  (4113, 411, 31, 50, 7.35, '2026-01-01 00:00:00'),
  (4114, 411, 51, 99999, 9.80, '2026-01-01 00:00:00');
