# ADR-0007 — Arquitetura de interface do OpenGSAN: canais sobre casos de uso

- **Status: Aceita** · Proposta em 2026-09-14 · **Decidida em 2026-09-29** · Decisor: responsável do projeto
- Relaciona-se com: [ADR-0001](0001-monolito-modular-spring-boot.md) (monólito modular) · [ADR-0008](0008-gestao-de-ativos-nativa.md) (Ativos; Redes/GIS) · divergências [D-01 a D-06, D-11](../compatibilidade/divergencias-aprovadas.md) · D-17 (proposta)

> **Histórico**: proposta em 2026-09-14 com três opções (SSR · REST + SPA · híbrido) e inclinação preliminar por um "híbrido restrito". A versão proposta **acoplava conceitos independentes** — tecnologia de tela, mecanismo de credencial e modelo de autorização — e considerava só usuário interno e integrações (§3). Esta versão corrige os acoplamentos, amplia os canais para o OpenGSAN conhecido depois da revisão de escopo, compara quatro alternativas por 20 critérios e **decide**.

---

## 1. Decisão, em uma página

```text
REGRA ÚNICA
  Apresentação é adaptador. Regra de negócio e autorização pertencem aos casos de uso.
  Todo canal chama os mesmos casos de uso; nenhum canal chama outro canal; nenhum canal lê o banco.

PADRÃO POR CLASSE DE CANAL
  Backoffice interno        server-driven com aprimoramento progressivo
                            (HTML no servidor + atualização parcial + JavaScript só onde agrega)
  Portal / Agência virtual  canal próprio; padrão por omissão igual ao do backoffice;
                            frontend independente só por critério registrado (§12)
  Integrações M2M           API explícita sob contrato público: autenticada, documentada, versionada
  Campo                     cliente especializado (app futuro, QField, terceiros) sobre contrato de campo
  QGIS / Giswater           clientes especializados sobre projeções publicadas + solicitações ao dono
  Mapa web                  componente incorporado sobre camada de publicação espacial (tecnologia não decidida)
  Relatórios                solicitar e obter artefato são casos de uso autorizados (corrige D-03)
  Analytics                 consome fatos e projeções publicados — nunca telas nem tabelas internas
```

**Alternativa escolhida: C — híbrido por canal, com o backoffice no padrão D** (server-driven + aprimoramento progressivo). Não há SPA no backoffice, microfrontend, BFF obrigatório nem HTTP entre módulos.

---

## 2. Contexto

### 2.1 O legado

🟢 O GSAN serve **JSP + Struts 1.1**; a autorização é ancorada na URL da Action (`FiltroSegurancaAcesso` sobre `*.do`) e o menu é a árvore de funcionalidades ([`modulos/seguranca.md`](../modulos/seguranca.md)). Consumidores que não são navegador — coletores, telemetria, GIS, app de OS — são atendidos por Actions e servlets **fora do gate** ([`modulos/integracoes.md`](../modulos/integracoes.md)). O artefato de relatório é recuperável **só pelo identificador** (achado 13, D-03).

🔵 O defeito do legado não é "ser server-side": é **amarrar autorização, contrato de integração e entrega de relatório à tecnologia da tela**.

### 2.2 O que já estava decidido antes desta ADR

| Decisão | Onde |
| ------- | ---- |
| Monólito modular com fronteiras verificadas | ADR-0001 |
| 🔴 **Concessão por caso de uso** — funcionalidade e operação com **identificador estável**, não URL | [Visão conceitual §15.2](../dominio/visao-conceitual-opengsan.md); [dependências §4.3](../modulos/dependencias-e-ordem-implementacao.md) |
| **Cliente final ≠ usuário interno** — autorização por vínculo, não RBAC | [Dependências §19.3](../modulos/dependencias-e-ordem-implementacao.md); [catálogo §13.2](../modulos/funcionalidades-futuras.md) |
| Camada de integração com política única; **toda origem externa autenticada** | Visão §18; D-04, D-05, D-06, D-11 |
| O artefato de relatório **pertence ao solicitante** | Visão §17; D-03 |
| QGIS/Giswater são **ferramentas**; ownership por atributo; OS não duplicada | ADR-0008 |

### 2.3 O escopo cresceu

Quando proposta, a ADR pensava em **usuário interno + integrações**. O OpenGSAN que a Fase 0 conhece agora tem **backoffice denso, portal, campo, GIS, relatórios, analytics** — e é **software livre** num **monólito modular**. Uma única tecnologia de tela não precisa servir a todos.

