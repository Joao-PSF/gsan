# Mapa Funcional — Integrações

> **Procedência da análise**: código em `HEAD = 2031c4ca762c3ec2597ea8c057db97aa388e5589`, branch `claude/gsan-modernizacao-tecnica-rd5g60`. Toda afirmação 🟢 abaixo cita arquivo e linha verificados nesse commit. Convenção de certeza: 🟢 fato comprovado no código · 🔵 interpretação sustentada por evidência · 🟡 hipótese · ❔ não compreendido.
>
> **Escopo**: comportamento das integrações — quem fala com quem, por qual protocolo, com qual autenticação, sob qual identidade e com qual tratamento de erro. **Não é inventário**: o inventário está em [`integracoes/integracoes-identificadas.md`](../integracoes/integracoes-identificadas.md) e não foi refeito. Este documento aprofunda os mecanismos.

---

## 1. Descoberta central: não existe uma camada de integração

🟢 O GSAN **não tem** um módulo de integração no sentido arquitetural. O pacote `gcom.integracao` contém 12 arquivos e cobre apenas **uma** das integrações (UPA/SAM). Todas as outras estão espalhadas: em Actions do Struts (`gcom.gui.micromedicao`, `gcom.gui.integracao`), em servlets fora do Struts (`gcom.api.*`), em utilitários (`gcom.util.email`, `gcom.util.sms`), em stubs gerados (`gcom.integracao.webservice.spc`) e dentro dos controladores de negócio (arquivos bancários, contabilidade).

🔵 A consequência para o SISAN é direta: **não há uma fronteira de integração para "portar"**. Há sete padrões técnicos distintos, com níveis de maturidade que vão de OAuth2 com credencial em banco até chave de API escrita no código-fonte. O trabalho do SISAN não é traduzir uma camada — é **criar** a camada que nunca existiu, preservando cada capacidade funcional.

---

## 2. Os sete padrões

| # | Padrão | Direção | Exemplares | Autenticação |
| - | ------ | ------- | ---------- | ------------ |
| A | Entry point HTTP fora do gate (`processarRequisicao*`) | entrada | dispositivo móvel, telemetria, GIS | **desigual** — de nenhuma a assinatura DSA |
| B | Servlet API `/api/*` | entrada | pagamentoCredito, ordem-servico | pseudo-autenticação / nenhuma |
| C | Cliente HTTP de saída | saída | `GsanApi` (serviço de relatórios) | **OAuth2 + Basic, credencial em banco** |
| D | Banco compartilhado | bidirecional | UPA/SAM | conexão de banco (segunda `SessionFactory`) |
| E | Arquivo | bidirecional | CNAB/FEBRABAN, contabilidade, mobile TXT | fora do escopo HTTP |
| F | SOAP | saída | SPC (Axis2) | credencial no envelope |
| G | Notificação | saída | e-mail (SMTP), SMS (REST) | SMTP: parâmetro de sistema · SMS: **chave no código** |

---

## 3. Padrão A — entry points fora do gate de autorização

### 3.1 O mecanismo

🟢 Existe uma família de Actions cujo nome começa com `processarRequisicao`, feita para ser chamada por **sistemas externos**, não por navegador. Todas estão **explicitamente listadas como exceção nos dois filtros** que protegem o resto da aplicação:

- `FiltroSessaoExpirada.java:47-53` — exceção à exigência de sessão
- `FiltroSegurancaAcesso.java:186-193` — exceção à verificação de funcionalidade/operação

🟢 As três estão vivas: mapeadas em `gcom/WEB-INF/{micromedicao,integracao}/struts-config-ProcessarRequisicao*.xml`, todas registradas no agregador `config` do `web.xml` (linhas 137-953). **Não é código morto.**

🔵 O desenho é intencional e defensável: um coletor de campo não tem sessão HTTP nem usuário de menu. O problema não é a exceção — é o que cada Action faz **no lugar** do gate.

### 3.2 O que cada uma faz no lugar do gate

**🟢 Dispositivo móvel — `ProcessarRequisicaoDipositivoMovelAction:67-116`**

