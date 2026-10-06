-- Delta — CEN-MIC-002 V4/V6: consumo mínimo na SITUAÇÃO de água LIGADO (last_nnconsumominimo = 15 m³). Afeta todo imóvel
-- LIGADO da massa. SINTÉTICO.
UPDATE atendimentopublico.ligacao_agua_situacao SET last_nnconsumominimo = 15 WHERE last_id = 3;