---

## 3. O que estava errado na versão proposta

| Afirmação da versão proposta | Problema | Correção |
| ---------------------------- | -------- | -------- |
| SSR ⇒ "autorização **por rota**, sessão HTTP" | SSR não implica autorização por rota. A rota por autorização é o **defeito do legado**, não do SSR | Autorização por **caso de uso** em qualquer alternativa |
| SPA ⇒ "**Token/JWT**, autorização por caso de uso" | SPA não implica JWT — pode usar sessão, cookie seguro, BFF, OIDC. E não é a SPA que traz autorização por caso de uso | Credencial é decidida **por classe de canal** (§9); autorização é do caso de uso |
| SPA ⇒ "**CSRF deixa de ser o problema central**" | Escolher arquitetura para fugir de CSRF troca um risco por outro (credencial acessível a script) | CSRF é **tratado** onde houver cookie (§9.4) |
| "**Uma só camada de API serve tela e integração**" | Integração consumindo endpoint de tela é **acoplamento acidental** — foi o que o legado fez com Actions servindo coletores | Contratos **distintos** por classe de consumidor (§10) |
| Híbrido ⇒ "**dois mecanismos de autenticação** a manter coerentes" | Confunde autenticação com autorização. **Uma política** serve vários canais; e classes de canal **precisam** de autenticações distintas (usuário, cliente, sistema, dispositivo) | Uma política de autorização; autenticação por classe de canal |
| "O módulo é escrito de forma diferente em cada opção — **e o modelo de autorização muda junto**" | Só é verdade se o caso de uso depender de HTTP | Casos de uso **independentes de HTTP**; muda só o adaptador |
| Relatórios: "**bytes na resposta × URL assinada**" como a questão | A questão é **qual caso de uso autoriza a entrega**. URL assinada é credencial ao portador — sozinha, reproduz D-03 | Download como **caso de uso autorizado** (§11) |
| Canais considerados: usuário interno + integrações | Ignorava portal, campo, GIS, QGIS/Giswater, QField, relatórios, analytics | Canais explícitos (§4) |

---

## 4. Canais que o OpenGSAN precisa atender

```text
DOMÍNIOS            Cadastro · Micromedição · Faturamento · Cobrança · Arrecadação · Atendimento e Execução
                    · Contabilização · Gestão Operacional · (trilha estrutural: Ativos, Redes)
    ▲
CASOS DE USO        regra de aplicação · autorização · validação · auditoria · transação local
    ▲
CANAIS              adaptadores de entrada — conhecem o canal; o domínio não
```

| # | Canal | Quem | Natureza | Identidade |
| - | ----- | ---- | -------- | ---------- |
| 1 | **Backoffice interno** | Atendimento, cadastro, faturamento, arrecadação, cobrança, contabilização, operação, administração | Formulários densos, grades, filtros, pesquisa, workflows, atalhos, alto volume | Usuário interno |
| 2 | **Portal / Agência virtual** | Cliente final | Fluxos curtos (2ª via, extrato, parcelamento, certidão, solicitação), celular, acesso externo | Cliente final |
| 3 | **Campo / mobile** | Leituristas, equipes de OS e de inspeção | Offline, GNSS, fotos, sincronização | Dispositivo + usuário |
| 4 | **Mapa web** | Usuários do backoffice e, eventualmente, do portal | Ver imóveis, rede, ativos, OS, ocorrências | A do canal hospedeiro |
| 5 | **QGIS / Giswater** | Cadastro técnico, engenharia | Edição e análise de rede, simulação | Usuário ou sistema |
| 6 | **QField** | Campo técnico | Coleta geoespacial offline | Dispositivo + usuário |
| 7 | **Integrações M2M** | Bancos, arrecadadores, PSP, bureau, ERP contábil, agência reguladora, telemetria | Arquivos e chamadas sistema a sistema | Sistema |
| 8 | **Relatórios** | Todos os canais humanos | Pedido síncrono pequeno × assíncrono pesado | A do canal |
| 9 | **Analytics** | Gestão | Leitura agregada | Sistema |
| — | **Batch** (interno) | O próprio sistema, a pedido de alguém | Aciona casos de uso em volume | Sistema + solicitante |

---

## 5. Alternativas avaliadas

