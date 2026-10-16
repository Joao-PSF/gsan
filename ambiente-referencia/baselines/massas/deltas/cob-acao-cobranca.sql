-- Delta — o que a AÇÃO DE COBRANÇA (aviso de corte) comandada exige (lote 8: CEN-COB-002, CEN-COB-007). Depende de
-- batch-catalogos.sql, de arr-processo-classificar.sql e da massa base (grupo de cobrança 1 na rota 1 de IMV-01/02/03).
--
-- EVIDÊNCIA (base reconstruída: nenhuma ação, atividade, critério, situação de ação ou de débito de cobrança):
-- · Inserir Comando de Ação de Cobrança eventual (InserirComandoAcaoCobrancaEventualConcluirAction →
--   ControladorCobranca.concluirComandoAcaoCobranca) grava o comando (cobranca_acao_ativ_cmd) para a ação, a atividade e o
--   grupo de cobrança; Inserir Processo de Cobrança Comandado (ControladorBatchSEJB.inserirProcessoCobrancaAtividadeEventual
--   :3472) inicia o PROCESSO DA ATIVIDADE (cobranca_atividade.proc_id) com as suas etapas — GERAR ATIVIDADE DE AÇÃO DE
--   COBRANÇA (Funcionalidade 539), por rota (TarefaBatchGerarAtividadeAcaoCobranca → BatchGerarAtividadeAcaoCobrancaMDB →
--   ControladorCobranca.gerarAtividadeAcaoCobranca:56518).
-- · Com o critério da ROTA (indicador 1), o critério é o da rota para a ação (cobranca.rota_acao_criterio,
--   pesquisarCriterioCobrancaRota); as linhas do critério (por categoria e perfil: valor e quantidade de contas) e as
--   situações de ligação de água (crit_situacao_lig_agua) decidem os imóveis.
-- · O documento gerado aponta a forma de emissão (DocumentoEmissaoForma.EVENTUAL = 2), a situação da ação
--   (CobrancaAcaoSituacao.PENDENTE = 1) e, cada item, a situação do débito (CobrancaDebitoSituacao.PENDENTE = 1).
-- Ids das constantes (CobrancaAcao.AVISO_CORTE = 1; CobrancaAtividade.SIMULAR/EMITIR/ENCERRAR = 1/2/3; DocumentoTipo
-- AVISO_CORTE = 12, DOCUMENTO_COBRANCA = 3); descrições, critério e valores SINTÉTICOS. O processo 3309 tem a etapa de
-- geração e a de ATUALIZAR COMANDO (1311: os totais e a realização do comando, por unidade COB ACAO ATIV COMAND = 11): a
-- de emissão (1312) só escreve o arquivo da gráfica no disco do servidor — fora da fronteira.
INSERT INTO cobranca.cobranca_debito_situacao (cdst_id, cdst_dssituacaodebito, cdst_icuso, cdst_tmultimaalteracao) VALUES
  (1, 'PENDENTE', 1, '2026-01-01 00:00:00'), (2, 'PAGO', 1, '2026-01-01 00:00:00'), (3, 'PARCELADO', 1, '2026-01-01 00:00:00'),
  (4, 'CANCELADO', 1, '2026-01-01 00:00:00'), (5, 'SEM DEBITOS', 1, '2026-01-01 00:00:00');
INSERT INTO cobranca.cobranca_acao_situacao (cast_id, cast_dssituacaoacao, cast_dsabreviada, cast_icuso, cast_tmultimaalteracao) VALUES
  (1, 'PENDENTE', 'PEND', 1, '2026-01-01 00:00:00'), (2, 'EXECUTADA', 'EXEC', 1, '2026-01-01 00:00:00'),
  (3, 'CANCELADA', 'CANC', 1, '2026-01-01 00:00:00'), (4, 'CANCELADA PRAZO', 'CPRZ', 1, '2026-01-01 00:00:00'),
  (5, 'FISCALIZADA', 'FISC', 1, '2026-01-01 00:00:00'), (6, 'ENVIADOS', 'ENVI', 1, '2026-01-01 00:00:00'),
  (7, 'SUSPENSA PAG PARC CANC', 'SUSP', 1, '2026-01-01 00:00:00'), (8, 'SUSPENSA PAG PARC CANC ATE', 'SUSA', 1, '2026-01-01 00:00:00'),
  (9, 'SUSPENSA PAG PARC CANC APOS', 'SUSD', 1, '2026-01-01 00:00:00');
