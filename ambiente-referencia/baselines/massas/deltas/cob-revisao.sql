-- Delta — o que COLOCAR CONTA EM REVISÃO exige (lote 7: CEN-COB-001 V1b). Depende de conta-ciclo-catalogos.sql (a
-- concessão de Manter Conta).
--
-- EVIDÊNCIA: faturamento.conta_motivo_revisao está VAZIA (a tela não teria motivo a escolher); a operação Colocar Conta em
-- Revisão não está concedida ao operador (a URL colocarRevisaoContaAction.do é de duas operações do catálogo: 56 em Manter
-- Conta (44) e 1050 em Colocar Conta em Revisão (196), cuja tela é exibirColocarRevisaoContaAction.do — as duas); e, para uma
-- conta vencida há mais de parm_nndiasrevcompermespecial (30) dias, ColocarRevisaoContaAction:94-112 exige a permissão
-- especial ENVIAR_CONTA_PARA_REVISAO (PermissaoEspecial = 94), que não existe na base — sem ela a recusa dependeria do
-- relógio (dias de atraso contados até HOJE). Motivo e permissão SINTÉTICOS com os ids das constantes; a permissão
-- referencia a operação de colocar em revisão.
INSERT INTO faturamento.conta_motivo_revisao (cmrv_id, cmrv_dsmotivorevisaoconta, cmrv_icuso, cmrv_tmultimaalteracao, crmv_iccancnegatconta)
VALUES (7101, 'REVISAO SINTETICA', 1, '2026-01-01 00:00:00', 2);
INSERT INTO seguranca.permissao_especial (pmep_id, pmep_dspermissaoespecial, pmep_icuso, pmep_tmultimaalteracao, oper_id)
VALUES (94, 'ENVIAR CONTA PARA REVISAO', 1, '2026-01-01 00:00:00', 56);
INSERT INTO seguranca.usuario_permissao_espec (usur_id, pmep_id, upes_tmultimaalteracao) VALUES (1001, 94, '2026-01-01 00:00:00');
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (1001, 56, 44, '2026-01-01 00:00:00'),
  (1001, 1050, 196, '2026-01-01 00:00:00');
