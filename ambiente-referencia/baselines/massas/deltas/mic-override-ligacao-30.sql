-- Delta — CEN-MIC-002 V3/V6: consumo mínimo FIXADO na ligação do IMV-01 (lagu_nnconsumominimoagua = 30 m³). Depende de
-- atendimento-os-consumo-minimo.sql. SINTÉTICO.
UPDATE atendimentopublico.ligacao_agua SET lagu_nnconsumominimoagua = 30 WHERE lagu_id = 100013;
