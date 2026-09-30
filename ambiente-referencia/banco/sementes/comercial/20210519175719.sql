-- P3 — grupo buscado pelo nome em 20210519175719 (grup_dsgrupo = 'CADASTRO PERFORMANCE').
-- O nome vem da própria migração; o ID é o próximo livre (SINTÉTICO).
INSERT INTO seguranca.grupo (grup_id, grup_dsgrupo, grup_dsabreviado, grup_icuso, grup_tmultimaalteracao)
SELECT max(grup_id) + 1, 'CADASTRO PERFORMANCE', 'CADPERF', 1, now() FROM seguranca.grupo;
