-- Delta — território em degraus para a abrangência (CEN-SEG-007; cenarios-criticos.md §13.4, "Território").
-- Depende de territorio-l1.sql e de imoveis-imv-01-02-03.sql (L1 = G1/U1/elo L1; IMV-01 100013 em L1).
--
-- Cada localidade nova fica UM degrau fora de L1, para que cada nível de abrangência tenha um imóvel dentro e
-- um fora (ControladorAcessoSEJB.verificarAcessoAbrangencia, :4153-4235):
--   L3  mesmo elo de L1 (loca_cdelo = 1), mesma unidade e gerência  → separa LOCALIDADE de ELO
--   L4  elo próprio, unidade U1, gerência G1                        → separa ELO de UNIDADE
--   L5  elo próprio, unidade U2 (de G1)                             → separa UNIDADE de GERÊNCIA
--   L2  elo próprio, unidade U3, gerência G2                        → fora da gerência
-- carregarAbrangencia (:4310-4325) deriva a unidade e a gerência do imóvel pelo ELO da localidade
-- (imovel.localidade.localidade.unidadeNegocio), não pela própria localidade: aqui as duas coincidem.
--
-- Um imóvel por localidade, como o IMV-01 (residencial, 1 economia, mesma tarifa e logradouro):
--   IMV-A3 100048 em L3 · IMV-A4 100056 em L4 · IMV-A5 100064 em L5 · IMV-A2 100072 em L2
-- Matrículas: número-base 10004..10007 seguido do dígito módulo 11 de gcom.util.Util.obterDigitoVerificadorModulo11.
-- Tudo SINTÉTICO.
--
-- loca_nnconsumograndeusuario: a coluna aceita nulo, mas Localidade.hbm.xml a mapeia num int primitivo
-- (consumoGrandeUsuario): carregar a ENTIDADE Localidade com o valor nulo falha (PropertyAccessException/NPE —
-- achado F2-29). Um usuário lotado numa localidade carrega a entidade já no login. Valor 0 — o "não informado" da
-- tela de Atualizar Localidade (ExibirAtualizarLocalidadeAction:492) — em L1 (só para quem aplica este delta) e
-- nas localidades novas. SINTÉTICO.
UPDATE cadastro.localidade SET loca_nnconsumograndeusuario = 0 WHERE loca_id = 1;
INSERT INTO cadastro.gerencia_regional (greg_id, greg_nmregional, greg_nmabreviado, greg_icuso, greg_tmultimaalteracao)
VALUES (2, 'GERENCIA SINTETICA 2', 'GS2', 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.unidade_negocio (uneg_id, greg_id, uneg_nmunidadenegocio, uneg_nmabreviado, uneg_icuso, uneg_tmultimaalteracao) VALUES
  (2, 1, 'UNIDADE NEGOCIO SINTETICA 2', 'UN2', 1, '2026-01-01 00:00:00'),
  (3, 2, 'UNIDADE NEGOCIO SINTETICA 3', 'UN3', 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.localidade (loca_id, loca_nmlocalidade, loca_cdelo, greg_id, uneg_id, loca_icuso, loca_icinformatizada,
                                 loca_icsede, loca_tmultimaalteracao, muni_idprincipal, loca_nnconsumograndeusuario) VALUES
  (3, 'LOCALIDADE L3 (SINTETICA)', 1, 1, 1, 1, 1, 2, '2026-01-01 00:00:00', 1, 0),
  (4, 'LOCALIDADE L4 (SINTETICA)', 4, 1, 1, 1, 1, 1, '2026-01-01 00:00:00', 1, 0),
  (5, 'LOCALIDADE L5 (SINTETICA)', 5, 1, 2, 1, 1, 1, '2026-01-01 00:00:00', 1, 0),
  (2, 'LOCALIDADE L2 (SINTETICA)', 2, 2, 3, 1, 1, 1, '2026-01-01 00:00:00', 1, 0);
INSERT INTO cadastro.setor_comercial (stcm_id, loca_id, stcm_cdsetorcomercial, stcm_nmsetorcomercial, stcm_icuso, muni_id,
                                      stcm_tmultimaalteracao, stcm_icalternativo) VALUES
  (3, 3, 1, 'SETOR 1 DE L3 (SINTETICO)', 1, 1, '2026-01-01 00:00:00', 2),
  (4, 4, 1, 'SETOR 1 DE L4 (SINTETICO)', 1, 1, '2026-01-01 00:00:00', 2),
  (5, 5, 1, 'SETOR 1 DE L5 (SINTETICO)', 1, 1, '2026-01-01 00:00:00', 2),
  (2, 2, 1, 'SETOR 1 DE L2 (SINTETICO)', 1, 1, '2026-01-01 00:00:00', 2);
INSERT INTO micromedicao.rota (rota_id, lttp_id, empr_id, rota_icuso, rota_tmultimaalteracao, ftgr_id, stcm_id, cbgr_id, rota_cdrota,
                               empr_idcobranca, rota_icalternativa, rota_ictransmissaooffline, rota_icdividerota,
                               rota_icimpressaotermicafinalgrupo) VALUES
  (3, 1, 1, 1, '2026-01-01 00:00:00', 1, 3, 1, 1, 1, 2, 2, 2, 2),
  (4, 1, 1, 1, '2026-01-01 00:00:00', 1, 4, 1, 1, 1, 2, 2, 2, 2),
  (5, 1, 1, 1, '2026-01-01 00:00:00', 1, 5, 1, 1, 1, 2, 2, 2, 2),
  (2, 1, 1, 1, '2026-01-01 00:00:00', 1, 2, 1, 1, 1, 2, 2, 2, 2);
INSERT INTO cadastro.quadra (qdra_id, stcm_id, qdra_nnquadra, rota_id, qdra_icuso, qdra_tmultimaalteracao, qdra_icautoincrementolote,
                             bair_id, qdra_icredeagua, qdra_icredeesgoto) VALUES
  (3, 3, 1, 3, 1, '2026-01-01 00:00:00', 2, 1, 1, 1),
  (4, 4, 1, 4, 1, '2026-01-01 00:00:00', 2, 1, 1, 1),
  (5, 5, 1, 5, 1, '2026-01-01 00:00:00', 2, 1, 1, 1),
  (2, 2, 1, 2, 1, '2026-01-01 00:00:00', 2, 1, 1, 1);

INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota) VALUES
  (100048, 3, 3, 3, 1, 0, '40', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 1),
  (100056, 4, 4, 4, 1, 0, '50', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 1),
  (100064, 5, 5, 5, 1, 0, '60', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 1),
  (100072, 2, 2, 2, 1, 0, '70', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 1);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao) VALUES
  (100048, 101, 1, '2026-01-01 00:00:00'),
  (100056, 101, 1, '2026-01-01 00:00:00'),
  (100064, 101, 1, '2026-01-01 00:00:00'),
  (100072, 101, 1, '2026-01-01 00:00:00');
