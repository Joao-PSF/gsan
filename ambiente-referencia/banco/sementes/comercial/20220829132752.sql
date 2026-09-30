-- P3-DDL — coluna pressuposta por 20220829132752 (RENAME COLUMN cntt_copasa TO
-- imov_idparametrosconvenio) e criada fora do histórico. O código mapeia o nome final
-- (src/gcom/cadastro/imovel/Imovel.hbm.xml: codigoConvenio, java.lang.Integer) e
-- 20220829140916 cria a FK para arrecadacao.arrecadador_contrato_convenio(arcc_id).
-- Sem ela, toda consulta Hibernate a Imovel falharia.
ALTER TABLE cadastro.imovel ADD COLUMN cntt_copasa integer;
