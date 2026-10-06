-- Delta — CEN-MIC-002 V7: a categoria RESIDENCIAL com FATOR DE ECONOMIAS 3 (catg_nnfatoreconomias): pelo código
-- (ControladorMicromedicao.obterConsumoMinimoLigacaoPorCategoria) o fator, quando presente, substitui o número de
-- economias no somatório. SINTÉTICO.
UPDATE cadastro.categoria SET catg_nnfatoreconomias = 3 WHERE catg_id = 1;