Protocolo binário sobre HTTP. `request.getInputStream()` → `DataInputStream` → `din.readByte()` devolve um opcode, e um `switch` despacha:

| Opcode | Método | Efeito |
| ------ | ------ | ------ |
| `PACOTE_BAIXAR_ARQUIVO` | `baixarArquivo` | entrega o arquivo de leitura da rota |
| `ATUALIZAR_MOVIMENTO` | `atualizarMovimentacao` | **grava** movimento de leitura |
| `FINALIZAR_LEITURA` | `finalizarMovimentacao` | **encerra** o movimento |
| `CONFIRMAR_ARQUIVO_RECEBIDO` | `confirmacaoArquivoRecebido` | confirma recebimento |
| `TESTE_CONEXAO` | — | responde OK |

🟢 **Nenhuma verificação de credencial no `execute`.** Não há login, token, assinatura ou identificação de dispositivo antes do `switch`.

**🟢 Telemetria — `ProcessarRequisicaoTelemetriaAction:50-53`**

```java
String dadosTelemetria = request.getParameter("dadosTelemetria");
TelemetriaLog telemetriaLog = this.getFachada().processarLeituraViaTelemetria(dadosTelemetria);
```

🟢 Duas linhas entre o parâmetro HTTP e o processamento da leitura. **Nenhuma verificação de credencial.** O formato é uma string delimitada por `*` e `;` (documentada em comentário nas linhas 56-65).

**🟢 GIS — `ProcessarRequisicaoGisAction:101,113,162`** — *a exceção positiva*

```java
String hashValidacao = request.getParameter("sign");
String loginUsuario  = request.getParameter("usur_nmlogin");
...
if (!verificador.validarHash(loginUsuario.getBytes(), hashValidacao.getBytes())) {
    throw new ActionServletException("atencao.assinatura.invalida", null, loginUsuario);
}
```

🟢 `AssinaturaDSA.validarHash:68-95` faz verificação criptográfica real: `Signature.getInstance("SHA1withDSA")`, chave pública, `Base64.decodeBase64`, exigência de assinatura de exatos 40 bytes. Depois disso, carrega o `Usuario` real por `FiltroUsuario` (linhas 172-180) e opera sob essa identidade.

🔵 **É a única integração de entrada com autenticação criptográfica.** Mostra que a competência existia na equipe — não foi aplicada nas outras.

🟢 Limitação estrutural dessa assinatura: ela cobre **apenas o login** (`loginUsuario.getBytes()`), não o corpo da requisição, nem um *nonce*, nem *timestamp*. 🔵 Uma assinatura válida é portanto um **portador estático e reutilizável indefinidamente** — autenticação sem prova de frescor, vulnerável a repetição. No SISAN isso vira token com expiração e escopo.

### 3.3 Conclusão do padrão A

🔵 Três integrações de entrada, três decisões independentes sobre autenticação, **nenhuma política comum**. Duas gravam dados de campo (leitura de hidrômetro, movimento de rota) sem identificar quem chama. Isso alimenta faturamento.

---

## 4. Padrão B — servlets `/api/*`

🟢 Dois servlets fora do Struts, mapeados em `web.xml:994-1010`:

| URL | Classe | Filtro aplicado |
| --- | ------ | --------------- |
| `/api/pagamentoCredito/*` | `gcom.api.pagamentocredito.PagamentoCreditoAPI` | `PagamentoCreditoFilter` |
| `/api/ordem-servico/*` | `gcom.api.ordemservico.OrdemServicoAPI` | **nenhum** |

🟢 Os filtros da aplicação (`filtroSSO`, `filtroSessaoExpirada`, `filtroSessao`, `filtroSegurancaAcesso`) são mapeados a `*.do` — nenhum alcança `/api/*`.

### 4.1 `PagamentoCreditoFilter` — o que ele realmente valida

