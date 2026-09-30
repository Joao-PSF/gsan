-- P3 — processo pressuposto por 20210920163300 (processo_funcionalidade com proc_id = 2).
-- Evidência: Processo.FATURAR_GRUPO_FATURAMENTO = 2.
INSERT INTO batch.processo (proc_id, proc_dsprocesso, proc_dsabreviado, proc_icuso, proc_tmultimaalteracao)
VALUES (2, 'FATURAR GRUPO FATURAMENTO', 'FATGRUPO', 1, now());
