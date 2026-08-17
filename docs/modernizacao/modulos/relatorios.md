# Módulo Relatórios — Mapa Funcional

Elaborado em 2026-08-14 (Fase 0). Pergunta desta análise: **como o GSAN recebe uma solicitação de relatório, decide como executá-la, obtém os dados, gera o artefato, controla estado/autorização e entrega o resultado?** Nenhum inventário de relatórios, classes ou templates foi refeito.

**Convenção**: 🟢 fato comprovado · 🔵 interpretação funcional sustentada · 🟡 hipótese · ❔ não compreendido (§30).

## 1. Responsabilidade e fronteiras

🔵 Relatórios é o **motor comum de extração e apresentação**: recebe uma solicitação parametrizada, decide se ela cabe numa execução interativa ou precisa ir para processamento assíncrono, obtém os dados (delegando a consulta ao módulo dono), preenche um template, exporta no formato pedido e entrega o artefato ao usuário.

🔵 Duas fronteiras que o código sustenta:
- **com os módulos de negócio**: o relatório **seleciona, organiza, formata e entrega**; a consulta/regra pertence ao módulo dono (§24).
- **com o Batch**: o Batch **agenda, acompanha e controla** a execução assíncrona; Relatórios **define o que gerar, produz o artefato e o entrega** ([batch.md](batch.md)).

## 2. Modelo conceitual — três conceitos distintos

🟢 Confirmados como entidades/papéis diferentes:

| Conceito | Onde vive | O que é |
| -------- | --------- | ------- |
| **Relatório (definição)** | `gcom.batch.Relatorio` → `batch.relatorio` (descrição, abreviada, indicador de uso) | O **tipo lógico** catalogado |
| **Tarefa de relatório (execução)** | `gcom.tarefa.TarefaRelatorio` (abstrata, estende `Tarefa`) | A **solicitação executável**, com parâmetros, formato e a lógica de obter dados/gerar |
| **Relatório gerado (resultado)** | `gcom.batch.RelatorioGerado` → `batch.relatorio_gerado` | O **artefato materializado**, ligado à `FuncionalidadeIniciada` e ao `Relatorio` |

🟢 `RelatorioGerado` guarda: `rege_pdf` (**o arquivo como binário no banco**), `rege_nnpaginas` (número de páginas), `rege_tmultimaalteracao`, e FKs **obrigatórias** para `FuncionalidadeIniciada` (`fuin_id`) e `Relatorio` (`rela_id`). 🔵 É pelo vínculo com a `FuncionalidadeIniciada` (que pertence a um `ProcessoIniciado`, que tem `usuario`) que o resultado se liga ao **solicitante**.

🔵 Distinto de tudo isso, `gcom.relatorio.RelatorioProcessado` é um **envelope em memória** (bytes + tipo de saída) usado no caminho online — não é entidade persistida (§10).

## 3. Solicitação de relatório

🔵 O fluxo começa numa Action que monta a `TarefaRelatorio` concreta com seus parâmetros (filtros escolhidos pelo usuário, formato de saída) e a submete ao gerenciador de execução. 🟢 A tarefa carrega **usuário** e, no caminho assíncrono, é **serializada** (mesmo mecanismo do Batch: `IoUtil.transformarObjetoParaBytes`, recuperada com `IoUtil` na entrega).

## 4. Decisão online × batch (mecanismo central)

🟢 Comprovado em `GerenciadorExecucaoTarefaRelatorio.analisarExecucao(TarefaRelatorio, int tipoTarefa)`:

```java
quantidadeRegistroGerado      = tarefaRelatorio.calcularTotalRegistrosRelatorio();
nomeClasseRelatorio           = tarefaRelatorio.getClass().getSimpleName();
quantidadeMaximaOnLine        = ConstantesExecucaoRelatorios.get(nomeClasseRelatorio);

if (quantidadeMaximaOnLine == QUANTIDADE_NAO_INFORMADA   // -1
    || quantidadeRegistroGerado > quantidadeMaximaOnLine) {
        if (SistemaParametro.INDICADOR_AUTORIZACAO_RELATORIO == NÃO)
             controladorBatch.iniciarProcessoRelatorio(tarefaRelatorio);
        else controladorBatch.iniciarProcessoRelatorioControleAutorizacao(tarefaRelatorio);
} else {
        byte[] dados = (byte[]) tarefaRelatorio.executar();      // ONLINE
        retorno = new RelatorioProcessado(dados, tipoTarefa);
}
```