INSERT INTO cobranca.documento_emissao_forma (demf_id, demf_dsdocumentoemissaoforma, demf_tmultimaalteracao) VALUES
  (1, 'CRONOGRAMA', '2026-01-01 00:00:00'), (2, 'EVENTUAL', '2026-01-01 00:00:00'), (3, 'INDIVIDUAL', '2026-01-01 00:00:00'),
  (4, 'IMPRESSAO SIMULTANEA', '2026-01-01 00:00:00');
INSERT INTO cobranca.documento_tipo (dotp_id, dotp_dsdocumentotipo, dotp_dsabreviado, dotp_icpagavel, dotp_icuso, dotp_tmultimaalteracao) VALUES
  (3, 'DOCUMENTO DE COBRANCA', 'DOCCOB', 1, 1, '2026-01-01 00:00:00'),
  (12, 'AVISO DE CORTE', 'AVCORTE', 1, 1, '2026-01-01 00:00:00');
-- Motivos de não geração: a base reconstruída só tem o 28; cada imóvel recusado grava o motivo (imovel_nao_gerado) e, sem
-- ele, a chave estrangeira aborta a rota inteira (a etapa termina CONCLUIDA COM ERRO). Os ids e os nomes vêm das constantes
-- de MotivoNaoGeracaoDocCobranca (2 a 27).
INSERT INTO cobranca.motivo_nao_ger_doc_cobr (mngd_id, mngd_dsmotivo, mngd_icuso, mngd_tmultimaalteracao) VALUES
  (2, 'IMOVEL EXCLUIDO', 1, '2026-01-01 00:00:00'),
  (3, 'NAO EXISTE DOCUMENTO PRECEDENTE VALIDO', 1, '2026-01-01 00:00:00'),
  (4, 'NAO EXISTE OS ACAO PRECEDENTE EXECUTADA PRAZO', 1, '2026-01-01 00:00:00'),
  (5, 'EXISTE DOCUMENTO VALIDO ACAO SUCESSORA', 1, '2026-01-01 00:00:00'),
  (6, 'EXISTE DOCUMENTO VALIDO MESMO TIPO', 1, '2026-01-01 00:00:00'),
  (7, 'SITUACAO LIGACAO AGUA INVALIDA', 1, '2026-01-01 00:00:00'),
  (8, 'SITUACAO LIGACAO ESGOTO INVALIDA', 1, '2026-01-01 00:00:00'),
  (9, 'IMOVEL EM SITUACAO ESPECIAL COBRANCA', 1, '2026-01-01 00:00:00'),
  (10, 'IMOVEL EM SITUACAO COBRANCA NAO PERMITIDA', 1, '2026-01-01 00:00:00'),
  (11, 'CRITERIO NAO PERMITE SITUACAO COBRANCA', 1, '2026-01-01 00:00:00'),
  (12, 'NAO HA CRITERIO PARA O PERFIL', 1, '2026-01-01 00:00:00'),
  (13, 'IMOVEL SEM DEBITOS', 1, '2026-01-01 00:00:00'),
  (14, 'CRITERIO NAO PERMITE DEBITO APENAS CONTA MES', 1, '2026-01-01 00:00:00'),
  (15, 'CRITERIO NAO PERMITE DEBITO APENAS CONTA ANTIGA', 1, '2026-01-01 00:00:00'),
  (16, 'CRITERIO NAO PERMITE DEB CONTA MES E ANTIGA', 1, '2026-01-01 00:00:00'),
  (17, 'VALOR DEBITO FORA INTERVALO CRITERIO', 1, '2026-01-01 00:00:00'),
  (18, 'QTD ITENS FORA INTERVALO CRITERIO', 1, '2026-01-01 00:00:00'),
  (19, 'VALOR DEBITO AUTOMATICO MENOR QUE MINIMO', 1, '2026-01-01 00:00:00'),
  (20, 'QTD ITENS MENOR MINIMA DEBITO AUTOMATICO', 1, '2026-01-01 00:00:00'),
  (21, 'VALOR DEBITO MENOR MINIMO INQUILINO', 1, '2026-01-01 00:00:00'),
  (22, 'VALOR DEBITO MENOR MINIMO INQUILINO CONTA MES', 1, '2026-01-01 00:00:00'),
  (23, 'QTD CONTAS PARCELADAS MENOR QUE MINIMA', 1, '2026-01-01 00:00:00'),
  (24, 'EXCEDEU METAS', 1, '2026-01-01 00:00:00'),
  (25, 'CONSUMO MEDIO FORA INTERVALO CRITERIO', 1, '2026-01-01 00:00:00'),
  (26, 'SITUACAO FISCALIZACAO NAO ATENDE CRITERIO', 1, '2026-01-01 00:00:00'),
  (27, 'QTD CONTAS INVALIDA PARA PARCELAMENTO', 1, '2026-01-01 00:00:00');