| | Alternativa | O que é |
| - | ----------- | ------- |
| **A** | **SSR predominante** | Spring MVC + templates no servidor; cada interação recarrega a página ("SSR puro"); REST só para integrações |
| **B** | **SPA predominante + API** | Toda tela é aplicação no navegador; o servidor expõe API para **todas** as telas; estado e roteamento no cliente |
| **C** | **Híbrido por canal** | Cada classe de canal com seu padrão. ⚠️ **Sem regra de fronteira, degenera em "cada um usa o que quiser"** — isso não é arquitetura |
| **D** | **Server-driven + aprimoramento progressivo** | HTML no servidor como base; requisições parciais devolvem **fragmentos**; JavaScript em **ilhas** onde agrega; API explícita só para canais externos |

Também avaliados e **não adotados como padrão**: microfrontends · BFF obrigatório · mesma API para tela e integração (§18).

---

## 6. Comparação pelos critérios

Legenda: ✅ favorável · ➖ neutro ou depende · ⚠️ desfavorável. Avaliação **para o backoffice**, salvo quando indicado.

| Critério | A — SSR puro | B — SPA + API | C — por canal, sem regra | D — server-driven + PE |
| -------- | ------------ | ------------- | ------------------------ | ---------------------- |
| Complexidade | ✅ baixa | ⚠️ duas aplicações, API para toda tela, estado no cliente, *build* de frontend | ➖ a pior das duas, se não houver fronteira | ✅ uma aplicação; JS pontual |
| Produtividade | ✅ formulário · ⚠️ interação | ⚠️ DTO e endpoint por tela; validação em dois lugares | ➖ | ✅ formulário e interação comum |
| Manutenção | ✅ | ⚠️ ritmo de atualização do ecossistema JS; duas bases | ➖ | ✅ poucas dependências no cliente |
| Acessibilidade | ✅ HTML semântico | ⚠️ exige disciplina: foco, rotas, anúncios | ➖ | ✅ base semântica; atualização parcial deve ser anunciada |
| Performance percebida | ⚠️ recarga a cada interação | ✅ fluida depois de carregar · ⚠️ carga inicial | ➖ | ✅ fragmentos pequenos, sem carga inicial pesada |
| Formulários densos | ✅ validação no servidor | ⚠️ validação duplicada ou mapeamento de erros | ➖ | ✅ validação no servidor com re-render parcial |
| Tabelas e filtros | ⚠️ recarga a cada filtro | ✅ | ➖ | ✅ paginação e filtro no servidor — que o volume do saneamento exige de qualquer forma |
| Testes | ✅ uma camada | ⚠️ cliente + contrato + ponta a ponta | ➖ | ✅ adaptador web + ponta a ponta |
| Segurança | ✅ sessão + CSRF padrão | ⚠️ armazenamento de credencial, CORS, superfície no cliente | ✅ isola a superfície externa (portal) | ✅ como A; política de conteúdo estrita com pouco JS |
| Autorização | ➖ neutra — o caso de uso decide | ➖ neutra · ⚠️ tentação de duplicar regra no cliente | ➖ | ➖ neutra; a tela consulta a mesma política |
| Integração | ✅ contratos separados | ⚠️ tentação de reusar endpoint de tela | ✅ | ✅ |
| Portal | ➖ adequado a fluxos simples | ✅ natural | ✅ liberdade por canal | ✅ adequado a fluxos simples e rede móvel |
| GIS | ⚠️ mapa exige componente JS | ✅ | ✅ | ✅ mapa como ilha |
| Mobile / campo | ➖ não atende offline | ➖ offline possível, mas campo é outro canal | ✅ cliente especializado | ➖ não atende offline — e não precisa (§13) |
| Contribuição open source | ✅ só Java e HTML | ⚠️ Java + ecossistema JS | ➖ | ✅ Java e HTML; sem *build* de frontend obrigatório |
| Tamanho de equipe | ✅ pequena | ⚠️ maior | ➖ | ✅ pequena |
| Dependência de especialistas frontend | ✅ baixa | ⚠️ alta | ➖ | ✅ baixa |
| Capacidade de evolução | ⚠️ limitada | ✅ na UI, a custo alto | ✅ por canal | ✅ ilhas quando justificadas; canais independentes |
| Acoplamento | ✅ adaptador no servidor | ⚠️ "API = domínio"; contrato de tela vira contrato público | ➖ | ✅ contrato público só onde há consumidor externo |
| Observabilidade | ✅ tudo passa pelo servidor | ⚠️ telemetria no cliente + rastreio de API | ➖ | ✅ tudo passa pelo servidor, com correlação |

🔵 **O que a tabela mostra**:

