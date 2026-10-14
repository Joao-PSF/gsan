-- Delta — o que a GERAÇÃO dos acréscimos por impontualidade no encerramento da arrecadação grava (lote 7: CEN-ARR-002 V2b).
-- Depende de batch-catalogos.sql, de arr-processo-classificar.sql (as concessões de Inserir Processo), de
-- fat-lancamentos-catalogos.sql (a forma de cobrança EM CONTA que o débito a cobrar exige — CobrancaForma.COBRANCA_EM_CONTA) e de
-- cob-acrescimos-indices.sql.
--
-- EVIDÊNCIA: a etapa GERAR_DEBITOS_A_COBRAR_ACRESCIMOS_IMPONTUALIDADE (Funcionalidade 188) inserida por Inserir Processo
-- monta a tarefa "encerrando a arrecadação" — multa, juros e atualização ligados, todas as rotas
-- (ControladorBatchSEJB.inserirProcessoIniciado:526-542) — e, por rota (UnidadeProcessamento.ROTA = 1), a variante COSANPA
-- (ControladorFaturamentoCOSANPASEJB.gerarDebitosACobrarDeAcrescimosPorImpontualidade:2382) gera débitos a cobrar de MULTA
-- (DebitoTipo.MULTA_IMPONTUALIDADE = 80), JUROS (JUROS_MORA = 91) e ATUALIZAÇÃO (ATUALIZACAO_MONETARIA = 94) para as contas
-- com pagamento CLASSIFICADO no mês, calculados com a menor data de pagamento (:2540-2576). A base não tem esses tipos de
-- débito (faturamento.debito_tipo só tem 2441, 2442, 2516) nem processo com a etapa 188.
-- Tipos de débito SINTÉTICOS com os ids das constantes; item contábil ACRÉSCIMOS POR IMPONTUALIDADE (2, já na base);
-- financiamento SERVIÇO NORMAL (1, já na base). Processo SINTÉTICO MENSAL 3305, sem autorização, num processo próprio
-- (as tarefas são montadas na inserção).
INSERT INTO faturamento.debito_tipo (dbtp_id, lict_id, dbtp_dsdebitotipo, dbtp_dsabreviado, dbtp_icuso, dbtp_tmultimaalteracao, fntp_id,
                                     dbtp_icgeracaoautomatica, dbtp_icgeracaoconta, dbtp_iccartaocredito, dbtp_icguiajurosctrparcel) VALUES
  (80, 2, 'MULTA POR IMPONTUALIDADE', 'MULTA', 1, '2026-01-01 00:00:00', 1, 1, 1, 2, 2),
  (91, 2, 'JUROS DE MORA', 'JUROS', 1, '2026-01-01 00:00:00', 1, 1, 1, 2, 2),
  (94, 2, 'ATUALIZACAO MONETARIA', 'ATUALIZ', 1, '2026-01-01 00:00:00', 1, 1, 1, 2, 2);
INSERT INTO batch.processo (proc_id, proc_dsprocesso, proc_dsabreviado, proc_icuso, proc_tmultimaalteracao, prtp_id, proc_icautorizacao) VALUES
  (3305, 'GERAR ACRESCIMOS IMPONT (SINTETICO)', 'ACRESC', 1, '2026-01-01 00:00:00', 3, 2);
INSERT INTO batch.processo_funcionalidade (prfn_id, proc_id, fncd_id, unpr_id, prfn_nnsequencialexecucao, prfn_icuso, prfn_tmultimaalteracao) VALUES
  (3306, 3305, 188, 1, 1, 1, '2026-01-01 00:00:00');
