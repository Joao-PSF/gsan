-- Delta — catálogos mínimos do Atendimento para executar uma OS de ligação de água pela tela do legado (lote 4:
-- CEN-ATE-007, CEN-ATE-008). Depende de territorio-l1.sql, imoveis-imv-01-02-03.sql e seguranca-auditoria.sql (a
-- operação 257 registra transação).
--
-- EVIDÊNCIA: a base reconstruída pelas migrações não tem NENHUMA linha de unidade organizacional, tipo e grupo de
-- solicitação, especificação, tipo/subgrupo/prioridade/perfil de serviço, diâmetro/material/perfil de ligação, nem a
-- situação de débito NORMAL (0) e a forma de cobrança EM CONTA (1) que gerarDebitoOrdemServico grava
-- (ControladorOrdemServicoSEJB:2105-2116). Tipo de financiamento 1 e item contábil 6 vêm das sementes das migrações.
-- Ids por constante do legado onde o código os fixa (citados na linha); o resto é SINTÉTICO.

-- Tipo de categoria (CategoriaTipo.PARTICULAR = 1, PUBLICO = 2). EVIDÊNCIA: as categorias das sementes não têm tipo
-- (cgtp_id nulo) e categoria_tipo está VAZIA; RepositorioImovelHBM.pesquisarObterQuantidadeEconomiasCategoria faz
-- inner join com o tipo, não acha nada, e ControladorImovelSEJB.obterQuantidadeEconomiasCategoria:1466 acusa
-- "imóvel sem subcategoria" — o valor do serviço e o débito da OS nunca seriam calculados. Descrições SINTÉTICAS.
INSERT INTO cadastro.categoria_tipo (cgtp_id, cgtp_dscategoriatipo, cgtp_dsabreviado, cgtp_tmultimaalteracao) VALUES
  (1, 'PARTICULAR', 'PART', '2026-01-01 00:00:00'),
  (2, 'PUBLICO', 'PUBL', '2026-01-01 00:00:00');
UPDATE cadastro.categoria SET cgtp_id = CASE WHEN catg_id = 4 THEN 2 ELSE 1 END WHERE cgtp_id IS NULL;

