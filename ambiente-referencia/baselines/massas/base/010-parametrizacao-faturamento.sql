-- Massa base — parametrização comercial para cálculo da conta (Fase 2, lote piloto).
--
-- Tudo aqui é SINTÉTICO: nenhum valor vem de companhia real. Onde o código do legado fixa um
-- identificador por constante, o identificador é o da constante (evidência na linha); o resto
-- (descrições, indicadores, valores de tarifa) é escolhido para a caracterização e declarado
-- como tal. Carimbos de tempo fixos: a massa é idêntica em toda aplicação.
--
-- Perfil TAR-01 (cenarios-criticos.md §13.5): tarifa com DUAS vigências e faixas por categoria.
-- A 2ª vigência (2026-07-16) cai no meio de julho de 2026: referências até 06/2026 têm uma só
-- vigência no período de leitura (CEN-FAT-001); 07/2026 atravessa a mudança (CEN-FAT-002).
-- ⚠️ Relógio: obterConsumoMinimoLigacao lê a vigência em vigor na data CORRENTE do servidor
-- (RepositorioMicromedicaoHBM.pesquisarMaiorDataVigenciaConsumoTarifaImovel, `new Date()`), não
-- a da referência. Por isso toda vigência desta massa é anterior à primeira captura (2026-09-30):
-- o resultado não muda com a data da execução. O executor confere essa pré-condição.

-- Tipos de cálculo de tarifa — gcom.faturamento.TarifaTipoCalculo (1 a 4).
INSERT INTO faturamento.tarifa_tipo_calculo
  (ttpc_id, ttpc_dstarifatipocalculo, ttpc_dsabreviado, ttpc_tmultimaalteracao, ttpc_icuso) VALUES
  (1, 'CALCULO PROPORCIONAL', 'PROP', '2026-01-01 00:00:00', 1),
  (2, 'CALCULO SEM FAIXA CAER', 'SFXC', '2026-01-01 00:00:00', 1),
  (3, 'CALCULO POR REFERENCIA', 'REF', '2026-01-01 00:00:00', 1),
  (4, 'CALCULO DIRETO NA FAIXA', 'DIRF', '2026-01-01 00:00:00', 1);

-- Situações da ligação de água — gcom.atendimentopublico.ligacaoagua.LigacaoAguaSituacao
-- (POTENCIAL = 1, LIGADO = 3). Indicadores SINTÉTICOS: LIGADO fatura; POTENCIAL não.
-- last_nnconsumominimo = 0: nenhum mínimo por situação (o override por situação é de CEN-MIC-002 V4).
INSERT INTO atendimentopublico.ligacao_agua_situacao
  (last_id, last_dsligacaoaguasituacao, last_icuso, last_tmultimaalteracao, last_dsabreviado,
   last_icfaturamento, last_nnconsumominimo, last_icexistenciarede, last_icexistencialigacao,
   last_icabastecimento, last_iccadastradaagua, last_icativaagua, last_icdesligadaagua,
   last_icanaliseagua, last_icconsumoreal, last_nndiascorte) VALUES
  (1, 'POTENCIAL', 1, '2026-01-01 00:00:00', 'POT', 2, 0, 1, 2, 2, 2, 2, 2, 2, 2, NULL),
  (3, 'LIGADO', 1, '2026-01-01 00:00:00', 'LIG', 1, 0, 1, 1, 1, 1, 1, 2, 2, 1, NULL);

-- Situações da ligação de esgoto — gcom.atendimentopublico.ligacaoesgoto.LigacaoEsgotoSituacao
-- (POTENCIAL = 1, LIGADO = 3). Indicadores SINTÉTICOS, mesmo critério da água.
INSERT INTO atendimentopublico.ligacao_esgoto_situacao
  (lest_id, lest_dsligacaoesgotosituacao, lest_icuso, lest_tmultimaalteracao, lest_dsabreviado,
   lest_icfaturamento, lest_nnvolumeminimo, lest_icexistenciarede, lest_icexistencialigacao,
   lest_iccadastradaesgoto, lest_icativaesgoto, lest_icdesligadaesgoto, lest_icanaliseesgoto) VALUES
  (1, 'POTENCIAL', 1, '2026-01-01 00:00:00', 'POT', 2, 0, 1, 2, 2, 2, 2, 2),
  (3, 'LIGADO', 1, '2026-01-01 00:00:00', 'LIG', 1, 0, 1, 1, 1, 1, 2, 2);

