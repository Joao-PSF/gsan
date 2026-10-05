# Cenários Críticos — Segurança

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md).
>
> ⚠️ **Nenhum valor desta página foi capturado.** Salvo onde marcado, a baseline é `⬜ A CAPTURAR NA FASE 2`.

🔵 **Leitura da área**: a Segurança é onde os dois oráculos mais convivem. As **concessões legítimas** (união de grupos, abrangência, permissões especiais, controles do ciclo de vida da credencial) são **oráculo 1** — o OpenGSAN não pode reduzi-las. As **falhas do legado** (hash sem salt, token MD5, filtros decorativos, credenciais versionadas) são **oráculo 2** — igualdade seria o defeito.

---

## CEN-SEG-001 — Autenticação legítima e forma da credencial armazenada

- **Criticidade**: P0
- **Etapa OpenGSAN**: 0 — Fundação (S1)
- **Conceitos relacionados**: Usuário (C1) · autenticação (C3)
- **Objetivo**: caracterizar a autenticação bem-sucedida e o contexto que ela produz; e registrar a forma da credencial armazenada, que o OpenGSAN deve alterar
- **Pré-condições**: USR-01 com situação ATIVO, dentro da validade de acesso, grupos com concessões conhecidas; USR-01B, outro usuário ativo com **a mesma senha** de USR-01
- **Entrada**: login e senha corretos de USR-01
- **Operação GSAN**: autenticação por consulta que casa login + hash (`fachada.validarUsuario`); contexto gravado na sessão
- **Operação conceitual OpenGSAN**: autenticar o ator com credencial válida
- **Observações semânticas**:
  - a) autenticado (sim/não)
  - b) identidade do ator no contexto
  - c) concessões disponíveis no contexto (união dos grupos)
  - d) situação do usuário após o login (inalterada)
  - e) contadores de acesso atualizados — ❔ semântica de `usur_nnacessos` não comprovada; capturar o que muda
  - f) valores armazenados da credencial de USR-01 e USR-01B
