-- Delta — os processos da CONTABILIZAÇÃO (lote 9: CEN-FIN-001, CEN-FIN-002). Depende de batch-catalogos.sql e de
-- arr-processo-classificar.sql (as concessões de Inserir Processo ao operador).
--
-- EVIDÊNCIA: nenhum processo da base tem as etapas do encerramento do faturamento e da contabilização (cadastradas em
-- seguranca.funcionalidade sem caminho de tela). A tarefa de cada etapa é montada na INSERÇÃO do processo
-- (ControladorBatchSEJB.inserirProcessoIniciado), com a referência do sistema daquele momento — por isso um processo por etapa:
-- · 3401 — ENCERRAR FATURAMENTO DO MÊS (Funcionalidade 552) em LOCALIDADE (6): ControladorFaturamentoFINAL.
--   encerrarFaturamentoMes:12611 grava o resumo do faturamento da referência de faturamento do sistema. O arquivamento e o avanço
--   da referência (647, GERAR_HISTORICO_PARA_ENCERRAR_FATURAMENTO_MES) ficam fora: o lote contabiliza a referência aberta.
-- · 3402 — GERAR LANÇAMENTOS CONTÁBEIS DO FATURAMENTO (681) em LOCALIDADE: ControladorFinanceiro.
--   gerarLancamentosContabeisFaturamento:335 lê o resumo da referência de faturamento.
-- · 3403 — GERAR LANÇAMENTOS CONTÁBEIS DA ARRECADAÇÃO (700) em LOCALIDADE: gerarLancamentoContabeisArrecadacao:5356 lê o
--   resumo da arrecadação da referência de arrecadação (o encerramento do lote 6c o grava).
-- · 3404 — GERAR LANÇAMENTOS CONTÁBEIS DOS AVISOS BANCÁRIOS (1291) em FUNCIONALIDADE (5): gerarLancamentosContabeisAvisos
--   Bancarios:12471.
-- · 79 — o id de Processo.GERAR_RESUMO_DEVEDORES_DUVIDOSOS, o processo que a tela Gerar Resumo dos Devedores Duvidosos insere
--   (GerarResumoDevedoresDuvidososAction) com a referência contábil do formulário: a etapa 714 (GERAR_RESUMO_DEVEDORES_
--   DUVIDOSOS) e a 755 (GERAR_LANCAMENTOS_CONTABEIS_DEVEDORES_DUVIDOSOS), ambas em LOCALIDADE. A 755 só é montada por esse
--   caminho (inserirProcessoIniciado com os dados do formulário, ControladorBatchSEJB:4514); pela tela Inserir Processo, a 714
--   receberia a referência no parâmetro errado ("anoMesFaturamento", :1548 — a tarefa lê "anoMesReferenciaContabil"). Na base,
--   o id 755 de seguranca.funcionalidade é outra funcionalidade ("Inserir Capacidade Hidrometro"): a etapa é a do código.
-- Tipos SINTÉTICOS: MENSAL (3) para os do mês, EVENTUAL (4) para o 79; sem autorização. Concessão: a tela Gerar Resumo dos
-- Devedores Duvidosos (funcionalidade 714, operação 915).
INSERT INTO batch.processo (proc_id, proc_dsprocesso, proc_dsabreviado, proc_icuso, proc_tmultimaalteracao, prtp_id, proc_icautorizacao) VALUES
  (3401, 'ENCERRAR FATURAMENTO DO MES (SINTETICO)', 'ENCFAT', 1, '2026-01-01 00:00:00', 3, 2),
  (3402, 'LANC CONTABEIS FATURAMENTO (SINTETICO)', 'LCFAT', 1, '2026-01-01 00:00:00', 3, 2),
  (3403, 'LANC CONTABEIS ARRECADACAO (SINTETICO)', 'LCARR', 1, '2026-01-01 00:00:00', 3, 2),
  (3404, 'LANC CONTAB AVISOS BANCARIOS (SINTETICO)', 'LCAVB', 1, '2026-01-01 00:00:00', 3, 2),
  (79, 'RESUMO DEVEDORES DUVIDOSOS (SINTETICO)', 'DEVDUV', 1, '2026-01-01 00:00:00', 4, 2);
INSERT INTO batch.processo_funcionalidade (prfn_id, proc_id, fncd_id, unpr_id, prfn_nnsequencialexecucao, prfn_icuso, prfn_tmultimaalteracao) VALUES
  (3401, 3401, 552, 6, 1, 1, '2026-01-01 00:00:00'),
  (3402, 3402, 681, 6, 1, 1, '2026-01-01 00:00:00'),
  (3403, 3403, 700, 6, 1, 1, '2026-01-01 00:00:00'),
  (3404, 3404, 1291, 5, 1, 1, '2026-01-01 00:00:00'),
  (3405, 79, 714, 6, 1, 1, '2026-01-01 00:00:00'),
  (3406, 79, 755, 6, 2, 1, '2026-01-01 00:00:00');
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (1001, 915, 714, '2026-01-01 00:00:00');
