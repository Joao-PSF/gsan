-- Delta — catálogos do framework batch e da micromedição para executar o FATURAMENTO EM GRUPO pelo legado, no EAR em
-- modo Batch (lote 5). Ids pelas constantes do código; descrições SINTÉTICAS.
--
-- EVIDÊNCIA (base reconstruída pelas migrações):
-- · batch.processo_situacao, funcionalidade_situacao e unidade_situacao estão VAZIAS — o framework grava as situações
--   pelas constantes de ProcessoSituacao, FuncionalidadeSituacao e UnidadeSituacao;
-- · faturamento.faturamento_atividade está VAZIA — a atividade FATURAR_GRUPO (FaturamentoAtividade = 5) aponta o
--   processo que o comando inicia (ControladorBatchSEJB.inserirProcessoIniciadoFaturamentoComandado:2678);
-- · o processo 2 (Processo.FATURAR_GRUPO_FATURAMENTO) existe, mas a sua etapa de faturar (funcionalidade 63,
--   Funcionalidade.FATURAR_GRUPO_FATURAMENTO) NÃO está em batch.processo_funcionalidade: só estão as etapas acessórias
--   1297 (e-mail da conta), 16087 (crédito Bolsa Água) e 16090 (registrar boletos);
-- · o processo 2 não tem tipo de processo;
-- · micromedicao.consumo_tipo e ligacao_tipo estão VAZIAS.
-- Configuração SINTÉTICA do processo 2: a etapa 63 entra (sequência 1, unidade ROTA) e as três acessórias ficam fora de
-- uso — a caracterização é do faturamento, não do e-mail, da Bolsa Água nem dos boletos.

INSERT INTO batch.processo_situacao (prst_id, prst_dsprocessosituacao, prst_dsabreviado, prst_icuso, prst_tmultimaalteracao) VALUES
  (1, 'EM PROCESSAMENTO', 'PROC', 1, '2026-01-01 00:00:00'),
  (2, 'CONCLUIDO', 'CONC', 1, '2026-01-01 00:00:00'),
  (3, 'EM ESPERA', 'ESPE', 1, '2026-01-01 00:00:00'),
  (4, 'AGENDADO', 'AGEN', 1, '2026-01-01 00:00:00'),
  (5, 'INICIO A COMANDAR', 'COMA', 1, '2026-01-01 00:00:00'),
  (6, 'CONCLUIDO COM ERRO', 'CERR', 1, '2026-01-01 00:00:00'),
  (7, 'EXECUCAO CANCELADA', 'CANC', 1, '2026-01-01 00:00:00'),
  (8, 'AGUARD AUTORIZACAO', 'AUTO', 1, '2026-01-01 00:00:00');
INSERT INTO batch.funcionalidade_situacao (fnst_id, fnst_dsoperacaosituacao, fnst_dsabreviado, fnst_icuso, fnst_tmultimaalteracao) VALUES
  (1, 'EM PROCESSAMENTO', 'PROC', 1, '2026-01-01 00:00:00'),
  (2, 'CONCLUIDA', 'CONC', 1, '2026-01-01 00:00:00'),
  (3, 'EM ESPERA', 'ESPE', 1, '2026-01-01 00:00:00'),
  (4, 'CONCLUIDA COM ERRO', 'CERR', 1, '2026-01-01 00:00:00'),
  (5, 'AGENDADA', 'AGEN', 1, '2026-01-01 00:00:00'),
  (6, 'EXECUCAO CANCELADA', 'CANC', 1, '2026-01-01 00:00:00'),
  (7, 'AGUARD AUTORIZACAO', 'AUTO', 1, '2026-01-01 00:00:00');
INSERT INTO batch.unidade_situacao (unst_id, unst_dsoperacaosituacao, unst_dsabreviado, unst_icuso, unst_tmultimaalteracao) VALUES
  (1, 'EM PROCESSAMENTO', 'PROC', 1, '2026-01-01 00:00:00'),
  (2, 'CONCLUIDA', 'CONC', 1, '2026-01-01 00:00:00'),
  (3, 'EM ESPERA', 'ESPE', 1, '2026-01-01 00:00:00'),
  (4, 'CONCLUIDA COM ERRO', 'CERR', 1, '2026-01-01 00:00:00');

INSERT INTO faturamento.faturamento_atividade (ftat_id, ftat_dsfaturamentoatividade, ftat_idatividadeprecedente, ftat_icobrigatoriedade,
                                               ftat_icrepeticao, ftat_iccomando, ftat_icuso, ftat_tmultimaalteracao,
                                               ftat_nnordemrealizacao, proc_id)
