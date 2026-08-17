# Módulo Segurança — Mapa Funcional

Elaborado em 2026-08-14 (Fase 0). **Este documento é complementar** aos já existentes: o diagnóstico de mecanismos e fragilidades está em [seguranca/modelo-legado.md](../seguranca/modelo-legado.md) e [seguranca/riscos-identificados.md](../seguranca/riscos-identificados.md) — **não repetidos aqui**. A pergunta desta análise é outra: **como funciona, funcionalmente, o modelo de identidade, autenticação, autorização, abrangência e auditoria do GSAN?**

Fontes: `gcom.seguranca.acesso` (+ `usuario`), `gcom.interceptor`, `gcom.gui.util.FiltroSegurancaAcesso`, `web.xml`, mapeamentos e DDL. **Convenção**: 🟢 fato comprovado · 🔵 interpretação funcional sustentada · 🟡 hipótese · ❔ não compreendido (§28).

## 1. Responsabilidade

A Segurança responde por quatro eixos **distintos** que o GSAN mantém separados: **autenticação** (quem é o usuário), **autorização** (que funcionalidade/operação pode executar), **abrangência** (sobre qual território/dados pode atuar) e **auditoria** (o que fica registrado sobre operações e alterações de dados). Há ainda um quinto elemento, organizacional e não estritamente de segurança: a **unidade organizacional**, que posiciona o usuário no fluxo de trabalho.

## 2. Identidade e Usuário

🟢 `seguranca.usuario` (id `usur_id`, login `usur_nmlogin` até 11 caracteres, senha `usur_nmsenha` varchar(40)) reúne **cinco eixos** cujos papéis são diferentes:

| Eixo | Campos/relações | Papel |
| ---- | --------------- | ----- |
| Identificação | login, nome, e-mail, `func_id` (funcionário), empresa | Quem é a pessoa |
| Classificação | `utip_id` (`UsuarioTipo`) | Natureza do usuário |
| Estado | `usst_id` (`UsuarioSituacao`), contadores e datas (§3) | Se pode entrar agora |
| Autorização | `usuario_grupo` → grupos (§9), permissões especiais (§11) | O que pode fazer |
| Território/organização | `unid_id` (unidade organizacional), `greg_id` (gerência regional), `loca_id`, `loca_cdelo` (localidade elo), `usab_id` (`UsuarioAbrangencia`) | Onde trabalha e o que pode ver (§13/§14) |

🟢 Na autenticação, o sistema carrega explicitamente gerência regional, localidade elo, localidade, situação, tipo, unidade organizacional (+ tipo), funcionário, empresa e **abrangência** (`validarUsuario`, `ControladorAcessoSEJB:1690` — lista de `adicionarCaminhoParaCarregamentoEntidade`). 🔵 Isso indica que o **contexto de segurança do usuário é montado no login**, não consultado a cada decisão.

## 3. Ciclo de vida do usuário

🟢 Situações comprovadas em uso no fluxo de login: **ATIVO**, **INATIVO**, **PENDENTE_SENHA**, **SENHA_BLOQUEADA** (`EfetuarLoginAction`:155, 181, 275–276, 310). 🟢 Regra de admissão: só passam **ATIVO** ou **PENDENTE_SENHA** (`verificarSituacaoUsuario`:266–276) — 🔵 ou seja, `PENDENTE_SENHA` é um estado que **permite entrar para trocar a senha** (primeiro acesso/senha redefinida), e não um bloqueio.

🟢 **Expiração é eixo independente da situação**: `dataExpiracaoAcesso` é verificada separadamente (`:168–174`), com aviso de dias restantes calculado antes do login (`:89`). 🟢 **Bloqueio por tentativas**: o número de tentativas é contado **na sessão** (`numeroTentativas`, `loginUsuarioSessao`) e, ao exceder o permitido, o sistema **bloqueia a senha** (`bloquearSenha(login)` → situação `SENHA_BLOQUEADA`, `:142`, `:310`).

🔵 Portanto, três conceitos distintos que o SISAN precisa manter separados: **inativo** (usuário desativado), **senha bloqueada** (consequência de tentativas), **acesso expirado** (validade vencida — o usuário continua cadastrado, com grupos preservados). 🟢 Complementos do modelo (já inventariados no documento preliminar): `usuario_periodo_bloqueio`, `usuario_afastamento` (+ motivo), `usuario_senha_historico`, `senha_invalida`, datas de cadastro/início/fim, `usur_nnacessos`, `usur_tmultimoacesso`.

❔ Não comprovei nesta análise se `usur_nnacessos` conta acessos bem-sucedidos ou tentativas, nem o limite exato de tentativas (parâmetro do sistema).

## 4. Autenticação

🟢 Fluxo comprovado: `EfetuarLoginAction` → `Fachada.validarUsuario(login, senha)` → `ControladorAcessoSEJB.validarUsuario` (:1690), que monta um `FiltroUsuario` com **login** e **`FiltroUsuario.SENHA = Criptografia.encriptarSenha(senha)`** e consulta o usuário.

🔵 Consequência funcional relevante: **a autenticação é uma consulta que casa login + hash** — não há leitura do hash armazenado seguida de comparação em memória. Se a consulta retorna usuário, a credencial é válida; se retorna nulo, o fluxo trata como senha inválida (incrementa tentativas na sessão e, no limite, bloqueia).

🟢 **Algoritmo do login: SHA-1** — `Criptografia.encriptarSenha` usa `MessageDigest.getInstance("SHA")` (`gcom/util/Criptografia.java:17`), sem salt. 🟢 O **MD5** de `Util` **não é usado no login**: aparece na geração de tokens de acesso a servlets auxiliares (`AcessarOperacionalServlet:48`, `AcessarNovoBatchServlet:98`, com `md5(nomeUsuario + timestamp)`). 🔵 Isso corrige uma leitura possível do diagnóstico preliminar: os dois algoritmos existem, mas em papéis distintos — **SHA-1 para senha, MD5 para token efêmero de acesso a módulos auxiliares**.

🟢 Após validar, o RA de segurança é a sessão: `usuarioLogado` é colocado na `HttpSession` e é a base de tudo depois (§6). ❔ Não comprovei existência de fluxo de redefinição/recuperação autônoma de senha nem política de complexidade.

## 5. Senhas

