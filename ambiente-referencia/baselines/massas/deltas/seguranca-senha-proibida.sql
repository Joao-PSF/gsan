-- Delta — CEN-SEG-003 V6: uma entrada na lista de senhas proibidas (seguranca.senha_invalida, vazia na base).
--
-- sniv_dssenhainvalida é character(6). O valor é um TERMO DE TESTE SINTÉTICO, nunca uma credencial: existe para responder "a troca de senha consulta a
-- lista?". EVIDÊNCIA de código: RepositorioAcessoHBM.pesquisarSenhasInvalidas (:288) não tem chamador em src/.
INSERT INTO seguranca.senha_invalida (sniv_id, sniv_dssenhainvalida, sniv_tmultimaalteracao)
VALUES (1, 'PROIB6', '2026-01-01 00:00:00');