🔵 Leitura funcional: **antes de gerar, o sistema conta os registros** que o relatório produziria e compara com um **limite por tipo de relatório**. Dentro do limite → executa **na hora** e devolve os bytes; acima do limite **ou sem limite configurado** → manda para o **Batch**. A decisão considera **apenas a quantidade de registros** — não formato, não perfil de usuário, não horário.

## 5. Limites de execução

🟢 `ConstantesExecucaoRelatorios` lê `/constantes_execucao_relatorios.properties` (em `src/gcom/properties/`), cujo cabeçalho declara: *"Arquivo que indica quantos registros um relatório pode apresentar online"*.
- 🟢 **Chave = nome simples da classe** da tarefa de relatório (`getSimpleName()`). Exemplos: `RelatorioManterBairro = 500`, `RelatorioManterCliente = 1000`, `RelatorioManterSetorComercial = 10`.
- 🟢 **Valor = quantidade máxima de registros para execução online.**
- 🟢 **`QUANTIDADE_NAO_INFORMADA = -1`** é o retorno quando a chave não existe — e, no `if`, leva a execução **para o Batch**. 🔵 Ou seja: **relatório sem limite configurado é sempre assíncrono** (padrão conservador).

⚠️ 🔵 Duas fragilidades funcionais do mecanismo: o vínculo é por **nome simples de classe** (renomear a classe silenciosamente muda o comportamento para batch) e o custo real do relatório é aproximado apenas por **contagem de registros**.

## 6. `TarefaRelatorio`

🟢 Classe abstrata (`gcom.tarefa.TarefaRelatorio extends Tarefa`) que define o contrato do motor:
- **formatos**: `TIPO_PDF=1`, `TIPO_RTF=2`, `TIPO_XLS=3`, `TIPO_HTML=4`;
- **contagem**: `calcularTotalRegistrosRelatorio()` (usada na decisão §4);
- **geração**: `gerarRelatorio(nomeRelatorio, parametrosRelatorio, RelatorioDataSource, tipoSaidaRelatorio)` → **`byte[]`**;
- **execução**: `executar()` (herdada de `Tarefa`), que o caminho online invoca diretamente;
- **internacionalização**: parâmetros `REPORT_LOCALE` e `REPORT_RESOURCE_BUNDLE` (`gcom.properties.application`);
- **vazio**: `RelatorioVazioException`.

🔵 Portanto **cada relatório é uma subclasse** que sabe contar seus registros, obter seus dados e nomear seu template — o motor comum cuida do resto.

## 7. Geração com JasperReports

🟢 Fluxo comprovado em `gerarRelatorio`:

```text
ConstantesRelatorios.getURLRelatorio(nomeRelatorio).openStream()
   → JRLoader.loadObject(stream)                       → JasperReport (template JÁ COMPILADO)
   → [locale, se definido]
   → JasperFillManager.fillReport(jasperReport, parametrosRelatorio, relatorioDataSource)
   → JasperPrint
   → exporter por tipo (ex.: JRPdfExporter com JASPER_PRINT + OUTPUT_STREAM) → byte[]
```

🟢 **Templates são `.jasper` compilados**, referenciados por constantes de caminho em `ConstantesRelatorios` (ex.: `/relatorioManterOperacao.jasper`, `/relatorioManterGrupo.jasper`) e resolvidos como **URL de recurso** (`getURLRelatorio`). 🟢 Existem `.jrxml` no repositório (registrado no diagnóstico técnico) — 🔵 os `.jrxml` são a fonte e os `.jasper` o artefato usado em runtime. ❔ Se a compilação ocorre no build ou é previamente versionada não foi verificado nesta análise; ❔ templates por companhia e subrelatórios não foram investigados.

## 8. Datasource e origem dos dados

🟢 O preenchimento recebe um **`RelatorioDataSource`** (classe própria em `gcom.relatorio`) — 🔵 o Jasper não consulta o banco diretamente: recebe uma fonte de dados montada pela aplicação. 🔵 Isso sustenta a fronteira: **o módulo de negócio produz/consulta a informação; o relatório organiza e formata**.