🟢 Estruturas do modelo: `usuario_senha_historico` (histórico de senhas anteriores), `senha_invalida` (🔵 lista de senhas proibidas — blacklist), `usuario_periodo_bloqueio`, e geração de senha com `Criptografia.encriptarSenha(senhaGerada)` no fluxo administrativo (`ControladorUsuarioSEJB:239`). 🔵 A existência de histórico + blacklist indica **política de reutilização e de senhas proibidas aplicada na troca**. ❔ Quantidade de senhas anteriores bloqueadas, validade mínima/máxima e regras de complexidade **não foram comprovadas** — são parâmetros a levantar.

Fragilidades criptográficas: já documentadas em `riscos-identificados.md`; aqui interessa a **semântica a preservar** (histórico, blacklist, expiração, bloqueio) versus a **implementação a substituir** (SHA-1 sem salt) — ver §25.

## 6. Sessão

🟢 `usuarioLogado` na `HttpSession`; o filtro de segurança o recupera em cada requisição (`FiltroSegurancaAcesso:96–99`). 🟢 Contadores de tentativa de login também vivem na sessão. 🟢 Há uma lista de URLs isentas de usuário em sessão, carregada de `urls_sem_usuario_na_sessao.properties` (`:62`).

🔵 Ponto importante para compatibilidade: **as permissões não são recarregadas a cada requisição a partir do zero** — o contexto do usuário vem da sessão, mas **a decisão de autorização é consultada no banco a cada requisição** (§7), o que significa que alterações de grupo/permissão tendem a valer na próxima requisição, sem necessidade de novo login. 🟡 Hipótese não fechada: se os **grupos** são recarregados ou vêm da sessão (a coleção de grupos é passada como parâmetro para os métodos de verificação).

## 7. Modelo de autorização — onde é efetivamente aplicada

🟢 **Descoberta central**: existe um **gate transversal** para rotas web — `gcom.gui.util.FiltroSegurancaAcesso`, mapeado no `web.xml` para **`*.do`**. ⚠️ **Precisão (revisão 2026-08-14)**: o fluxo **não é** uma sequência universal "funcionalidade → operação → abrangência". O código real é:

```text
REQUISIÇÃO *.do
   ↓
FiltroSegurancaAcesso
   ├─ usuarioLogado ausente? → tratamento próprio (há lista de URLs sem usuário na sessão, via properties)
   ├─ a URL está na LISTA DE EXCEÇÕES do próprio filtro (contains/toLowerCase)? 
   │     → SIM: segue SEM este bloco de autorização funcional
   └─ NÃO:
        tipoURL = fachada.verificarTipoURL(enderecoURL)
          ├─ "funcionalidade" → verificarAcessoPermitidoFuncionalidade
          │                      nega → /jsp/util/acesso_negado_funcionalidade.jsp
          │                      permite → segue (SEM verificação de abrangência neste ramo)
          ├─ "operacao"       → verificarAcessoPermitidoOperacao
          │                      nega → /jsp/util/acesso_negado_operacao.jsp
          │                      permite → SE houver contexto de abrangência na requisição:
          │                                  verificarAcessoAbrangencia
          │                                    nega → /jsp/util/acesso_negado_abrangencia.jsp
          │                                  (sem contexto de abrangência → segue)
          └─ tipoURL == null  → acesso negado (funcionalidade)
```

🔵 Três consequências funcionais que a formulação anterior escondia: (a) **funcionalidade e operação são caminhos alternativos** (a URL é classificada como um ou outro), não etapas encadeadas; (b) a **abrangência é verificada condicionalmente** — apenas no ramo "operação" e apenas quando há contexto de abrangência na requisição; (c) **URL não catalogada é negada** (`tipoURL == null` → acesso negado), o que é um padrão *fail-closed* para o que passa pelo bloco.

🟢 **URL direta (calibrado)**: para **rotas protegidas e não excepcionadas**, digitar o endereço direto **continua passando pelo filtro** — a autorização não depende do menu. Porém, **rotas explicitamente excepcionadas** pelo próprio filtro **não passam por esse bloco**, e **superfícies fora de `*.do`** (servlets, APIs — §22) seguem mecanismos próprios. 🔵 Ou seja: o filtro é o **principal gate transversal identificado para rotas web protegidas**, mas **não constitui, sozinho, uma política universal de autorização de todas as superfícies do GSAN** — controles internos nas Actions/controladores (permissões especiais, abrangência, regras de negócio) completam o quadro.

### Exceções do filtro — por categoria (não inventário)

🟢 A lista de exclusões é feita por `contains()` sobre a URL (algumas em `toLowerCase`), agrupável em:

| Categoria | Exemplos observados |
| --------- | ------------------- |
| Autenticação/sessão | Login, Logoff, telaPrincipal, alteração de senha (normal e simplificada), carregar parâmetros |
| Consultas/relatórios | qualquer URL contendo **`pesquisar`** ou **`relatorio`** (case-insensitive), popups de consulta (dados de pagamento, situação especial de faturamento/cobrança, histórico de alteração) |
| Integrações/dispositivos | dispositivo móvel (inclusive impressão simultânea, acompanhamento de serviço, recadastramento), telemetria, GIS (requisição e coordenadas) |
| Portal/público | `portal`, segunda-via-conta, extrato-débitos, certidões (imóvel/cliente), lojas/canais de atendimento, parcelamento-débitos, cadastro/validação de login do cliente, "água para" |
| Rotina específica | **`executarBatch`** (ver ressalva abaixo) |
| Outras | treinamentos, informar melhorias |

⚠️ 🔵 A exceção por **substring `pesquisar`/`relatorio`** é a de maior alcance: qualquer Action cujo nome contenha esses termos sai do bloco de autorização funcional do filtro. Isso não significa ausência de qualquer controle (a Action pode ter verificações próprias), mas é característica estrutural relevante do legado.

🔵 **Aprofundamento (2026-08-14, [mapa de Relatórios §16–17](relatorios.md))**: no caso dos relatórios, a autorização tende a ocorrer **antes**, na tela chamadora (Action de funcionalidade não excepcionada) que monta os filtros e submete a solicitação; e o filtro só avalia requisições com **usuário em sessão**. ⚠️ Porém, a Action de **download** do relatório batch (`ExibirRelatorioBatchAction`) localiza o artefato **apenas pelo `idFuncionalidadeIniciada` recebido no request**, e **nenhuma comparação com o usuário logado foi localizada** no trecho analisado — combinado com a exceção de URL, isso torna a verificação de acesso ao artefato uma **dúvida prioritária** (não é declaração de vulnerabilidade; exige rastreio dirigido).