```java
private static final String PROD_DOMINIO  = "http://gsan.cosanpa.pa.gov.br";
private static final String HOMOL_DOMINIO = "http://homologa.cosanpa.pa.gov.br";

String dominio = extrairDominio(req.getRequestURL().toString());
if (!dominio.equalsIgnoreCase(PROD_DOMINIO) && !dominio.equalsIgnoreCase(HOMOL_DOMINIO)) {
    request.setAttribute("filtro", HttpStatus.SC_FORBIDDEN);
}
chain.doFilter(request, response);
```

🟢 Três fatos precisos, que corrigem e afiam o que o inventário chamava de "pseudo-autenticação por domínio":

1. **Não autentica o cliente.** `req.getRequestURL()` é a URL pelo qual **o próprio servidor** foi alcançado. O filtro verifica o *host de destino*, não a origem. Qualquer cliente que alcance aquele host passa.
2. **O filtro não bloqueia.** Mesmo reprovando, chama `chain.doFilter` — apenas marca um atributo. 🟢 A recusa efetiva ocorre no servlet (`PagamentoCreditoAPI:160,169-170`, que lê o atributo e devolve `SC_FORBIDDEN`). O controle está partido entre duas classes.
3. **Ambos os domínios permitidos são `http://`** — sem TLS, coerente com o achado 5 de [`riscos-identificados.md`](../seguranca/riscos-identificados.md).

### 4.2 `OrdemServicoAPI` — sem filtro e sem sessão

🟢 Despacho em `OrdemServicoAPI:36-58`:

```java
doGet:  if (verificarRequisicao("usuario"))     validarLogin();
        if (verificarRequisicao("programadas")) pesquisarProgramadas();
doPost: if (verificarRequisicao("encerrar"))    encerrar();
        if (verificarRequisicao("fotos"))       salvarFotos();

private boolean verificarRequisicao(String url) { return request.getRequestURI().contains(url); }
```

🟢 Quatro fatos:

1. **`encerrar`, `fotos` e `programadas` não verificam credencial alguma.** `encerrar` (linha 60) desserializa o JSON do corpo e processa o encerramento da OS.
2. **`validarLogin` (linha 107) não estabelece sessão nem emite token.** Valida `login`/`senha` e responde — não protege as demais chamadas.
3. **O despacho é por `contains()`**, não por rota: uma URI pode casar mais de um ramo.
4. 🟢 **`request`, `response` e `resposta` são campos de instância** do servlet (linhas 32-34). Servlet é singleton no container — requisições concorrentes compartilham esse estado.

🔵 Os itens 1 e 4 são defeitos de classes diferentes: o primeiro é ausência de controle de acesso; o quarto é corrupção de resposta entre usuários simultâneos. Ambos → `NÃO TRANSPORTAR` (§9).

---

## 5. Padrão C — `GsanApi`: o contraexemplo maduro

🟢 `src/gcom/api/GsanApi.java:128-160` (**não** confundir com a cópia obsoleta em `api/GsanApi.java` na raiz, que não tem `TokenDto` nem os subpacotes):

```java
String caminhoApi = Fachada.getInstancia()
    .getSegurancaParametro(SegurancaParametro.NOME_PARAMETRO_SEGURANCA.URL_BASIC_AUTH.toString());
Object[] credenciais = Fachada.getInstancia().obterCredenciaisOauth();
String basic = Base64.encodeBase64((client_id + ":" + client_pass).getBytes("UTF-8"));
... connection.setRequestProperty("Authorization", "Basic " + basic);
TokenDto tokenDto = gson.fromJson(builder.toString(), TokenDto.class);
return tokenDto.getToken_type() + " " + tokenDto.getAccess_token();
```

🟢 Fluxo OAuth2 *client credentials*: Basic com `client_id:client_pass` → token → `Authorization: Bearer`. 🟢 **As credenciais vêm do banco** (`obterCredenciaisOauth`, `SegurancaParametro`) — não do código, não de properties versionado.

🔵 Este é o padrão mais próximo do alvo do SISAN em todo o repositório, e prova que a prática correta era conhecida. Serve como **referência interna** ao desenhar a camada de integração: configuração externalizada, credencial em repositório de segredos, token com escopo.

❔ Não foi rastreado neste round: rotação/expiração do token, comportamento em falha de autenticação, e se `obterCredenciaisOauth` lê de tabela com criptografia em repouso.