❔ **Não verifiquei** quantos relatórios seguem estritamente esse padrão. 🟡 Hipótese sustentada por outros mapas (ex.: relatórios que instanciam `ConsumoHistorico`/`ImovelEconomia` diretamente, vistos em cadastro/micromedição): **parte dos relatórios contém consulta e alguma regra própria** — exceção a registrar, não generalizar.

## 9. Formatos de saída

🟢 O motor suporta **PDF, RTF, XLS e HTML** (constantes + exporters). 🟢 A coluna que armazena o resultado assíncrono chama-se **`rege_pdf`** e o download batch usa `Content-Disposition: attachment; filename=relatorio.pdf` com `mimeType = "application/pdf"` no primeiro ramo — 🔵 indicando o **PDF como formato padrão do resultado persistido**, embora a Action trate outros ramos de tipo (há mais `addHeader` para outros formatos). 🔵 O tipo de saída é decidido pela Action/tarefa (parâmetro `tipoSaidaRelatorio`), não pelo motor.

## 10. Execução online

🔵 Fluxo comprovado:

```text
Action → monta TarefaRelatorio (parâmetros + tipo de saída)
      → GerenciadorExecucaoTarefaRelatorio.analisarExecucao(tarefa, tipoTarefa)
      → [dentro do limite] tarefaRelatorio.executar()  → byte[]
      → new RelatorioProcessado(byte[], tipoTarefa)
      → Action escreve os bytes na resposta HTTP (headers/MIME definidos pela camada web)
```

Respostas diretas: 🟢 o resultado online **não é persistido** — vive como `byte[]` dentro de `RelatorioProcessado` e vai para a resposta; 🟢 **não há `RelatorioGerado` no caminho online**, logo **não há estado persistente** de "relatório online executado"; 🔵 o formato vem da tarefa/Action. ❔ **Auditoria da solicitação online não foi comprovada** — não localizei registro de operação específico para geração online (o gate de segurança e a auditoria genérica de operação podem ou não cobrir; ver §17).

## 11. Execução assíncrona (batch)

🔵 Fluxo comprovado, apoiado no framework descrito em [batch.md](batch.md) (não repetido aqui):

```text
analisarExecucao decide BATCH
   → ControladorBatch.iniciarProcessoRelatorio(tarefaRelatorio)
        ou iniciarProcessoRelatorioControleAutorizacao(tarefaRelatorio)   [conforme §13]
   → cria ProcessoIniciado (processo de relatório resolvido por
        GerenciadorExecucaoTarefaRelatorio.obterProcessoRelatorio(nomeRelatorio),
        que mapeia nome do relatório → constante de Processo)
   → FuncionalidadeIniciada (tarefa serializada nos parâmetros)
   → execução: iniciarFuncionalidadeIniciadaRelatorio(id) → tarefa gera o artefato
   → persiste RelatorioGerado (arquivo + páginas + vínculos)
   → encerrarFuncionalidadeIniciadaRelatorio(id, concluiuComErro)
   → usuário consulta status e faz download
```

🟢 Existe também `iniciarRelatoriosAgendados()` — 🔵 relatórios podem ser **agendados**, além de solicitados sob demanda.

## 12. Integração com o Batch — a adaptação específica

🔵 O que é **próprio dos relatórios** dentro do framework batch: métodos dedicados no `ControladorBatchSEJB` (`iniciarProcessoRelatorio`, `...ControleAutorizacao`, `iniciarRelatoriosAgendados`, `iniciar/encerrarFuncionalidadeIniciadaRelatorio`), o mapeamento **nome do relatório → processo** (`obterProcessoRelatorio`), e o **resultado persistido** (`RelatorioGerado`) — que os processos batch comuns não produzem. 🔵 O restante (processo iniciado, etapas, estados, acompanhamento) é o framework padrão.

❔ **Não verifiquei** se relatórios batch usam `UnidadeProcessamento`/`UnidadeIniciada` como os processos de negócio, ou se executam como etapa única — diferença relevante para o modelo.

## 13. Autorização de relatório (operacional)

