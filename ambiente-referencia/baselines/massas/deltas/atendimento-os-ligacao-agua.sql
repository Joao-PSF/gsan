-- Delta — RA e OS de ligação de água ENCERRADA como executada, ainda sem a atualização comercial, para um imóvel com
-- água FACTÍVEL (CEN-ATE-007 V1, CEN-ATE-008).
-- Depende de atendimento-catalogos.sql e de clientes-imovel-imv03.sql (tipos de relação cliente × imóvel).
--
-- Por que por SQL: o objeto destes cenários é o EFEITO da execução da OS (operação "Efetuar Ligação de Água"); a
-- abertura do RA e a geração da OS são de CEN-ATE-002. O RA e a OS nascem aqui no estado em que a abertura os deixaria
-- (RegistroAtendimento.SITUACAO_PENDENTE = 1; OrdemServico.SITUACAO_ENCERRADO = 2, motivo com execução,
-- orse_iccomercialatualizado = 2). EVIDÊNCIA: fora do encerramento, a operação "Efetuar Ligação de Água" só aceita
-- OS ENCERRADA, executada e com o comercial ainda não atualizado (ControladorOrdemServicoSEJB.
-- validaOrdemServicoDiasAditivoPrazo:13840) — o efeito cadastral é da operação, não do encerramento.
--
-- IMV-A01 100200 (número-base 10020 + dígito módulo 11 0): residencial, 1 economia, água FACTÍVEL (2), esgoto
-- POTENCIAL (1), na quadra 6 de L1/setor 1 — quadra COM REDE de água e esgoto (Quadra.COM_REDE = 2).
-- ⚠️ A quadra 1 de territorio-l1.sql grava qdra_icredeagua = 1, que pela constante é SEM_REDE (Quadra.SEM_REDE = 1):
-- a operação recusaria a ligação ("situação de rede de água da quadra", ControladorLocalidadeSEJB.integracaoQuadraFace).
-- territorio-l1.sql não muda (as baselines que o usam não dependem da rede). Datas, ids e valores SINTÉTICOS.
INSERT INTO cadastro.quadra (qdra_id, stcm_id, qdra_nnquadra, rota_id, qdra_icuso, qdra_tmultimaalteracao, qdra_icautoincrementolote,
                             bair_id, qdra_icredeagua, qdra_icredeesgoto)
VALUES (6, 1, 6, 1, 1, '2026-01-01 00:00:00', 2, 1, 2, 2);
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota)
VALUES (100200, 1, 1, 6, 20, 0, '200', 2, 2, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 20);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100200, 101, 1, '2026-01-01 00:00:00');

-- Cliente USUÁRIO do imóvel: a tela de Efetuar Ligação de Água o exige (ExibirEfetuarLigacaoAguaAction.pesquisarCliente,
-- "Nenhum(a) … encontrado(a)" sem ele). Cliente SINTÉTICO de verificação (clie_id 1).
INSERT INTO cadastro.cliente_imovel (clim_id, clie_id, imov_id, clim_dtrelacaoinicio, clim_dtrelacaofim, clim_tmultimaalteracao,
                                     crtp_id, clim_icnomeconta)
VALUES (21, 1, 100200, '2026-01-01', NULL, '2026-01-01 00:00:00', 2, 1);

INSERT INTO atendimentopublico.registro_atendimento
  (rgat_id, step_id, meso_id, rgat_cdsituacao, rgat_tmregistroatendimento, rgat_dtprevistaoriginal, rgat_dtprevistaatual,
   rgat_icatendimentoonline, imov_id, loca_id, stcm_id, qdra_id, unid_idatual, rgat_tmultimaalteracao)
VALUES (1, 1, 1, 1, '2026-09-01 08:00:00', '2026-09-11', '2026-09-11', 1, 100200, 1, 1, 6, 1, '2026-09-01 08:00:00');

INSERT INTO atendimentopublico.ordem_servico
  (orse_id, rgat_id, svtp_id, orse_cdsituacao, orse_tmgeracao, orse_tmencerramento, amen_id, stpr_idoriginal, stpr_idatual,
   orse_iccomercialatualizado, orse_icdiagnostico, unid_idatual, imov_id, orse_vlservicooriginal, orse_vlservicoatual,
   orse_tmultimaalteracao)
VALUES (1, 1, 619, 2, '2026-09-01 08:00:00', '2026-09-05 10:00:00', 1, 1, 1, 2, 2, 1, 100200, 100.00, 100.00,
        '2026-09-05 10:00:00');