VALUES (5, 'FATURAR GRUPO', NULL, 1, 2, 1, 1, '2026-01-01 00:00:00', 5, 2);

-- O processo 2 da base não tem tipo (prtp_id nulo): ControladorBatchSEJB.verificarAutorizacaoBatch:6272 o lê sem testar e
-- o início do processo quebra (NPE). Tipo FATURAMENTO COMANDADO (ProcessoTipo.FATURAMENTO_COMANDADO = 1).
UPDATE batch.processo SET prtp_id = 1 WHERE proc_id = 2;

INSERT INTO batch.processo_funcionalidade (prfn_id, proc_id, fncd_id, unpr_id, prfn_nnsequencialexecucao, prfn_icuso, prfn_tmultimaalteracao)
VALUES (3001, 2, 63, 1, 1, 1, '2026-01-01 00:00:00');
UPDATE batch.processo_funcionalidade SET prfn_icuso = 2 WHERE proc_id = 2 AND fncd_id IN (1297, 16087, 16090);

INSERT INTO micromedicao.ligacao_tipo (lgti_id, lgti_dsligacaotipo, lgti_icuso, lgti_tmultimaalteracao) VALUES
  (1, 'AGUA', 1, '2026-01-01 00:00:00'),
  (2, 'ESGOTO', 1, '2026-01-01 00:00:00');
INSERT INTO micromedicao.consumo_tipo (cstp_id, cstp_dsconsumotipo, cstp_dsabreviadaconsumotipo, cstp_icuso, cstp_iccalculomedia,
                                       cstp_tmultimaalteracao) VALUES
  (0, 'INDEFINIDO', 'IND', 1, 2, '2026-01-01 00:00:00'),
  (1, 'REAL', 'REA', 1, 1, '2026-01-01 00:00:00'),
  (2, 'CONS MEDIO AJUSTADO', 'CMA', 1, 2, '2026-01-01 00:00:00'),
  (3, 'MEDIA HIDROMETRO', 'MHI', 1, 2, '2026-01-01 00:00:00'),
  (4, 'INFORMADO', 'INF', 1, 2, '2026-01-01 00:00:00'),
  (5, 'NAO MEDIDO', 'NME', 1, 2, '2026-01-01 00:00:00'),
  (6, 'ESTIMADO', 'EST', 1, 2, '2026-01-01 00:00:00'),
  (7, 'CONS MINIMO FIXADO', 'CMF', 1, 2, '2026-01-01 00:00:00'),
  (8, 'SEM CONSUMO', 'SEM', 1, 2, '2026-01-01 00:00:00'),
  (9, 'MEDIA IMOVEL', 'MIM', 1, 2, '2026-01-01 00:00:00');

-- Situação de débito/crédito NORMAL (DebitoCreditoSituacao.NORMAL = 0): a conta gerada nasce nela; a base só tem PAGA
-- (13) e a inserção da conta falha por chave estrangeira (fk16_conta).
INSERT INTO faturamento.debito_credito_situacao (dcst_id, dcst_dsdebitocreditosituacao, dcst_dsabreviado, dcst_tmultimaalteracao)
VALUES (0, 'NORMAL', 'NOR', '2026-01-01 00:00:00');

-- Tipos de conta (gcom.faturamento.conta.ContaTipo, 1 a 6): a conta para impressão de toda conta gerada aponta um deles
-- (CONTA_NORMAL = 5 no caso comum); a tabela está VAZIA e a gravação falha por chave estrangeira (fk5_conta_impressao).
INSERT INTO faturamento.conta_tipo (cttp_id, cttp_dstipoconta, cttp_icuso, cttp_tmultimaalteracao) VALUES
  (1, 'RETIDA POR EC', 1, '2026-01-01 00:00:00'),
  (2, 'RETIDA POR BC', 1, '2026-01-01 00:00:00'),
  (3, 'CLIENTE RESPONSAVEL', 1, '2026-01-01 00:00:00'),
  (4, 'DEBITO AUTOMATICO', 1, '2026-01-01 00:00:00'),
  (5, 'NORMAL', 1, '2026-01-01 00:00:00'),
  (6, 'DEB AUTO CLI RESP', 1, '2026-01-01 00:00:00');

-- Concessão do operador: Inserir Processo Faturamento Comandado (funcionalidade 374, operação 473).
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao)
VALUES (1001, 473, 374, '2026-01-01 00:00:00');
