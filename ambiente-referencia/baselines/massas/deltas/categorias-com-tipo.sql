-- Delta — tipo de categoria (CategoriaTipo.PARTICULAR = 1, PUBLICO = 2) para as categorias das sementes, que não têm
-- (cgtp_id nulo; categoria_tipo VAZIA). EVIDÊNCIA: RepositorioImovelHBM.pesquisarObterQuantidadeEconomiasCategoria faz
-- inner join com o tipo; sem ele, ControladorImovelSEJB.obterQuantidadeEconomiasCategoria:1466 acusa "imóvel sem
-- subcategoria" — o faturamento em grupo falha em todo imóvel (achado F2-44). Mesmo conteúdo da parte correspondente de
-- atendimento-catalogos.sql, isolado para os lotes que não usam o resto daquele delta. Descrições SINTÉTICAS.
INSERT INTO cadastro.categoria_tipo (cgtp_id, cgtp_dscategoriatipo, cgtp_dsabreviado, cgtp_tmultimaalteracao) VALUES
  (1, 'PARTICULAR', 'PART', '2026-01-01 00:00:00'),
  (2, 'PUBLICO', 'PUBL', '2026-01-01 00:00:00');
UPDATE cadastro.categoria SET cgtp_id = CASE WHEN catg_id = 4 THEN 2 ELSE 1 END WHERE cgtp_id IS NULL;