⚠️ 🟢 **Ressalva importante sobre `executarBatch`**: a exceção **não** significa que o framework Batch opere sem autorização. `gcom.batch.ExecutarBatch` é uma **Action Struts específica** (`extends GcomAction`, ~2 KB, mapeada em `struts-config.xml` como `/executarBatch`) que apenas invoca `ControladorOrdemServico.atualizarOrdemServicoAcompanhamentoServico(...)` — é uma **rotina pontual ligada ao Atendimento/OS**, não o disparo do framework de processamento em lote. A autorização dos fluxos batch é analisada em [batch.md §17](batch.md).

🟢 Como a decisão é calculada (`verificarAcessoPermitidoFuncionalidade`:2664 e `verificarAcessoPermitidoOperacao`:3137):
- resolve `Funcionalidade` por **`CAMINHO_URL`** (ou por id) — e `Operacao` também por **`CAMINHO_URL`**, obtendo dela a funcionalidade dona;
- monta a lista de **funcionalidades permitidas** incluindo as **funcionalidades principais** obtidas via `FuncionalidadeDependencia`;
- consulta **`GrupoFuncionalidadeOperacao`** filtrando por (funcionalidade ∈ lista) **OR**-encadeadas, pela operação, e pelos **grupos do usuário** (também OR);
- **se existir ao menos um registro → permitido**.

🔵 Portanto o modelo é de **grant positivo com união dos grupos**: basta um grupo conceder. 🟢 A operação é ancorada na funcionalidade (`Operacao.getFuncionalidade()`), e o par funcionalidade+operação é a unidade de concessão.

## 8. Módulo / Funcionalidade / Operação

🟢 Entidades: `Modulo`, `FuncionalidadeCategoria`, `Funcionalidade` (+ `FuncionalidadeCaracteristica`, `FuncionalidadeDependencia`), `Operacao` (+ `OperacaoTipo`, `OperacaoTabela`, `OperacaoOrdemExibicao`), e `CasoDeUso` (+ `CasoDeUsoTipo`).

🔵 Interpretação funcional: **Funcionalidade ≈ tela/caso de uso acessível por URL**; **Operação ≈ ação executável dentro dela, também endereçável por URL**; **Módulo/Categoria** organizam a árvore (menu e administração de acesso). 🟢 O que é **efetivamente usado na autorização** é o par **Funcionalidade × Operação × Grupo** resolvido por URL — comprovado no fluxo do filtro. 🟡 `CasoDeUso`/`CasoDeUsoTipo` parecem estrutura paralela/legada de catalogação (não apareceram no caminho de decisão) — ❔ papel atual não confirmado.

🟢 **`FuncionalidadeDependencia` participa da autorização**: a verificação inclui as funcionalidades principais das quais a funcionalidade acessada depende — 🔵 conceder acesso a uma funcionalidade principal habilita o acesso às suas dependentes nesse cálculo. ❔ `FuncionalidadeCaracteristica` não apareceu no caminho de decisão; papel (comportamento/menu/cadastro) não determinado.

## 9. Grupo e concessões

🟢 `Grupo` + `usuario_grupo` (N:N) + **`GrupoFuncionalidadeOperacao`** (chave composta grupo × funcionalidade × operação) + `GrupoAcesso`. 🔵 O Grupo é um **perfil funcional** (conjunto de concessões), não um cargo nem uma unidade; um usuário pode pertencer a vários e **as concessões se somam** (§7). 🟢 Existe `grupo_permissao_especial` (permissões especiais atribuídas ao grupo — §11) e `grupo_func_operacao` como núcleo das concessões comuns.

❔ Não comprovei: existência de grupo padrão, hierarquia entre grupos, validade temporal do vínculo usuário×grupo.

## 10. Restrições

🟢 `UsuarioGrupoRestricao` existe e seu mapping vincula-se a **`GrupoFuncionalidadeOperacao`** e a **`UsuarioGrupo`** (ambas as associações com `update="false" insert="false"` sobre a coluna `grup_id`) — 🔵 ou seja, a restrição é modelada **no cruzamento entre um vínculo usuário-grupo e uma concessão específica do grupo**, o que sugere semântica de **"este usuário, neste grupo, não recebe esta concessão"**.

❔ **Não comprovei que a restrição participe do cálculo de autorização do filtro**: os métodos `verificarAcessoPermitido*` que li consultam `GrupoFuncionalidadeOperacao` e os grupos do usuário, sem consulta visível a `UsuarioGrupoRestricao`. Isso é uma **lacuna importante** — a existência da tabela não prova o uso (regra do §35 do roteiro). Classificação: **DÚVIDA ABERTA** de alta prioridade, com duas leituras possíveis: (a) a restrição é aplicada em outro ponto (montagem da coleção de grupos/consulta específica), (b) é estrutura pouco utilizada. Precisa de rastreio dirigido antes de qualquer decisão no SISAN.

## 11. Permissões especiais

🟢 Entidades: `PermissaoEspecial`, `usuario_permissao_espec`, `grupo_permissao_especial`, **`ControleLiberacaoPermissaoEspecial`** (com `fclp_icuso`).

🟢 **Uso comprovado e revelador**: permissões especiais são consultadas **explicitamente nas Actions**, por constante nomeada, via `Fachada.verificarPermissaoEspecial(PermissaoEspecial.X, usuarioLogado)`. Exemplos reais encontrados:
- `PermissaoEspecial.ATUALIZAR_INSTALACAO_DO_HIDROMETRO` (`ExibirAtualizarInstalacaoHidrometroAction:67`)
- `PermissaoEspecial.ATUALIZAR_LIGACAO_DE_ESGOTO_SEM_RA` (`ExibirAtualizarLigacaoEsgotoAction:99`)
- `PermissaoEspecial.REPLICAR_VALOR_COBRANCA_SERVICO` (`ExibirInserirValorCobrancaServicoAction:71`)
- `PermissaoEspecial.ENCERRAR_COMANDO_COBRANCA_EMPRESA` (`ExibirConsultarComandosAcompanhamentoCobrancaResultadoAction:69`)

