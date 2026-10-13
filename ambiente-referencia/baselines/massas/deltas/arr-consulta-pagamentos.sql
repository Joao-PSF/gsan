-- Delta — a concessão de Consultar Pagamento ao operador (lote 6c: CEN-ARR-006, CEN-ARR-005 V4, CEN-ARR-010).
-- EVIDÊNCIA: sem ela, consultarPagamentoAction.do responde "Acesso a operação negado" (exploração do lote 6c). A
-- funcionalidade Consultar Pagamento (236, menu exibirFiltrarPagamentoConsultaAction.do) e a operação Filtrar Pagamento
-- (294, consultarPagamentoAction.do) são as das migrações do legado (popula_tabela), como o grupo administrador as tem.
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES (1001, 294, 236, '2026-01-01 00:00:00');
