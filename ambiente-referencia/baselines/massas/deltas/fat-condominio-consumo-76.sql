-- Delta — o IMV-C de fat-condominio-micros.sql consome 76 m³ em 05/2026: a ratear 31 m³ — um volume que não se divide
-- igualmente entre as 2 economias (lote 5b: CEN-FAT-006 V2). Depende de fat-condominio-micros.sql. SINTÉTICO.
UPDATE micromedicao.consumo_historico SET cshi_nnconsumofaturadomes = 76 WHERE cshi_id = 11;
