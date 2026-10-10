-- Delta — o tipo de consumo NÃO MEDIDO (ConsumoTipo = 5) associado à situação de água LIGADO (3) (lote 5e: CEN-MIC-002 V4d).
-- Depende de mic-override-situacao-15.sql.
--
-- EVIDÊNCIA: com consumo mínimo de faturamento > 0 na situação, a ligação só fatura se o consumo for ≥ ao mínimo E o tipo
-- de consumo estiver associado à situação (ControladorFaturamentoFINAL.permiteFaturamentoParaAgua:1957-1990, chamado pela
-- consistência em ControladorMicromedicao:2395); sem faturar, a consistência grava o consumo como 0
-- (ControladorMicromedicao:2447-2449). atendimentopublico.lig_agua_sit_cons_tipo está VAZIA na base: é dado de instalação.
-- Associação SINTÉTICA, só para mostrar a regra quando a configuração existe.
INSERT INTO atendimentopublico.lig_agua_sit_cons_tipo (lact_id, last_id, cstp_id, lact_tmultimaalteracao, lact_icuso)
VALUES (1, 3, 5, '2026-01-01 00:00:00', 1);