🔵 Interpretação: a permissão especial é uma **capacidade adicional e nomeada**, verificada **dentro** da funcionalidade já autorizada, tipicamente para **exceções** ("fazer sem RA", "alterar/replicar valor", "encerrar comando"). Ela **não substitui** o par funcionalidade/operação do filtro (o usuário precisa antes chegar à tela); **amplia** o que ele pode fazer lá dentro. 🔵 `ControleLiberacaoPermissaoEspecial` funciona como **controle de quais funcionalidades exigem liberação por permissão especial** (há `existeControlePermissaoEspecialFuncionalidade(idFuncionalidade)`, `ControladorAcessoSEJB:5011`, e manutenção própria em :4810/:4896).

❔ Não comprovei: validade temporal das permissões especiais, se podem ignorar abrangência, e como a atribuição por grupo se combina com a atribuição direta ao usuário.

## 12. Precedência da autorização — o que está confirmado e o que não

🟢/🔵 **Confirmado** (fluxo do filtro + métodos de verificação):

```text
requisição *.do
  ├─ 1. IDENTIDADE: usuarioLogado na sessão (situação/expiração validadas no login)
  ├─ 2. FUNCIONALIDADE: URL → Funcionalidade (+ funcionalidades principais via dependência)
  ├─ 3. OPERAÇÃO:      URL → Operacao (e sua funcionalidade dona)
  ├─ 4. CONCESSÃO:     existe GrupoFuncionalidadeOperacao para (func ∈ lista) × operação × (algum grupo do usuário)?
  │                    → UNIÃO dos grupos; basta um conceder; não há deny explícito nesse caminho
  ├─ 5. ABRANGÊNCIA:   verificarAcessoAbrangencia(abrangencia) compara os níveis informados com os do usuário
  └─ 6. se tudo passar → Action executa
         └─ dentro da Action: PERMISSÕES ESPECIAIS nomeadas habilitam exceções pontuais
```

❔ **Não confirmado** (registrado como lacuna, sem inventar fórmula):
1. **Restrições** (`UsuarioGrupoRestricao`) — não observadas no caminho de decisão (§10). Sem isso, não é possível afirmar se existe *deny* efetivo nem sua precedência.
2. Se permissão especial pode **vencer abrangência**.
3. Se a abrangência é sempre aplicada **antes** da função (no filtro ela vem depois das checagens funcionais, mas cada consulta pode reaplicá-la — §13).
4. Interação entre permissão especial por grupo × por usuário.

🔵 O que se pode afirmar com segurança: o modelo é **allow-list por união de grupos, ancorado em URL, com abrangência como segundo filtro e permissões especiais como exceções nomeadas dentro da funcionalidade**.

## 13. Abrangência

🟢 `UsuarioAbrangencia` no usuário + entidade `Abrangencia` usada na verificação. 🟢 `verificarAcessoAbrangencia` (`:4153`) **compara os valores informados na requisição com os do usuário**, nos eixos: **GerenciaRegional**, **UnidadeNegocio**, **Localidade Elo/Polo** e **Localidade** (variáveis `gerenciaRegionalInformada`/`...Usuario`, `unidadeNegocioInformada`, `eloPoloInformado`, `localidadeInformada`), após `carregarAbrangencia(abrangencia)`.

🔵 Interpretação: a abrangência é um **recorte territorial hierárquico por níveis** (do mais amplo ao mais restrito), e a verificação é essencialmente *"o que você pediu está dentro do que sua abrangência permite?"*.

⚠️ 🟢 **Ponto estrutural crítico**: além do filtro, a abrangência é verificada **manualmente em muitos pontos** — `Fachada`, `ControladorImovelSEJB`, `ControladorLocalidadeSEJB`, `ControladorArrecadacao`, `ControladorMicromedicao`, `FiltrarImovelInserirManterContaAction`, `ExibirManterContaAction` chamam `verificarAcessoAbrangencia` / `existeLocalidadeForaDaAbrangenciaUsuario` (`:4412`). 🔵 Conclusão: **a filtragem territorial das consultas não é garantida automaticamente pelo framework** — depende de cada Action/controlador/repositório aplicar a verificação. 🔵 Isso é um **risco estrutural de autorização** (uma consulta nova que esqueça a checagem vaza dados fora da abrangência) e uma diferença importante de projeto para o SISAN. Registrado aqui por ser **fato funcional do modelo**, complementando (sem repetir) o inventário de riscos.

## 14. Unidade organizacional × abrangência

🟢 O usuário tem `unid_id` (unidade organizacional, com tipo), carregada no login; RA e OS têm `unid_idatual`; `Tramite` registra unidade origem/destino e usuários. 🟢 A abrangência é estrutura separada (`usab_id` + eixos territoriais).

🔵 **Resposta à pergunta central**: sim, os papéis são distintos — **unidade organizacional posiciona o usuário no fluxo de trabalho** (de onde ele opera, para onde tramita, qual "caixa" é dele), enquanto **abrangência define o recorte territorial de dados** que ele pode ver/atuar. Não são sinônimos e podem divergir (um usuário de unidade central pode ter abrangência estadual; um de unidade local, abrangência de uma localidade).

❔ **Não comprovei** que a unidade organizacional funcione como *controle de autorização* (isto é, que o sistema impeça um usuário de tramitar/encerrar RA de outra unidade). No caminho de decisão do filtro **não há checagem de unidade** — ela aparece como dado de roteamento/estado. Ver §16.

## 15. Solicitação de acesso

🟢 Existe o conjunto `SolicitacaoAcesso`, `SolicitacaoAcessoSituacao`, `SolicitacaoAcessoGrupo` (+ PK própria) em `seguranca.acesso.usuario`, com tabelas correspondentes (`solicitacao_acesso`, `solicitacao_acesso_grupo`) e relatório de acompanhamento (`GerarRelatorioManterSolicitacaoAcessoSituacaoAction`).

🔵 Interpretação: há **workflow de concessão de acesso** — solicita-se acesso indicando **grupos** pretendidos, a solicitação tem **situação** própria (fluxo de aprovação) e é acompanhável por relatório. 🔵 Isso é governança de acesso, não apenas permissão estática — conceito relevante a preservar. ❔ Quem aprova, se a concessão é automática após aprovação, se há recusa/revogação/validade: **não comprovado**.

## 16. Autorização no Atendimento (fronteira deixada por `atendimento.md`)

