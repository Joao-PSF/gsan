-- Delta — o processo de CLASSIFICAÇÃO de pagamentos e devoluções (lote 6). Depende de batch-catalogos.sql. NÃO se combina
-- com conta-ciclo-processo-prescricao.sql (lote 5d), que concede as mesmas operações de Inserir Processo.
--
-- EVIDÊNCIA: nenhum processo da base tem a etapa "Classificar Pagamentos e Devoluções" (Funcionalidade.
-- CLASSIFICAR_PAGAMENTOS_DEVOLUCOES = 545, cadastrada em seguranca.funcionalidade sem caminho de tela). Processo SINTÉTICO do
-- tipo EVENTUAL (ProcessoTipo.EVENTUAL = 4), sem autorização, com a etapa 545 em unidades LOCALIDADE
-- (UnidadeProcessamento.LOCALIDADE = 6): ControladorBatchSEJB:546-561 monta a tarefa com as localidades que têm pagamento
-- ou devolução NO MOMENTO em que o processo é inserido, e TarefaBatchClassificarPagamentosDevolucoes envia uma mensagem
-- por localidade (ControladorArrecadacao.classificarPagamentosDevolucoes:14185, NotSupported).
-- Concessões do operador: Inserir Processo (funcionalidade 369, operação 466) e Inserir Processo Mensal/Eventual (372,
-- 471) — a tela de onde o processo é iniciado.
INSERT INTO batch.processo (proc_id, proc_dsprocesso, proc_dsabreviado, proc_icuso, proc_tmultimaalteracao, prtp_id, proc_icautorizacao)
VALUES (3201, 'CLASSIFICAR PAGAMENTOS (SINTETICO)', 'CLAS', 1, '2026-01-01 00:00:00', 4, 2);
INSERT INTO batch.processo_funcionalidade (prfn_id, proc_id, fncd_id, unpr_id, prfn_nnsequencialexecucao, prfn_icuso, prfn_tmultimaalteracao)
VALUES (3202, 3201, 545, 6, 1, 1, '2026-01-01 00:00:00');
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (1001, 466, 369, '2026-01-01 00:00:00'),
  (1001, 471, 372, '2026-01-01 00:00:00');
