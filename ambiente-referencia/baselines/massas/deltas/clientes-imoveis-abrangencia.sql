-- Delta — cliente USUÁRIO dos imóveis da abrangência (CEN-SEG-007). Depende de clientes-imovel-imv03.sql (tipos de
-- relação e cliente SINTÉTICO de verificação clie_id 1) e de territorio-abrangencia.sql.
--
-- EVIDÊNCIA: Manter Conta, depois de passar pela abrangência, exige o cliente do tipo usuário do imóvel; sem ele
-- responde "Nenhum(a) cliente do tipo usuário foi encontrado(a)." (atencao.naocadastrado) — e o imóvel permitido não
-- se distinguiria do negado pelo conteúdo. Um vínculo por imóvel, todos com o mesmo cliente SINTÉTICO.
INSERT INTO cadastro.cliente_imovel (clim_id, clie_id, imov_id, clim_dtrelacaoinicio, clim_dtrelacaofim, clim_tmultimaalteracao,
                                     crtp_id, clim_icnomeconta) VALUES
  (2, 1, 100013, '2026-01-01', NULL, '2026-01-01 00:00:00', 2, 1),
  (3, 1, 100048, '2026-01-01', NULL, '2026-01-01 00:00:00', 2, 1),
  (4, 1, 100056, '2026-01-01', NULL, '2026-01-01 00:00:00', 2, 1),
  (5, 1, 100064, '2026-01-01', NULL, '2026-01-01 00:00:00', 2, 1),
  (6, 1, 100072, '2026-01-01', NULL, '2026-01-01 00:00:00', 2, 1);