---

## 6. Padrão D — integração por banco compartilhado (UPA/SAM)

### 6.1 O mecanismo

🟢 `RepositorioIntegracaoHBM.exportarOrdemServicoMovimentos:88-108`:

```java
StatelessSession session = HibernateUtil.getStatelessSessionIntegracaoSAM();
...
try { session.insert(obj); }
catch (ConstraintViolationException exception) {
    // Não fazer nada pois o registro já está inserido no banco da SAM
}
```

🟢 `HibernateUtil:810,1819,1837` mantém uma **segunda `SessionFactory`** (`sessionFactoryIntegracaoSAM`) e expõe `getStatelessSessionIntegracaoSAM()` / `getSessionIntegracaoSAM()`.

🟢 Portanto: **o GSAN escreve diretamente dentro do banco de dados do sistema SAM**, através de uma conexão própria, usando a entidade `gcom.integracao.upa.OrdensServico` (mapeada em `OrdensServico.hbm.xml`).

🟢 A idempotência é obtida **engolindo a violação de constraint** — se a linha já existe, ignora.

### 6.2 O ciclo completo

🟢 `ControladorIntegracaoSEJB`:

| Método | Linha | Papel |
| ------ | ----- | ----- |
| `enviarMovimentoExportacaoFirma()` | 90 | seleciona `OrdemServicoMovimento` pendentes, monta `OrdensServico`, insere no banco SAM, marca `indicadorMovimento` 1 → 2 |
| `receberMovimentoExportacaoFirma()` | 200 | lê OS executadas de volta, notifica a empresa por e-mail e **encerra a OS no GSAN** |
| `gerarOS(Usuario, OrdemServico)` | 385 | criação de OS a partir da integração |
| `pesquisarHorarioProcessoIntegracaoUPA()` | 477 | horário/intervalo do processo, lidos de `SistemaParametro` |

🟢 Disparo: `gcom.util.TarefaIntegracaoUPA implements Job` (Quartz), agendamento em `SistemaParametro` (`horaInicioProcesso`, `intervaloHorasProcesso` — `RepositorioIntegracaoHBM:337-339`).

🟢 O estado do protocolo é uma coluna: `indicadorMovimento` (1 = pendente, 2 = enviado).

### 6.3 Identidade e falha silenciosa

🟢 `ControladorIntegracaoSEJB:238-248` — a identidade atravessa a fronteira como **string de login**, resolvida na volta:

```java
filtroUsuario.adicionarParametro(new ParametroSimples(FiltroUsuario.LOGIN,
    movimento.getLoginUsuario()==null ? "" : movimento.getLoginUsuario()));
usuario = (Usuario) getControladorUtil().pesquisar(...).iterator().next();
} catch (Exception e) {
    System.out.println("A ORDEM DE SERVICO: "+movimento.getId()+" nao possui usuario valido e nao teve a OS fechada");
    continue;
}
```

🟢 Se o login não resolve, a OS **não é encerrada** e o processo **segue em frente**, registrando apenas em `System.out`. 🔵 Não há registro durável, contador de rejeição, fila de erro ou alerta. A OS fica presa no limbo sem que ninguém seja notificado — o operador só descobre pela ausência do efeito.

🔵 Este é o achado mais importante do padrão D para o SISAN: **acoplamento máximo (escrita no banco alheio) combinado com observabilidade mínima (`System.out` + `continue`)**.

---

## 7. Padrões E, F, G — resumo verificado

### E — Arquivo

🔵 Já mapeado em [`arrecadacao.md`](arrecadacao.md) (movimento do arrecadador, aviso bancário, débito automático) e no inventário. Entidades confirmadas: `ArrecadadorMovimento`, `ArrecadadorMovimentoItem`, `MovimentoCartaoRejeita`, `DebitoAutomatico{,Movimento,RetornoCodigo}`. **Não reanalisado aqui** — a fronteira é o módulo Arrecadação, não este.

🟢 Contabilidade: `GerarIntegracaoContabilidadeAction` e a variante `...CaernAction` — 🟡 a existência de variante por companhia sugere layout contábil específico por cliente, não confirmado neste round.

