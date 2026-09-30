-- P3 — processo buscado pela descrição em 20210806133855.
-- A migração que deveria criá-lo (20210623185452) tem a seção "do" vazia; só o UNDO
-- sobreviveu, e é de lá que vem a descrição. ID: próximo livre (SINTÉTICO).
INSERT INTO batch.processo (proc_id, proc_dsprocesso, proc_dsabreviado, proc_icuso, proc_tmultimaalteracao)
SELECT max(proc_id) + 1, 'ENVIAR NOTIFICAÇÃO DE VENCIMENTO', 'NOTIFVENC', 1, now() FROM batch.processo;
