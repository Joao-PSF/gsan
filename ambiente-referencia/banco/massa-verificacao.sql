-- Massa sintética mínima de VERIFICAÇÃO do ambiente de referência (Fase 1).
-- Existe só para que o teste de fumaça execute uma consulta de domínio que carregue a entidade
-- central Cliente por inteiro (mapeamento Hibernate completo, inclusive a coluna do P6). Não é
-- massa de caracterização: os perfis da Fase 2 (testes/cenarios-criticos.md §13) são outra
-- coisa. Nenhum dado pessoal; nomes marcados como sintéticos. Idempotente.
--
-- Evidência dos identificadores: EsferaPoder.PARTICULAR = 4 e
-- ClienteTipo.INDICADOR_PESSOA_FISICA = 1 (src/gcom/cadastro/cliente/). O tipo de cliente 1 e o
-- cliente 1 são sintéticos.
INSERT INTO cadastro.esfera_poder (epod_id, epod_dsesferapoder, epod_icuso)
SELECT 4, 'PARTICULAR', 1
WHERE NOT EXISTS (SELECT 1 FROM cadastro.esfera_poder WHERE epod_id = 4);

INSERT INTO cadastro.cliente_tipo (cltp_id, cltp_dsclientetipo, cltp_icpessoafisicajuridica, cltp_icuso, epod_id)
SELECT 1, 'PESSOA FISICA (SINTETICO)', 1, 1, 4
WHERE NOT EXISTS (SELECT 1 FROM cadastro.cliente_tipo WHERE cltp_id = 1);

INSERT INTO cadastro.cliente (clie_id, clie_nmcliente, cltp_id, clie_icuso, clie_tmultimaalteracao)
SELECT 1, 'CLIENTE SINTETICO DE VERIFICACAO', 1, 1, now()
WHERE NOT EXISTS (SELECT 1 FROM cadastro.cliente WHERE clie_id = 1);
