-- Delta — catálogos e parâmetros para executar a CONSISTÊNCIA DE LEITURAS E CÁLCULO DE CONSUMOS pelo legado, no EAR em
-- modo Batch (lote 5c). Depende de batch-catalogos.sql (situações do framework, tipos de consumo e de ligação).
--
-- EVIDÊNCIA (base reconstruída):
-- · nenhum processo tem a etapa Consistir Leituras e Calcular Consumos (Funcionalidade 52); faturamento_atividade VAZIA;
-- · TODA a Micromedição está vazia: tipo de medição, situação e anormalidade de leitura, anormalidade de consumo, as
--   ações paramétricas da anormalidade (consumo e leitura a faturar), tipo de rateio, hidrômetros e os seus catálogos;
-- · o parâmetro de faturamento CONSUMO_MINIMO_BOLSA_AGUA não existe — a consistência o lê com Integer.valueOf para todo
--   imóvel com ligação de água (ControladorMicromedicao.determinarDadosFaturamentoAgua);
-- · sistema_parametros.parm_nnmesescalcmediacons (meses da média de consumo) é NULO — o cálculo da média o lê como número;
-- · os limites de consumo das categorias (alto, baixo, estouro) são NULOS.
-- Ids pelas constantes do código (FaturamentoAtividade, Funcionalidade, MedicaoTipo, LeituraSituacao,
-- ConsumoAnormalidade, LeituraAnormalidadeConsumo, LeituraAnormalidadeLeitura, HidrometroSituacao). Processo, valores
-- dos parâmetros, limites e descrições SINTÉTICOS.
INSERT INTO batch.processo (proc_id, proc_dsprocesso, proc_dsabreviado, proc_icuso, proc_tmultimaalteracao, prtp_id, proc_icautorizacao)
VALUES (3001, 'CONSISTIR LEITURAS (SINTETICO)', 'CONS', 1, '2026-01-01 00:00:00', 1, 2);
INSERT INTO batch.processo_funcionalidade (prfn_id, proc_id, fncd_id, unpr_id, prfn_nnsequencialexecucao, prfn_icuso, prfn_tmultimaalteracao)
VALUES (3002, 3001, 52, 1, 1, 1, '2026-01-01 00:00:00');
INSERT INTO faturamento.faturamento_atividade (ftat_id, ftat_dsfaturamentoatividade, ftat_idatividadeprecedente, ftat_icobrigatoriedade,
                                               ftat_icrepeticao, ftat_iccomando, ftat_icuso, ftat_tmultimaalteracao,
                                               ftat_nnordemrealizacao, proc_id) VALUES
  (2, 'EFETUAR LEITURA', NULL, 1, 2, 2, 1, '2026-01-01 00:00:00', 2, NULL),
  (9, 'CONSISTIR LEITURAS', NULL, 1, 2, 1, 1, '2026-01-01 00:00:00', 4, 3001);

INSERT INTO micromedicao.medicao_tipo (medt_id, medt_dsmedicaotipo, medt_icuso, medt_tmultimaalteracao) VALUES
  (1, 'LIGACAO DE AGUA', 1, '2026-01-01 00:00:00'),
  (2, 'POCO', 1, '2026-01-01 00:00:00');
INSERT INTO micromedicao.leitura_situacao (ltst_id, ltst_dsleiturasituacao, ltst_icuso, ltst_tmultimaalteracao) VALUES
  (1, 'REALIZADA', 1, '2026-01-01 00:00:00'),
  (2, 'NAO REALIZADA', 1, '2026-01-01 00:00:00'),
  (3, 'CONFIRMADA', 1, '2026-01-01 00:00:00'),
  (4, 'LEITURA ALTERADA', 1, '2026-01-01 00:00:00');
