# Modelo de Segurança Legado

Levantamento do comportamento atual — base para reproduzir o **modelo conceitual** de segurança no SISAN (Fase 5) antes de qualquer fortalecimento. As estruturas físicas podem evoluir (ADR-0006); o modelo de autorização, não, sem mapeamento completo.

## Autenticação

- Login próprio (tabela `seguranca.usuario`): `usur_nmlogin` (máx. 11 chars), `usur_nmsenha` varchar(40).
- Hash de senha: **SHA-1 sem salt** (`gcom.util.Criptografia.encriptarSenha` → `MessageDigest.getInstance("SHA")`). **Precisão obtida em 2026-08-14**: o **login usa SHA-1** — `ControladorAcessoSEJB.validarUsuario` consulta o usuário filtrando por `LOGIN` + `SENHA = Criptografia.encriptarSenha(senha)`, ou seja, a validação é uma **consulta que casa login+hash**, não uma comparação em memória. O **MD5** (`gcom.util.Util.md5`) **não participa do login**: é usado para gerar **token efêmero** de acesso aos servlets auxiliares (`AcessarOperacionalServlet`, `AcessarNovoBatchServlet`). Ver [modulos/seguranca.md §4](../modulos/seguranca.md).
- Controles existentes a preservar: expiração de acesso (`usur_dtexpiracaoacesso`), bloqueio (`usur_nnbloqueioacesso`, `usuario_periodo_bloqueio`), histórico de senhas (`usuario_senha_historico`), senhas inválidas (`senha_invalida`), afastamento de usuário, solicitação de acesso com workflow (`solicitacao_acesso*`).
- Sessão: `HttpSession` do container (JBoss), sem atributos modernos de cookie configurados.
- Tokens de API: tabela `seguranca.token` (adição de 2024) + parâmetro `INDICADOR_VALIDA_TOKEN`; serviço externo `gsan-relatorios` consumido com token via `api/GsanApi`.

## Autorização (RBAC próprio — 53 tabelas no schema `seguranca`)

- Estrutura: `usuario` → `usuario_grupo` → `grupo` → `grupo_func_operacao` → `funcionalidade`/`operacao`; exceções via `permissao_especial`, `grupo_permissao_especial`, `usuario_permissao_espec`; restrições por grupo (`usuario_grupo_restricao`) e abrangência (`usuario_abrangencia`, localidade/gerência regional no próprio usuário).
- Granularidade por funcionalidade e operação (URL/ação), com categorias (`funcionalidade_categoria`) e dependências (`funcionalidade_depend`).
- Auditoria de uso: `operacao_efetuada`, `usuario_acao`, alteração de linhas (`tabela_linha_alteracao`, `tab_linha_col_alteracao`) — trilha de auditoria de dados feita pela aplicação.
- **Comportamento comprovado (2026-08-14)**: a autorização é aplicada por um **filtro de servlet central** (`FiltroSegurancaAcesso`, mapeado para `*.do`) que resolve **funcionalidade e operação pela URL** e concede por **união dos grupos** (`GrupoFuncionalidadeOperacao`), com **abrangência** como segundo eixo e **permissões especiais nomeadas** como exceções dentro da funcionalidade. Detalhamento funcional em [modulos/seguranca.md](../modulos/seguranca.md); atenção especial a dois achados: a abrangência **depende de verificações explícitas** em cada consulta, e o uso de `UsuarioGrupoRestricao` no cálculo **não foi comprovado**.
- **Regra da modernização**: o Spring Security do SISAN deverá reproduzir esse modelo conceitual (perfis, grupos, funcionalidades, operações, permissões especiais e abrangência) — as tabelas podem ser modernizadas (ADR-0006), mas o modelo de autorização não será substituído sem mapeamento completo, e a migração de perfis/permissões de instalações GSAN deve ser possível.

## Superfícies expostas

- Aplicação web Struts (`*.do`, JSPs) atrás de verificação de sessão própria.
- APIs servlet `/api/pagamentoCredito/*` e `/api/ordem-servico/*`: "autenticação" por comparação do domínio da URL requisitada com hosts hard-coded **HTTP** (`gsan.cosanpa.pa.gov.br`) — trivialmente contornável (ver riscos).
- `/autocomplete` genérico, web services Axis2, applet de impressão assinado(?), upload de arquivos (retornos bancários, leituras, fotos de campo).

## Credenciais e segredos conhecidos

- Roles de banco criadas com **senha igual ao login** em script versionado público (`gsan-migracoes/comercial/scripts/20160118183208_create_roles.sql`: `gsan_admin`, `gsan_batch`, `gsan_dba`, `gsan_olap`, `gsan_online`) — considerar comprometidas.
- Credenciais reais do datasource ficam nos `*-ds.xml` do JBoss dos servidores de cada instalação — em instalações operantes, inventariar e rotacionar (item do checklist de migração futura; este projeto não opera infraestrutura GSAN). Nenhuma dessas credenciais deve ser reutilizada em qualquer ambiente SISAN.
