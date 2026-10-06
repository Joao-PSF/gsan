-- Delta — L1 com loca_nnconsumograndeusuario preenchido (0, o "não informado" de ExibirAtualizarLocalidadeAction:492).
-- Depende de territorio-l1.sql.
--
-- EVIDÊNCIA (achado F2-29): a coluna aceita nulo, mas Localidade.hbm.xml:21 a mapeia num int primitivo; toda tela que
-- carrega a ENTIDADE Localidade falha com o valor nulo da massa do território (ex.: Consultar Relação Cliente e Imóvel —
-- ExibirImovelRelacaoClienteImovelAction:79 → HTTP 500 "setRollbackOnly() not allowed without a transaction", que
-- mascara a PropertyAccessException). territorio-l1.sql não muda: as baselines que o usam continuam válidas.
-- Valor SINTÉTICO.
UPDATE cadastro.localidade SET loca_nnconsumograndeusuario = 0 WHERE loca_id = 1;
