-- Delta — concessões do operador da caracterização para ACOMPANHAR, AUTORIZAR e REINICIAR um processo iniciado
-- (lote 5: CEN-BAT-001 V2, CEN-BAT-002 V2). Depende de batch-catalogos.sql (grupo 1001 do operador).
--   Consultar Dados Processo Iniciado  funcionalidade 375 (Filtrar Processo),            operação 485
--   Reiniciar Batch                    funcionalidade 375 (Filtrar Processo),            operação 1064
--   Autorizar Processo Iniciado        funcionalidade 1225 (Autorizar Relatorios Batch), operação 1527
-- Ids da base reconstruída (seguranca.funcionalidade, seguranca.operacao).
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (1001, 485, 375, '2026-01-01 00:00:00'),
  (1001, 1064, 375, '2026-01-01 00:00:00'),
  (1001, 1527, 1225, '2026-01-01 00:00:00');
