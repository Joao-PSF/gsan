# Segurança — Riscos Identificados (Fase 0)

Achados do diagnóstico inicial. Nenhuma correção aplicada ainda; prioridades P0 (imediato), P1 (antes do primeiro deploy novo), P2 (durante a migração dos módulos).

| # | Achado | Evidência | Risco | Prioridade / ação |
| - | ------ | --------- | ----- | ----------------- |
| 1 | Senhas de usuário com MD5/SHA-1 sem salt | `gcom/util/Util.java` (MD5), `gcom/util/Criptografia.java` (SHA-1); `usur_nmsenha varchar(40)` | Quebra trivial por rainbow table em caso de vazamento | P1: novo sistema autentica contra hash legado e re-hasheia no primeiro login com BCrypt/Argon2 (coluna nova); política de expiração acelera a troca |
| 2 | Credenciais de banco padrão versionadas (senha = login) | `gsan-migracoes/.../20160118183208_create_roles.sql` | Acesso direto ao banco se exposto na rede | P0: rotacionar todas as roles `gsan_*`; verificar `pg_hba.conf` e exposição de rede; considerar comprometidas |
| 3 | API com pseudo-autenticação por domínio, HTTP sem TLS | `gcom/api/pagamentocredito/PagamentoCreditoFilter.java` (compara domínio da URL com hosts hard-coded `http://`) | Endpoints de pagamento/OS efetivamente abertos (spoof de Host/URL) | P0: avaliar exposição real na rede; colocar atrás de proxy com TLS + token real (tabela `seguranca.token`) já no legado se exposto externamente |
| 4 | ~830 pontos de SQL/HQL concatenado | `Repositorio*HBM` (grep de concatenação em WHERE) | SQL Injection | P1/P2: no código novo, 100% parametrizado; no legado, corrigir sob demanda os fluxos expostos a entrada direta do usuário |
| 5 | Ausência de TLS ponta a ponta | domínios `http://` hard-coded; JBoss 4 sem config TLS no repo | Credenciais e dados pessoais em claro | P0/P1: TLS no proxy reverso na frente do legado; HSTS/cookies `Secure` no novo |
| 6 | Sessões/cookies sem atributos modernos | `web.xml` sem `HttpOnly`/`Secure`/`SameSite` (Servlet 2.x não suporta) | Sequestro de sessão, CSRF | P1: proxy pode adicionar atributos; novo sistema com Spring Security (CSRF, fixation, timeout) |
| 7 | Stack EOL sem patches (JBoss 4.0.1, Struts 1.1, log4j 1.x, Axis2 1.5.1, commons-httpclient 3, Hibernate 3) | `lib/`, `build.xml` | CVEs conhecidos sem correção disponível | P1: reduzir exposição de rede do legado (só via proxy); a mitigação definitiva é a própria modernização |
| 8 | Dados pessoais (LGPD) em base e logs | Clientes com CPF/NIS, `consulta_receita_federal`, `consulta_cdl`; 70 colunas `bytea` com documentos | Vazamento/uso indevido | P2: anonimização obrigatória em massas de teste; revisão de logs no sistema novo; inventário de dados pessoais por tabela |
| 9 | Upload de arquivos sem validação centralizada | commons-fileupload antigo; múltiplos fluxos (retornos bancários, fotos, leituras) | Upload malicioso | P2: validação de tipo/tamanho/conteúdo centralizada no novo; armazenar fora do webroot |
| 10 | Trilha de auditoria dependente da aplicação | `operacao_efetuada`, `tabela_linha_alteracao` preenchidas via código | Escritas fora da aplicação não auditadas | P2: preservar trilha no novo sistema; avaliar auditoria complementar no banco para tabelas financeiras |

## Regras desde já

- Qualquer segredo encontrado em código, script ou configuração é considerado comprometido e entra na lista de rotação.
- Nenhuma melhoria pode reduzir controles existentes (expiração, bloqueio, histórico de senha, permissões especiais, abrangência, auditoria).
- Secrets do sistema novo: fora do código, por ambiente (variáveis/cofre), com contas de banco distintas por finalidade e menor privilégio no PostgreSQL.