🟢 Dois caminhos, escolhidos por **`SistemaParametro.INDICADOR_AUTORIZACAO_RELATORIO`**: sem autorização → `iniciarProcessoRelatorio`; com autorização → `iniciarProcessoRelatorioControleAutorizacao`. 🟢 Existe tela dedicada `ExibirAutorizarRelatoriosBatchAction`.

🔵 Interpretação: trata-se de **aprovação operacional para gerar relatório pesado** (controle de carga), **não** de permissão de segurança do usuário — é o mesmo tipo de mecanismo da autorização de processo vista no Batch (`Processo.indicadorAutorizacao` + `AGUARDANDO_AUTORIZACAO`), aplicado à família de relatórios e ligado por **parâmetro global do sistema**. ⚠️ Não confundir com **permissão de acesso** (§17).

❔ Quem autoriza (perfil/permissão específica) e se o estado usado é o mesmo `AGUARDANDO_AUTORIZACAO` do processo **não foram comprovados**.

## 14. `RelatorioGerado` — armazenamento

🟢 O artefato é gravado **no próprio banco**, como binário, na coluna `rege_pdf` de `batch.relatorio_gerado`, com número de páginas e timestamp de última alteração; vínculos obrigatórios com `FuncionalidadeIniciada` e `Relatorio`.

❔ **Não comprovados** (e explicitamente não inferidos): nome de arquivo persistido, MIME type persistido, formato armazenado como campo, política de **expiração**, **rotina de limpeza/retenção**, e se relatórios ficam armazenados indefinidamente. O nome da coluna (`rege_pdf`) e o download com `filename=relatorio.pdf` sugerem PDF como padrão, mas **não provam** que outros formatos não sejam gravados ali.

## 15. Recuperação e download

🟢 `ExibirRelatorioBatchAction` implementa a entrega:

```text
idFuncionalidadeIniciada = request.getParameter("idFuncionalidadeIniciada")   ← vem do request
FiltroRelatorioGerado por FUNCIONALIDADE_INICIADA_ID
   → pesquisa RelatorioGerado
   → desserializa a TarefaRelatorio associada (IoUtil)
   → define Content-Disposition/MIME conforme o tipo
   → escreve os bytes no OutputStream da resposta
```

🟢 Acompanhamento: `ExibirStatusGeracaoAction` e **`ExibirStatusGeracaoUsuarioAction`**, esta última usando `fachada.pesquisarRelatoriosBatchPorUsuarioSistema(idProcesso)` — 🔵 **existe consulta de relatórios por usuário**, que é como o solicitante encontra os seus.

## 16. Segurança do download — ponto de atenção

⚠️ 🟢 **Fato**: no trecho analisado de `ExibirRelatorioBatchAction`, a recuperação usa **apenas o `idFuncionalidadeIniciada` recebido no request** para localizar o `RelatorioGerado`; **não localizei, nesse trecho, comparação com o usuário logado** (nem via `ProcessoIniciado.usuario`, nem por abrangência).

🔵 Isso **não é declaração de vulnerabilidade** — a proteção poderia estar (a) no gate de autorização da URL, (b) em validação anterior na tela de status que fornece o id, ou (c) em outro ponto do fluxo que não inspecionei. ⚠️ Porém, há dois agravantes conhecidos que tornam o ponto **prioritário**: o `FiltroSegurancaAcesso` **exclui do bloco de autorização qualquer URL contendo `relatorio`** ([seguranca.md §7](seguranca.md)), e a Action de download se chama `ExibirRelatorioBatchAction` — cuja URL provavelmente contém "relatorio".

❔ **Dúvida prioritária registrada** (§30): *um usuário autenticado consegue baixar o relatório gerado por outro informando outro `idFuncionalidadeIniciada`?* Precisa de rastreio dirigido — **não presumir** nem em favor nem contra.

## 17. Segurança — a exceção `relatorio` no filtro

🟢 O filtro exclui URLs contendo `relatorio` (case-insensitive) do bloco de autorização funcional. ⚠️ **Não concluir** que relatórios não têm autorização:
- 🔵 a **tela chamadora** (que monta os filtros e submete a solicitação) normalmente é uma Action de funcionalidade **não excepcionada**, e portanto passa pelo gate — a autorização tende a ocorrer **antes**, no acesso à tela;
- 🟢 é necessário **usuário em sessão** para o filtro sequer avaliar a requisição (a guarda inicial verifica `usuarioLogado != null`), e há lista própria de URLs sem usuário em sessão;
- ❔ **não comprovei** validação interna de permissão nas Actions de geração/download.