- **D domina no backoffice**: tem as vantagens de A em simplicidade, segurança, testes e contribuição e cobre as fraquezas de A em filtros, tabelas e interação.
- **B só vence onde a interação rica no cliente ou o offline dominam** — e nenhum caso do backoffice é assim. Os canais em que isso pode acontecer, portal e campo, são **outros canais**.
- **C está certo no nível do canal**, mas só é arquitetura **com fronteira declarada** — e D é o padrão que falta a C no backoffice.
- **Autorização é neutra em todas**, porque o caso de uso decide. A versão proposta dizia o contrário (§3).

---

## 7. Decisão

### 7.1 A regra única — invariantes

1. **Casos de uso existem sem HTTP.** O domínio e a camada de aplicação não importam nada de web, sessão, template ou API.
2. **Autorização, validação de negócio e auditoria acontecem no caso de uso**, sob **uma** política. O canal pode **consultar** a política para decidir o que exibir; nunca a substitui.
3. **Cada classe de canal tem um padrão fixo** (§7.2). Mudar o padrão de uma classe exige **revisão desta ADR**.
4. **Nenhum canal consome endpoints de outro canal.** Endpoints de tela são internos ao adaptador — não são contrato.
5. **Nenhum canal, ferramenta ou integração lê ou escreve o banco interno do OpenGSAN.** Lições D-12 e do satélite `gsan-operacional` ([`operacional.md §6.3`](../modulos/operacional.md)).
6. **Contrato público só existe onde há consumidor externo**; é explícito, autenticado, documentado e versionado (§10).
7. **O domínio não sabe qual canal o chamou.** O canal de origem pode ser **registrado como metadado de auditoria** pela camada de aplicação — nunca usado como regra.

### 7.2 Padrão por classe de canal

| Classe de canal | Padrão decidido | Por quê |
| --------------- | --------------- | ------- |
| **Backoffice interno** | **Server-driven com aprimoramento progressivo** (§7.3) | Telas densas e operacionais; equipe pequena; contribuição aberta; segurança por padrão |
| **Portal / Agência virtual** | **Canal próprio**. Padrão por omissão: o mesmo do backoffice. Frontend independente **permitido por critério** (§12) | Identidade, superfície e escala diferentes; fluxos curtos cabem no padrão por omissão |
| **Integrações M2M** | **API explícita** sob contrato público; arquivos quando o parceiro exige | Consumidor externo exige contrato estável |
| **Campo** | **Cliente especializado** sobre contrato de campo | Offline, dispositivo e GNSS não são problema do backoffice |
| **QGIS / Giswater · QField** | **Clientes especializados** sobre projeções publicadas + solicitações ao dono | ADR-0008: ferramentas, não sistemas de registro |
| **Mapa web** | **Ilha de componente** no canal hospedeiro, sobre camada de publicação espacial | Mapa é componente, não aplicação |
| **Relatórios** | **Casos de uso** de solicitação e de obtenção do artefato, usados por qualquer canal autorizado | D-03 |
| **Analytics** | **Contrato de dados** sobre fatos e projeções publicados | Nunca telas nem tabelas internas |
| **Batch** | Acionamento interno de casos de uso | Mesma política, identidade de sistema + solicitante |

### 7.3 O que "server-driven com aprimoramento progressivo" significa — sem ambiguidade

⚠️ **Não é "SSR puro"** (recarga a cada interação) e **não é SPA**.

| Camada | Regra |
| ------ | ----- |
| **Base** | HTML semântico renderizado **no servidor** pelo adaptador web do módulo. O servidor é a fonte de verdade de **estado, validação e autorização** |
| **Aprimoramento** | Interações comuns — filtrar, paginar, ordenar, validar campo, trocar aba, tramitar, confirmar — por **requisições parciais** que devolvem **fragmentos HTML**, sem recarregar a página |
| **JavaScript** | Só onde agrega, em **ilhas** com gatilho declarado: mapa; visualização ou edição de hierarquia grande (ativos, estrutura operacional); gráficos; interação contínua no cliente; atalhos de teclado. Uma ilha **não contém regra de negócio nem decide autorização** |
| **Proibido no backoffice** | SPA · roteamento no cliente · estado de negócio no cliente · lógica de autorização no cliente · *build* de frontend obrigatório para contribuir. Uma ilha que precise de componente empacotado o traz como dependência versionada, sem impor ferramental de frontend ao resto |
| **Operações críticas** | Financeiras e de segurança **nunca dependem de lógica no cliente** |
| **Acessibilidade** | HTML semântico; atualizações parciais anunciadas; navegação por teclado; referência **WCAG 2.2 nível AA** |