Com o mecanismo esclarecido, as ações do Atendimento se classificam assim:

| Ação | Como é controlada | Certeza |
| ---- | ----------------- | ------- |
| Abrir/atualizar RA, gerar OS, encerrar RA, encerrar OS, reativar, tramitar | **Funcionalidade + Operação** (URL) concedidas por grupo, via `FiltroSegurancaAcesso` | 🟢 mecanismo; 🔵 aplicação a cada ação específica |
| Atualizar instalação de hidrômetro **sem RA** | **Permissão especial** `ATUALIZAR_INSTALACAO_DO_HIDROMETRO` (verificada na Action) | 🟢 |
| Atualizar ligação de esgoto **sem RA** | **Permissão especial** `ATUALIZAR_LIGACAO_DE_ESGOTO_SEM_RA` | 🟢 |
| Replicar/alterar valor de cobrança de serviço | **Permissão especial** `REPLICAR_VALOR_COBRANCA_SERVICO` (+ `indicadorPermiteAlterarValor` no tipo de serviço/especificação = **regra de negócio paramétrica**) | 🟢 |
| Encerrar comando de cobrança por empresa | **Permissão especial** `ENCERRAR_COMANDO_COBRANCA_EMPRESA` | 🟢 |
| Atuar sobre imóvel/localidade de outro território | **Abrangência** (verificação no filtro + checagens manuais nos controladores) | 🟢 mecanismo |
| Tramitar/encerrar RA de **outra unidade** | ❔ **Sem controle central identificado** — a unidade aparece como dado de roteamento/estado, não como checagem de autorização no filtro | ❔ |
| Aplicar motivo de não cobrança, liberar OS em "aguardando liberação", alterar prioridade | ❔ Não localizei permissão especial nomeada nem checagem central específica — provável combinação de operação + regra na Action | ❔ |

🔵 **Padrão comprovado**: o GSAN controla o **acesso** de forma central (filtro) e as **exceções** de forma nomeada (permissões especiais nas Actions); regras de negócio parametrizadas (ex.: "permite alterar valor") vivem em tabelas de domínio. 🔵 Quando uma autorização **não** tem funcionalidade/operação própria nem permissão especial, ela tende a ser **regra dentro da Action** — o que significa autorização dispersa e difícil de auditar (característica do legado a considerar no SISAN).

## 17. Operações financeiras sensíveis (amostras)

Usando os módulos já mapeados apenas como amostra, o mesmo padrão se repete: o **acesso** à funcionalidade (retificar conta, cancelar conta, parcelar, desfazer parcelamento, conceder desconto, devolução, alterar vencimento, corte/religação) passa pelo filtro por URL; as **exceções e autorizações especiais** aparecem como permissões especiais nomeadas ou como **estruturas de negócio** (ex.: `ResolucaoDiretoria` no parcelamento — cobranca.md §10; motivos e usuários registrados em desfazimento/cancelamento). 🔵 Ou seja: parte da governança financeira do GSAN está no **domínio** (motivo + usuário + autorização formal registrada), não no RBAC — e isso é semântica a preservar. ❔ Inventário de quais operações financeiras exigem permissão especial não foi feito.

## 18. Menu × autorização efetiva

🟢 Já respondido em §7: o filtro atua sobre `*.do` **exceto** as rotas de sua lista de exceções; o menu é derivado da árvore de funcionalidades (`pesquisarArvoreFuncionalidades`, `:1793`/`:2000`). 🔵 Portanto a segurança **não depende do menu**, mas também **não se resume ao filtro**: há três camadas a considerar — (a) o gate do filtro para rotas protegidas; (b) controles internos nas Actions/controladores (permissões especiais, abrangência, regras de negócio); (c) superfícies fora desse caminho — URLs excepcionadas pelo filtro, páginas de `urls_sem_usuario_na_sessao.properties` e **APIs/servlets fora do mapeamento `*.do`** (§22).

## 19. Auditoria de operação

🟢 `OperacaoEfetuada` + `RegistradorOperacao` (`gcom.interceptor`): o padrão de uso é instanciar `new RegistradorOperacao(Operacao.OPERACAO_X, new UsuarioAcaoUsuarioHelper(usuarioLogado, UsuarioAcao.USUARIO_ACAO_EFETUOU_OPERACAO))`, criar a `OperacaoEfetuada` e chamar `registrarOperacao(objetoTransacao)`, que **associa a operação efetuada ao objeto de negócio** (`objetoTransacao.setOperacaoEfetuada(...)`) — padrão visto em uso real no Faturamento (`informarConsumoMinimoParametro`) e em toda a base.

🔵 Interpretação: a auditoria de operação é **explícita e programática** (o desenvolvedor a declara na operação), correlaciona **usuário + operação + objetos atingidos**, e é o que permite responder "quem executou esta operação". 🟢 `UsuarioAcao` classifica o tipo de ação do usuário na operação. ❔ Se IP, unidade e data/hora ficam registrados na `OperacaoEfetuada` (colunas exatas) não foi confirmado nesta análise.

## 20. Auditoria de dados

🟢 Mecanismo declarativo: anotação **`@ControleAlteracao`** (`gcom.interceptor`), aplicada em classes/atributos ("definir os atributos e classes que serão registradas nas operações efetuadas", com `value()` para o campo de filtro necessário ao carregamento e agrupamento por funcionalidade), + `Interceptador` + as tabelas `tabela_linha_alteracao` e `tab_linha_col_alteracao` (linha e coluna alteradas), com `operacao_tabela` ligando operação a tabela. 🟢 As entidades de domínio estendem `ObjetoTransacao`/`ObjetoGcom` e são anotadas (ex.: `@ControleAlteracao()` em `DebitoTipo`).

🔵 Interpretação: a trilha de dados é **por linha e por coluna**, **restrita ao que está anotado**, e acoplada à operação efetuada (§19) — o que permite reconstituir "nesta operação, este usuário mudou esta coluna desta linha". 🔵 Duas consequências funcionais: (a) **não é auditoria universal** — o que não está anotado não gera trilha; (b) escrita fora da aplicação não passa pelo interceptador (risco já documentado; aqui interessa o mecanismo).

## 21. Usuário Batch

