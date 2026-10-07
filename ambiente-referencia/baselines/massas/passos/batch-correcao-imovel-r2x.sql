-- Correção da causa da falha controlada (lote 5: CEN-BAT-002 V2) — aplicada pelo ROTEIRO entre a execução com falha
-- e o reinício, NÃO como massa inicial. Depende de batch-rotas-r2-r3.sql.
--
-- O IMV-R2x (100226) recebe a composição que lhe faltava: residencial padrão, 1 economia — o que o operador gravaria
-- pela manutenção do imóvel. A manutenção do imóvel é outra fronteira (CEN-CAD-*); a operação sob teste aqui é o
-- REINÍCIO da etapa, e a correção só remove a causa. SINTÉTICO.
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao)
VALUES (100226, 101, 1, '2026-06-01 09:00:00');