### F — SOAP (SPC)

🟢 `gcom.integracao.webservice.spc.ConsultaWebServiceStub` — stub gerado por Axis2, endpoint padrão `https://servicos.spc.org.br:443/spcjava/remoting/ws/consulta/consultaWebService` (linhas 112, 122). 🟢 É a única integração de saída com **HTTPS** por padrão. 🔵 Consulta ao birô de crédito, ligada à negativação (módulo Cobrança).

### G — Notificação

**🟢 E-mail — `gcom.util.email.ServicosEmail`**: host SMTP obtido de `SistemaParametro` (linhas 49, 89-92) — configuração externalizada, padrão correto. Sete variantes de envio (texto, HTML, anexo, compactado). ❔ Autenticação SMTP e TLS não localizados no trecho lido.

**🟢 SMS — `gcom.util.sms.ServicoSMS`**: ver §8.2. É o pior caso do repositório.

---

## 8. Achados de segurança (análise estática; nenhuma execução)

> Conforme a regra do projeto: análise do fluxo de autorização no código, **sem exploração ofensiva**. Nenhum valor de segredo é transcrito nesta documentação.

### 8.1 Entrada de dados de campo sem autenticação — **novo, alto**

🟢 `ProcessarRequisicaoDipositivoMovelAction` (opcodes `ATUALIZAR_MOVIMENTO`, `FINALIZAR_LEITURA`) e `ProcessarRequisicaoTelemetriaAction` aceitam e gravam dados de leitura **sem identificar quem chama**, estando ambos fora dos dois filtros por listagem explícita.

🔵 Impacto: leitura de hidrômetro é insumo direto de consumo → faturamento. Injeção de leitura falsa é fraude de faturamento, não apenas incidente de TI.

### 8.2 Chave de API de SMS no código-fonte — **novo, P0**

🟢 `gcom/util/sms/ServicoSMS.java:17` — chave de API do provedor de SMS **hard-coded como constante Java**, e duplicada em `src/gcom/properties/sms.properties:1`. Dois exemplares do mesmo segredo versionados no Git.

🟢 Agravantes verificados no mesmo arquivo:

| Linha | Fato | Consequência |
| ----- | ---- | ------------ |
| 35 | URL **`http://`** hard-coded, com a leitura do properties comentada — o properties traz `https://`, ignorado | a chave trafega **em claro** |
| 72-84 | `inicializarPropriedades()` tem o corpo comentado e **retorna `null`** | o arquivo de configuração é inerte; tudo vem das constantes |
| 41-58 | `getJson` **ignora o parâmetro `tipoMensagem`** e sempre envia o texto de confirmação de cadastro no Portal | 🟢 `ControladorFaturamento:15268` pede aviso de vencimento e o cliente recebe "Recebemos seu cadastro no Portal" — **defeito funcional que alcança o cliente final** |
| 67 | número de telefone real em `main()` | dado pessoal versionado (LGPD) |
| 37-39 | resposta HTTP nunca verificada; `System.out.println("FIM")` | falha de envio é silenciosa |

🟢 `ControladorCobranca:62373` — o SMS de corte está **comentado**, logo inativo.

**Ação obrigatória**: a chave é considerada **comprometida** e entra na lista de rotação (regra do projeto). A rotação é responsabilidade de quem opera a instalação; neste projeto o registro é o próprio dever.

### 8.3 `/api/ordem-servico/*` sem autenticação — **alto** (registrado em §4.2)

### 8.4 Assinatura DSA sem frescor — **médio** (registrado em §3.2)

🔵 Assinatura sobre o login apenas → portador estático e replicável.

### 8.5 Servlet com estado de instância — **médio** (registrado em §4.2, item 4)

---

## 9. Compatibilidade GSAN → SISAN

