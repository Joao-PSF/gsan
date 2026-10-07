-- Delta — IMV-01, IMV-02 e IMV-03 com um CLIENTE RESPONSÁVEL de esfera FEDERAL e os quatro impostos retidos, com as
-- alíquotas vigentes desde 01/2026 (lote 5b: CEN-FAT-005 V1 a V3). Depende de imoveis-imv-01-02-03.sql (as contas de
-- 110,40, 168,09 e 252,60 são as bases) e de batch-faturamento-g1-202605.sql.
--
-- EVIDÊNCIA (base reconstruída): faturamento.imposto_tipo e imposto_tipo_aliquota VAZIAS; a única esfera de poder é
-- PARTICULAR (4). O faturamento só deduz impostos de imóvel com cliente RESPONSÁVEL (ClienteRelacaoTipo = 3) de esfera
-- FEDERAL, ESTADUAL ou MUNICIPAL (RepositorioFaturamentoHBM.pesquisarClienteResponsavelImovel); EsferaPoder.FEDERAL = 3.
-- Impostos pelas constantes de gcom.faturamento.ImpostoTipo (IR 1, CSLL 2, COFINS 3, PIS_PASEP 4). Alíquotas SINTÉTICAS
-- (1,20 · 1,00 · 3,00 · 0,65 — a forma da retenção federal; não são dado de instalação). Cliente SINTÉTICO.
-- Tipos de relação cliente × imóvel: a base não tem nenhum; mesmos ids e textos de clientes-imovel-imv03.sql
-- (gcom.cadastro.cliente.ClienteRelacaoTipo: PROPRIETARIO 1, USUARIO 2, RESPONSAVEL 3).
INSERT INTO cadastro.cliente_relacao_tipo (crtp_id, crtp_dsclienterelacaotipo, crtp_icuso, crtp_tmultimaalteracao) VALUES
  (1, 'PROPRIETARIO', 1, '2026-01-01 00:00:00'),
  (2, 'USUARIO', 1, '2026-01-01 00:00:00'),
  (3, 'RESPONSAVEL', 1, '2026-01-01 00:00:00');
INSERT INTO cadastro.esfera_poder (epod_id, epod_dsesferapoder, epod_icuso, epod_tmultimaalteracao, epod_icpermitecndparaimovel,
                                   epod_icpermitecndparacliente)
VALUES (3, 'FEDERAL', 1, '2026-01-01 00:00:00', 2, 2);
INSERT INTO cadastro.cliente_tipo (cltp_id, cltp_dsclientetipo, cltp_icpessoafisicajuridica, cltp_icuso, cltp_tmultimaalteracao, epod_id)
VALUES (9301, 'ORGAO PUBLICO FEDERAL (SINTETICO)', 2, 1, '2026-01-01 00:00:00', 3);
INSERT INTO cadastro.cliente (clie_id, clie_nmcliente, clie_nmabreviado, cltp_id, clie_icuso, clie_tmultimaalteracao,
                              clie_icusonomefantasiaconta, clie_icpermitenegativacao, clie_icnegativacaoperiodo)
VALUES (9301, 'ORGAO PUBLICO SINTETICO', 'ORG SINT', 9301, 1, '2026-01-01 00:00:00', 2, 2, 2);
INSERT INTO cadastro.cliente_imovel (clim_id, clie_id, imov_id, clim_dtrelacaoinicio, clim_tmultimaalteracao, crtp_id, clim_icnomeconta) VALUES
  (9301, 9301, 100013, '2026-01-01', '2026-01-01 00:00:00', 3, 2),
  (9302, 9301, 100021, '2026-01-01', '2026-01-01 00:00:00', 3, 2),
  (9303, 9301, 100030, '2026-01-01', '2026-01-01 00:00:00', 3, 2);

INSERT INTO faturamento.imposto_tipo (imtp_id, imtp_dsimposto, imtp_dsabreviadaimposto, imtp_icuso, imtp_tmultimaalteracao) VALUES
  (1, 'IR', 'IR', 1, '2026-01-01 00:00:00'),
  (2, 'CSLL', 'CSLL', 1, '2026-01-01 00:00:00'),
  (3, 'COFINS', 'COFINS', 1, '2026-01-01 00:00:00'),
  (4, 'PIS PASEP', 'PIS', 1, '2026-01-01 00:00:00');
INSERT INTO faturamento.imposto_tipo_aliquota (imta_id, imtp_id, imta_amreferencia, imta_pcaliquota, imta_tmultimaalteracao) VALUES
  (1, 1, 202601, 1.20, '2026-01-01 00:00:00'),
  (2, 2, 202601, 1.00, '2026-01-01 00:00:00'),
  (3, 3, 202601, 3.00, '2026-01-01 00:00:00'),
  (4, 4, 202601, 0.65, '2026-01-01 00:00:00');
