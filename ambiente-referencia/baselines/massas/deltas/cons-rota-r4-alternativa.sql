-- Delta — a rota R4 passa a ser uma rota ALTERNATIVA (rota_icalternativa = 1) (lote 5e: CEN-CAD-005 V2). Depende de
-- mic-rota-r4-consistir-202605.sql e de cons-rota-alternativa.sql.
--
-- EVIDÊNCIA: o indicador da rota decide como a consistência seleciona os imóveis — rota comum: os da quadra SEM rota
-- alternativa (RepositorioMicromedicaoHBM.pesquisarImovelConsistirLeituraPorRota); rota alternativa: SÓ os imóveis que a
-- apontam como alternativa (…PorRotaAlternativa) — ControladorMicromedicao.pesquisarImovelParaConsistirLeitura. SINTÉTICO.
UPDATE micromedicao.rota SET rota_icalternativa = 1 WHERE rota_id = 4;