🟢 `Usuario.USUARIO_BATCH` é usado como identidade nas execuções não interativas (ex.: `RelatorioPadraoBatch(Usuario.USUARIO_BATCH)`, geração de OS seletiva/fiscalização em relatórios batch). 🔵 Interpretação: existe uma **identidade de sistema** que carimba operações automáticas — de modo que a auditoria não fique sem autor. 🟢 O modelo tem também `usuario_banco` (contas de banco por usuário) e o servlet `AcessarNovoBatchServlet` gera token MD5 efêmero para acesso ao módulo batch.

**Atualização (2026-08-14, mapa do Batch — [batch.md §14/§15](batch.md))**: 🟢 o **solicitante é registrado** (`ProcessoIniciado.usuario`, gravado com o usuário logado no disparo manual) e a tarefa agendada **carrega um usuário** (JobDataMap) — portanto não é correto dizer que o batch roda sem identidade. 🟢 Há **dois níveis de autorização no disparo**: a tela de batch é uma Action `*.do` sujeita ao gate, e existe **autorização do próprio processo** (`Processo.indicadorAutorizacao` + estado `AGUARDANDO_AUTORIZACAO` + `AutorizarProcessoIniciadoAction`). 🟢 A exceção `executarBatch` do filtro **não** se refere a este framework (§7). ❔ Permanecem abertos: quando `USUARIO_BATCH` substitui o solicitante; se MDB/JMS têm autenticação própria; e se a execução revalida permissões (indício forte de que não). ❔ **Abrangência no batch não foi localizada** — nem nas telas nem no controlador —, então a pergunta continua aberta e virou candidato prioritário de caracterização.

## 22. APIs e tokens

🟢 Fatos: `seguranca.token` e o parâmetro `INDICADOR_VALIDA_TOKEN` (migrations 2024); as APIs `/api/pagamentoCredito/*` e `/api/ordem-servico/*` são **servlets próprios** com `url-pattern` fora de `*.do`, e `/autocomplete` idem. 🔵 Consequência funcional direta: **essas superfícies não passam pelo `FiltroSegurancaAcesso`** — logo **não são cobertas pelo RBAC de funcionalidade/operação**; seguem seus próprios mecanismos (token / filtro próprio). 🔵 Distinção necessária no SISAN: **usuário interativo** (sessão + RBAC) × **cliente de sistema** (credencial própria com escopo). ❔ Escopo, validade e vínculo do token (usuário? sistema? companhia?) não determinados. Fragilidades específicas já em `riscos-identificados.md`.

## 23. Variações por companhia

🟢 Não foram identificadas subclasses por companhia nos controladores de acesso/usuário (`ControladorAcessoSEJB`, `ControladorUsuarioSEJB` — apenas o conjunto padrão). 🔵 A variabilidade esperada é de **dados** (grupos, funcionalidades, operações, permissões especiais, abrangências configuradas por instalação). ⚠️ Não comprovado que toda diferença entre companhias seja apenas paramétrica; classificação REGRA BASE / PARAMETRIZAÇÃO / CUSTOMIZAÇÃO / EVOLUÇÃO POSTERIOR deve ser mantida na análise futura. 🟢 Evolução posterior observada na instalação de referência: `seguranca.token`, `informacoes_armazenamento_bucket`/`inform_armaz_bucket_tabelas`, `func_contr_lib_pmep`.

## 24. Regras estruturantes

1. 🟢 **Existe um gate transversal de autorização para rotas web** (`FiltroSegurancaAcesso`, `*.do`): para rotas protegidas e não excepcionadas, o controle não depende do menu e a URL direta passa por ele. ⚠️ O gate **não é universal** — há lista de exceções no próprio filtro, controles internos nas Actions e superfícies fora de `*.do`.
2. 🟢 **Funcionalidade e Operação são identificadas pela URL** e a concessão é o trio **grupo × funcionalidade × operação**.
3. 🟢 **União dos grupos**: basta um grupo conceder; não há *deny* no caminho de decisão observado.
4. 🟢 **Dependência entre funcionalidades participa** do cálculo (funcionalidade principal habilita dependentes).
5. 🟢 **Permissões especiais são capacidades nomeadas verificadas dentro da funcionalidade**, para exceções — não substituem a concessão comum.
6. 🟢 **Abrangência é um segundo eixo, territorial e hierárquico** (gerência regional, unidade de negócio, elo/polo, localidade).
7. 🟢 **A aplicação da abrangência depende de chamadas explícitas** em Actions/controladores além do filtro — não é garantida pelo framework.
8. 🔵 **Unidade organizacional é posicionamento no fluxo de trabalho**, não controle de autorização no caminho observado.
9. 🟢 **Autenticação é consulta por login + hash** (SHA-1 sem salt), com contagem de tentativas na sessão e bloqueio da senha por situação.
10. 🟢 **Situação, bloqueio de senha e expiração são eixos independentes**; `PENDENTE_SENHA` permite entrar para trocar a senha.
11. 🟢 **Auditoria tem dois níveis distintos**: operação efetuada (quem fez o quê) e alteração de dados por linha/coluna (o que mudou), acoplados e **restritos ao que está anotado**.
12. 🟢 **Existe identidade de sistema para batch** e superfícies (APIs/servlets) **fora do RBAC de tela**.
13. 🟢 **Existe workflow de solicitação de acesso** por grupos, com situação própria — governança, não só permissão estática.

## 25. Compatibilidade GSAN → SISAN

