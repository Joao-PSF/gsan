-- Delta — o que a manutenção de conta (retificar, cancelar) exige e a base reconstruída não tem (lote 5d: CEN-FAT-007,
-- CEN-FAT-008). Depende de batch-catalogos.sql (situação NORMAL), de imoveis-imv-01-02-03.sql e de
-- seguranca-auditoria.sql (as duas operações registram transação).
--
-- EVIDÊNCIA (base reconstruída pelas migrações):
-- · faturamento.debito_credito_situacao só tem PAGA (13) — e NORMAL (0) pela massa do lote 5. Retificar grava
--   CANCELADA POR RETIFICAÇÃO (4) e RETIFICADA (1) (ControladorRetificarConta.retificarContasReferenciaContabilMenor);
--   cancelar grava CANCELADA (3) ou DÉBITO PRESCRITO (8) (ControladorFaturamentoFINAL.cancelarConta); a prescrição em lote
--   grava 8 e 12 (RepositorioCobrancaHBM.prescreverDebitosDeImoveis*). Ids das constantes de DebitoCreditoSituacao.
-- · faturamento.conta_motivo_retificacao e conta_mot_cancelamento estão VAZIAS: as telas de retificar e de cancelar
--   recusam-se a abrir sem motivo ("atencao.pesquisa.nenhum_registro_tabela").
-- · seguranca.permissao_especial não tem RETIFICAR CONTA SEM RA (48) nem CANCELAR CONTA SEM RA (51)
--   (PermissaoEspecial): sem a permissão, a operação exige um RA do imóvel com especificação de ALTERAÇÃO DE CONTA.
-- · IMV-01 não tem cliente USUÁRIO: Manter Conta, de onde se cancela, recusa o imóvel sem ele (atencao.naocadastrado).
-- · o parâmetro de faturamento CONSUMO_MINIMO_BOLSA_AGUA não existe: RetificarContaAction:81 o lê para TODA conta, antes
--   de olhar o perfil do imóvel — sem ele, a retificação termina em HTTP 500 (NoSuchElementException em
--   ControladorFaturamento.getFaturamentoParametro). Mesmo valor SINTÉTICO de mic-catalogos.sql (lote 5c).
-- Ids de motivo SINTÉTICOS (34xx, 35xx), exceto o motivo DÉBITO PRESCRITO (ContaMotivoCancelamento.DEBITO_PRESCRITO = 64),
-- que o código grava pelo id. Descrições SINTÉTICAS.

INSERT INTO faturamento.debito_credito_situacao (dcst_id, dcst_dsdebitocreditosituacao, dcst_dsabreviado, dcst_tmultimaalteracao) VALUES
  (1, 'RETIFICADA', 'RET', '2026-01-01 00:00:00'),
  (2, 'INCLUIDA', 'INC', '2026-01-01 00:00:00'),
  (3, 'CANCELADA', 'CAN', '2026-01-01 00:00:00'),
  (4, 'CANCELADA POR RETIFICACAO', 'CRE', '2026-01-01 00:00:00'),
  (8, 'DEBITO PRESCRITO', 'PRE', '2026-01-01 00:00:00'),
  (12, 'DEBITO PRESCRITO INCLUIDAS', 'PRI', '2026-01-01 00:00:00');

INSERT INTO faturamento.conta_motivo_retificacao (cmrt_id, cmrt_dsmotivoretificacaoconta, cmrt_icuso, cmrt_tmultimaalteracao,
                                                  cmrt_nnocorrmesmomotivonoano, cmrt_iccompetenciaconsumo) VALUES
  (3401, 'ECONOMIAS ERRADAS (SINTETICO)', 1, '2026-01-01 00:00:00', NULL, 2),
  (3402, 'CONSUMO ERRADO (SINTETICO)', 1, '2026-01-01 00:00:00', NULL, 2);

INSERT INTO faturamento.conta_mot_cancelamento (cmcn_id, cmcn_dsmotivocancelamentoconta, cmcn_icuso, cmcn_tmultimaalteracao) VALUES
  (3501, 'CANCELAMENTO A PEDIDO (SINTETICO)', 1, '2026-01-01 00:00:00'),
  (64, 'DEBITO PRESCRITO (SINTETICO)', 1, '2026-01-01 00:00:00');

INSERT INTO faturamento.parametro (id, nome, valor) VALUES (101, 'CONSUMO_MINIMO_BOLSA_AGUA', '10');

INSERT INTO seguranca.permissao_especial (pmep_id, pmep_dspermissaoespecial, pmep_icuso, pmep_tmultimaalteracao, oper_id) VALUES
  (48, 'RETIFICAR CONTA SEM RA', 1, '2026-01-01 00:00:00', 261),
  (51, 'CANCELAR CONTA SEM RA', 1, '2026-01-01 00:00:00', 230);

-- Concessões do operador: Manter Conta (funcionalidade 44, operação 57 com a URL da funcionalidade), Cancelar Conta (a
-- URL cancelarContaAction.do é de duas operações do catálogo: 230 em Manter Conta e 1049 em Cancelar Conta — as duas)
-- e Retificar Conta (funcionalidade 200: 261 retificar, 256 calcular valores).
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (1001, 57, 44, '2026-01-01 00:00:00'),
  (1001, 230, 44, '2026-01-01 00:00:00'),
  (1001, 1049, 198, '2026-01-01 00:00:00'),
  (1001, 261, 200, '2026-01-01 00:00:00'),
  (1001, 256, 200, '2026-01-01 00:00:00');

-- Cliente USUÁRIO de IMV-01 (o cliente SINTÉTICO de verificação, clie_id 1, pessoa física PARTICULAR). Tipos de relação
-- pelas constantes de ClienteRelacaoTipo (PROPRIETARIO = 1, USUARIO = 2, RESPONSAVEL = 3).
INSERT INTO cadastro.cliente_relacao_tipo (crtp_id, crtp_dsclienterelacaotipo, crtp_icuso, crtp_tmultimaalteracao) VALUES
  (1, 'PROPRIETARIO', 1, '2026-01-01 00:00:00'),
  (2, 'USUARIO', 1, '2026-01-01 00:00:00'),
  (3, 'RESPONSAVEL', 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.cliente_imovel (clim_id, clie_id, imov_id, clim_dtrelacaoinicio, clim_dtrelacaofim, clim_tmultimaalteracao,
                                     crtp_id, clim_icnomeconta)
VALUES (5001, 1, 100013, '2026-01-01', NULL, '2026-01-01 00:00:00', 2, 1);

-- Referência de faturamento do sistema = a do grupo (05/2026), como numa instalação em operação durante o mês: a base
-- parou em 201410 (F2-70, F2-80). A retificação e o cancelamento decidem por ela (situação anterior, referência
-- contábil, retificar em lugar ou gerar conta nova).
-- Meses da média de consumo (parm_nnmesescalcmediacons), NULOS na base: a retificação que muda o consumo e confirma
-- "substituir o consumo para o cálculo da média" os lê como número (RepositorioMicromedicaoHBM.
-- pesquisaConsumoHistoricoSubstituirConsumo:5292) — sem eles, NPE e "erro de acesso ao banco". Mesmo valor SINTÉTICO de
-- mic-catalogos.sql (lote 5c).
UPDATE cadastro.sistema_parametros SET parm_amreferenciafaturamento = 202605, parm_nnmesescalcmediacons = 6;