INSERT INTO micromedicao.consumo_anormalidade (csan_id, csan_dsconsumoanormalidade, csan_dsabrvconsanormalidade, csan_icuso,
                                               csan_tmultimaalteracao, csan_iccalcularmedia) VALUES
  (2, 'CONSUMO INFORMADO', 'INF', 1, '2026-01-01 00:00:00', 2),
  (4, 'BAIXO CONSUMO', 'BXC', 1, '2026-01-01 00:00:00', 1),
  (5, 'ESTOURO DE CONSUMO', 'EST', 1, '2026-01-01 00:00:00', 2),
  (6, 'ALTO CONSUMO', 'ALT', 1, '2026-01-01 00:00:00', 1),
  (7, 'LEIT ATUAL MENOR PROJET', 'LMP', 1, '2026-01-01 00:00:00', 2),
  (8, 'LEIT ATUAL MENOR ANTERIOR', 'LMA', 1, '2026-01-01 00:00:00', 2),
  (9, 'HIDROMETRO SUBST INFORM', 'HSI', 1, '2026-01-01 00:00:00', 2),
  (10, 'LEITURA NAO INFORMADA', 'LNI', 1, '2026-01-01 00:00:00', 2),
  (11, 'ESTOURO COBRANCA MEDIA', 'ECM', 1, '2026-01-01 00:00:00', 2),
  (12, 'CONSUMO MINIMO FIXADO', 'CMF', 1, '2026-01-01 00:00:00', 2),
  (13, 'FORA DE FAIXA', 'FFX', 1, '2026-01-01 00:00:00', 1),
  (14, 'HIDROMETRO SUBST NAO INF', 'HSN', 1, '2026-01-01 00:00:00', 2),
  (15, 'FATURAMENTO ANTECIPADO', 'FAN', 1, '2026-01-01 00:00:00', 2),
  (16, 'VIRADA DE HIDROMETRO', 'VIR', 1, '2026-01-01 00:00:00', 1),
  (17, 'ANORMALIDADE DE LEITURA', 'ANL', 1, '2026-01-01 00:00:00', 2);
-- Tipo de rateio (gcom.micromedicao.RateioTipo): todo consumo gravado pela consistência aponta um — SEM RATEIO (0)
-- no caso comum; a tabela está VAZIA e a gravação falha por chave estrangeira (fk2_consumo_historico).
INSERT INTO micromedicao.rateio_tipo (rttp_id, rttp_dsrateiotipo, rttp_icuso, rttp_tmultimaalteracao) VALUES
  (0, 'SEM RATEIO', 1, '2026-01-01 00:00:00'),
  (4, 'RATEIO NAO MEDIDO AGUA', 1, '2026-01-01 00:00:00'),
  (5, 'RATEIO AREA COMUM', 1, '2026-01-01 00:00:00');
INSERT INTO micromedicao.leitura_anorm_consumo (lacs_id, lacs_dsconsumoacobrar, lacs_icsemleitura, lacs_iccomleitura, lacs_icuso,
                                                lacs_tmultimaalteracao) VALUES
  (0, 'NAO OCORRE', 1, 1, 1, '2026-01-01 00:00:00'),
  (1, 'MINIMO', 1, 1, 1, '2026-01-01 00:00:00'),
  (2, 'MEDIA', 1, 1, 1, '2026-01-01 00:00:00'),
  (3, 'NORMAL', 1, 1, 1, '2026-01-01 00:00:00'),
  (4, 'MAIOR MEDIA OU MEDIDO', 1, 1, 1, '2026-01-01 00:00:00'),
  (5, 'MENOR MEDIA OU MEDIDO', 1, 1, 1, '2026-01-01 00:00:00'),
  (7, 'FIXO', 1, 1, 1, '2026-01-01 00:00:00'),
  (8, 'NAO MEDIDO', 1, 1, 1, '2026-01-01 00:00:00');
INSERT INTO micromedicao.leitura_anorm_leitura (lalt_id, lalt_dsleituraafaturar, lalt_icsemleitura, lalt_iccomleitura, lalt_icuso,
                                                lalt_tmultimaalteracao) VALUES
  (0, 'ANTERIOR MAIS MEDIA', 1, 1, 1, '2026-01-01 00:00:00'),
  (1, 'ANTERIOR', 1, 1, 1, '2026-01-01 00:00:00'),
  (2, 'ANTERIOR MAIS CONSUMO', 1, 1, 1, '2026-01-01 00:00:00'),
  (3, 'INFORMADA', 1, 1, 1, '2026-01-01 00:00:00'),
  (4, 'NORMAL', 1, 1, 1, '2026-01-01 00:00:00');
-- Anormalidade de leitura SINTÉTICA "imóvel fechado": sem leitura, cobra a MÉDIA e fatura a leitura ANTERIOR + MÉDIA;
-- com leitura, NORMAL / INFORMADA. Fatores 1.
INSERT INTO micromedicao.leitura_anormalidade (ltan_id, ltan_dsleituraanormalidade, ltan_icrelativohidrometro, ltan_icimovelsemhidrometro,
                                               ltan_icusosistema, ltan_icemissaoordemservico, ltan_icuso, lacs_idconsacobrarsemleit,
                                               lacs_idconsacobrarcomleit, lalt_idleitafaturarsemleit, lalt_idleitafaturarcomleit,
                                               ltan_icperdatarifasocial, ltan_tmultimaalteracao, ltan_nnfatorsemleitura,
                                               ltan_nnfatorcomleitura, ltan_icleitura, ltan_dsabrevleituraanormalidad,
                                               ltan_icimpressaosimultanea, ltan_icexibirrelatorio, ltan_iccalcadamsg,
                                               ltan_icsubshidrometrormsg, ltan_icnaoimprimirconta)
