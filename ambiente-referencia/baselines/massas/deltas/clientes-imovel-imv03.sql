-- Delta — vínculo cliente × imóvel mínimo: o cliente SINTÉTICO de verificação (clie_id 1, massa da Fase 1,
-- presente no modelo congelado) como USUÁRIO do imóvel IMV-03 (100030). Depende de imoveis-imv-01-02-03.sql.
--
-- Usado em CEN-SEG-005: a pesquisa de imóvel do legado (PesquisarImovelAction) procura pelo vínculo
-- cliente × imóvel — sem vínculo, nada a retornar, e a pergunta "o filtro deixa um usuário sem concessão
-- obter dado cadastral?" não seria respondível.
-- Tipos de relação — ids de gcom.cadastro.cliente.ClienteRelacaoTipo (PROPRIETARIO = 1, USUARIO = 2,
-- RESPONSAVEL = 3); a base reconstruída não tem nenhum. Descrições SINTÉTICAS.

INSERT INTO cadastro.cliente_relacao_tipo (crtp_id, crtp_dsclienterelacaotipo, crtp_icuso, crtp_tmultimaalteracao) VALUES
  (1, 'PROPRIETARIO', 1, '2026-01-01 00:00:00'),
  (2, 'USUARIO', 1, '2026-01-01 00:00:00'),
  (3, 'RESPONSAVEL', 1, '2026-01-01 00:00:00');

INSERT INTO cadastro.cliente_imovel (clim_id, clie_id, imov_id, clim_dtrelacaoinicio, clim_dtrelacaofim, clim_tmultimaalteracao,
                                     crtp_id, clim_icnomeconta)
VALUES (1, 1, 100030, '2026-01-01', NULL, '2026-01-01 00:00:00', 2, 1);
