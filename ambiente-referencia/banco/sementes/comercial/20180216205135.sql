-- P3 — grupos de acesso de produção referenciados por ID nas concessões
-- (seguranca.grupo_func_operacao) de 20180216205135 em diante; lista extraída das migrações
-- (a primeira que cita cada grupo está no README). Só o 46 tem constante
-- (Grupo.ATENDENTE_LOJA = 46); os demais são SINTÉTICOS, identificados como tal, e sem usuários.
-- format(): a migração 20160118183217 cria casts implícitos para text, e `'texto' || inteiro`
-- fica ambíguo nesta base.
INSERT INTO seguranca.grupo (grup_id, grup_dsgrupo, grup_dsabreviado, grup_icuso, grup_tmultimaalteracao)
SELECT g,
       CASE WHEN g = 46 THEN 'ATENDENTE LOJA' ELSE format('GRUPO %s (SEMENTE REFERENCIA)', g) END,
       format('G%s', g), 1, now()
FROM unnest(ARRAY[3, 11, 16, 20, 21, 34, 39, 42, 43, 46, 47, 48, 49, 50, 52, 53, 54, 55,
                  56, 58, 61, 62, 63, 67, 69, 73, 108]) AS g;