- **Localizadores GSAN**: `Criptografia.java:17` (SHA-1); `usuarioLogado` na `HttpSession` (`FiltroSegurancaAcesso:96–99`); `usur_tmultimoacesso`, `usur_nnacessos`
- **Resultado semântico esperado**: usuário ATIVO, dentro da validade e com credencial correta é autenticado; o contexto passa a conter sua identidade e as concessões **da união** dos seus grupos. Para (f): no GSAN, 🟢 a mesma senha produz **o mesmo valor armazenado** (sem salt); no OpenGSAN, deve produzir **valores distintos**, e o algoritmo não pode ser SHA-1 sem salt
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (Fase 2, lote de Segurança, 2026-10-05) — V1 em [`golden/seguranca/CEN-SEG-001/`](../../../../ambiente-referencia/baselines/golden/seguranca/CEN-SEG-001/): autenticado; contexto com usuário, grupo e menu; situação ATIVO inalterada; `usur_nnacessos` = 1 e último acesso preenchido depois do 1º login. (f): USR-01 e USR-01B trocam a senha **pela tela do GSAN** para a mesma senha nova — o legado grava **o mesmo valor**, Base64 de 20 bytes (SHA-1 sem salt). Registro de D-01, nunca golden master a reproduzir; o valor do hash não é gravado ([relatório §16](../fase2/fase2-caracterizacao-baselines.md#16-lote-2--autenticação-e-autorização-2026-10-05))
- **Normalizações**: identificador de sessão; timestamp de último acesso
- **Divergência permitida**: **D-01** (observável f)
- **Oráculo**: **1** (a–e) · **2** (f)
- **Gate que este cenário protege**: 0 → 1 — *autenticação contra hash moderno*
- **Evidência**: [`modulos/seguranca.md`](../../modulos/seguranca.md) §login; [`riscos-identificados.md`](../../seguranca/riscos-identificados.md) achado 1; [D-01](../../compatibilidade/divergencias-aprovadas.md)

---

## CEN-SEG-002 — Credencial inválida e bloqueio por tentativas

- **Criticidade**: P0
- **Etapa OpenGSAN**: 0 — Fundação (S1)
- **Conceitos relacionados**: bloqueio de senha (C1) · contagem de tentativas (**CAND-03**)
- **Objetivo**: caracterizar a recusa de credencial inválida e o bloqueio da senha quando o limite de tentativas é excedido
- **Pré-condições**: USR-01 ATIVO; limite de tentativas conhecido (❔ parâmetro do sistema — registrar o valor vigente na instância de referência)
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Uma senha errada, depois a correta, **na mesma sessão** |
  | V2 | Senhas erradas até exceder o limite, **na mesma sessão** |
  | V3 | Senhas erradas **distribuídas em sessões diferentes**, somando mais que o limite |

- **Operação GSAN**: tentativa de login; contagem em `numeroTentativas` **na sessão** (`:111`, `:138`); ao exceder, `bloquearSenha(login)` (`:142`, `:310`)
- **Operação conceitual OpenGSAN**: autenticar com credencial inválida
- **Observações semânticas**: autenticado (sim/não) · situação do usuário após cada tentativa · momento em que a situação passa a `SENHA_BLOQUEADA` · login com senha correta após o bloqueio
- **Localizadores GSAN**: `numeroTentativas`, `loginUsuarioSessao` (sessão); situação do usuário em `seguranca.usuario`
- **Resultado semântico esperado**: V1 — recusa e, em seguida, autenticação normal. V2 — ao exceder o limite a senha é bloqueada (`SENHA_BLOQUEADA`) e **permanece** bloqueada mesmo com a senha correta. V3 — 🟢 no GSAN o contador vive **na sessão**; espera-se que tentativas distribuídas **não** bloqueiem — **a capturar**
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (2026-10-05) — V1, V2, V3 em [`golden/seguranca/CEN-SEG-002/`](../../../../ambiente-referencia/baselines/golden/seguranca/CEN-SEG-002/). ⚠️ Limite: o parâmetro é **nulo** na base reconstruída (a 1ª senha errada dá HTTP 500 — achado 29); a massa o **fixa em 3, sintético**. V1: recusa e depois autentica. V2: a 4ª tentativa (excede 3) bloqueia (SENHA BLOQUEADA); a senha correta é recusada na tela **mas a sessão fica autenticada** — tela principal e funcionalidade concedida abrem (achado 26, **CAND-07**). V3: 4 erradas em 2 sessões **não bloqueiam** (**CAND-03** caracterizado) ([relatório §16](../fase2/fase2-caracterizacao-baselines.md#16-lote-2--autenticação-e-autorização-2026-10-05))
- **Normalizações**: identificador de sessão; timestamps
- **Divergência permitida**: nenhuma aprovada. ⚠️ V3 é **CANDIDATO A DIVERGÊNCIA** (CAND-03)
- **Oráculo**: **1** (V1, V2) · ⚠️ **PENDENTE DE DECISÃO** (V3)
- **Gate que este cenário protege**: 0 → 1
- **Evidência**: [`modulos/seguranca.md`](../../modulos/seguranca.md) §autenticação (contagem em sessão classificada `REESTRUTURAR`); [visão conceitual §26](../../dominio/visao-conceitual-opengsan.md) linha 25

⚠️ **Por que V3 não é oráculo 2**: a visão conceitual atribui a persistência do contador a D-01, mas o **texto de D-01 cobre apenas o hash**. Até que o registro seja ajustado — ampliando D-01 ou criando uma divergência própria —, a diferença entre sessões **não está aprovada**, e o teste não pode tratá-la como esperada.

---

## CEN-SEG-003 — Ciclo de vida da credencial: situação, expiração e política de senha

- **Criticidade**: P1
- **Etapa OpenGSAN**: 0 — Fundação (S1)
- **Conceitos relacionados**: situação do usuário, expiração, histórico de senha (C1)
- **Objetivo**: caracterizar os controles do ciclo de vida da credencial — ⚠️ **nenhum pode ser reduzido** no OpenGSAN
- **Pré-condições**: USR-04 (INATIVO), USR-05 (PENDENTE_SENHA), USR-06A (acesso expirado), USR-06B (acesso a expirar em N dias), USR-07 (com histórico de senhas)
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | USR-04 tenta autenticar com senha correta |
  | V2 | USR-05 autentica |
  | V3 | USR-06A autentica |
  | V4 | USR-06B autentica |
  | V5 | USR-07 troca a senha para uma já usada no histórico |
  | V6 | Qualquer usuário troca a senha para uma presente na lista de senhas proibidas |

- **Operação GSAN**: login; troca de senha
- **Operação conceitual OpenGSAN**: autenticar; trocar senha
- **Observações semânticas**: autenticado (sim/não) · fluxo imposto (troca obrigatória em V2) · aviso de dias restantes (V4) · troca aceita ou recusada (V5, V6) · situação e datas após a operação
- **Localizadores GSAN**: `dataExpiracaoAcesso` (`:168–174`); aviso de dias restantes (`:89`); `usuario_senha_historico`; `senha_invalida`
- **Resultado semântico esperado**: 🟢 situação, bloqueio e expiração são **eixos independentes** — um usuário pode estar ativo e expirado. V1 e V3 negam o acesso sem alterar grupos. V2 permite entrar apenas para trocar a senha. V5 e V6 recusam a troca
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2 — incluindo os parâmetros vigentes (nº de senhas no histórico, validade, antecedência do aviso)
- **Normalizações**: timestamps
- **Divergência permitida**: nenhuma — ⚠️ regra 4 do registro de divergências: *nenhuma divergência pode reduzir expiração, bloqueio ou histórico de senha*
- **Oráculo**: **1**
- **Gate que este cenário protege**: 0 → 1
- **Evidência**: [`modulos/seguranca.md`](../../modulos/seguranca.md) §situação e expiração; [`estruturas-centrais.md`](../../compatibilidade/estruturas-centrais.md) SEG-04

---

## CEN-SEG-004 — Matriz de autorização: concessão por união de grupos e negação

- **Criticidade**: P0
- **Etapa OpenGSAN**: 1 — Primeira fatia vertical
- **Conceitos relacionados**: grupo, concessão por união (C1) · 🆕 restrição por usuário (C1) · funcionalidade/operação ancorada em URL (C2)
- **Objetivo**: caracterizar quem pode executar o quê — **e provar a negação**, não só a concessão
- **Pré-condições**: funcionalidades F1 (concedida ao grupo A), F2 (concedida ao grupo B), F3 (não concedida a ninguém do cenário), F4 (dependente de F1); operação O1 de F1 concedida a A e operação O2 de F1 **não** concedida; USR-01 (grupo A), USR-02 (grupos A e B), USR-03 (nenhum dos dois)
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | USR-01 acessa F1 |
  | V2 | USR-02 acessa F1 e F2 (união) |
  | V3 | USR-01 acessa F2 |
  | V4 | USR-03 acessa F1 **digitando o endereço direto** em rota protegida e não excepcionada |
  | V5 | USR-01 executa O1; depois O2 |
  | V6 | USR-01 acessa F4 tendo apenas F1 concedida |
  | V7 🆕 | Restrição por usuário: (a) USR-01 com restrição sobre O1 **pelo grupo A** — seu único caminho de concessão; (b) USR-02 com restrição sobre O1 pelo grupo A, **com B também concedendo O1**; (c) usuário com mais concessões do que grupos, para exercitar a composição do filtro (CAND-05) |

- **Operação GSAN**: acesso à Action `*.do`; `FiltroSegurancaAcesso` classifica a URL como funcionalidade **ou** operação e consulta `GrupoFuncionalidadeOperacao` — 🆕 e as restrições `UsuarioGrupoRestricao` do usuário (`ControladorAcessoSEJB:3104`, `:3517`)
- **Operação conceitual OpenGSAN**: executar caso de uso protegido
- **Observações semânticas**: permitido/negado por variação · recurso efetivamente executado (sim/não) · efeito colateral em caso de negação (nenhum esperado)
- **Localizadores GSAN**: `seguranca.grupo_funcionalidade_operacao`; 🆕 `UsuarioGrupoRestricao`; `FiltroSegurancaAcesso`
- **Resultado semântico esperado**: V1, V2, V5-O1 permitidos. V3, V4, V5-O2 negados, **sem efeito colateral**. 🟢 A concessão é a **união** dos grupos. V4 — 🟢 para rota protegida e não excepcionada, o endereço direto **passa pelo filtro** e é barrado. V6 — dependência entre funcionalidades participa da decisão: **a capturar** se concede ou nega. 🆕 V7 — regra lida no código: **acesso se restrições < concessões** — (a) **negado**, (b) **permitido** (B concede sem restrição); (c) **a capturar** — se a composição de `:3072` desviar da regra, não reproduzir exige divergência (CAND-05)
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (2026-10-05) — V1–V6, V5b, V7a, V7b, V7c, V7c2 em [`golden/seguranca/CEN-SEG-004/`](../../../../ambiente-referencia/baselines/golden/seguranca/CEN-SEG-004/): V1 e V2 permitidos (união); V3 e V4 negados; V5 O1 permitida e executada, O2 negada; V6 a dependência **não concede** (F4 negada); V7a negado; V7b permitido; V7c e V7c2 permitidos — a decisão segue "restrições < concessões" nas composições testadas (CAND-05 sem efeito observado). 🆕 V5b: a negação de O2 é **contornada** pela entrada de F1 com a matrícula — encaminhamento interno não refiltrado (achado 27, **CAND-06**) ([relatório §16](../fase2/fase2-caracterizacao-baselines.md#16-lote-2--autenticação-e-autorização-2026-10-05))
- **Normalizações**: endereço/rota (a unidade de concessão muda de URL para identificador de domínio — comparar pela **funcionalidade**, não pelo caminho)
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — por mapeamento semântico funcionalidade ↔ caso de uso
- **Gate que este cenário protege**: 1 → 2 — *matriz de autorização testada com negação provada*
- **Evidência**: [`modulos/seguranca.md`](../../modulos/seguranca.md) §7 e §27 itens 9–13

---

## CEN-SEG-005 — Rota excepcionada por substring no filtro de autorização

- **Criticidade**: P0
- **Etapa OpenGSAN**: 1 — Primeira fatia vertical
- **Conceitos relacionados**: concessão (C1) · exceção por substring (**CAND-04**)
- **Objetivo**: caracterizar o que acontece quando um usuário **sem concessão** chama uma Action cujo nome contém `pesquisar` ou `relatorio`
- **Pré-condições**: USR-03 autenticado, **sem** concessão para a funcionalidade dona da consulta; amostra de Actions excepcionadas — ao menos uma de consulta (`pesquisar`) e uma de relatório (`relatorio`), escolhidas entre as que **retornam dado cadastral ou financeiro**
- **Entrada**: chamada direta às Actions da amostra
- **Operação GSAN**: requisição a `*.do` cujo caminho casa `url.contains(key) || url.toLowerCase().contains(key)`
- **Operação conceitual OpenGSAN**: executar consulta protegida
- **Observações semânticas**: o filtro permitiu? · a Action aplicou verificação própria? · **dados retornados** (sim/não, e quais)
- **Localizadores GSAN**: `FiltroSegurancaAcesso:451–456`; lista de exceções do próprio filtro
- **Resultado semântico esperado**: 🟢 a Action **sai do bloco de autorização funcional do filtro**. ❔ Se ela tem verificação própria **não está comprovado** — é exatamente o que a caracterização descobre. ⚠️ Para `relatorio` no download do artefato, a ausência de controle já é **achado confirmado** (ver CEN-REL-001)
- **Baseline concreta do legado**: 🟢 **CAPTURADA** (2026-10-05) — V1 em [`golden/seguranca/CEN-SEG-005/`](../../../../ambiente-referencia/baselines/golden/seguranca/CEN-SEG-005/): com USR-03 **sem nenhuma concessão**, a funcionalidade comum é negada, mas as Actions com `pesquisar`/`relatorio` passam; `pesquisarImovelAction` **devolve matrícula, cliente e endereço**; o relatório de dados cadastrais é gerado (só com a matrícula — os campos vêm da sessão). Decide o oráculo pendente: **dado retornado sem concessão → proteger exige divergência** (CAND-04 sustentado; achado 28) ([relatório §16](../fase2/fase2-caracterizacao-baselines.md#16-lote-2--autenticação-e-autorização-2026-10-05))
- **Normalizações**: nenhuma sobre os dados retornados
- **Divergência permitida**: nenhuma aprovada. ⚠️ **CANDIDATO A DIVERGÊNCIA** (CAND-04) — se a caracterização mostrar dado retornado sem concessão
- **Oráculo**: ⚠️ **PENDENTE DE CARACTERIZAÇÃO** — se o GSAN proteger por controle interno, oráculo 1; se retornar dado, a proteção no OpenGSAN exige divergência aprovada
- **Gate que este cenário protege**: 1 → 2
- **Evidência**: [`modulos/seguranca.md`](../../modulos/seguranca.md) §7 (*"a exceção por substring é a de maior alcance"*); achado 13

---

## CEN-SEG-006 — Auditoria em dois níveis

- **Criticidade**: P0
- **Etapa OpenGSAN**: 0 — Fundação
- **Conceitos relacionados**: auditoria (C1) — ⚠️ auditoria ≠ histórico de negócio
- **Objetivo**: caracterizar o que o legado registra de uma operação sensível e de uma alteração de dado
- **Pré-condições**: USR-01 com concessão para uma operação registrada como sensível e para alterar um objeto com campos anotados para auditoria **e** campos não anotados
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Execução de operação sensível |
  | V2 | Alteração de campo **anotado** |
  | V3 | Alteração de campo **não anotado** |

- **Operação GSAN**: operação de negócio registrada; trilha por linha/coluna restrita ao anotado
- **Operação conceitual OpenGSAN**: executar operação auditada
- **Observações semânticas**: registro de operação efetuada (autor, operação, objeto, momento) · trilha por linha/coluna (valor anterior, valor novo) · ausência de trilha em V3
- **Localizadores GSAN**: `OperacaoEfetuada`; tabelas de trilha de alteração
- **Resultado semântico esperado**: V1 produz registro correlacionando **usuário × operação × objeto**. V2 produz trilha com valor anterior e novo. V3 — 🟢 **não** produz trilha. ⚠️ O OpenGSAN pode auditar **mais** (V3 incluído), nunca menos
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos dos registros de auditoria; timestamps
- **Divergência permitida**: nenhuma para V1/V2. Auditar V3 é **acréscimo**, não divergência — não altera nenhum observável do GSAN
- **Oráculo**: **1** (V1, V2) — V3 não é comparado
- **Gate que este cenário protege**: 0 → 1 — *uma escrita produz registro de auditoria legível*
- **Evidência**: [`modulos/seguranca.md`](../../modulos/seguranca.md) §auditoria; SEG-05

---

## CEN-SEG-007 — Abrangência territorial onde o legado a verifica

- **Criticidade**: P0
- **Etapa OpenGSAN**: 2 — Núcleo de atendimento e execução (S2)
- **Conceitos relacionados**: escopo territorial — conceito (C1)
- **Objetivo**: caracterizar a restrição por território **nas superfícies em que o GSAN chama a verificação** — a garantia que o OpenGSAN não pode perder
- **Pré-condições**: território com duas gerências regionais, unidades de negócio, elos/polos e localidades (L1, L2); USR-08 com abrangência restrita, **uma variação por nível**; objetos (imóvel, RA) em L1 e em L2; lista de superfícies que **comprovadamente** chamam `verificarAcessoAbrangencia`
- **Entrada**: USR-08 consulta, em cada superfície da lista, um objeto **dentro** e um **fora** da sua abrangência, para cada nível
- **Operação GSAN**: consulta com verificação explícita de abrangência
- **Operação conceitual OpenGSAN**: consulta sob escopo territorial
- **Observações semânticas**: acesso concedido/negado · dados retornados · comportamento por nível
- **Localizadores GSAN**: `verificarAcessoAbrangencia`; `UsuarioAbrangencia`
- **Resultado semântico esperado**: objeto dentro da abrangência é acessível; objeto fora é negado — em cada um dos quatro níveis
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma sobre os dados
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 2 → 3 — *escopo territorial aplicado*
- **Evidência**: [`modulos/seguranca.md`](../../modulos/seguranca.md) §abrangência; SEG-03

⚠️ **Superfícies onde o GSAN *não* chama a verificação ficam fora deste cenário**: são `BLQ-01`, bloqueado até a decisão sobre **D-17**.

---

## CEN-SEG-008 — Permissão especial nomeada

- **Criticidade**: P1
- **Etapa OpenGSAN**: 2 — Núcleo de atendimento e execução
- **Conceitos relacionados**: permissões especiais (C1)
- **Objetivo**: caracterizar exceções nomeadas **dentro** de uma funcionalidade concedida
- **Pré-condições**: USR-09 com a funcionalidade **e** a permissão especial; USR-01 com a funcionalidade e **sem** a permissão
- **Entrada**: cada usuário executa as ações que o legado condiciona a permissão especial — instalação de hidrômetro sem RA; ligação de esgoto sem RA; replicar valor de cobrança de serviço; encerrar comando de cobrança por empresa
- **Operação GSAN**: operação condicionada a permissão especial
- **Operação conceitual OpenGSAN**: operação com exceção autorizada
- **Observações semânticas**: permitido/negado · efeito produzido
- **Localizadores GSAN**: catálogo de permissões especiais; vínculo usuário × permissão
- **Resultado semântico esperado**: com a permissão, a ação é executada; sem ela, é negada **mesmo com a funcionalidade concedida**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 2 → 3
- **Evidência**: [`modulos/seguranca.md`](../../modulos/seguranca.md) §27 item 17; SEG-04

---

## CEN-SEG-009 — Token de acesso dos servlets auxiliares

- **Criticidade**: P1
- **Etapa OpenGSAN**: 0 — Fundação (S1)
- **Conceitos relacionados**: autenticação auxiliar (C3)
- **Objetivo**: registrar a forma do token efêmero usado por servlets auxiliares, que o OpenGSAN deve substituir
- **Pré-condições**: USR-01 autenticado; servlets auxiliares disponíveis na instância de referência
- **Entrada**: obtenção e uso do token; reuso do mesmo token após o uso e após tempo decorrido
- **Operação GSAN**: `AcessarOperacionalServlet:48`, `AcessarNovoBatchServlet:98`
- **Operação conceitual OpenGSAN**: autenticação entre componentes, com escopo e expiração
- **Observações semânticas**: formato e construção do token · aceitação após reuso · aceitação após tempo decorrido · escopo do que o token libera
- **Localizadores GSAN**: os dois servlets citados
- **Resultado semântico esperado**: no GSAN o token é 🟢 **MD5**. No OpenGSAN o token deve ter **escopo e expiração**: reuso fora do escopo ou após expirar deve ser **recusado**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2 (reuso e expiração não comprovados)
- **Normalizações**: valor do token
- **Divergência permitida**: **D-02**
- **Oráculo**: **2**
- **Gate que este cenário protege**: 0 → 1
- **Evidência**: [D-02](../../compatibilidade/divergencias-aprovadas.md); achado 1b

---

## CEN-SEG-010 — Cadeia de filtros sem elo decorativo

- **Criticidade**: P1
- **Etapa OpenGSAN**: 0 — Fundação (S1)
- **Conceitos relacionados**: cadeia de filtros (C3)
- **Objetivo**: registrar que dois elos da cadeia do legado não barram nada, e exigir que no OpenGSAN **cada elo prove que barra**
- **Pré-condições**: requisição sem sessão prévia a rota protegida
- **Entrada**: V1 — requisição sem sessão; V2 — requisição com sessão sem usuário autenticado
- **Operação GSAN**: `FiltroSSO` → `FiltroSessaoExpirada` → `FiltroSegurancaAcesso`
- **Operação conceitual OpenGSAN**: cadeia de verificação da requisição
- **Observações semânticas**: qual elo decidiu · resultado final (negado/permitido) · se algum elo executou sem efeito possível
- **Localizadores GSAN**: `FiltroSSO:19–29` (ramos `if/else` idênticos); `FiltroSessaoExpirada:38` (guarda inalcançável)
- **Resultado semântico esperado**: 🟢 no GSAN, `FiltroSSO` cria a sessão e segue em **ambos** os ramos; `FiltroSessaoExpirada` só barra quando a sessão é nula — **inalcançável** depois do elo anterior. No OpenGSAN, **cada elo tem teste próprio que o faz barrar**. ⚠️ O resultado final (negação) pode coincidir: o que diverge é a existência de elo sem efeito
- **Baseline concreta do legado**: 🟢 **CAPTURADA** — registro da divergência D-07 (2026-10-05), V1 e V2 em [`golden/seguranca/CEN-SEG-010/`](../../../../ambiente-referencia/baselines/golden/seguranca/CEN-SEG-010/): quem nega é o **último elo**, `FiltroSegurancaAcesso` (`:287`, encaminha à página de negação). V1, sem sessão: `FiltroSSO` cria a sessão e segue; a página de negação **quebra** com a sessão recém-criada (HTTP 500 — o recurso não é servido). V2, com sessão sem usuário: página "Acesso a funcionalidade negado" (HTTP 200) ([relatório §16](../fase2/fase2-caracterizacao-baselines.md#16-lote-2--autenticação-e-autorização-2026-10-05))
- **Normalizações**: nenhuma
- **Divergência permitida**: **D-07**
- **Oráculo**: **2**
- **Gate que este cenário protege**: 0 → 1
- **Evidência**: [D-07](../../compatibilidade/divergencias-aprovadas.md); achado 14

---

## CEN-SEG-011 — Nenhuma credencial em artefato versionado

- **Criticidade**: P0
- **Etapa OpenGSAN**: 0 — Fundação
- **Conceitos relacionados**: segredos (C3) · credenciais de banco (C3)
- **Objetivo**: registrar credenciais presentes em artefatos versionados do legado e exigir sua ausência no OpenGSAN
- **Pré-condições**: repositórios do legado e do OpenGSAN acessíveis à verificação
- **Entrada**: varredura dos artefatos versionados
- **Operação GSAN**: não se executa o sistema — ⚠️ **o observável é o próprio artefato**
- **Operação conceitual OpenGSAN**: verificação automatizada no pipeline (*secret scan*) e revisão de configuração
- **Observações semânticas**: presença de chave de API em código-fonte · presença de chave em properties versionado · presença de credencial de banco com senha igual ao login · 🆕 presença de usuário e senha em strings de conexão `dblink` dentro de funções armazenadas de dumps versionados
- **Localizadores GSAN**: `ServicoSMS.java:17`; `src/gcom/properties/sms.properties`; `gsan-migracoes/.../20160118183208_create_roles.sql`; 🆕 `gsan-migracoes/comercial/scripts/20160118183224_dump.sql` (5 strings, entre elas a da função `operacao.geraindicador`), `gsan-migracoes/comercial/dump.sql` (as mesmas 5), `gsan-migracoes/gerencial/scripts/20160118183224_dump.sql` (81)
- **Resultado semântico esperado**: GSAN — credenciais **presentes** em todos os artefatos listados. OpenGSAN — **nenhuma** credencial em artefato versionado; o pipeline **reprova** um commit que a introduza
- **Baseline concreta do legado**: 🟢 **JÁ COMPROVADA** — ⚠️ justificativa: aqui o observável é o artefato versionado, e lê-lo **é** observá-lo; não há comportamento em execução a inferir. 🔴 O **valor** do segredo **nunca é transcrito** — está considerado comprometido e marcado para rotação
- **Normalizações**: não aplicável
- **Divergência permitida**: **D-08**, **D-16**
- **Oráculo**: **2**
- **Gate que este cenário protege**: 0 → 1 — *CI reprova segredo commitado*
- **Evidência**: achados 2, 11 e 20 de [`riscos-identificados.md`](../../seguranca/riscos-identificados.md); [D-08, D-16](../../compatibilidade/divergencias-aprovadas.md); achado 20 localizado em [`modulos/operacional.md §6.3`](../../modulos/operacional.md)

---

## CEN-SEG-012 — Sessão e requisição forjada

- **Criticidade**: P1
- **Etapa OpenGSAN**: 1 — Primeira fatia vertical
- **Conceitos relacionados**: sessão e proteção contra requisição forjada (C3 — D-18)
- **Objetivo**: registrar que o legado aceita requisição forjada com a sessão do usuário e exigir que o OpenGSAN a recuse
- **Pré-condições**: USR-01 autenticado em navegador; página de **outra origem** que submete uma operação que altera estado (ex.: tramitar RA) usando a sessão do usuário
- **Entrada**: V1 — requisição forjada sem token; V2 — requisição legítima com token; V3 — inspeção dos atributos do cookie de sessão
- **Operação GSAN**: submissão de Action `*.do` que altera estado, a partir de outra origem
- **Operação conceitual OpenGSAN**: executar caso de uso que altera estado por canal de navegador
- **Observações semânticas**: requisição aceita ou recusada · efeito colateral (estado alterado sim/não) · atributos `HttpOnly`, `Secure`, `SameSite` do cookie
- **Localizadores GSAN**: `gcom/WEB-INF/web.xml` (sem `session-config`); ausência de `saveToken`/`isTokenValid` em `src/`
- **Resultado semântico esperado**: GSAN — 🟢 V1 **aceita**, com efeito (não há token a verificar); cookie **sem** os três atributos. OpenGSAN — V1 **recusada sem efeito colateral**; V2 aceita; cookie **com** os três atributos
- **Baseline concreta do legado**: 🟢 **CAPTURADA** — registro da divergência D-18 (2026-10-05), V1 em [`golden/seguranca/CEN-SEG-012/`](../../../../ambiente-referencia/baselines/golden/seguranca/CEN-SEG-012/): cookie `JSESSIONID` **sem** `HttpOnly`, `Secure` e `SameSite` (`Path=/gsan`); uma submissão que altera estado (troca de senha) **sem token** é aceita e tem efeito — o login seguinte só entra com a senha nova. V2 ("com token") não se aplica ao legado: não há token ([relatório §16](../fase2/fase2-caracterizacao-baselines.md#16-lote-2--autenticação-e-autorização-2026-10-05))
- **Normalizações**: identificador de sessão
- **Divergência permitida**: **D-18**
- **Oráculo**: **2**
- **Gate que este cenário protege**: 1 → 2
- **Evidência**: achado 6 de [`riscos-identificados.md`](../../seguranca/riscos-identificados.md); [D-18](../../compatibilidade/divergencias-aprovadas.md); [ADR-0007 §9.4](../../decisoes/0007-arquitetura-de-interface.md)
