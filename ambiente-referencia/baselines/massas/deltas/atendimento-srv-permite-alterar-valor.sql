-- Delta — CEN-ATE-008 V3: o tipo de serviço 619 PERMITE alterar o valor (svtp_icpermitealterarvalor = 1; perfil SRV-03 de
-- cenarios-criticos.md §13). Depende de atendimento-catalogos.sql. SINTÉTICO.
UPDATE atendimentopublico.servico_tipo SET svtp_icpermitealterarvalor = 1 WHERE svtp_id = 619;