### 7.4 Tecnologia da primeira fatia

**Spring MVC** (já na stack da ADR-0001) renderizando HTML no servidor com **motor de templates integrado ao Spring Boot**, **atualização parcial declarativa por atributos HTML** e **sessão no servidor com proteção CSRF** (Spring Security). Nenhuma SPA, nenhuma API pública e nenhum *build* de frontend obrigatório.

A **biblioteca concreta** de templates e de atualização parcial é escolhida **no início da Etapa 0**, dentro deste padrão, pelos critérios abaixo, e registrada em §20 desta ADR — **sem reabri-la**. Candidatos de referência, a título de exemplo: motores como Thymeleaf ou JTE; bibliotecas como HTMX ou Unpoly.

| Critério | |
| -------- | - |
| Suporte ao Spring Boot 4 e manutenção ativa | Obrigatório |
| Licença compatível com software livre | Obrigatório |
| Sem *build* Node obrigatório | Obrigatório |
| Compatível com política de conteúdo estrita (sem *script* inline obrigatório) | Obrigatório |
| Fragmentos reutilizáveis entre página e resposta parcial | Obrigatório |
| Acessibilidade das atualizações parciais | Avaliado |

---

## 8. Arquitetura resultante

```text
 CANAIS — adaptadores de entrada                                   CONTRATO
 ┌─────────────────────────────┐
 │ Backoffice web              │ server-driven + PE               interno — não é contrato
 │ usuário interno             │─────────────┐
 └─────────────────────────────┘             │
 ┌─────────────────────────────┐             │
 │ Portal / Agência virtual    │─────────────┤                    próprio do portal
 │ cliente final               │             │
 └─────────────────────────────┘             ▼
 ┌─────────────────────────────┐   ┌───────────────────────────────────────┐
 │ Integrações M2M · sistema   │──►│           CASOS DE USO                │◄── Batch
 └─────────────────────────────┘   │ autorização · validação · auditoria   │    sistema + solicitante
 ┌─────────────────────────────┐   │ transação local · canal = metadado    │
 │ Campo: app, QField, 3ºs     │──►└───────────────────┬───────────────────┘
 │ dispositivo + usuário       │                       │ contratos internos (Java) — sem HTTP
 └─────────────────────────────┘                       ▼
 ┌─────────────────────────────┐   ┌───────────────────────────────────────┐
 │ QGIS / Giswater             │──►│   DOMÍNIOS OpenGSAN — monólito modular │
 │ solicitações ao dono        │   └───────────────────┬───────────────────┘
 └─────────────────────────────┘                       │ fatos e projeções publicados
                                                       ▼
 ┌─────────────────────────────┐   ┌───────────────────────────────────────┐
 │ Mapa web (ilha no canal)    │◄──│ publicação espacial · projeções GIS    │──► QGIS / Giswater (leitura)
 └─────────────────────────────┘   │ contrato de dados                      │──► Analytics
                                   └───────────────────────────────────────┘
```

🔵 **Monólito modular preservado (ADR-0001)**: o adaptador de canal vive **dentro do módulo dono** do caso de uso. Uma tela que mostra dados de vários módulos — a consulta de imóvel, por exemplo — compõe-se chamando os **contratos internos** de cada módulo, **nunca** o repositório de outro. Cada caso de uso é uma **transação local**; nenhuma transação é orquestrada entre chamadas HTTP.

🔴 **O domínio sabe qual UI o chamou? Não.**

---

## 9. Autenticação e autorização por canal

### 9.1 Quatro coisas que não se fundem

| | Pergunta | Onde se decide |
| - | -------- | -------------- |
| **Autenticação** | Quem é? | Por **classe de ator** |
| **Autorização** | O que pode executar? | No **caso de uso**, sob uma política |
| **Transporte da credencial** | Como a identidade viaja? | Por **classe de canal** |
| **Canal** | De onde veio? | No adaptador; vai para a auditoria como metadado |

### 9.2 Por classe de canal

