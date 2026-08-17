# [2026-08-14] Mapa funcional da Segurança (+ ajustes de precisão do Atendimento)

- **Atividade**: análise **funcional** dos quatro eixos de segurança (autenticação, autorização, abrangência, auditoria) seguindo os fluxos de execução. **Complementa** — não substitui — `seguranca/modelo-legado.md` e `seguranca/riscos-identificados.md`, que permanecem como diagnóstico de mecanismos e riscos. Nenhuma implementação realizada; nenhum inventário de vulnerabilidades refeito.
- **Documentos criados**: `docs/modernizacao/modulos/seguranca.md` (29 seções, com níveis de certeza).
- **Documentos alterados**: `modulos/atendimento.md` (três ajustes de precisão — ver [registro próprio](2026-08-14-ajustes-precisao-atendimento.md) — e §31 com a fronteira de autorização resolvida), `seguranca/modelo-legado.md` (precisão sobre onde SHA-1 e MD5 são usados + comportamento comprovado da autorização), `modulos/README.md`, `docs/modernizacao/README.md`, `MODERNIZACAO_GSAN.md`.

## Principais descobertas

- **A autorização é centralizada num Servlet Filter** (`FiltroSegurancaAcesso`, mapeado no `web.xml` para `*.do`) que verifica funcionalidade, operação e abrangência a cada requisição — logo **acesso direto por URL a funcionalidade fora do menu é barrado**; o menu não é o controle.
- **Funcionalidade e Operação são resolvidas pela URL** (`CAMINHO_URL`), e a concessão é o trio **grupo × funcionalidade × operação** em `GrupoFuncionalidadeOperacao`.
- **Modelo de grant positivo com união dos grupos**: basta um grupo conceder; **nenhum deny observado** no caminho de decisão. `FuncionalidadeDependencia` participa (funcionalidade principal habilita dependentes).
- **`UsuarioGrupoRestricao` existe mas seu uso no cálculo não foi comprovado** — lacuna de alta prioridade registrada como dúvida (a existência da tabela não prova o uso).
- **Permissões especiais são capacidades nomeadas verificadas dentro da Action** (`verificarPermissaoEspecial`), para exceções — comprovadas: instalação de hidrômetro sem RA, ligação de esgoto sem RA, replicar valor de cobrança de serviço, encerrar comando de cobrança por empresa.
- **Abrangência** é territorial e hierárquica (gerência regional, unidade de negócio, elo/polo, localidade) — e sua aplicação **depende de chamadas explícitas** em Actions/controladores além do filtro (`Fachada`, imóvel, localidade, arrecadação, micromedição): **risco estrutural de autorização por omissão**.
- **Unidade organizacional ≠ abrangência**: a primeira posiciona o usuário no fluxo de trabalho; a segunda define o recorte de dados. Não foi identificado bloqueio de autorização por unidade.
- **Autenticação é uma consulta que casa login + hash SHA-1** (`validarUsuario` com `FiltroUsuario.SENHA = Criptografia.encriptarSenha`), montando o contexto do usuário (território, unidade, abrangência) no login. **MD5 não participa do login** — é token efêmero de servlets auxiliares (precisão aplicada ao `modelo-legado.md`).
- **Situação, senha bloqueada e expiração são eixos independentes**; `PENDENTE_SENHA` permite entrar para trocar a senha; tentativas são contadas **na sessão** e o excesso bloqueia a senha.
- **Auditoria em dois níveis**: `OperacaoEfetuada` + `RegistradorOperacao` (quem executou qual operação sobre quais objetos) e trilha por **linha/coluna** via `@ControleAlteracao` + `Interceptador` — **restrita ao que está anotado**.
- **Identidade de sistema para batch** (`Usuario.USUARIO_BATCH`) e superfícies **fora do RBAC de tela** (APIs/servlets fora de `*.do`, URLs isentas por properties).
- **Workflow de solicitação de acesso** por grupos, com situação própria e relatório de acompanhamento — governança, não apenas permissão estática.

- **Fronteira do Atendimento**: resolvida no que diz respeito ao mecanismo (filtro + permissões especiais nomeadas + abrangência); permanecem em aberto o controle por unidade organizacional e as ações sem permissão especial nomeada.
- **Cenários**: 24 identificados. **Dúvidas abertas**: 12, com destaque para o uso das restrições no cálculo de autorização e a autorização nos fluxos batch (encaminhada ao próximo mapa).
- **Testes**: n/a (documental) · **Risco**: baixo · **Rollback**: `git revert` do commit.
