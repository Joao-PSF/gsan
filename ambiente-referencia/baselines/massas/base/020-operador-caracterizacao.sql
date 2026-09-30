-- Massa base — operador da caracterização (Fase 2).
--
-- As operações dos cenários são executadas pelas telas do GSAN, autenticadas. O grupo
-- ADMINISTRADOR da base de referência só tem as concessões que as migrações criaram (Fase 1,
-- relatório §17) e não é alterado aqui: a caracterização usa um operador SINTÉTICO, num grupo
-- próprio, com concessões explícitas — uma linha por operação que um lote capturado exige.
--
-- 🔴 Sem senha: usur_nmsenha fica nula aqui. O executor (ferramentas/executor.py) gera uma senha
-- aleatória a cada execução, grava só o hash no formato do legado e a descarta ao terminar.
-- Situação, abrangência, tipo e empresa: os mesmos do usuário `admin` da semente (id 1).

INSERT INTO seguranca.grupo (grup_id, grup_dsgrupo, grup_dsabreviado, grup_icuso, grup_tmultimaalteracao, grup_icsuperintendencia)
VALUES (1001, 'CARACTERIZACAO FASE 2 (SINTETICO)', 'CAR', 1, '2026-01-01 00:00:00', 2);

INSERT INTO seguranca.usuario
  (usur_id, utip_id, usur_nmlogin, usur_nmsenha, usur_tmultimaalteracao, usst_id, usab_id, empr_id,
   usur_nmusuario, usur_ictiporelatoriopadrao, usur_icexibemensagem, usur_icrotinabatch, usur_icinternet)
VALUES (1001, 1, 'fase2.oper', NULL, '2026-01-01 00:00:00', 1, 1, 1,
        'OPERADOR DE CARACTERIZACAO (SINTETICO)', 1, 1, 2, 2);

INSERT INTO seguranca.usuario_grupo (grup_id, usur_id, usgr_tmultimaalteracao) VALUES (1001, 1001, '2026-01-01 00:00:00');

-- Concessões (grupo, operação, funcionalidade) — ids do catálogo das migrações.
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  -- [UC0157] Simular Cálculo da Conta (CEN-FAT-001, CEN-MIC-002): a simulação e o popup de categoria.
  (1001, 458, 364, '2026-01-01 00:00:00'),
  (1001, 394, 316, '2026-01-01 00:00:00'),
  -- [UC0472] Consultar Imóvel — aba Dados Cadastrais (CEN-CAD-003).
  (1001, 303, 241, '2026-01-01 00:00:00');