VALUES (101, 'IMOVEL FECHADO (SINT)', 1, 2, 2, 2, 1, 2, 3, 0, 3, 2, '2026-01-01 00:00:00', 1.00, 1.00, 2, 'FECH', 2, 2, 2, 2, 2);

INSERT INTO micromedicao.hidrometro_marca (himc_id, himc_dshidrometromarca, himc_dsabreviadahidrmarca, himc_nndiarevisao, himc_icuso,
                                           himc_tmultimaalteracao, himc_cdhidrometromarca, himc_icmicro, himc_icmacro)
VALUES (1, 'MARCA SINTETICA', 'MS', 1825, 1, '2026-01-01 00:00:00', 'MS', 1, 2);
INSERT INTO micromedicao.hidrometro_capacidade (hicp_id, hicp_dshidrometrocapacidade, hicp_dsabreviadahidrcapacidade, hicp_nndigitosleituraminimo,
                                                hicp_nndigitosleituramaximo, hicp_icuso, hicp_tmultimaalteracao, hicp_nnordem,
                                                hicp_cdhidrometrocapacidade)
VALUES (1, '1,5 M3/H (SINTETICO)', '1,5', 4, 6, 1, '2026-01-01 00:00:00', 1, 'A');
INSERT INTO micromedicao.hidrometro_tipo (hitp_id, hitp_dshidrometrotipo, hitp_dcabreviadahidrometrotipo, hitp_icuso, hitp_tmultimaalteracao)
VALUES (1, 'VELOCIMETRICO (SINT)', 'VEL', 1, '2026-01-01 00:00:00');
INSERT INTO micromedicao.hidrometro_diametro (hidm_id, hidm_dshidrometrodiametro, hidm_dsabreviadahidrdiametro, hidm_icuso,
                                              hidm_tmultimaalteracao, hidm_nnordem)
VALUES (1, '3/4 POL (SINTETICO)', '3/4', 1, '2026-01-01 00:00:00', 1);
INSERT INTO micromedicao.hidrometro_situacao (hist_id, hist_dshidrometrosituacao, hist_icuso, hist_tmultimaalteracao, hist_ichidrometroextraviado) VALUES
  (1, 'INSTALADO', 1, '2026-01-01 00:00:00', 2),
  (2, 'EM MANUTENCAO', 1, '2026-01-01 00:00:00', 2),
  (3, 'DISPONIVEL', 1, '2026-01-01 00:00:00', 2);
INSERT INTO micromedicao.hidrometro_classe_metrlg (hicm_id, hicm_dshidrclassemetrologica, hicm_dsabrvhidmtclassemetl, hicm_icuso, hicm_tmultimaalteracao)
VALUES (1, 'CLASSE B (SINTETICO)', 'B', 1, '2026-01-01 00:00:00');
INSERT INTO micromedicao.hidrometro_local_inst (hili_id, hili_dshidmtlocalinstalacao, hili_dsabrvhidmtlocinstalacao, hili_icuso, hili_tmultimaalteracao)
VALUES (1, 'MURO (SINTETICO)', 'MUR', 1, '2026-01-01 00:00:00');
INSERT INTO micromedicao.hidrometro_protecao (hipr_id, hipr_dshidrometroprotecao, hipr_dsabrvhidmtprotecao, hipr_icuso, hipr_tmultimaalteracao)
VALUES (1, 'CAIXA (SINTETICO)', 'CX', 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.ligacao_agua_diametro (lagd_id, lagd_dsligacaoaguadiametro, lagd_icuso, lagd_tmultimaalteracao)
VALUES (1, '3/4 POL (SINTETICO)', 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.ligacao_agua_material (lagm_id, lagm_dsligacaoaguamaterial, lagm_icuso, lagm_tmultimaalteracao)
VALUES (1, 'PVC (SINTETICO)', 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.ligacao_agua_perfil (lapf_id, lapf_dsligacaoaguaperfil, lapf_icuso, lapf_tmultimaalteracao)
VALUES (1, 'NORMAL (SINTETICO)', 1, '2026-01-01 00:00:00');

INSERT INTO faturamento.parametro (id, nome, valor) VALUES (101, 'CONSUMO_MINIMO_BOLSA_AGUA', '10');
UPDATE cadastro.sistema_parametros SET parm_nnmesescalcmediacons = 6;
UPDATE cadastro.categoria SET catg_nnconsumoalto = 50, catg_nnmediabaixoconsumo = 10, catg_nnvezesmediaaltoconsumo = 2.0,
                              catg_pcmediabaixoconsumo = 50.00, catg_nnconsumoestouro = 100, catg_nnvezesmediaestouro = 3.0;
