-- Delta — o processo de PRESCRIÇÃO de débitos (lote 5d: CEN-FAT-008 V2). Depende de batch-catalogos.sql.
--
-- EVIDÊNCIA: nenhum processo da base tem a etapa "Gerar Prescrever Débitos de Imóveis" (Funcionalidade.
-- GERAR_PRESCREVER_DEBITOS_DE_IMOVEIS = 1350, cadastrada em seguranca.funcionalidade sem caminho de tela). Processo
-- SINTÉTICO do tipo EVENTUAL (ProcessoTipo.EVENTUAL = 4), sem autorização, com a etapa 1350 numa unidade FUNCIONALIDADE
-- (UnidadeProcessamento.FUNCIONALIDADE = 5: ControladorCobranca.gerarPrescreverDebitosDeImoveis inicia uma unidade só).
-- Concessões do operador: Inserir Processo (funcionalidade 369, operação 466) e Inserir Processo Mensal/Eventual (372,
-- 471) — a tela de onde o processo é iniciado.
INSERT INTO batch.processo (proc_id, proc_dsprocesso, proc_dsabreviado, proc_icuso, proc_tmultimaalteracao, prtp_id, proc_icautorizacao)
VALUES (3101, 'PRESCREVER DEBITOS (SINTETICO)', 'PRES', 1, '2026-01-01 00:00:00', 4, 2);
INSERT INTO batch.processo_funcionalidade (prfn_id, proc_id, fncd_id, unpr_id, prfn_nnsequencialexecucao, prfn_icuso, prfn_tmultimaalteracao)
VALUES (3102, 3101, 1350, 5, 1, 1, '2026-01-01 00:00:00');
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (1001, 466, 369, '2026-01-01 00:00:00'),
  (1001, 471, 372, '2026-01-01 00:00:00');

-- Uma situação de cobrança com cbst_icprescreveparticular = 2. EVIDÊNCIA: cobranca.cobranca_situacao está VAZIA na base; a
-- tarefa monta a lista dessas situações (RepositorioCobrancaHBM.obterCobrancaSituacaoParaPrescreverDebitos) e corta a
-- última vírgula com Util.removerUltimosCaracteres — com a lista vazia, StringIndexOutOfBoundsException no job do Quartz
-- (TarefaBatchGerarPrescreverDebitosDeImoveis:51), antes de qualquer registro: o processo e a etapa ficam EM
-- PROCESSAMENTO para sempre, sem erro gravado (exploração do lote 5d). A lista vai à mensagem do MDB e NÃO é usada pela
-- regra executada (ControladorCobranca.gerarPrescreverDebitosDeImoveis só repassa a referência, a data e o usuário).
-- Indicadores e descrição SINTÉTICOS.
INSERT INTO cobranca.cobranca_situacao (cbst_id, cbst_dscobrancasituacao, cbst_icuso, cbst_tmultimaalteracao, cbst_icbloqueioparcel,
                                        cbst_icbloqueioinclusao, cbst_icbloqueioretirada, cbst_icselecaopermesp,
                                        cbst_icprescreveparticular, cbst_icnaocobranca, cbst_iccancelanegativacao)
VALUES (1, 'COBRANCA JUDICIAL (SINTETICO)', 1, '2026-01-01 00:00:00', 2, 2, 2, 2, 2, 2, 2);
