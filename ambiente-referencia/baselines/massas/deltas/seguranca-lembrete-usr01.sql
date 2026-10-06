-- Delta — CEN-SEG-006 V3: USR-01 já tem o lembrete de senha que a troca vai submeter. Na troca, o campo
-- anotado para a operação 52 (lembreteSenha) não muda; só a senha (usur_nmsenha, sem @ControleAlteracao em
-- Usuario.java) e o carimbo de última alteração mudam. Valor SINTÉTICO.
UPDATE seguranca.usuario SET usur_dslembretesenha = 'LEMBRETE SINTETICO' WHERE usur_id = 2001;
