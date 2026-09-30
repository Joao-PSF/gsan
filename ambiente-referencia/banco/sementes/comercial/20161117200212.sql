-- P3 — tipos de processo pressupostos por 20161117200212 (processo com prtp_id = 4).
-- Evidência: src/gcom/batch/ProcessoTipo.java — FATURAMENTO_COMANDADO = 1, COBRANCA_COMANDADO = 2,
-- MENSAL = 3, EVENTUAL = 4, RELATORIO = 5, SEMANAL = 6, DIARIO = 7. Descrição = nome da constante.
INSERT INTO batch.processo_tipo (prtp_id, prtp_dsprocessotipo, prtp_icuso, prtp_tmultimaalteracao) VALUES
  (1, 'FATURAMENTO COMANDADO', 1, now()), (2, 'COBRANCA COMANDADO', 1, now()), (3, 'MENSAL', 1, now()),
  (4, 'EVENTUAL', 1, now()), (5, 'RELATORIO', 1, now()), (6, 'SEMANAL', 1, now()), (7, 'DIARIO', 1, now());