🔵 Distinção essencial: **permissão de acesso** (RBAC, §17) ≠ **aprovação operacional para gerar relatório pesado** (§13).

## 18. Identidade e auditoria

🟢 **Solicitante**: existe e é rastreável — o relatório batch nasce como `ProcessoIniciado`, que grava `usuario` (batch.md §14), e a consulta por usuário confirma o vínculo prático. 🟢 **Executor**: `RelatorioPadraoBatch(Usuario.USUARIO_BATCH)` é usado em relatórios executados em contexto batch (evidência já registrada em seguranca.md §21) — 🔵 nesses casos o **autor da execução** é a identidade de sistema, enquanto o **solicitante** permanece no processo iniciado. 🟢 **Resultado**: `RelatorioGerado` liga-se ao solicitante **indiretamente**, via `FuncionalidadeIniciada → ProcessoIniciado → usuario`.

❔ **Não comprovado**: auditoria do **download** (quem baixou, quando) e auditoria da **geração online**.

## 19. Parâmetros e consistência temporal

🟢 No caminho batch, a **tarefa inteira é serializada** (mesmo mecanismo do Batch) e recuperada na entrega (`IoUtil` em `ExibirRelatorioBatchAction`) — 🔵 os parâmetros da solicitação **são preservados** e a solicitação é reconstruível. ⚠️ 🟢 Isso implica **dependência de serialização Java de classes do legado** (o mesmo risco de migração apontado em batch.md).

🔵 **Consistência temporal**: como o que se persiste é a **tarefa com seus filtros** (e a consulta acontece quando a tarefa executa), o relatório batch tende a refletir os dados **no instante da execução**, não no da solicitação. ⚠️ 🔵 Porém, a contagem (`calcularTotalRegistrosRelatorio`) ocorre **no instante da solicitação** — 🔵 logo há uma janela em que a quantidade decidida e a quantidade gerada podem divergir. ❔ Não verifiquei se algum relatório materializa dados na solicitação; **não generalizar** a partir de um caso.

## 20. Acompanhamento operacional

🟢 Telas de **status de geração** (geral e por usuário), **autorização de relatórios batch**, e a Action de **download**. 🔵 O usuário descobre que seu relatório terminou consultando o status; o **estado vem da `FuncionalidadeIniciada`** (situações do framework batch) e o **artefato, do `RelatorioGerado`**. ❔ Percentual de progresso e notificação (e-mail/alerta) **não comprovados**.

## 21. Relatório vazio

🟢 `RelatorioVazioException` existe e é lançada por `gerarRelatorio`. 🔵 Ou seja: relatório sem dados é tratado como **situação funcional nomeada**, não como erro genérico. ❔ Como a mensagem chega ao usuário e se o comportamento difere entre online e batch (no batch, se vira `CONCLUIDA_COM_ERRO` ou conclusão com aviso) **não foi comprovado**.

## 22. Serviço externo de relatórios

🟡 Existe evidência de um **serviço externo**: o diagnóstico técnico registrou a biblioteca `gsan-relatorios` (Jersey + Gson) e a classe `api/GsanApi.java` com URL e token; há também `AcessoServicoReportException`. ❔ **Não comprovei** nesta análise: qual servidor/serviço é, quais relatórios o utilizam, se é alternativa ou complemento ao motor local, se é obrigatório e se é específico de companhia. 🔵 Registrado como **caminho paralelo provável**, a investigar no mapa de Integrações — **não** documentar arquitetura por inferência de nome.

## 23. Casos representativos

**Online** 🔵 — família `RelatorioManter*` (ex.: `RelatorioManterSetorComercial`, limite 10; `RelatorioManterBairro`, 500): Action monta a tarefa com os filtros da consulta → `analisarExecucao` conta registros → dentro do limite → `executar()` → `gerarRelatorio` (template `.jasper` + datasource + exporter) → `RelatorioProcessado` → bytes na resposta HTTP. Sem persistência, sem estado.

