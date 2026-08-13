# Modelo de Segurança Legado

Levantamento do comportamento atual — base para reprodução fiel no sistema novo (Fase 5) antes de qualquer fortalecimento.

## Autenticação

- Login próprio (tabela `seguranca.usuario`): `usur_nmlogin` (máx. 11 chars), `usur_nmsenha` varchar(40).
- Hash de senha: **MD5 sem salt** (`gcom.util.Util`) e **SHA-1 sem salt** (`gcom.util.Criptografia`) — mapear exatamente onde cada um é usado antes de migrar.
- Controles existentes a preservar: expiração de acesso (`usur_dtexpiracaoacesso`), bloqueio (`usur_nnbloqueioacesso`, `usuario_periodo_bloqueio`), histórico de senhas (`usuario_senha_historico`), senhas inválidas (`senha_invalida`), afastamento de usuário, solicitação de acesso com workflow (`solicitacao_acesso*`).
- Sessão: `HttpSession` do container (JBoss), sem atributos modernos de cookie configurados.
- Tokens de API: tabela `seguranca.token` (adição de 2024) + parâmetro `INDICADOR_VALIDA_TOKEN`; serviço externo `gsan-relatorios` consumido com token via `api/GsanApi`.

## Autorização (RBAC próprio — 53 tabelas no schema `seguranca`)

- Estrutura: `usuario` → `usuario_grupo` → `grupo` → `grupo_func_operacao` → `funcionalidade`/`operacao`; exceções via `permissao_especial`, `grupo_permissao_especial`, `usuario_permissao_espec`; restrições por grupo (`usuario_grupo_restricao`) e abrangência (`usuario_abrangencia`, localidade/gerência regional no próprio usuário).
- Granularidade por funcionalidade e operação (URL/ação), com categorias (`funcionalidade_categoria`) e dependências (`funcionalidade_depend`).
- Auditoria de uso: `operacao_efetuada`, `usuario_acao`, alteração de linhas (`tabela_linha_alteracao`, `tab_linha_col_alteracao`) — trilha de auditoria de dados feita pela aplicação.
- **Regra da modernização**: o Spring Security deverá consumir essas mesmas tabelas (perfis, grupos, funcionalidades, permissões especiais e abrangência) — não substituir o modelo sem mapeamento completo.

## Superfícies expostas

- Aplicação web Struts (`*.do`, JSPs) atrás de verificação de sessão própria.
- APIs servlet `/api/pagamentoCredito/*` e `/api/ordem-servico/*`: "autenticação" por comparação do domínio da URL requisitada com hosts hard-coded **HTTP** (`gsan.cosanpa.pa.gov.br`) — trivialmente contornável (ver riscos).
- `/autocomplete` genérico, web services Axis2, applet de impressão assinado(?), upload de arquivos (retornos bancários, leituras, fotos de campo).

## Credenciais e segredos conhecidos

- Roles de banco criadas com **senha igual ao login** em script versionado público (`gsan-migracoes/comercial/scripts/20160118183208_create_roles.sql`: `gsan_admin`, `gsan_batch`, `gsan_dba`, `gsan_olap`, `gsan_online`) — considerar comprometidas.
- Credenciais reais do datasource ficam nos `*-ds.xml` do JBoss nos servidores — inventariar e rotacionar.
