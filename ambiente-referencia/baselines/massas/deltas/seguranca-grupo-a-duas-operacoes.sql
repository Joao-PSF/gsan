-- Delta — CEN-SEG-004 V7(c): o grupo A passa a conceder DUAS operações de F1 (303 e 305 Dados
-- Complementares). USR-01 tem um só grupo e duas concessões na funcionalidade: é o caso em que o filtro de
-- restrições (ControladorAcessoSEJB:3040-3090) compara o contador das concessões com o número de GRUPOS
-- (CAND-05). SINTÉTICO.
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao)
VALUES (2001, 305, 241, '2026-01-01 00:00:00');