| Conceito | Classificação | Motivo |
| -------- | ------------- | ------ |
| Identidade do usuário (login, vínculo com funcionário/empresa/unidade) | PRESERVAR CONCEITO | Migração de usuários depende de identidade reconhecível |
| Situação do usuário + bloqueio de senha + expiração como eixos separados | PRESERVAR CONCEITO | Semântica operacional distinta; controles atuais não podem ser reduzidos |
| Grupo como perfil funcional e vínculo N:N com usuário | PRESERVAR CONCEITO | Base do RBAC e da migração de perfis |
| Concessão como trio grupo × funcionalidade × operação | PRESERVAR CONCEITO | É a granularidade real do GSAN; migrável 1:1 |
| União de concessões entre grupos | PRESERVAR CONCEITO | Comportamento esperado pelos usuários |
| Permissões especiais como capacidades nomeadas para exceções | PRESERVAR CONCEITO | Padrão maduro; nomes têm significado de negócio |
| Abrangência territorial hierárquica | PRESERVAR CONCEITO | Requisito real de companhias multirregionais |
| Unidade organizacional como posicionamento de fluxo | PRESERVAR CONCEITO | Necessária ao Atendimento |
| Workflow de solicitação de acesso | PRESERVAR CONCEITO | Governança de acesso |
| Auditoria em dois níveis (operação + linha/coluna) | PRESERVAR CONCEITO | Rastreabilidade financeira e cadastral |
| Identidade de sistema para execuções automáticas | PRESERVAR CONCEITO | Auditoria sem autor humano |
| Autorização ancorada em **URL de Action** | MODERNIZAR MANTENDO COMPATIBILIDADE | A semântica (funcionalidade/operação) se preserva; o identificador não pode continuar sendo a URL de uma Action Struts — precisa de chave estável de funcionalidade/operação para migrar as concessões |
| Aplicação manual da abrangência em cada consulta | **REESTRUTURAR** | Fonte de vazamento por omissão; o SISAN deve aplicar escopo territorial de forma sistemática |
| Auditoria dependente de anotação campo a campo | MODERNIZAR MANTENDO COMPATIBILIDADE | Manter a trilha por linha/coluna, reduzindo a chance de esquecer o que auditar |
| Hash SHA-1 sem salt e comparação por consulta | **NÃO TRANSPORTAR** (a implementação) | A **semântica** (validar credencial, histórico, blacklist, bloqueio) é preservada; o mecanismo é substituído, com migração progressiva do hash legado |
| Contagem de tentativas em sessão | REESTRUTURAR | Controle por sessão é contornável; deve ser persistente/por identidade |
| Token MD5 efêmero para servlets auxiliares; pseudo-autenticação de APIs | **NÃO TRANSPORTAR** | Substituir por credenciais de sistema com escopo |
| `UsuarioGrupoRestricao` (deny) | EXIGE APROFUNDAMENTO | Estrutura existe; **uso no cálculo não comprovado** — decidir só depois de rastrear |
| `CasoDeUso`/`CasoDeUsoTipo`, `FuncionalidadeCaracteristica` | EXIGE APROFUNDAMENTO | Não apareceram no caminho de decisão; papel atual indefinido |
| Escopo/validade de tokens de API | EXIGE APROFUNDAMENTO | Necessário para desenhar clientes de sistema |

## 26. Hipóteses para avaliação futura (não são decisões)

1. **RBAC com escopo territorial de primeira classe** — motivado pelo fato de a abrangência existir como conceito, mas depender de chamadas manuais.
2. **Camada de política de autorização** que resolva funcionalidade/operação por **identificador estável** (não por URL), preservando o mapeamento das concessões atuais para migração.
3. **Capacidades nomeadas com validade** para as permissões especiais (o legado já as nomeia; falta ciclo de vida explícito).
4. **Auditoria estruturada por evento** mantendo a granularidade linha/coluna, sem depender de anotar cada campo.
5. **Autenticação moderna com migração progressiva do hash legado** (validar contra SHA-1 no primeiro acesso e re-hashear) — preserva a base de usuários sem transportar o algoritmo.
6. **Contas de serviço para batch e APIs**, separando identidade interativa de identidade de sistema.
7. **Governança de acesso** (solicitação/aprovação/revogação com validade) como parte do produto, não como cadastro paralelo.

## 27. Cenários de caracterização identificados (sustentados por evidência)

> Cenário sustentado por evidência de que o fluxo existe — o **resultado esperado** de vários deles será estabelecido na caracterização.

1. Login válido (situação ATIVO) → contexto de segurança montado na sessão.
2. Senha inválida → incremento de tentativas na sessão.
3. Tentativas excedidas → senha bloqueada (`SENHA_BLOQUEADA`).
4. Usuário `INATIVO` tentando entrar.
5. Usuário `PENDENTE_SENHA` (deve entrar para trocar a senha).
6. Acesso expirado (`dataExpiracaoAcesso` no passado) e aviso de dias restantes antes de expirar.
7. Troca de senha e tentativa de reutilizar senha do histórico.
8. Senha presente em `senha_invalida`.
9. Acesso a funcionalidade concedida por um grupo.
10. Usuário em múltiplos grupos com concessões diferentes (união).
11. Acesso a funcionalidade **dependente** tendo apenas a principal concedida.
12. **Acesso direto por URL** a funcionalidade não concedida, em rota **protegida e não excepcionada** (esperado: barrado pelo filtro); e o contraste com uma rota **excepcionada** (ex.: nome contendo `pesquisar`/`relatorio`), para verificar qual controle atua.
13. Acesso a operação (URL de operação) sem a concessão correspondente.
14. Usuário com concessão funcional, mas **fora da abrangência** do objeto consultado.
15. Cada nível de abrangência (gerência regional, unidade de negócio, elo/polo, localidade).
16. Consulta que **não** aplica a verificação de abrangência (verificar se há vazamento — cenário de risco estrutural, §13).
17. Ação com permissão especial concedida × não concedida: instalação de hidrômetro sem RA; ligação de esgoto sem RA; replicar valor de cobrança de serviço; encerrar comando de cobrança por empresa.
18. Usuário de unidade diferente tentando tramitar/encerrar RA (verificar se há bloqueio — §14/§16).
19. Restrição (`UsuarioGrupoRestricao`) configurada: verificar se afeta a autorização efetiva (§10).
20. Operação sensível gerando `OperacaoEfetuada` (correlação usuário × operação × objeto).
21. Alteração de campo anotado gerando trilha por linha/coluna; e alteração de campo **não** anotado (ausência de trilha).
22. Execução batch registrando `Usuario.USUARIO_BATCH` como autor.
23. Chamada a API/servlet fora de `*.do` (fora do RBAC de tela).
24. Solicitação de acesso: criação, mudança de situação, concessão dos grupos pedidos.

## 28. Dúvidas abertas

