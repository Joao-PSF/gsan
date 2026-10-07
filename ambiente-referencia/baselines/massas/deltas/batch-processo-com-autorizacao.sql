-- Delta — o processo FATURAR GRUPO (2) passa a exigir AUTORIZAÇÃO (lote 5: CEN-BAT-001 V2). Depende de
-- batch-catalogos.sql e de batch-permissoes-processo.sql.
--
-- Indicador de autorização do processo (batch.processo.proc_icautorizacao = 1): o processo iniciado nasce AGUARDANDO
-- AUTORIZAÇÃO em vez de EM ESPERA (ControladorBatchSEJB.verificarAutorizacaoBatch:6278). Configuração SINTÉTICA.
UPDATE batch.processo SET proc_icautorizacao = 1 WHERE proc_id = 2;
