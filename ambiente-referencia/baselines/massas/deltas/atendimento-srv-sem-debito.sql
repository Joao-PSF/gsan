-- Delta — CEN-ATE-007 V1: o tipo de serviço 619 SEM tipo de débito — a execução da OS só tem o efeito cadastral.
-- Depende de atendimento-catalogos.sql. SINTÉTICO.
UPDATE atendimentopublico.servico_tipo SET dbtp_id = NULL WHERE svtp_id = 619;