| Canal | Ator | Autenticação esperada | Transporte da credencial |
| ----- | ---- | --------------------- | ------------------------ |
| Backoffice | Usuário interno | Credencial própria com hash moderno (D-01); federação corporativa (OIDC) possível depois | **Sessão no servidor**; cookie `HttpOnly`, `Secure`, `SameSite`; **CSRF** |
| Portal | Cliente final | Autocadastro com verificação; fator adicional conforme o risco da operação | Sessão e cookie no padrão por omissão. Se frontend independente: cookie no mesmo site ou OIDC com PKCE — **nunca credencial de longa duração em armazenamento acessível a script** |
| Integrações | Sistema | Credencial **por parceiro**, com escopo, revogável — por exemplo, credenciais de cliente OAuth2 ou mTLS (D-04, D-06) | TLS obrigatório (D-09) |
| Campo | Dispositivo + usuário | Identidade de **dispositivo** revogável + usuário (D-05) | TLS; credencial por dispositivo |
| QGIS / Giswater / QField | Usuário ou sistema | Conforme o uso: usuário para editar, sistema para projeção | TLS |
| Batch | Sistema | Identidade de sistema + **solicitante registrado** | Interno |

🔴 **Identidades não se misturam**: usuário interno e cliente final são **populações distintas**. A infraestrutura de identidade e o serviço de política **podem ser compartilhados**; as contas, nunca.

### 9.3 Onde a autorização é aplicada

- **No caso de uso**, para **todo** canal: web, portal, API, campo, GIS, batch e integração que acionem o mesmo caso de uso respeitam **a mesma política**.
- A política combina: concessão por **funcionalidade/operação com identificador estável** (união dos grupos, permissões especiais) · **escopo territorial** (aplicação sistemática depende de **D-17**, proposta) · para o cliente final, **vínculo** com imóvel ou cliente.
- 🟢 **Avaliada a cada execução contra o estado vigente**. Preserva um comportamento do GSAN: mudança de grupo vale na requisição seguinte, sem novo login ([`seguranca.md §6`](../modulos/seguranca.md)).
- A tela **consulta** a política para esconder o que não pode ser feito. Esconder **não é** autorizar.

### 9.4 Sessão e CSRF

Onde houver sessão com cookie em navegador:

- **token CSRF** em toda requisição que altera estado, **inclusive as parciais**; `SameSite` como defesa adicional;
- nenhuma alteração de estado por `GET`;
- proteção contra fixação de sessão, expiração e invalidação no logout;
- política de conteúdo estrita.

⚠️ Não se escolheu arquitetura para **evitar** CSRF: ele é **tratado**. Estes controles são **novos no OpenGSAN** — o legado não os tem (achado 6) — e entram como **requisito da fundação (S1)**, não como cenário de equivalência.

---

## 10. APIs e contratos

### 10.1 API é adaptador, não domínio

```text
API = superfície de um canal sobre casos de uso
API ≠ arquitetura interna do OpenGSAN
```

### 10.2 Classes de contrato

| Contrato | Consumidor | Público? | Versionamento |
| -------- | ---------- | -------- | ------------- |
| **Integração M2M** | Parceiros e sistemas externos | ✅ | Estratégia de compatibilidade; mudança incompatível = nova versão com período de convivência |
| **Campo** | Aplicativos e dispositivos | ✅ | Idem; **idempotente** por chave de negócio; tolerante a sincronização tardia |
| **GIS** — projeções e solicitações | QGIS, Giswater, QField, publicação espacial | ✅ | Idem |
| **Portal** | Frontend do portal | ✅ **só** se o portal for independente; se servido pelo monólito, é interno | Conforme o caso |
| **Dados para Analytics** | Ferramentas analíticas | ✅ | Idem |
| **Endpoints do backoffice** — páginas, fragmentos, ilhas | O próprio adaptador web | ❌ **Não é contrato** | Evolui com o código; integração não pode consumi-lo |
| **Contratos entre módulos** | Outros módulos do monólito | ❌ Interno, em Java | Evolui com o código; verificado pela fronteira modular (ADR-0001) |

### 10.3 Princípios da API externa

Explícita (feita para o consumidor, não derivada da tela) · autenticada (§9.2) · versionável quando há contrato externo · **documentada em especificação legível por máquina** quando existir · **independente da estrutura interna** (nenhuma entidade de persistência exposta) · idempotência por chave de negócio · erro **durável e observável** (visão §18).

### 10.4 API interna

🔴 **Não há HTTP entre módulos do monólito.** Módulos conversam por **contratos internos explícitos** — interfaces Java publicadas pelo módulo dono, verificadas pela fronteira modular. Não se criam versões artificiais para eles.

---

## 11. Relatórios