-- Critério SINTÉTICO: vigente, conta antiga 0, sem os "emitir para imóvel com…" (paralisação, situação de cobrança, conta
-- em revisão, inquilino só com a conta do mês), mas EMITINDO para débito só da conta do mês e só de conta antiga — com
-- "não", o imóvel com uma única conta é recusado (motivos 14 e 15: com conta antiga 0, toda conta é "antiga"); uma linha
-- para RESIDENCIAL (1) × perfil 5 (o dos três imóveis): de R$ 0,01 a R$ 99.999,99 e de 1 a 99 contas.
INSERT INTO cobranca.cobranca_criterio (cbct_id, cbct_dscobrancacriterio, cbct_dtiniciovigencia, cbct_icuso, cbct_nncontaantiga,
                                        cbct_icemsimvparalisacao, cbct_tmultimaalteracao, cbct_icemsimvsitcob, cbct_icemissaodebitocontames,
                                        cbct_icemissaocontarevisao, cbct_icemsinqdebcontames, cbct_icemsdebcontaantiga,
                                        cbct_pcvlminimopgparccanc, cbct_pcqtminimopgparccanc, cbct_vllimiteprioridade) VALUES
  (7101, 'CRITERIO AVISO SINTETICO', '2026-01-01', 1, 0, 2, '2026-01-01 00:00:00', 2, 1, 2, 2, 1, 0.00, 0.00, 0.00);
INSERT INTO cobranca.cobranca_criterio_linha (cbcl_id, cbcl_vlminimodebito, cbcl_qtminimacontas, catg_id, iper_id, cbct_id, cbcl_vlmaximodebito,
                                              cbcl_vlmindebdebaut, cbcl_qtmaximacontas, cbcl_qtmincontasdebaut, cbcl_vlminimocontames,
                                              cbcl_tmultimaalteracao, cbcl_qtmincontasparcmt) VALUES
  (7101, 0.01, 1, 1, 5, 7101, 99999.99, 0.01, 99, 1, 0.00, '2026-01-01 00:00:00', 0);