-- Subcategoria "zero": com parm_ictarifacategoria = 1 (tarifa por CATEGORIA, valor da semente de
-- sistema_parametros), o legado procura a tarifa da categoria com scat_id = 0
-- (gcom.cadastro.imovel.Subcategoria.SUBCATEGORIA_ZERO; RepositorioMicromedicaoHBM
-- .pesquisarConsumoMinimoTarifaCategoriaVigencia). Descrição e indicadores SINTÉTICOS.
INSERT INTO cadastro.subcategoria
  (scat_id, catg_id, scat_cdsubcategoria, scat_dssubcategoria, scat_icuso, scat_tmultimaalteracao,
   scat_nnfatorfiscalizacao, scat_icsazonalidade, scat_icrural) VALUES
  (0, 1, 0, 'SUBCATEGORIA ZERO (SINTETICA)', 1, '2026-01-01 00:00:00', 1, 2, 2);

-- Grupo de faturamento G1 (cenarios-criticos.md §13.4 "rotas R1–R3 no grupo G1"). SINTÉTICO.
INSERT INTO faturamento.faturamento_grupo
  (ftgr_id, ftgr_dsfaturamentogrupo, ftgr_dsabreviado, ftgr_icuso, ftgr_tmultimaalteracao,
   ftgr_amreferencia, ftgr_nndiavencimento, ftgr_icvencimentomesfatura) VALUES
  (1, 'GRUPO G1 (SINTETICO)', 'G1', 1, '2026-01-01 00:00:00', 202605, 10, 2);

-- TAR-01 — tipo de cálculo 1; valores SINTÉTICOS (duas casas, como numeric(13,2)).
INSERT INTO faturamento.consumo_tarifa
  (cstf_id, cstf_dsconsumotarifa, cstf_icuso, cstf_tmultimaalteracao, lapf_id, ttpc_id) VALUES
  (1, 'TAR-01 (SINTETICA)', 1, '2026-01-01 00:00:00', NULL, 1);

INSERT INTO faturamento.consumo_tarifa_vigencia (cstv_id, cstf_id, cstv_dtvigencia, cstv_tmultimaalteracao) VALUES
  (1, 1, '2025-01-01', '2026-01-01 00:00:00'),
  (2, 1, '2026-07-16', '2026-01-01 00:00:00');

-- Mínimo e tarifa mínima por categoria e vigência (scat_id = 0). O mínimo COMERCIAL muda entre as
-- vigências (15 → 20 m³) para tornar observável de qual vigência o legado tira o mínimo.
INSERT INTO faturamento.consumo_tarifa_categoria
  (cstc_id, cstv_id, catg_id, cstc_nnconsumominimo, cstc_vltarifaminima, cstc_tmultimaalteracao, scat_id) VALUES
  (11, 1, 1, 10, 32.50, '2026-01-01 00:00:00', 0),
  (12, 1, 2, 15, 71.40, '2026-01-01 00:00:00', 0),
  (13, 1, 3, 20, 128.00, '2026-01-01 00:00:00', 0),
  (14, 1, 4, 10, 45.90, '2026-01-01 00:00:00', 0),
  (21, 2, 1, 10, 35.10, '2026-01-01 00:00:00', 0),
  (22, 2, 2, 20, 97.10, '2026-01-01 00:00:00', 0),
  (23, 2, 3, 20, 138.24, '2026-01-01 00:00:00', 0),
  (24, 2, 4, 10, 49.57, '2026-01-01 00:00:00', 0);

-- Faixas progressivas acima do mínimo, em R$/m³ (a faixa começa no mínimo + 1).
INSERT INTO faturamento.consumo_tarifa_faixa
  (ctfx_id, cstc_id, ctfx_nncosumofaixainicio, ctfx_nnconsumofaixafim, ctfx_vlconsumotarifa, ctfx_tmultimaalteracao) VALUES
  (111, 11, 11, 20, 4.15, '2026-01-01 00:00:00'),
  (112, 11, 21, 30, 5.20, '2026-01-01 00:00:00'),
  (113, 11, 31, 50, 7.35, '2026-01-01 00:00:00'),
  (114, 11, 51, 99999, 9.80, '2026-01-01 00:00:00'),
  (121, 12, 16, 30, 6.85, '2026-01-01 00:00:00'),
  (122, 12, 31, 99999, 9.12, '2026-01-01 00:00:00'),
  (131, 13, 21, 99999, 8.77, '2026-01-01 00:00:00'),
  (141, 14, 11, 99999, 6.05, '2026-01-01 00:00:00'),
  (211, 21, 11, 20, 4.48, '2026-01-01 00:00:00'),
  (212, 21, 21, 30, 5.62, '2026-01-01 00:00:00'),
  (213, 21, 31, 50, 7.94, '2026-01-01 00:00:00'),
  (214, 21, 51, 99999, 10.58, '2026-01-01 00:00:00'),
  (221, 22, 21, 30, 7.40, '2026-01-01 00:00:00'),
  (222, 22, 31, 99999, 9.85, '2026-01-01 00:00:00'),
  (231, 23, 21, 99999, 9.47, '2026-01-01 00:00:00'),
  (241, 24, 11, 99999, 6.53, '2026-01-01 00:00:00');