| | Síncrono — pequeno | Assíncrono — pesado |
| - | ------------------ | ------------------- |
| Quem decide o modo | O **caso de uso**, pela estimativa de custo — preserva a decisão automática do GSAN ([`relatorios.md §27`](../modulos/relatorios.md)) | Idem |
| Entrega | Na resposta do próprio caso de uso autorizado | **Solicitação registrada** (solicitante, parâmetros, escopo) → Processamento → **artefato persistido** |
| Artefato | — | Com **dono**, **escopo**, metadados (formato, nome, tamanho) e **expiração** conforme política |
| Recuperação | — | 🔴 Caso de uso **"obter artefato"**: verifica **usuário autenticado**, **propriedade ou permissão explícita** e **escopo** a cada acesso |

🔴 **Corrige D-03**: nenhum artefato é recuperável **só pelo identificador**, nenhum acesso é anônimo, e a entrega **não depende de Action de download**. Se um armazenamento externo vier a exigir URL pré-assinada, ela só pode ser emitida **por esse caso de uso**, com validade curta, e **não substitui** a verificação. Onde o artefato fica armazenado **não é decidido aqui**.

---

## 12. Portal / Agência virtual

- **Canal próprio**, com identidade do **cliente final** e autorização por **vínculo**.
- **Não é obrigado** a usar a arquitetura visual do backoffice. **Padrão por omissão**: o mesmo server-driven, adequado a fluxos curtos, rede móvel e acessibilidade.
- **Frontend independente é permitido** quando, na sua entrada (Etapa 8), se registrar ao menos um destes motivos:
  - requisito de experiência que o padrão por omissão não atende com qualidade — uso offline, instalação como aplicativo, interação contínua rica no dispositivo;
  - equipe capaz de mantê-lo;
  - **contrato de canal do portal** explícito — nunca os endpoints do backoffice.
- Pode ter **implantação separada** (superfície externa, escala própria) **sem separar o domínio**.
- **Compartilha** casos de uso, regras, políticas e a infraestrutura de identidade. **Não compartilha** a base de usuários internos.
- ⚠️ Framework **não decidido** — nem é necessário agora.

---

## 13. GIS e campo

| Canal | Decisão |
| ----- | ------- |
| **QGIS / Giswater** | Clientes especializados. Leem **projeções publicadas**; escrita sobre atributo de outro dono é **solicitação ao dono** ([`gis-redes-ativos.md §7`](../arquitetura/gis-redes-ativos.md)). **Nunca** acesso ao banco interno. ⚠️ Não se reconstrói o QGIS no navegador |
| **Mapa web** | **Ilha** no backoffice ou no portal, consumindo uma **camada de publicação espacial**. QGIS Server é **candidato** — **nada decidido** |
| **QField** | Cliente de campo técnico via projetos QGIS. Execução de **OS** feita por ele passa pelo **contrato de campo do Atendimento e Execução** — a OS continua deste domínio |
| **Campo** (app OpenGSAN futuro, terceiros) | Cliente especializado; **offline** resolvido no cliente e no contrato — sincronização idempotente; identidade de dispositivo (D-05). 🔴 **O backoffice web não precisa funcionar offline** |

---

## 14. Primeira fatia vertical

```text
autenticar          página do backoffice → caso de uso "autenticar" → sessão + CSRF
   ↓
consultar           formulário de pesquisa com resultado por fragmento → casos de uso de consulta do Cadastro
imóvel/cliente      (composição pelos contratos internos, com autorização no caso de uso)
   ↓
abrir RA            formulário gerado a partir da especificação (regra como dado) → caso de uso "abrir demanda"
   ↓
tramitar RA         ação com confirmação por fragmento → caso de uso "tramitar demanda"; histórico auditado
```

Infraestrutura exigida: Spring MVC + motor de templates + biblioteca de atualização parcial + Spring Security (sessão, CSRF). **Nada além.** Sem SPA, API pública, BFF ou *build* de frontend. Testes: adaptador web e ponta a ponta no navegador, além dos testes dos casos de uso, que não dependem da tela.

---

## 15. Impacto nos cenários críticos

🟢 **Verificado: as 79 especificações são neutras à interface** — nenhuma descreve tela, rota ou recurso. A decisão **não acrescenta observável de equivalência**:

- **CEN-SEG-004** já compara pela **funcionalidade**, não pelo caminho.
- **CEN-REL-001** já exige negar V2 e V3; a decisão fixa **como** — caso de uso de obtenção do artefato.
- **Sessão, cookie e CSRF** são controles **sem antecedente** no GSAN: testes próprios da fundação (S1), não equivalência — e o achado 6 não tem `D-xx` registrado (pendência da auditoria).

---

