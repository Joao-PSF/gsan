-- Delta — o operador da caracterização com as permissões especiais RETIFICAR CONTA SEM RA (48) e CANCELAR CONTA SEM RA
-- (51) (lote 5d). Depende de conta-ciclo-catalogos.sql.
--
-- Sem elas, retificar e cancelar exigem um RA pendente do imóvel cuja especificação valide ALTERAÇÃO DE CONTA
-- (ControladorRegistroAtendimentoSEJB.verificarExistenciaRegistroAtendimento) — a variação "originada por RA" (CEN-FAT-007
-- V4) é a que NÃO aplica este delta. Concessão SINTÉTICA.
INSERT INTO seguranca.usuario_permissao_espec (usur_id, pmep_id, upes_tmultimaalteracao) VALUES
  (1001, 48, '2026-01-01 00:00:00'),
  (1001, 51, '2026-01-01 00:00:00');
