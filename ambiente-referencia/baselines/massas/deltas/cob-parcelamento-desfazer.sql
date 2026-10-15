-- Delta — o que o DESFAZIMENTO do parcelamento exige (lote 7c: CEN-COB-005). Depende de cob-parcelamento-catalogos.sql e de
-- arr-processo-classificar.sql (as concessões de Inserir Processo).
--
-- EVIDÊNCIA (base reconstruída):
-- · cobranca.parcel_motivo_desfazer está VAZIA: a tela Consultar Parcelamento lista os motivos para o Desfazer
--   (ExibirConsultarParcelamentoDebitoAction:272-274) e o desfazimento automático grava ENTRADA NÃO PAGA
--   (ParcelamentoMotivoDesfazer.ENTRADA_NAO_PAGA = 4; ControladorCobranca.desfazerParcelamentosPorEntradaNaoPaga
--   SemAnoMesReferencia:61928).
-- · O desfazimento automático grava o desfazimento em nome do usuário de ROTINA BATCH (RepositorioUsuarioHBM
--   .pesquisarUsuarioRotinaBatch: usur_icrotinabatch = 1) — a base não tem nenhum: sem ele,
--   "atencao.usuario_rotina_batch_nao_cadastrado". Um usuário SINTÉTICO próprio, sem senha (não autentica) e sem grupo,
--   distinto do operador do executor.
-- · A etapa da instalação é a 16044 (Desfazer Parcel por Entrada nao Paga sem ano mes faturamento — no processo 49 da
--   base, que não tem tipo de processo e não aparece em Inserir Processo); um processo SINTÉTICO EVENTUAL 3307 com ela,
--   em unidade FUNCIONALIDADE (iniciarUnidadeProcessamentoBatch(..., FUNCIONALIDADE, 0)).
-- · Concessões do operador: Consultar Parcelamento de Débitos (funcionalidade 331) com as operações que as migrações
--   concedem ao grupo administrador nela — entre elas Desfazer Parcelamento do Débito (516) — e a tela do parcelamento
--   (funcionalidade 389, a da URL exibirConsultarParcelamentoDebitoAction.do e da operação 516).
-- Situações de parcelamento DESFEITO (2), CONCLUÍDO (3) e CANCELADO (4) (ParcelamentoSituacao; a massa do lote 5b só tem
-- NORMAL): o desfazimento grava DESFEITO (atualizarParcelamento:6288) — sem ela, a gravação falha por chave estrangeira
-- (fk12_parcelamento) e a etapa termina COM ERRO (exploração).
INSERT INTO cobranca.parcelamento_situacao (pcst_id, pcst_dsparcelamentosituacao, pcst_dsabreviado, pcst_tmultimaalteracao) VALUES
  (2, 'DESFEITO', 'DES', '2026-01-01 00:00:00'),
  (3, 'CONCLUIDO', 'CON', '2026-01-01 00:00:00'),
  (4, 'CANCELADO', 'CAN', '2026-01-01 00:00:00');
INSERT INTO cobranca.parcel_motivo_desfazer (pmdz_id, pmdz_dsparcmtmotivodesfazer, pmdz_icuso, pmdz_tmultimaalteracao) VALUES
  (4, 'ENTRADA NAO PAGA', 1, '2026-01-01 00:00:00'),
  (7101, 'PEDIDO DO CLIENTE (SINTETICO)', 1, '2026-01-01 00:00:00');
INSERT INTO seguranca.usuario
  (usur_id, utip_id, usur_nmlogin, usur_nmsenha, usur_tmultimaalteracao, usst_id, usab_id, empr_id,
   usur_nmusuario, usur_ictiporelatoriopadrao, usur_icexibemensagem, usur_icrotinabatch, usur_icinternet)
VALUES (1002, 1, 'rot.batch', NULL, '2026-01-01 00:00:00', 1, 1, 1,
        'ROTINA BATCH (SINTETICO)', 1, 1, 1, 2);
INSERT INTO batch.processo (proc_id, proc_dsprocesso, proc_dsabreviado, proc_icuso, proc_tmultimaalteracao, prtp_id, proc_icautorizacao) VALUES
  (3307, 'DESFAZER PARC ENTRADA NAO PAGA (SINT)', 'DESFPARC', 1, '2026-01-01 00:00:00', 3, 2);
INSERT INTO batch.processo_funcionalidade (prfn_id, proc_id, fncd_id, unpr_id, prfn_nnsequencialexecucao, prfn_icuso, prfn_tmultimaalteracao) VALUES
  (3308, 3307, 16044, 5, 1, 1, '2026-01-01 00:00:00');
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao)
SELECT 1001, oper_id, 331, '2026-01-01 00:00:00' FROM seguranca.grupo_func_operacao WHERE grup_id = 1 AND fncd_id = 331;
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (1001, 516, 389, '2026-01-01 00:00:00');
