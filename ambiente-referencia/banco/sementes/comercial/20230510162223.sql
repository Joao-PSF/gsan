-- P2b — valor de sequence evidenciado por migração posterior. 20230510162223 cria duas
-- funcionalidades por nextval('seguranca.seq_funcionalidade'); 20230510162447 as referencia
-- pelos IDs que o nextval produziu em produção: 16108 e 16109. A sequence é posicionada
-- para reproduzi-los.
SELECT setval('seguranca.seq_funcionalidade', 16107);
