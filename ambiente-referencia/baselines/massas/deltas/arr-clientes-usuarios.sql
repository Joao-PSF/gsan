-- Delta — cliente USUÁRIO de IMV-02 e IMV-03 (lote 6), como conta-ciclo-catalogos.sql faz para IMV-01. Depende de
-- conta-ciclo-catalogos.sql (tipos de relação cliente × imóvel e o vínculo de IMV-01).
--
-- EVIDÊNCIA: a posição de dívida que a Cobrança calcula (Consultar Débitos → ControladorCobranca.obterDebitoImovelOuCliente
-- → RepositorioCobrancaHBM.pesquisarContasImovel:295) parte de cadastro.cliente_conta — a conta só aparece se o
-- faturamento a gravou com o cliente do imóvel; sem cliente, a consulta é sempre vazia e nada se observa da quitação. O
-- vínculo precisa existir ANTES do faturamento do grupo. Cliente SINTÉTICO de verificação (clie_id 1).
INSERT INTO cadastro.cliente_imovel (clim_id, clie_id, imov_id, clim_dtrelacaoinicio, clim_dtrelacaofim, clim_tmultimaalteracao,
                                     crtp_id, clim_icnomeconta) VALUES
  (5002, 1, 100021, '2026-01-01', NULL, '2026-01-01 00:00:00', 2, 1),
  (5003, 1, 100030, '2026-01-01', NULL, '2026-01-01 00:00:00', 2, 1);
