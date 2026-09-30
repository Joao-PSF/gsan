-- P3 — categorias pressupostas por 20210203135248 (faixa_valor_consumo com catg_id = 1).
-- Evidência: src/gcom/cadastro/imovel/Categoria.java — RESIDENCIAL = 1, COMERCIAL = 2, INDUSTRIAL = 3, PUBLICO = 4.
-- Sintético: abreviaturas; os parâmetros de consumo ficam nulos (a massa da Fase 2 os define).
INSERT INTO cadastro.categoria (catg_id, catg_dscategoria, catg_dsabreviado, catg_icuso, catg_tmultimaalteracao)
VALUES (1, 'RESIDENCIAL', 'RES', 1, now()), (2, 'COMERCIAL', 'COM', 1, now()),
       (3, 'INDUSTRIAL', 'IND', 1, now()), (4, 'PUBLICO', 'PUB', 1, now());