INSERT INTO cobranca.crit_situacao_lig_agua (cbct_id, last_id, csla_tmultimaalteracao) VALUES (7101, 3, '2026-01-01 00:00:00');
-- Ação AVISO DE CORTE (1): documento AVISO DE CORTE, ligação de água LIGADO (3), o critério 7101, com acréscimos, sem OS
-- (sem tipo de serviço), sem cronograma, validade de 30 dias, vencimento em 10.
INSERT INTO cobranca.cobranca_acao (cbac_id, cbac_dscobrancaacao, cbac_icobrigatoriedade, cbac_icrepeticao, cbac_icsuspensaoabastecimento,
                                    cbac_nndiasvalidade, cbac_nndiasminacaoprecedente, cbac_icuso, cbac_tmultimaalteracao, svtp_id, dotp_id,
                                    last_id, lest_id, cbac_iccobrancadebacobrar, cbac_icgeracaotaxa, cbac_nnordemrealizacao, cbct_id,
                                    cbac_icacrescimoimpontualidade, cbac_iccronograma, cbac_icboletim, cbac_icdebito, cbac_nndiasvencimento,
                                    cbac_icusametas, cbac_icusaordenamentocron, cbac_icusaordenamentoeven, cbac_icdebitointerfereacao,
                                    cbac_iccreditoarealizar, cbac_icnotapromissoria, cbac_icordmaiorvlr, cbac_icvalitemcobrado,
                                    cbac_icaceitardcriterio, cbac_iccpfcnpjvalido) VALUES
  (1, 'AVISO DE CORTE', 2, 1, 2, 30, 0, 1, '2026-01-01 00:00:00', NULL, 12, 3, NULL, 2, 2, 1, 7101, 1, 2, 2, 1, 10, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2);
INSERT INTO cobranca.rota_acao_criterio (rota_id, cbac_id, cbct_id, racc_tmultimaalteracao) VALUES (1, 1, 7101, '2026-01-01 00:00:00');
INSERT INTO batch.processo (proc_id, proc_dsprocesso, proc_dsabreviado, proc_icuso, proc_tmultimaalteracao, prtp_id, proc_icautorizacao) VALUES
  (3309, 'GERAR ATIV ACAO COBRANCA (SINTETICO)', 'ATIVCOB', 1, '2026-01-01 00:00:00', 3, 2);
INSERT INTO batch.processo_funcionalidade (prfn_id, proc_id, fncd_id, unpr_id, prfn_nnsequencialexecucao, prfn_icuso, prfn_tmultimaalteracao) VALUES
  (3310, 3309, 539, 1, 1, 1, '2026-01-01 00:00:00'),
  (3311, 3309, 1311, 11, 2, 1, '2026-01-01 00:00:00');
INSERT INTO cobranca.cobranca_atividade (cbat_id, cbat_idatividadeprecedente, cbat_dscobrancaatividade, cbat_iccomando, cbat_icexecucao, cbat_icuso,
                                         cbat_tmultimaalteracao, cbat_nnordemrealizacao, cbat_iccronograma, proc_id, cbat_icobrigatoriedade,
                                         cbat_nndiasexecucao, cbac_id) VALUES
  (1, NULL, 'SIMULAR', 1, 1, 1, '2026-01-01 00:00:00', 1, 2, 3309, 2, 0, NULL),
  (2, NULL, 'EMITIR', 1, 1, 1, '2026-01-01 00:00:00', 2, 2, 3309, 1, 0, NULL),
  (3, 2, 'ENCERRAR', 1, 1, 1, '2026-01-01 00:00:00', 3, 2, NULL, 2, 0, NULL);
-- Concessões do operador: Inserir Comando de Ação de Cobrança (117) com as operações que as migrações concedem ao grupo
-- administrador nela; a tela do comando eventual por rota (413) e Inserir Processo de Cobrança Comandado (373), pelas
-- operações do catálogo (528, 472).
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao)
SELECT 1001, oper_id, 117, '2026-01-01 00:00:00' FROM seguranca.grupo_func_operacao WHERE grup_id = 1 AND fncd_id = 117;
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (1001, 528, 413, '2026-01-01 00:00:00'),
  (1001, 472, 373, '2026-01-01 00:00:00');
