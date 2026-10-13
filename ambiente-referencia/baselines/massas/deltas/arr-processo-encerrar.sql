-- Delta — os processos do ENCERRAMENTO da arrecadação do mês (lote 6c: CEN-ARR-010, CEN-ARR-006, CEN-ARR-005 V4). Depende
-- de batch-catalogos.sql e de arr-processo-classificar.sql (as concessões de Inserir Processo ao operador).
--
-- EVIDÊNCIA: nenhum processo da base tem as etapas do encerramento (Funcionalidade.ENCERRAR_ARRECADACAO_MES = 546,
-- GERAR_HISTORICO_CONTA = 653 e GERAR_HISTORICO_PARA_ENCERRAR_ARRECADACAO_MES = 642, cadastradas em
-- seguranca.funcionalidade sem caminho de tela), e nenhuma migração cadastra o processo 50. Três processos SINTÉTICOS do
-- tipo MENSAL (ProcessoTipo.MENSAL = 3), sem autorização:
-- · 50 (o id de Processo.ENCERRAR_ARRECADACAO_MES) — a etapa 546 em unidades LOCALIDADE (UnidadeProcessamento.LOCALIDADE
--   = 6): ControladorArrecadacao.encerrarArrecadacaoMes apaga e regrava o resumo da arrecadação do mês, por localidade.
-- · 3301 — o arquivamento dos pagamentos, devoluções, guias, débitos e créditos do mês: a etapa 642 em LOCALIDADE; ao
--   concluí-la, o legado avança a referência de arrecadação do sistema (FuncionalidadeIniciada:286-295 →
--   atualizarAnoMesArrecadacao). Num processo à parte porque a tarefa de cada etapa é montada na INSERÇÃO do processo
--   (ControladorBatchSEJB.inserirProcessoIniciado:339-600) e a de 642 recusa a inserção sem resumo do mês ("Não existem
--   dados do resumo da arrecadação...", :577-581) — o resumo tem de existir antes.
-- · 3302 — o arquivamento das contas pagas: a etapa 653 (GERAR_HISTORICO_CONTA) em SETOR COMERCIAL (8), que escolhe as
--   contas pelos pagamentos CLASSIFICADOS ainda na tabela de pagamentos (RepositorioArrecadacaoHBM.
--   pesquisarContasDePagamentosClassificadosContaEPagamentosAnterioresContaClassificadosNoMes:18461) — por isso antes de
--   642, que tira esses pagamentos de lá. Num processo à parte porque, nesta instalação, ela falha sempre (CEN-ARR-010 V4)
--   e, falhando, deixa as etapas seguintes do mesmo processo EM ESPERA para sempre (exploração do lote 6c).
-- Fora destes processos, com motivo: os acréscimos por impontualidade do encerramento (GERAR_DEBITOS_A_COBRAR_ACRESCIMOS_
-- IMPONTUALIDADE em modo "encerrando a arrecadação", ControladorBatchSEJB:526-542) — exigem índices de acréscimo, tipos de
-- débito de multa, juros e atualização e a regra por categoria; ficam para um lote próprio.
INSERT INTO batch.processo (proc_id, proc_dsprocesso, proc_dsabreviado, proc_icuso, proc_tmultimaalteracao, prtp_id, proc_icautorizacao) VALUES
  (50, 'ENCERRAR ARRECADACAO DO MES (SINTETICO)', 'ENCARR', 1, '2026-01-01 00:00:00', 3, 2),
  (3301, 'ARQUIVAR ARRECADACAO DO MES (SINTETICO)', 'HISTARR', 1, '2026-01-01 00:00:00', 3, 2),
  (3302, 'ARQUIVAR CONTAS PAGAS (SINTETICO)', 'HISTCNT', 1, '2026-01-01 00:00:00', 3, 2);
INSERT INTO batch.processo_funcionalidade (prfn_id, proc_id, fncd_id, unpr_id, prfn_nnsequencialexecucao, prfn_icuso, prfn_tmultimaalteracao) VALUES
  (3302, 50, 546, 6, 1, 1, '2026-01-01 00:00:00'),
  (3303, 3301, 642, 6, 1, 1, '2026-01-01 00:00:00'),
  (3304, 3302, 653, 8, 1, 1, '2026-01-01 00:00:00');