**Batch** 🔵 — mesmo tipo de relatório **acima do limite**, ou qualquer relatório **sem chave no properties**: `analisarExecucao` → `iniciarProcessoRelatorio(...)` (ou a variante com autorização) → `ProcessoIniciado` (com solicitante) → `FuncionalidadeIniciada` com a tarefa serializada → execução → `RelatorioGerado` (binário + páginas) → status por usuário → `ExibirRelatorioBatchAction` entrega os bytes.

## 24. Fronteiras com os módulos de negócio

🔵 Relatórios consultam praticamente todos os módulos (cadastro, micromedição, faturamento, cobrança, arrecadação, atendimento, segurança), mas **não são donos dessas regras**: o padrão é receber um `RelatorioDataSource` já montado. ⚠️ 🟡 **Exceção a registrar**: parte dos relatórios monta a própria consulta e contém alguma regra de apresentação/derivação — comportamento observado indiretamente nos mapas anteriores, **não quantificado aqui**.

## 25. Variações por companhia

❔ Não investigado nesta atividade. 🔵 Pontos onde variação é plausível e deve ser verificada depois: templates `.jasper` por companhia, relatórios exclusivos de uma instalação e valores do properties de limites. Sem evidência, **nada classificado** como REGRA BASE / PARAMETRIZAÇÃO / CUSTOMIZAÇÃO / EVOLUÇÃO POSTERIOR.

## 26. Regras estruturantes

1. 🟢 **Relatório, tarefa e resultado são conceitos distintos** (definição catalogada, execução parametrizada, artefato materializado).
2. 🟢 **A decisão online × assíncrono é automática e prévia**, baseada em contagem de registros versus limite por tipo.
3. 🟢 **Sem limite configurado ⇒ assíncrono** (padrão conservador).
4. 🟢 **O caminho online não persiste nada**; o assíncrono **persiste o artefato** vinculado à execução.
5. 🟢 **O artefato liga-se ao solicitante indiretamente**, pela execução (`FuncionalidadeIniciada → ProcessoIniciado → usuario`).
6. 🟢 **Existe aprovação operacional para relatórios pesados**, ligada por parâmetro global — distinta de permissão de acesso.
7. 🟢 **O motor é comum**: template compilado + datasource + exportador, com formatos PDF/RTF/XLS/HTML.
8. 🟢 **Relatório vazio é situação funcional nomeada.**
9. 🟢 **A solicitação é preservada** (tarefa serializada), tornando a execução reconstruível.
10. 🔵 **A consulta ocorre na execução**, enquanto a contagem ocorre na solicitação — há janela temporal entre as duas.

## 27. Compatibilidade GSAN → SISAN

| Conceito | Classificação | Motivo |
| -------- | ------------- | ------ |
| Relatório como **solicitação parametrizada** com definição catalogada | PRESERVAR CONCEITO | Base do modelo; migrável |
| Distinção **execução interativa × assíncrona** | PRESERVAR CONCEITO | Necessidade real: processamento pesado não pode bloquear o uso interativo |
| **Critério prévio** para decidir o modo de execução | PRESERVAR CONCEITO (o critério) | A ideia de decidir antes de gerar é boa |
| Limite por **nome simples de classe** em `.properties`, medindo só quantidade de registros | **REESTRUTURAR** | Mecanismo legado frágil (renomear classe muda comportamento; custo aproximado por contagem) — o conceito permanece, a implementação não |
| **Estado da geração** e resultado recuperável | PRESERVAR CONCEITO | Usuário precisa acompanhar e recuperar |
| **Identidade do solicitante** vinculada ao resultado | PRESERVAR CONCEITO | Rastreabilidade e controle de acesso ao artefato |
| **Aprovação operacional** de relatório pesado | PRESERVAR CONCEITO | Controle de carga com governança |
| **Relatório vazio** como situação funcional | PRESERVAR CONCEITO | Experiência do usuário |
| **Formatos** exigidos pelos usuários (PDF/XLS ao menos) | PRESERVAR CONCEITO | Requisito de negócio, independente de motor |
| Vínculo do artefato ao solicitante **apenas indireto** | MODERNIZAR MANTENDO COMPATIBILIDADE | A informação existe; o acesso ao artefato deveria ser verificado explicitamente |
| **JasperReports**, `.jasper` compilado, exporters | **NÃO TRANSPORTAR automaticamente** | Tecnologia; a necessidade é gerar artefatos formatados — reavaliar sem herdar o motor |
| **Armazenamento do arquivo no banco** (`rege_pdf`) | **NÃO TRANSPORTAR automaticamente** | Requisito real: *resultado assíncrono recuperável*; **onde** armazenar é decisão futura |
| **Serialização Java da tarefa** (parâmetros e entrega) | **REESTRUTURAR** | Frágil e amarra a migração; a necessidade (preservar a solicitação) permanece |
| Struts/EJB/Quartz/JMS no caminho de relatórios | **NÃO TRANSPORTAR** | Tecnologia |
| Segurança do **download** do artefato | **EXIGE APROFUNDAMENTO** | Verificação por usuário não localizada (§16) — decidir só após rastrear |
| **Retenção/expiração** de relatórios gerados | **EXIGE APROFUNDAMENTO** | Política não comprovada; afeta volume e privacidade |
| Uso de **unidades de processamento** em relatórios batch | EXIGE APROFUNDAMENTO | Não verificado (§12) |
| **Serviço externo** de relatórios | EXIGE APROFUNDAMENTO | Existência sugerida, papel não comprovado (§22) |

