-- P3 — pressupostos por 20170512142138 (processo_funcionalidade com proc_id = 151 e unpr_id = 19).
-- Unidades de processamento: src/gcom/batch/UnidadeProcessamento.java (ROTA = 1 ... FATURAMENTO_GRUPO = 21;
-- não há 13). A 22 (REFERENCIA) é criada por migração posterior e fica de fora. Descrição = nome
-- da constante, cortado em 20 caracteres (tamanho da coluna).
INSERT INTO batch.unidade_processamento (unpr_id, unpr_dsunidadeprocessamento, unpr_tmultimaalteracao, unpr_icuso, unpr_dsabreviada)
SELECT u.id, substr(u.nome, 1, 20), now(), 1, NULL
FROM (VALUES (1, 'ROTA'), (2, 'CONTA'), (3, 'FATURAMENTO ATIVIDADE CRONOGRAMA ROTA'), (4, 'RELATORIO'),
             (5, 'FUNCIONALIDADE'), (6, 'LOCALIDADE'), (7, 'COBRANCA GRUPO CRONOGRAMA MES'), (8, 'SETOR COMERCIAL'),
             (9, 'HIDROMETRO MARCA'), (10, 'COB ACAO ATIV CRONOG'), (11, 'COB ACAO ATIV COMAND'), (12, 'RA ENCERRAMENTO COM'),
             (14, 'NEGATIVADOR MOVIMENTO REG'), (15, 'COMANDO EMPRESA COBRANCA CONTA'),
             (16, 'COMANDO EMPRESA COBRANCA CONTA EXTENSAO'), (17, 'UNIDADE NEGOCIO'), (18, 'HIDROMETRO'),
             (19, 'EMPRESA'), (20, 'QUADRA'), (21, 'FATURAMENTO GRUPO')) AS u (id, nome)
WHERE NOT EXISTS (SELECT 1 FROM batch.unidade_processamento x WHERE x.unpr_id = u.id);

-- Processo 151: referenciado por 20170512142138 e 20180307165455 (cobrança por resultado); sem
-- constante em src/gcom/batch/Processo.java — linha SINTÉTICA, identificada como tal.
INSERT INTO batch.processo (proc_id, proc_dsprocesso, proc_dsabreviado, proc_icuso, proc_tmultimaalteracao)
VALUES (151, 'PROCESSO 151 (SEMENTE REFERENCIA)', 'SEMENTE', 1, now());