## 16. Relação com outras decisões

| Decisão | Efeito |
| ------- | ------ |
| **ADR-0001** — monólito modular | ✅ Compatível: adaptadores dentro dos módulos; sem microserviços, microfrontends ou HTTP interno |
| **ADR-0008** — Ativos nativa; Giswater/QGIS | ✅ Coerente: ferramentas GIS como clientes especializados; ownership por atributo; OS não duplicada |
| **D-03** | ✅ Corrigida por desenho (§11) |
| **D-17** (proposta) | ⚠️ Continua pendente — afeta a **política**, não a interface |
| **Não decidido aqui** | Schema de Ativos · tecnologia GIS · QGIS Server · framework do portal · telemetria · eventos · mensageria · microserviços · onde armazenar artefatos |

---

## 17. Consequências

- (+) Uma aplicação e uma linguagem de ponta a ponta no backoffice: quem contribui com Java contribui com a tela.
- (+) Segurança por padrão nos canais de navegador; credencial fora do alcance de *script*; autorização em um só lugar.
- (+) Contratos públicos só onde há consumidor: menos superfície para versionar e documentar.
- (+) Canais podem evoluir **independentemente** — portal, campo, GIS — sem tocar domínio nem autorização.
- (−) Ilhas de JavaScript exigem disciplina: sem regra de negócio, sem autorização, com gatilho declarado.
- (−) Se o portal for independente, haverá um segundo ferramental de frontend — custo aceito **só** por critério registrado.
- ⚠️ Risco: tratar endpoints de fragmento como API e deixar uma integração consumi-los. Mitigação: invariante 4 e verificação de fronteira.

---

## 18. Alternativas rejeitadas

| Alternativa | Motivo |
| ----------- | ------ |
| **A — SSR puro** | Recarga a cada filtro e paginação em telas de alto volume; o mapa exigiria JS de qualquer forma. D mantém as vantagens de A sem esse custo |
| **B — SPA predominante** | Custo de duas aplicações, API para cada tela e especialistas frontend — **sem retorno** no backoffice, que é formulário, grade e workflow. Incentiva reutilizar endpoint de tela como integração. "É moderno" não é critério |
| **C sem regra de fronteira** | "Usar SSR ou SPA quando quiser" não é arquitetura |
| **Microfrontends** | Resolvem implantação independente entre muitas equipes — problema que o OpenGSAN não tem nesta escala |
| **BFF obrigatório** | O backoffice é servido pelo próprio monólito, que já é seu *backend*. Só se considera um BFF se o portal independente precisar, e então se registra |
| **Mesma API para tela e integração** | Acoplamento acidental — o defeito do legado |

---

## 19. Respostas diretas

| Pergunta | Resposta |
| -------- | -------- |
| Como construímos as telas internas? | HTML no servidor pelo adaptador web do módulo dono (§7.3) |
| Como adicionamos comportamento dinâmico? | Requisições parciais com fragmentos; ilhas de JS com gatilho declarado |
| Como o Portal conversa com o sistema? | Pelos mesmos casos de uso — via adaptador próprio ou contrato de canal do portal; nunca pelo backoffice |
| Como integrações conversam? | API explícita sob contrato público, autenticada por identidade de sistema |
| Como QGIS/Giswater conversam? | Projeções publicadas para leitura; solicitação ao dono para escrita; nunca o banco interno |
| Como QField e o campo conversam? | Contrato de campo com identidade de dispositivo, sincronização idempotente |
| Onde a autorização é aplicada? | No caso de uso, sob uma política, para todo canal |
| Que autenticação por classe de canal? | Usuário interno · cliente final · sistema · dispositivo + usuário (§9.2) |
| Como relatórios são entregues? | Síncrono na resposta; assíncrono como artefato com dono, recuperado por caso de uso autorizado |
| O que é contrato público? | Integração, campo, GIS, dados para Analytics e portal independente. Nunca endpoints do backoffice nem contratos entre módulos |
| O domínio sabe qual UI o chamou? | **Não** |

---

## 20. Registro de implementação

*A preencher na Etapa 0*: biblioteca de templates e de atualização parcial escolhidas pelos critérios de §7.4, com a justificativa. ⚠️ Registro de escolha **dentro** do padrão — não reabre esta ADR.

## Rollback

Decisão conceitual, sem código. Como os casos de uso não dependem de HTTP (invariante 1), trocar o padrão de uma classe de canal afeta **só os adaptadores daquela classe** — e exige revisão desta ADR com o motivo registrado.