| Conceito / estrutura | Classificação | Motivo |
| -------------------- | ------------- | ------ |
| **Capacidade** de coleta em campo (baixar rota, enviar movimento, finalizar leitura) | **PRESERVAR CONCEITO** | Necessidade real de negócio; é o ciclo da micromedição |
| Protocolo binário por opcode + ausência de autenticação | **NÃO TRANSPORTAR** | Sem identificação da origem em escrita que alimenta faturamento |
| **Capacidade** de integração móvel de OS (listar programadas, encerrar, enviar fotos) | **PRESERVAR CONCEITO** | Requisito funcional legítimo do Atendimento |
| `OrdemServicoAPI`: servlet com estado, despacho por `contains`, endpoints sem credencial | **NÃO TRANSPORTAR** | Três defeitos independentes na mesma classe |
| **Capacidade** de troca de OS com executante terceirizado (UPA/SAM) | **PRESERVAR CONCEITO** | Fluxo de negócio real (empresa executa, GSAN encerra) |
| Escrita direta no banco do sistema parceiro + idempotência por `ConstraintViolationException` engolida | **REESTRUTURAR** | Acoplamento máximo; contrato implícito no schema alheio |
| Identidade atravessando como string de login, com falha silenciosa (`continue` + `System.out`) | **REESTRUTURAR** | Perda de trabalho sem rastro |
| Assinatura DSA do GIS | **MODERNIZAR** | Conceito certo (autenticar a origem criptograficamente); falta frescor e escopo |
| `GsanApi` (OAuth2, credencial em banco) | **PRESERVAR CONCEITO** | Único padrão já alinhado ao alvo; serve de referência |
| Pseudo-autenticação por domínio (`PagamentoCreditoFilter`) | **NÃO TRANSPORTAR** | Valida o host do próprio servidor, não o chamador |
| Chave de SMS em código; URL `http://` fixa; `tipoMensagem` ignorado | **NÃO TRANSPORTAR** | Segredo versionado + defeito funcional |
| SMTP configurado por `SistemaParametro` | **MODERNIZAR** | Externalização correta; falta autenticação/TLS confirmadas |
| Consulta SPC por SOAP/Axis2 | **MODERNIZAR** | Capacidade necessária; transporte e biblioteca obsoletos |
| Agendamento de integração em `SistemaParametro` + Quartz `Job` | **MODERNIZAR** | Conceito preservado; tecnologia substituída junto com o Batch |
| Estado do protocolo em coluna (`indicadorMovimento` 1→2) | **PRESERVAR CONCEITO** | Máquina de estados simples e adequada; formalizar no SISAN |

---

## 10. Cenários de caracterização identificados

> Inventário de cenários. Conforme a correção aceita na revisão, cenário identificado **não é** especificação de teste — a especificação (entrada, pré-condições, operação, campos observados, resultado esperado, normalizações, divergências permitidas) é entregável do fechamento da Fase 0, ver [`estrategia-testes.md`](../testes/estrategia-testes.md).

1. Download do arquivo de rota pelo coletor (opcode `PACOTE_BAIXAR_ARQUIVO`)
2. Envio de movimento de leitura (`ATUALIZAR_MOVIMENTO`) e efeito em `ConsumoHistorico`
3. Finalização de movimento (`FINALIZAR_LEITURA`) e liberação da rota para faturamento
4. Confirmação de recebimento com a variação por `CODIGO_EMPRESA_FEBRABAN_CAER`
5. Teste de conexão (`TESTE_CONEXAO`)
6. Processamento de string de telemetria bem formada
7. Processamento de string de telemetria malformada (comportamento não caracterizado)
8. Requisição GIS com assinatura válida
9. Requisição GIS com assinatura inválida (`atencao.assinatura.invalida`)
10. Requisição GIS com assinatura válida e usuário inexistente
11. Exportação UPA: movimento pendente → inserido no banco SAM → `indicadorMovimento` 1→2
12. Exportação UPA: registro já existente no SAM (violação de constraint engolida)
13. Recebimento UPA com login de usuário válido → OS encerrada
14. Recebimento UPA com login inválido → OS **não** encerrada, processo continua
15. Recebimento UPA com empresa sem e-mail cadastrado
16. `/api/pagamentoCredito` com host permitido × host não permitido (403 pelo servlet)
17. `/api/ordem-servico/encerrar` — comportamento atual sem credencial
18. `/api/ordem-servico` com duas requisições concorrentes (campos de instância)
19. Envio de e-mail com anexo e com falha de SMTP
20. Envio de SMS por tipo de mensagem (caracteriza o defeito do `tipoMensagem` ignorado)
21. Consulta SPC com retorno positivo, negativo e indisponibilidade do serviço
22. Geração de integração contábil padrão × variante CAERN

