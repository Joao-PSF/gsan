-- P3 — negativadores pressupostos por 20181107145817 (negatd_retorno_motivo com negt_id = 2).
-- Evidência: src/gcom/cobranca/Negativador.java — NEGATIVADOR_SPC = 1, NEGATIVADOR_SERASA = 2.
-- Sintético: negt_cdagente.
INSERT INTO cobranca.negativador (negt_id, negt_cdagente, negt_icuso, negt_tmultimaalteracao)
VALUES (1, 1, 1, now()), (2, 2, 1, now());
