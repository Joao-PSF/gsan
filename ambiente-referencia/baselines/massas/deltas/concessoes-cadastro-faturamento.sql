-- Delta — concessão do operador da caracterização para o lote 3 (cadastro e faturamento online).
-- Consultar Relação Cliente e Imóvel: funcionalidade 121 (ExibirConsultarRelacaoClienteImovelAction.do) com a
-- operação 158 (ConsultarRelacaoClienteImovelAction.do) — ids do catálogo das migrações. A lista é exibida pelo
-- encaminhamento interno a ExibirImovelRelacaoClienteImovelAction (não refiltrado). Concessão SINTÉTICA.
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao)
VALUES (1001, 158, 121, '2026-01-01 00:00:00');