---

## 11. Dúvidas abertas

| # | Dúvida | Por que importa |
| - | ------ | --------------- |
| 1 | Quais consumidores reais existem hoje para cada entry point? (coletor, app, telemetria, GIS) | Define o que é contrato público a preservar × o que pode ser redesenhado livremente |
| 2 | Como o `sessionFactoryIntegracaoSAM` é configurado (datasource, credencial, se ainda aponta para banco existente)? | Determina se a integração UPA está ativa ou é resíduo |
| 3 | O layout do arquivo do coletor (opcode `PACOTE_BAIXAR_ARQUIVO`) é documentado em algum lugar fora do código? | É contrato binário com hardware de campo |
| 4 | `obterCredenciaisOauth` guarda a credencial com que proteção em repouso? | Define o padrão de segredo a herdar ou corrigir |
| 5 | O `ProcessarRequisicaoDipositivoMovelImpressaoSimultaneaAction` e o `...AcompanhamentoServicoAction` seguem o mesmo padrão dos analisados? | Não lidos neste round — assumir equivalência seria extrapolação |
| 6 | Existe autenticação/TLS no SMTP de `ServicosEmail`? | Credencial e conteúdo em claro |
| 7 | A variante contábil CAERN indica layout por companhia ou só rotina distinta? | Afeta o desenho da integração contábil |
| 8 | Há retentativa em qualquer integração, ou toda falha é terminal? | Nenhum mecanismo de retry foi localizado neste round |
| 9 | O `indicadorMovimento` tem valores além de 1 e 2? | Completude da máquina de estados |
| 10 | Quem consome `GisRetornoMotivo` e as views `vw_*_geo_*`? | Fronteira do GIS com o banco |

---

## 12. Fronteiras com outros módulos

- **Micromedição** — dona do efeito dos padrões A (coletor, telemetria). O entry point é a porta; a regra é de lá. Ver [`micromedicao.md`](micromedicao.md).
- **Atendimento** — dono do efeito do padrão D (UPA/SAM) e da API de OS. O encerramento de OS pela integração é o mesmo encerramento do módulo. Ver [`atendimento.md`](atendimento.md).
- **Arrecadação** — dona do padrão E (arquivos bancários, débito automático, PIX). Ver [`arrecadacao.md`](arrecadacao.md).
- **Cobrança** — dona do consumo do SPC (negativação) e da cobrança terceirizada. Ver [`cobranca.md`](cobranca.md).
- **Segurança** — o padrão A existe **por exceção** às listas dos filtros; as duas listas estão descritas em [`seguranca.md`](seguranca.md).
- **Batch** — o disparo do padrão D é um `Job` Quartz, sob o mesmo mecanismo de agendamento descrito em [`batch.md`](batch.md).

---

## 13. Síntese

🔵 O GSAN integra por **sete mecanismos independentes**, criados em momentos diferentes, sem política comum de autenticação, de tratamento de erro ou de observabilidade. O espectro vai de OAuth2 com credencial em banco (`GsanApi`) a chave de API escrita em constante Java (`ServicoSMS`), passando por escrita direta no banco de um sistema parceiro (UPA/SAM).

🔵 Para o SISAN, a conclusão não é "portar as integrações": é **preservar todas as capacidades funcionais** (coleta em campo, OS móvel, troca com executante terceirizado, consulta a birô, arquivos bancários, notificação) sob **uma** camada com política única — autenticação real da origem, identidade rastreável atravessando a fronteira, erro durável e observável, segredo fora do código e transporte cifrado.

🔵 O `GsanApi` prova que esse padrão já era conhecido dentro do próprio código. A camada de integração do SISAN é a generalização dele, não uma invenção.
