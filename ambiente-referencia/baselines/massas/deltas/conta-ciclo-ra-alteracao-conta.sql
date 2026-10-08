-- Delta — um RA PENDENTE de IMV-01 (100013) cuja especificação valida ALTERAÇÃO DE CONTA (lote 5d: CEN-FAT-007 V4, a
-- retificação "originada por RA"). Depende de conta-ciclo-catalogos.sql. A variação NÃO aplica conta-ciclo-permissao-
-- sem-ra.sql: sem a permissão RETIFICAR CONTA SEM RA, o legado procura o RA do imóvel (ExibirRetificarContaAction,
-- ControladorRetificarConta.retificarContasReferenciaContabilMenor → atualizarContaCanceladaOuRetificada) e, depois de
-- retificar, o encerra (ControladorRetificarConta.encerrarRA).
--
-- EVIDÊNCIA: a base reconstruída não tem unidade organizacional, meio de solicitação, tipo/especificação de solicitação,
-- tipo de validação de especificação, motivo de encerramento nem tipo de relação do atendimento. O encerramento
-- automático grava o motivo CONCLUSÃO DE SERVIÇO (AtendimentoMotivoEncerramento.CONCLUSAO_SERVICO = 2) e o trâmite
-- ENCERRAR (AtendimentoRelacaoTipo.ENCERRAR = 3) na unidade do usuário — ra_unidade.unid_id é obrigatória: o operador
-- é lotado na unidade de atendimento, como numa instalação em operação.
-- Por que pela massa: o objeto é o efeito do RA sobre a retificação (e o da retificação sobre o RA); a abertura do RA é
-- de CEN-ATE-001. Ids pelas constantes do código onde ele os fixa (código de validação 'C' =
-- EspecificacaoTipoValidacao.ALTERACAO_CONTA; RegistroAtendimento.SITUACAO_PENDENTE = 1); o resto é SINTÉTICO.
INSERT INTO cadastro.unidade_tipo (untp_id, untp_dsunidadetipo, untp_icuso, untp_tmultimaalteracao)
VALUES (1, 'ATENDIMENTO (SINTETICO)', 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.unidade_organizacional (unid_id, unid_dsunidade, unid_dssiglaunidade, untp_id, empr_id, unid_icesgoto, unid_ictramite,
                                             unid_ictarifasocial, unid_icabertura, unid_icuso, unid_tmultimaalteracao, loca_id, greg_id, uneg_id)
VALUES (1, 'UNI-01 ATENDIMENTO (SINTETICO)', 'UNI01', 1, 1, 2, 1, 2, 1, 1, '2026-01-01 00:00:00', 1, 1, 1);
UPDATE seguranca.usuario SET unid_id = 1 WHERE usur_id = 1001;

INSERT INTO atendimentopublico.meio_solicitacao (meso_id, meso_dsmeiosolicitacao, meso_icuso, meso_tmultimaalteracao)
VALUES (1, 'BALCAO (SINTETICO)', 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.solicitacao_tipo_grupo (sotg_id, sotg_dssolicitacaotipogrupo, sotg_icuso, sotg_icesgoto, sotg_tmultimaalteracao)
VALUES (2, 'CONTAS (SINTETICO)', 1, 2, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.solicitacao_tipo (sotp_id, sotp_dssolicitacaotipo, sotg_id, sotp_icfaltaagua, sotp_ictarifasocial, sotp_icuso, sotp_tmultimaalteracao)
VALUES (2, 'REVISAO DE CONTA (SINTETICO)', 2, 2, 2, 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.solicitacao_tipo_espec (step_id, step_dssolcttipoespec, sotp_id, unid_id, step_icgeracaoordemservico, step_icuso,
                                                       step_icligacaoagua, step_icpavimentocalcada, step_icpavimentorua, step_nndiaprazo,
                                                       step_tmultimaalteracao)
VALUES (2, 'RETIFICACAO DE CONTA (SINTETICO)', 2, 1, 2, 1, 2, 2, 2, 10, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.espec_tipo_validacao (estv_id, step_id, estv_dsespecificaotipvalidacao, estv_cdconstante, estv_icuso,
                                                    estv_tmultimaalteracao)
VALUES (1, 2, 'ALTERACAO DE CONTA (SINTETICO)', 'C', 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.atend_motivo_encmt (amen_id, amen_dsmotivoencerramento, amen_icuso, amen_icexecucao, amen_icduplicidade,
                                                   amen_tmultimaalteracao)
VALUES (2, 'CONCLUSAO DO SERVICO (SINTETICO)', 1, 1, 2, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.atendimento_relacao_tipo (attp_id, attp_dsatendimentorelacaotipo, attp_icuso, attp_tmultimaalteracao)
VALUES (3, 'ENCERRAR', 1, '2026-01-01 00:00:00');

INSERT INTO atendimentopublico.registro_atendimento
  (rgat_id, step_id, meso_id, rgat_cdsituacao, rgat_tmregistroatendimento, rgat_dtprevistaoriginal, rgat_dtprevistaatual,
   rgat_icatendimentoonline, imov_id, loca_id, stcm_id, qdra_id, unid_idatual, rgat_tmultimaalteracao)
VALUES (2, 2, 1, 1, '2026-06-15 09:00:00', '2026-06-25', '2026-06-25', 1, 100013, 1, 1, 1, 1, '2026-06-15 09:00:00');
