-- P3-DDL — pré-requisito de 20210825174243 (ALTER TABLE cadastro.cliente_login).
-- A migração 20210708140147 declara a tabela e a sequence, mas toda a sua seção
-- "do" (linhas 5-88) está dentro de um comentário /* ... */: ela não cria nada.
-- Em produção os objetos foram criados fora do histórico. O código mapeia a tabela
-- (src/gcom/cadastro/cliente/ClienteLogin.hbm.xml). Conteúdo abaixo: linhas 6-61 de
-- gsan-migracoes/comercial/scripts/20210708140147_Tabela_de_login_de_cliente_-_loja_virtual.sql
-- (commit fixado em versoes.env), sem alteração. Só o DDL: o INSERT de funcionalidade e de
-- envio_email que também está no bloco comentado é feito de verdade por 20231207190119.

CREATE TABLE IF NOT EXISTS cadastro.cliente_login
(
    cllo_id integer NOT NULL,
    imov_id integer NOT NULL,
    cllo_nmcliente character varying(50) NOT NULL,
    cllo_nncpfcnpj character varying(14) NOT NULL,
    cllo_dtnascimento date NOT NULL,
    cllo_nncelular character varying(11) NOT NULL,
    cllo_dsemail character varying(40) NOT NULL,
    cllo_nmsenha character varying(40) NOT NULL,
    cllo_icemailconfirmado smallint NOT NULL,
    cllo_tmcadastro timestamp without time zone NOT NULL,
    cllo_cdsituacao smallint NOT NULL,
    cllo_tmanalise timestamp without time zone,
    cllo_tmultimaalteracao timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT cliente_login_pkey PRIMARY KEY (cllo_id),
    CONSTRAINT fk1_cliente_login FOREIGN KEY (imov_id) REFERENCES cadastro.imovel (imov_id) MATCH SIMPLE ON UPDATE RESTRICT ON DELETE RESTRICT
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE cadastro.cliente_login OWNER to gsan_admin;
GRANT ALL ON TABLE cadastro.cliente_login TO gsan_admin;
GRANT DELETE, INSERT, SELECT, UPDATE ON TABLE cadastro.cliente_login TO role_aplic;
GRANT SELECT ON TABLE cadastro.cliente_login TO role_users;

COMMENT ON TABLE cadastro.cliente_login IS 'Tabela para armazenar os dados de solicitação de cadastro de Login de Cliente no Portal';
COMMENT ON COLUMN cadastro.cliente_login.cllo_id IS 'Id da Tabela cadastro.cliente_login (sequencial)';
COMMENT ON COLUMN cadastro.cliente_login.imov_id IS 'Id do Imovel';
COMMENT ON COLUMN cadastro.cliente_login.cllo_nmcliente IS 'Nome do Cliente';
COMMENT ON COLUMN cadastro.cliente_login.cllo_nncpfcnpj IS 'CPF ou CNPJ do Cliente';
COMMENT ON COLUMN cadastro.cliente_login.cllo_dtnascimento IS 'Data de Nascimento do Cliente';
COMMENT ON COLUMN cadastro.cliente_login.cllo_nncelular IS 'Número de Celular do Cliente';
COMMENT ON COLUMN cadastro.cliente_login.cllo_dsemail IS 'Email do Cliente';
COMMENT ON COLUMN cadastro.cliente_login.cllo_nmsenha IS 'Senha do Login que será criado para o Cliente';
COMMENT ON COLUMN cadastro.cliente_login.cllo_icemailconfirmado IS 'Indica se o cliente confirmou o cadastro via email (1 = Sim; 2 = NAO)';
COMMENT ON COLUMN cadastro.cliente_login.cllo_tmcadastro IS 'Timestamp da solicitação do cadastro';
COMMENT ON COLUMN cadastro.cliente_login.cllo_icemailconfirmado IS 'Situação do cadastro do cliente (0 = CADASTRADO; 1 = APROVADO, 2 = REPROVADO)';
COMMENT ON COLUMN cadastro.cliente_login.cllo_tmcadastro IS 'Data em que o cadastro foi APROVADO ou REPROVADO';
COMMENT ON COLUMN cadastro.cliente_login.cllo_tmultimaalteracao IS 'Timestamp da Última Alteração';

-- SEQUENCE: cadastro.seq_cliente_login

CREATE SEQUENCE cadastro.seq_cliente_login
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE cadastro.seq_cliente_login OWNER TO gsan_admin;
GRANT SELECT, UPDATE ON SEQUENCE cadastro.seq_cliente_login TO gsan_admin;
GRANT SELECT, UPDATE ON SEQUENCE cadastro.seq_cliente_login TO role_aplic;
GRANT SELECT ON SEQUENCE cadastro.seq_cliente_login TO role_users;
