-- Delta — um RA PENDENTE de IMV-01 (100013) cuja especificação permite GUIA DE DEVOLUÇÃO (lote 6b: CEN-ARR-004 V2). NÃO se
-- combina com conta-ciclo-ra-alteracao-conta.sql (lote 5d), que cria a mesma unidade, meio e grupo de solicitação.
--
-- EVIDÊNCIA: a guia de devolução nasce de um RA (InserirGuiaDevolucaoAction: "Informe Registro de Atendimento") aberto,
-- com imóvel, cuja especificação tem o indicador de GERAÇÃO DE CRÉDITO ligado — senão
-- "atencao.registro_atendimento.nao.permite.guia.devolucao" (ControladorArrecadacao.validarExibirInserirGuiaDevolucao:32016).
-- A base reconstruída não tem unidade organizacional, meio, tipo/especificação de solicitação nem RA. Por que pela massa: o
-- objeto é a devolução do pagamento; a abertura do RA é de CEN-ATE-001. Situação PENDENTE pela constante
-- (RegistroAtendimento.SITUACAO_PENDENTE = 1); o resto — unidade, meio, tipo, especificação, datas — é SINTÉTICO.
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
VALUES (3, 'DEVOLUCAO DE VALORES (SINTETICO)', 2, 2, 2, 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.solicitacao_tipo_espec (step_id, step_dssolcttipoespec, sotp_id, unid_id, step_icgeracaoordemservico, step_icuso,
                                                       step_icligacaoagua, step_icpavimentocalcada, step_icpavimentorua, step_nndiaprazo,
                                                       step_icgeracaocredito, step_tmultimaalteracao)
VALUES (3, 'DEVOLUCAO PAGTO DUPLICIDADE (SINTETICO)', 3, 1, 2, 1, 2, 2, 2, 10, 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.registro_atendimento
  (rgat_id, step_id, meso_id, rgat_cdsituacao, rgat_tmregistroatendimento, rgat_dtprevistaoriginal, rgat_dtprevistaatual,
   rgat_icatendimentoonline, imov_id, loca_id, stcm_id, qdra_id, unid_idatual, rgat_tmultimaalteracao)
VALUES (3, 3, 1, 1, '2026-06-15 09:00:00', '2026-06-25', '2026-06-25', 1, 100013, 1, 1, 1, 1, '2026-06-15 09:00:00');