## 28. Hipóteses para avaliação futura (não são decisões; nenhuma tecnologia escolhida)

1. **Solicitação de relatório como recurso de primeira classe** (com solicitante, parâmetros, estado e resultado), unificando online e assíncrono sob o mesmo modelo.
2. **Critério de execução baseado em custo estimado**, evoluindo o limite atual sem herdar o acoplamento ao nome da classe.
3. **Artefato com metadados explícitos** (formato, MIME, nome, tamanho, expiração) e **controle de acesso próprio**, em vez de vínculo apenas indireto.
4. **Contexto da solicitação em formato estável** (não serialização Java), preservando a reconstrução da solicitação.
5. **Política de retenção explícita** para artefatos gerados.

## 29. Cenários de caracterização identificados (sustentados por evidência)

> Cenário sustentado por evidência de que o fluxo existe; o resultado esperado será estabelecido na caracterização.

1. Relatório **abaixo do limite** → execução online e resposta direta.
2. Relatório **acima do limite** → envio ao batch.
3. Relatório **sem chave** no properties → batch (limite = −1).
4. Relatório batch com `INDICADOR_AUTORIZACAO_RELATORIO = NÃO` (sem aprovação).
5. Relatório batch com autorização exigida → estado de espera → autorização concedida.
6. Geração online com sucesso (PDF).
7. Geração online em outro formato (XLS).
8. **Relatório vazio** (online e batch) — comportamento e mensagem.
9. Erro na geração online.
10. Geração batch com sucesso → `RelatorioGerado` persistido (arquivo + páginas + vínculos).
11. Erro na geração batch → estado da `FuncionalidadeIniciada`.
12. Consulta de **status por usuário** e localização do próprio relatório.
13. **Download pelo solicitante**.
14. **Tentativa de download por outro usuário** informando `idFuncionalidadeIniciada` alheio (§16 — prioritário).
15. Parâmetros da solicitação preservados e reconstruídos na entrega.
16. Divergência entre a contagem na solicitação e o volume na execução (janela temporal, §19).
17. Relatório agendado (`iniciarRelatoriosAgendados`).
18. Relatório com template/subrelatório (se confirmado).
19. Caminho por serviço externo (**somente se comprovado**, §22).

## 30. Dúvidas abertas

1. ❔ **Segurança do download**: há verificação de que o solicitante é quem baixa? (prioritária — §16).
2. ❔ **Retenção/expiração/limpeza** de `RelatorioGerado`; se há crescimento indefinido.
3. ❔ Se `RelatorioGerado` guarda **formato/MIME/nome de arquivo** ou se é sempre tratado como PDF.
4. ❔ Se relatórios batch usam **unidades de processamento** ou executam como etapa única.
5. ❔ **Auditoria** de geração online e de download.
6. ❔ Quem **autoriza** relatórios batch e qual estado é usado.
7. ❔ Comportamento do **relatório vazio no batch** (erro × conclusão com aviso).
8. ❔ **Compilação dos templates** (build × versionados) e existência de templates por companhia/subrelatórios.
9. ❔ **Serviço externo** de relatórios: existência real, papel e alcance (§22).
10. ❔ Quantos relatórios seguem o padrão datasource-injetado e quantos embutem consulta/regra própria (§8/§24).
11. ❔ Existência de **notificação** e de **progresso** para relatórios longos.