1. ❔ **`UsuarioGrupoRestricao` participa do cálculo de autorização?** (alta prioridade — define se existe *deny* efetivo).
2. ❔ Precedência entre permissão especial e abrangência.
3. ❔ Se a unidade organizacional restringe tramitação/encerramento (fronteira do Atendimento parcialmente aberta).
4. ❔ Papel atual de `CasoDeUso`/`CasoDeUsoTipo` e de `FuncionalidadeCaracteristica`.
5. ❔ Se os **grupos** são recarregados por requisição ou vêm da sessão.
6. ❔ Parâmetros da política de senha (nº de senhas no histórico, validade, complexidade) e limite de tentativas.
7. ❔ Semântica de `usur_nnacessos` (acessos × tentativas).
8. ❔ Conteúdo exato registrado em `OperacaoEfetuada` (IP, unidade, data/hora).
9. ❔ Workflow de solicitação de acesso: quem aprova, recusa, revogação, validade.
10. ❔ Abrangência nos fluxos **batch** — investigada no [mapa do Batch](batch.md) e **não localizada** (nem nas telas de disparo nem no `ControladorBatchSEJB`); a autorização do disparo, essa sim, foi esclarecida (§21). Permanece como caracterização prioritária.
11. ❔ Escopo/validade/vínculo dos tokens de API.
12. ❔ Existência de controle de sessão simultânea e de registro de IP no login.

## 29. Evidências principais

```text
Filtro central:   gcom/gui/util/FiltroSegurancaAcesso.java (extends HttpServlet implements Filter):
                  :62 urls_sem_usuario_na_sessao.properties; :96–99 usuarioLogado da HttpSession;
                  :219 verificarAcessoPermitidoFuncionalidade; :241 verificarAcessoPermitidoOperacao;
                  :255 verificarAcessoAbrangencia; :301 filterChain.doFilter
                  web.xml: <filter-class>gcom.gui.util.FiltroSegurancaAcesso</filter-class> + <url-pattern>*.do</url-pattern>
Autorização:      ControladorAcessoSEJB.verificarAcessoPermitidoFuncionalidade:2664 (resolve Funcionalidade por
                  FiltroFuncionalidade.CAMINHO_URL ou ID; agrega funcionalidades principais via
                  FuncionalidadeDependencia; consulta GrupoFuncionalidadeOperacao por FUNCIONALIDADE_ID/OPERACAO_ID/
                  GRUPO_ID com conectores OR → permitido se existir registro)
                  verificarAcessoPermitidoOperacao:3137 (Operacao por CAMINHO_URL; funcionalidade dona via
                  operacao.getFuncionalidade())
                  pesquisarArvoreFuncionalidades:1793/2000 (menu)
Abrangência:      verificarAcessoAbrangencia:4153 (carregarAbrangencia + comparação de gerenciaRegional/unidadeNegocio/
                  eloPolo/localidade informados × do usuário); existeLocalidadeForaDaAbrangenciaUsuario:4412;
                  chamadas manuais em Fachada, ControladorImovelSEJB, ControladorLocalidadeSEJB,
                  ControladorArrecadacao, ControladorMicromedicao, FiltrarImovelInserirManterContaAction,
                  ExibirManterContaAction
Autenticação:     gui/seguranca/acesso/EfetuarLoginAction.java (:80 senha; :89 dias p/ expiração; :104
                  fachada.validarUsuario; :111/:138 numeroTentativas na sessão; :142 bloquearSenha;
                  :155 UsuarioSituacao.INATIVO; :168–174 dataExpiracaoAcesso; :181 PENDENTE_SENHA;
                  :266–276 verificarSituacaoUsuario (só ATIVO ou PENDENTE_SENHA); :310 SENHA_BLOQUEADA)
                  ControladorAcessoSEJB.validarUsuario:1690 (FiltroUsuario LOGIN + SENHA=Criptografia.encriptarSenha;
                  carrega gerenciaRegional, localidadeElo, localidade, usuarioSituacao, usuarioTipo,
                  unidadeOrganizacional.unidadeTipo, funcionario, empresa, usuarioAbrangencia)
                  gcom/util/Criptografia.java:17 MessageDigest.getInstance("SHA") → SHA-1 no login
                  MD5 (Util.md5) em AcessarOperacionalServlet:48 e AcessarNovoBatchServlet:98 (token efêmero)
                  ControladorUsuarioSEJB:239 Criptografia.encriptarSenha(senhaGerada)
Permissões esp.:  Fachada.verificarPermissaoEspecial(PermissaoEspecial.X, usuarioLogado) em
                  ExibirAtualizarInstalacaoHidrometroAction:67 (ATUALIZAR_INSTALACAO_DO_HIDROMETRO),
                  ExibirAtualizarLigacaoEsgotoAction:99 (ATUALIZAR_LIGACAO_DE_ESGOTO_SEM_RA),
                  ExibirInserirValorCobrancaServicoAction:71 (REPLICAR_VALOR_COBRANCA_SERVICO),
                  ExibirConsultarComandosAcompanhamentoCobrancaResultadoAction:69 (ENCERRAR_COMANDO_COBRANCA_EMPRESA);
                  ControleLiberacaoPermissaoEspecial (fclp_icuso) + inserir:4810/manter:4896/
                  existeControlePermissaoEspecialFuncionalidade:5011
Restrição:        UsuarioGrupoRestricao.hbm.xml (many-to-one para GrupoFuncionalidadeOperacao e UsuarioGrupo,
                  ambos sobre grup_id com update/insert=false) — uso no cálculo NÃO observado
Auditoria:        gcom/interceptor/RegistradorOperacao.java (:28/:38 construtores com idOperacao +
                  UsuarioAcaoUsuarioHelper; :60 registrarOperacao → objetoTransacao.setOperacaoEfetuada);
                  ControleAlteracao.java (@interface com value() e agrupamento por funcionalidade);
                  Interceptador.java; OperacaoEfetuada; tabelas tabela_linha_alteracao, tab_linha_col_alteracao,
                  operacao_tabela; entidades anotadas com @ControleAlteracao (ex.: DebitoTipo)
Batch/sistema:    Usuario.USUARIO_BATCH em RelatorioPadraoBatch, RelatorioEmitirOrdemServicoSeletiva(:778)/Analitico(:730),
                  RelatorioOrdemFiscalizacao:176; usuario_banco; AcessarNovoBatchServlet
Solicitação:      seguranca/acesso/usuario/SolicitacaoAcesso.java, SolicitacaoAcessoSituacao.java,
                  SolicitacaoAcessoGrupo(+PK); GerarRelatorioManterSolicitacaoAcessoSituacaoAction
APIs/token:       web.xml (/api/pagamentoCredito/*, /api/ordem-servico/*, /autocomplete fora de *.do);
                  seguranca.token + INDICADOR_VALIDA_TOKEN (migrations 2024)
```
