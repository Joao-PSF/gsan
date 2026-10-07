-- Delta — alíquota do IR em 2,50% (lote 5b: CEN-FAT-005 V2). Depende de fat-impostos-orgao-federal.sql.
-- Sobre a base do IMV-03 (252,60) o IR dá EXATAMENTE meio centavo: 6,315 — HALF_DOWN leva a 6,31; HALF_UP levaria a
-- 6,32. Alíquota SINTÉTICA, escolhida para isso.
UPDATE faturamento.imposto_tipo_aliquota SET imta_pcaliquota = 2.50 WHERE imta_id = 1;