## 31. Evidências principais

```text
Decisão:      relatorio/GerenciadorExecucaoTarefaRelatorio.analisarExecucao(TarefaRelatorio, int):
                calcularTotalRegistrosRelatorio() + getClass().getSimpleName() +
                ConstantesExecucaoRelatorios.get(nome) → se QUANTIDADE_NAO_INFORMADA (-1) ou quantidade > limite
                → iniciarProcessoRelatorio | iniciarProcessoRelatorioControleAutorizacao
                   (conforme SistemaParametro.INDICADOR_AUTORIZACAO_RELATORIO)
                senão → tarefaRelatorio.executar() → new RelatorioProcessado(byte[], tipoTarefa)
              .obterProcessoRelatorio(nomeRelatorio) → mapeia nome do relatório → constante de Processo
Limites:      relatorio/ConstantesExecucaoRelatorios (QUANTIDADE_NAO_INFORMADA = -1;
                carrega /constantes_execucao_relatorios.properties)
              src/gcom/properties/constantes_execucao_relatorios.properties
                ("quantos registros um relatório pode apresentar online";
                 ex.: RelatorioManterBairro=500, RelatorioManterCliente=1000, RelatorioManterSetorComercial=10)
Motor:        tarefa/TarefaRelatorio (abstract, extends Tarefa): TIPO_PDF/RTF/XLS/HTML,
                calcularTotalRegistrosRelatorio(), gerarRelatorio(nome, parametros, RelatorioDataSource, tipoSaida) → byte[]
                ConstantesRelatorios.getURLRelatorio(nome).openStream() → JRLoader.loadObject → JasperReport
                JasperFillManager.fillReport(...) → JasperPrint → JRPdfExporter (JASPER_PRINT + OUTPUT_STREAM)
                REPORT_LOCALE / REPORT_RESOURCE_BUNDLE (gcom.properties.application); RelatorioVazioException
Templates:    relatorio/ConstantesRelatorios (constantes ".jasper", ex.: /relatorioManterOperacao.jasper)
Modelo:       batch/Relatorio.hbm.xml → batch.relatorio (rela_dsrelatorio, rela_icuso)
              batch/RelatorioGerado.hbm.xml → batch.relatorio_gerado (rege_pdf = arquivo, rege_nnpaginas,
                rege_tmultimaalteracao; FKs obrigatórias fuin_id → FuncionalidadeIniciada e rela_id → Relatorio)
              relatorio/RelatorioProcessado (envelope em memória: bytes + tipo) — não persistido
Batch:        ControladorBatchSEJB.iniciarProcessoRelatorio / iniciarProcessoRelatorioControleAutorizacao /
                iniciarRelatoriosAgendados / iniciarFuncionalidadeIniciadaRelatorio /
                encerrarFuncionalidadeIniciadaRelatorio(id, concluiuComErro)
Entrega:      gui/batch/relatorio/ExibirRelatorioBatchAction: lê request "idFuncionalidadeIniciada" →
                FiltroRelatorioGerado por FUNCIONALIDADE_INICIADA_ID → RelatorioGerado →
                desserializa TarefaRelatorio (IoUtil) → Content-Disposition "attachment; filename=relatorio.pdf",
                mimeType "application/pdf" → OutputStream
                (⚠️ nenhuma comparação com usuário logado localizada no trecho analisado)
Acompanhar:   gui/batch/relatorio/ExibirStatusGeracaoAction; ExibirStatusGeracaoUsuarioAction
                (fachada.pesquisarRelatoriosBatchPorUsuarioSistema(idProcesso)); ExibirAutorizarRelatoriosBatchAction
Identidade:   relatorio/RelatorioPadraoBatch(Usuario.USUARIO_BATCH) — execução em contexto batch
Serviço ext.: (🟡 a confirmar) lib gsan-relatorios (Jersey/Gson) + api/GsanApi.java com token;
                relatorio/AcessoServicoReportException
```