-- Unidade organizacional UNI-01 (unidade atual do RA e da OS).
INSERT INTO cadastro.unidade_tipo (untp_id, untp_dsunidadetipo, untp_icuso, untp_tmultimaalteracao)
VALUES (1, 'ATENDIMENTO (SINTETICO)', 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.unidade_organizacional (unid_id, unid_dsunidade, unid_dssiglaunidade, untp_id, empr_id, unid_icesgoto, unid_ictramite,
                                             unid_ictarifasocial, unid_icabertura, unid_icuso, unid_tmultimaalteracao, loca_id, greg_id, uneg_id)
VALUES (1, 'UNI-01 ATENDIMENTO (SINTETICO)', 'UNI01', 1, 1, 2, 1, 2, 1, 1, '2026-01-01 00:00:00', 1, 1, 1);

INSERT INTO atendimentopublico.meio_solicitacao (meso_id, meso_dsmeiosolicitacao, meso_icuso, meso_tmultimaalteracao)
VALUES (1, 'BALCAO (SINTETICO)', 1, '2026-01-01 00:00:00');

-- Situação de água FACTÍVEL (LigacaoAguaSituacao.FACTIVEL = 2): a de partida do imóvel da OS. Indicadores SINTÉTICOS
-- (não fatura), como POTENCIAL na massa base.
INSERT INTO atendimentopublico.ligacao_agua_situacao
  (last_id, last_dsligacaoaguasituacao, last_icuso, last_tmultimaalteracao, last_dsabreviado,
   last_icfaturamento, last_nnconsumominimo, last_icexistenciarede, last_icexistencialigacao,
   last_icabastecimento, last_iccadastradaagua, last_icativaagua, last_icdesligadaagua,
   last_icanaliseagua, last_icconsumoreal, last_nndiascorte) VALUES
  (2, 'FACTIVEL', 1, '2026-01-01 00:00:00', 'FAC', 2, 0, 1, 2, 2, 2, 2, 2, 2, 2, NULL);

-- Características da ligação que a tela exige (diâmetro, material, perfil).
INSERT INTO atendimentopublico.ligacao_agua_diametro (lagd_id, lagd_dsligacaoaguadiametro, lagd_icuso, lagd_tmultimaalteracao)
VALUES (1, '3/4 POL (SINTETICO)', 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.ligacao_agua_material (lagm_id, lagm_dsligacaoaguamaterial, lagm_icuso, lagm_tmultimaalteracao)
VALUES (1, 'PVC (SINTETICO)', 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.ligacao_agua_perfil (lapf_id, lapf_dsligacaoaguaperfil, lapf_icuso, lapf_tmultimaalteracao)
VALUES (1, 'NORMAL (SINTETICO)', 1, '2026-01-01 00:00:00');

-- Seletores que a tela de Efetuar Ligação de Água exige não vazios (ExibirEfetuarLigacaoAguaAction.
-- consultaSelectObrigatorio: "Nenhum(a) … encontrado(a)" e HTTP 500 sem eles): motivo de não cobrança e local de
-- instalação do ramal; a origem da ligação é opcional, mas entra para o seletor não ficar vazio. SINTÉTICOS.
INSERT INTO atendimentopublico.servico_nao_cobr_motivo (sncm_id, sncm_dsservnaocobmotivo, sncm_tmultimaalteracao)
VALUES (1, 'CORTESIA (SINTETICO)', '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.ramal_local_instalacao (rlin_id, rlin_dsramallocalinstalcao, rlin_dsabreviado, rlin_icuso, rlin_tmultimaalteracao)
VALUES (1, 'PASSEIO (SINTETICO)', 'PAS', 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.ligacao_origem (lgor_id, lgor_dsligacaoorigem, lgor_dsabreviado, lgor_icuso, lgor_tmultimaalteracao)
VALUES (1, 'REDE PUBLICA', 'RED', 1, '2026-01-01 00:00:00');

-- Motivo de encerramento com execução (AtendimentoMotivoEncerramento.indicadorExecucao = SIM): validaOrdemServico
-- DiasAditivoPrazo só aceita a OS ENCERRADA e executada para a operação comercial posterior. SINTÉTICO.
INSERT INTO atendimentopublico.atend_motivo_encmt (amen_id, amen_dsmotivoencerramento, amen_icuso, amen_icexecucao, amen_icduplicidade,
                                                   amen_tmultimaalteracao)
VALUES (1, 'SERVICO EXECUTADO (SINTETICO)', 1, 1, 2, '2026-01-01 00:00:00');

-- Débito: situação NORMAL (DebitoCreditoSituacao.NORMAL = 0), forma EM CONTA (CobrancaForma.COBRANCA_EM_CONTA = 1) e
-- o tipo de débito do serviço (SINTÉTICO; financiamento 1 SERVICO NORMAL e item contábil 6 OUTROS SERVICOS AGUA das
-- sementes).
INSERT INTO faturamento.debito_credito_situacao (dcst_id, dcst_dsdebitocreditosituacao, dcst_dsabreviado, dcst_tmultimaalteracao)
VALUES (0, 'NORMAL', 'NOR', '2026-01-01 00:00:00');
INSERT INTO cobranca.cobranca_forma (cbfm_id, cbfm_dscobrancaforma, cbfm_dsabreviado, cbfm_icuso, cbfm_tmultimaalteracao)
VALUES (1, 'COBRANCA EM CONTA', 'CONTA', 1, '2026-01-01 00:00:00');
INSERT INTO faturamento.debito_tipo (dbtp_id, dbtp_dsdebitotipo, dbtp_dsabreviado, lict_id, fntp_id, dbtp_icuso,
                                     dbtp_icgeracaoautomatica, dbtp_icgeracaoconta, dbtp_vllimite, dbtp_tmultimaalteracao)
VALUES (3001, 'LIGACAO DE AGUA (SINTETICO)', 'LIGAG', 6, 1, 1, 2, 1, 999999.99, '2026-01-01 00:00:00');

-- Tipo de serviço "ligação de água" (ServicoTipo.TIPO_LIGACAO_AGUA = 619), ligado à operação 257 (Operacao.
-- OPERACAO_LIGACAO_AGUA_EFETUAR) — sem esse vínculo, validarLigacaoAguaExibir derruba a tela (NPE, achado do lote).
-- Valor R$ 100,00 em svtp_vlservico: sem linha em servico_cobranca_valor, obterValorDebito usa o valor do tipo.
INSERT INTO atendimentopublico.servico_tipo_grupo (stgr_id, stgr_dsservicotipogrupo, stgr_dsabreviado, stgr_icuso, stgr_tmultimaalteracao)
VALUES (1, 'LIGACOES (SINTETICO)', 'LIG', 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.servico_tipo_subgrupo (stsg_id, stsg_dsservicotiposubgrupo, stgr_id, stsg_icuso, stsg_tmcadastramento, stsg_tmultimaalteracao)
VALUES (1, 'LIGACAO DE AGUA (SINTETICO)', 1, 1, '2026-01-01 00:00:00', '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.servico_tipo_prioridade (stpr_id, stpr_dsservicotipoprioridade, stpr_icuso, stpr_tmultimaalteracao)
VALUES (1, 'NORMAL (SINTETICO)', 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.servico_perfil_tipo (sptp_id, sptp_dsservicoperfiltipo, sptp_icveiculoproprio, sptp_icuso, sptp_tmultimaalteracao)
VALUES (1, 'EQUIPE PROPRIA (SINTETICO)', 2, 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.servico_tipo
  (svtp_id, svtp_dsservicotipo, svtp_dsabreviado, svtp_vlservico, svtp_icpavimento, svtp_icatualizacomercial, svtp_icterceirizado,
   svtp_cdservicotipo, svtp_nntempomedioexecucao, dbtp_id, stsg_id, sptp_id, stpr_id, svtp_icuso, svtp_icfiscalizacaoinfracao,
   svtp_icvistoria, svtp_icpermitealterarvalor, svtp_iccobrarjuros, svtp_tmultimaalteracao)
VALUES (619, 'LIGACAO DE AGUA (SINTETICO)', 'LIGAG', 100.00, 2, 1, 2, 'O', 60, 3001, 1, 1, 1, 1, 2, 2, 2, 2, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.servico_tipo_operacao (svtp_id, oper_id, stop_tmultimaalteracao)
VALUES (619, 257, '2026-01-01 00:00:00');

-- Tipo de solicitação e especificação que gera a OS (perfil ESP-02 de cenarios-criticos.md §13).
INSERT INTO atendimentopublico.solicitacao_tipo_grupo (sotg_id, sotg_dssolicitacaotipogrupo, sotg_icuso, sotg_icesgoto, sotg_tmultimaalteracao)
VALUES (1, 'LIGACOES (SINTETICO)', 1, 2, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.solicitacao_tipo (sotp_id, sotp_dssolicitacaotipo, sotg_id, sotp_icfaltaagua, sotp_ictarifasocial, sotp_icuso, sotp_tmultimaalteracao)
VALUES (1, 'LIGACAO DE AGUA (SINTETICO)', 1, 2, 2, 1, '2026-01-01 00:00:00');
INSERT INTO atendimentopublico.solicitacao_tipo_espec (step_id, step_dssolcttipoespec, sotp_id, svtp_id, unid_id, step_icgeracaoordemservico,
                                                       step_icuso, step_icligacaoagua, step_icpavimentocalcada, step_icpavimentorua,
                                                       step_nndiaprazo, step_tmultimaalteracao)
VALUES (1, 'LIGACAO DE AGUA NOVA (SINTETICO)', 1, 619, 1, 1, 1, 1, 2, 2, 10, '2026-01-01 00:00:00');

-- Concessões do operador: Efetuar Ligação de Água (funcionalidade 204). A URL efetuarLigacaoAguaAction.do é de duas
-- operações do catálogo (257 e 16045 "com Substituição de Hidrômetro"): as duas, para o filtro aceitar qualquer uma.
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (1001, 257, 204, '2026-01-01 00:00:00'),
  (1001, 16045, 204, '2026-01-01 00:00:00');
