-- Delta — território mínimo sintético: localidade L1, setor 1, quadra 1 e rota R1 no grupo G1
-- (cenarios-criticos.md §13.4, "Território"). Base de todo perfil de imóvel (IMV-*).
--
-- Tudo SINTÉTICO — nomes, códigos, CEP e UF (sigla ZZ, inexistente) não correspondem a lugar real.
-- Identificadores por constante do legado, onde há: LeituraTipo.CONVENCIONAL = 1
-- (gcom.micromedicao.leitura.LeituraTipo); empresa 1 = a da semente de sistema_parametros.
-- Depende da massa base (grupo de faturamento G1, id 1).

INSERT INTO cadastro.regiao (regi_id, regi_nmregiao, regi_icuso, regi_tmultimaalteracao)
VALUES (1, 'REGIAO SINTETICA', 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.microrregiao (mreg_id, regi_id, mreg_nmmicrorregiao, mreg_icuso, mreg_tmultimaalteracao)
VALUES (1, 1, 'MICRORREGIAO SINTETICA', 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.regiao_desenvolvimento (rdes_id, rdes_nmregiaodesenvolvimento, rdes_icuso, rdes_tmultimaalteracao)
VALUES (1, 'REG DESENV SINTETICA', 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.unidade_federacao (unfe_id, unfe_dsuf, unfe_dsufsigla, unfe_tmultimaalteracao)
VALUES (1, 'UF SINTETICA', 'ZZ', '2026-01-01 00:00:00');
INSERT INTO cadastro.municipio (muni_id, muni_nmmunicipio, rdes_id, mreg_id, unfe_id, muni_icuso, muni_tmultimaalteracao)
VALUES (1, 'MUNICIPIO SINTETICO', 1, 1, 1, 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.bairro (bair_id, muni_id, bair_cdbairro, bair_nmbairro, bair_icuso, bair_tmultimaalteracao)
VALUES (1, 1, 1, 'BAIRRO SINTETICO', 1, '2026-01-01 00:00:00');

INSERT INTO cadastro.logradouro_tipo (lgtp_id, lgtp_dslogradourotipo, lgtp_dsabreviado, lgtp_icuso, lgtp_tmultimaalteracao)
VALUES (1, 'RUA', 'R', 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.logradouro (logr_id, logr_nmlogradouro, lgtp_id, muni_id, logr_icuso, logr_tmultimaalteracao)
VALUES (1, 'SINTETICA A', 1, 1, 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.logradouro_bairro (lgbr_id, logr_id, bair_id, lgbr_tmultimaalteracao)
VALUES (1, 1, 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.cep (cep_id, cep_cdcep, cep_dsufsigla, cep_nmmunicipio, cep_nmbairro, cep_nmlogradouro,
                          cep_dslogradourotipo, cep_icuso, cep_tmultimaalteracao)
VALUES (1, 99999000, 'ZZ', 'MUNICIPIO SINTETICO', 'BAIRRO SINTETICO', 'SINTETICA A', 'RUA', 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.logradouro_cep (lgcp_id, logr_id, cep_id, lgcp_icuso, lgcp_tmultimaalteracao)
VALUES (1, 1, 1, 1, '2026-01-01 00:00:00');

INSERT INTO cadastro.gerencia_regional (greg_id, greg_nmregional, greg_nmabreviado, greg_icuso, greg_tmultimaalteracao)
VALUES (1, 'GERENCIA SINTETICA 1', 'GS1', 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.unidade_negocio (uneg_id, greg_id, uneg_nmunidadenegocio, uneg_nmabreviado, uneg_icuso, uneg_tmultimaalteracao)
VALUES (1, 1, 'UNIDADE NEGOCIO SINTETICA 1', 'UN1', 1, '2026-01-01 00:00:00');
-- loca_cdelo = a própria localidade: L1 é o seu elo (polo).
INSERT INTO cadastro.localidade (loca_id, loca_nmlocalidade, loca_cdelo, greg_id, uneg_id, loca_icuso, loca_icinformatizada,
                                 loca_icsede, loca_tmultimaalteracao, muni_idprincipal)
VALUES (1, 'LOCALIDADE L1 (SINTETICA)', 1, 1, 1, 1, 1, 1, '2026-01-01 00:00:00', 1);
INSERT INTO cadastro.setor_comercial (stcm_id, loca_id, stcm_cdsetorcomercial, stcm_nmsetorcomercial, stcm_icuso, muni_id,
                                      stcm_tmultimaalteracao, stcm_icalternativo)
VALUES (1, 1, 1, 'SETOR 1 (SINTETICO)', 1, 1, '2026-01-01 00:00:00', 2);

INSERT INTO micromedicao.leitura_tipo (lttp_id, lttp_dsleituratipo, lttp_icuso, lttp_tmultimaalteracao)
VALUES (1, 'CONVENCIONAL', 1, '2026-01-01 00:00:00');
INSERT INTO cobranca.cobranca_grupo (cbgr_id, cbgr_dscobrancagrupo, cbgr_dsabreviado, cbgr_icuso, cbgr_tmultimaalteracao, cbgr_icexecautomatica)
VALUES (1, 'COBRANCA SINTETICA 1', 'CB1', 1, '2026-01-01 00:00:00', 2);
INSERT INTO micromedicao.rota (rota_id, lttp_id, empr_id, rota_icuso, rota_tmultimaalteracao, ftgr_id, stcm_id, cbgr_id, rota_cdrota,
                               empr_idcobranca, rota_icalternativa, rota_ictransmissaooffline, rota_icdividerota,
                               rota_icimpressaotermicafinalgrupo)
VALUES (1, 1, 1, 1, '2026-01-01 00:00:00', 1, 1, 1, 1, 1, 2, 2, 2, 2);
INSERT INTO cadastro.quadra (qdra_id, stcm_id, qdra_nnquadra, rota_id, qdra_icuso, qdra_tmultimaalteracao, qdra_icautoincrementolote,
                             bair_id, qdra_icredeagua, qdra_icredeesgoto)
VALUES (1, 1, 1, 1, 1, '2026-01-01 00:00:00', 2, 1, 1, 1);
