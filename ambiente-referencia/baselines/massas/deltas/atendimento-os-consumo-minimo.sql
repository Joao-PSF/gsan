-- Delta — OS de "calcular consumo mínimo de água" para o IMV-01 (100013) e o IMV-03 (100030), ENCERRADAS e executadas,
-- para a tela Atualizar Consumo Mínimo da Ligação de Água exibir o "Valor Obtido" (CEN-MIC-002). Depende de
-- atendimento-catalogos.sql.
--
-- EVIDÊNCIA: ExibirAtualizarConsumoMinimoLigacaoAguaAction.preencherDadosImovel chama
-- obterConsumoMinimoLigacao(imovel, null) e exibe o resultado; a validação (ControladorLigacaoAguaSEJB:244-300) exige o
-- serviço com a operação 393 (Operacao.OPERACAO_CONSUMO_MINIMO_LIGACAO_AGUA_ATUALIZAR) ou o tipo 690
-- (ServicoTipo.TIPO_CALCULAR_CONSUMO_MINIMO_AGUA), a OS encerrada e executada e o imóvel COM ligação de água —
-- IMV-01 e IMV-03 são LIGADO na massa, mas sem linha em ligacao_agua.
-- IMV-01 faz o papel do IMV-04 da especificação (sem hidrômetro, residencial, 1 economia). SINTÉTICO.
INSERT INTO atendimentopublico.servico_tipo
  (svtp_id, svtp_dsservicotipo, svtp_dsabreviado, svtp_vlservico, svtp_icpavimento, svtp_icatualizacomercial, svtp_icterceirizado,
   svtp_cdservicotipo, svtp_nntempomedioexecucao, dbtp_id, stsg_id, sptp_id, stpr_id, svtp_icuso, svtp_icfiscalizacaoinfracao,
   svtp_icvistoria, svtp_icpermitealterarvalor, svtp_iccobrarjuros, svtp_tmultimaalteracao)
VALUES (690, 'CALCULAR CONSUMO MINIMO (SINTETICO)', 'CMIN', 0.00, 2, 1, 2, 'O', 30, NULL, 1, 1, 1, 1, 2, 2, 2, 2, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.servico_tipo_operacao (svtp_id, oper_id, stop_tmultimaalteracao)
VALUES (690, 393, '2026-01-01 00:00:00');

INSERT INTO atendimentopublico.ligacao_agua (lagu_id, lagu_dtligacaoagua, lagd_id, lagm_id, lapf_id, lagu_tmultimaalteracao) VALUES
  (100013, '2025-01-01', 1, 1, 1, '2026-01-01 00:00:00'),
  (100030, '2025-01-01', 1, 1, 1, '2026-01-01 00:00:00');

-- Cliente USUÁRIO do IMV-01 (a tela o exige: "Nenhum(a) Cliente encontrado(a)" sem ele); o IMV-03 já tem o seu em
-- clientes-imovel-imv03.sql. Cliente SINTÉTICO de verificação.
INSERT INTO cadastro.cliente_imovel (clim_id, clie_id, imov_id, clim_dtrelacaoinicio, clim_dtrelacaofim, clim_tmultimaalteracao,
                                     crtp_id, clim_icnomeconta)
VALUES (22, 1, 100013, '2026-01-01', NULL, '2026-01-01 00:00:00', 2, 1);

INSERT INTO atendimentopublico.registro_atendimento
  (rgat_id, step_id, meso_id, rgat_cdsituacao, rgat_tmregistroatendimento, rgat_dtprevistaoriginal, rgat_dtprevistaatual,
   rgat_icatendimentoonline, imov_id, loca_id, stcm_id, qdra_id, unid_idatual, rgat_tmultimaalteracao) VALUES
  (2, 1, 1, 1, '2026-09-01 08:00:00', '2026-09-11', '2026-09-11', 1, 100013, 1, 1, 1, 1, '2026-09-01 08:00:00'),
  (3, 1, 1, 1, '2026-09-01 08:00:00', '2026-09-11', '2026-09-11', 1, 100030, 1, 1, 1, 1, '2026-09-01 08:00:00');
INSERT INTO atendimentopublico.ordem_servico
  (orse_id, rgat_id, svtp_id, orse_cdsituacao, orse_tmgeracao, orse_tmencerramento, amen_id, stpr_idoriginal, stpr_idatual,
   orse_iccomercialatualizado, orse_icdiagnostico, unid_idatual, imov_id, orse_vlservicooriginal, orse_vlservicoatual,
   orse_tmultimaalteracao) VALUES
  (2, 2, 690, 2, '2026-09-01 08:00:00', '2026-09-05 10:00:00', 1, 1, 1, 2, 2, 1, 100013, 0.00, 0.00, '2026-09-05 10:00:00'),
  (3, 3, 690, 2, '2026-09-01 08:00:00', '2026-09-05 10:00:00', 1, 1, 1, 2, 2, 1, 100030, 0.00, 0.00, '2026-09-05 10:00:00');

-- Concessões do operador: Atualizar Consumo Mínimo da Ligação de Água (funcionalidade 282; operações 393 e 344 do
-- catálogo).
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (1001, 393, 282, '2026-01-01 00:00:00'),
  (1001, 344, 282, '2026-01-01 00:00:00');
