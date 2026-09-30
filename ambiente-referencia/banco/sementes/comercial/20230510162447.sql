-- P2b — valor de sequence evidenciado por migração posterior. 20230510162447 cria operações
-- por nextval('seguranca.seq_operacao'); 20230510162504 referencia a primeira pelo ID que o
-- nextval produziu em produção: 15123. A sequence é posicionada para reproduzi-lo.
SELECT setval('seguranca.seq_operacao', 15122);
