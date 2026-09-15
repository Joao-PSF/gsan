# GSAN → OpenGSAN — Controle do Projeto

> Visão executiva e operacional da modernização. Documentação técnica detalhada em [`docs/modernizacao/`](docs/modernizacao/README.md).

## STATUS GERAL

Fase 0 em andamento. 1ª execução (2026-08-13): diagnóstico técnico do legado, inventário do `gsan_comercial` e plano de trabalho. 2ª execução (2026-08-13): premissas revisadas — **não há GSAN em produção neste projeto**; SISAN é **modernização evolutiva do GSAN** com banco próprio (UTF-8) e **migração de instalações GSAN como requisito arquitetural futuro**; repositório SISAN confirmado para o código novo; execução inicial em VPS. Registro completo em [alteracoes/2026-08-13-revisao-premissas-fase0.md](docs/modernizacao/alteracoes/2026-08-13-revisao-premissas-fase0.md). 3ª execução (2026-08-14): **glossário de domínio concluído** — 25 conceitos com evidências em [dominio/glossario.md](docs/modernizacao/dominio/glossario.md). 4ª execução (2026-08-14): **mapa funcional do Cadastro concluído** — [modulos/cadastro.md](docs/modernizacao/modulos/cadastro.md); dúvidas 1, 2 e 6 do glossário resolvidas. 5ª execução (2026-08-14): **mapa funcional da Micromedição concluído** — [modulos/micromedicao.md](docs/modernizacao/modulos/micromedicao.md); precedência das rotas resolvida; 12 cenários de caracterização identificados. 6ª execução (2026-08-14): **mapa funcional do Faturamento concluído** — [modulos/faturamento.md](docs/modernizacao/modulos/faturamento.md); mecanismo ContaGeral/histórico, retificação, cancelamento, tarifa por vigência e fronteira de consumo resolvidos; 13 golden masters financeiros identificados. 7ª execução (2026-08-14): **mapa funcional da Cobrança concluído** — [modulos/cobranca.md](docs/modernizacao/modulos/cobranca.md); identidade da dívida, ações parametrizadas, parcelamento/desfazer/reparcelamento e negativação compreendidos; 14 cenários de caracterização. 8ª execução (2026-08-14): **mapa funcional da Arrecadação concluído** — [modulos/arrecadacao.md](docs/modernizacao/modulos/arrecadacao.md); recepção × classificação, situações do pagamento, conciliação e encerramento contábil compreendidos; 20 cenários. 9ª execução (2026-08-14): **mapa funcional do Atendimento concluído** — [modulos/atendimento.md](docs/modernizacao/modulos/atendimento.md); RA×OS, especificação como núcleo paramétrico e mecanismo real do efeito cadastral esclarecidos; 22 cenários. 10ª execução (2026-08-14): **mapa funcional da Segurança concluído** — [modulos/seguranca.md](docs/modernizacao/modulos/seguranca.md); autorização central por filtro (URL → funcionalidade/operação, união de grupos), permissões especiais nomeadas, abrangência territorial com aplicação manual, ciclo do usuário e auditoria em dois níveis; 24 cenários; ajustes de precisão no mapa do Atendimento no mesmo commit. 11ª execução (2026-08-14): **mapa funcional do Batch concluído** — [modulos/batch.md](docs/modernizacao/modulos/batch.md); modelo de processamento (definição × execução em três níveis), formas de disparo, retomada por unidade e reprocessamento por etapa; 20 cenários; correção residual do gate de autorização em `seguranca.md` no mesmo commit. 12ª execução (2026-08-14): **mapa funcional dos Relatórios concluído** — [modulos/relatorios.md](docs/modernizacao/modulos/relatorios.md); modelo relatório × tarefa × resultado, decisão automática online/batch, motor Jasper, artefato persistido e entrega; 19 cenários; três correções residuais no `batch.md` no mesmo commit. 13ª execução (2026-09-14): **mapa funcional das Integrações concluído** — [modulos/integracoes.md](docs/modernizacao/modulos/integracoes.md) — e **rodada de correções** decorrente de revisão externa.

14ª execução (2026-09-14): **mapa de domínio consolidado concluído** — [dominio/mapa-de-dominio.md](docs/modernizacao/dominio/mapa-de-dominio.md): os dez mapas funcionais viraram **uma** visão integrada (conceitos centrais e sua natureza, 12 identidades estáveis com criticidade de migração, os quatro mecanismos de tempo, ownership por conceito, 14 fronteiras entre módulos, **7 dependências circulares confirmadas**, núcleo comercial, domínios financeiro e operacional, 16 famílias de regra-como-dado, 5 mecanismos de variação por companhia, 5 conceitos sobrecarregados, 9 conceitos implícitos e 10 pontos de maior risco).

15ª execução (2026-09-14): **análise de compatibilidade das estruturas centrais concluída** — [compatibilidade/estruturas-centrais.md](docs/modernizacao/compatibilidade/estruturas-centrais.md): **64 decisões estruturais** classificadas conforme ADR-0006 (classificação primária: 37 PRESERVAR · 14 REESTRUTURAR · 6 MODERNIZAR · 5 EXIGE APROFUNDAMENTO · 2 NÃO TRANSPORTAR; 12 decisões têm classificação dupla), mais 6 famílias não transportadas e 16 famílias paramétricas. Cada `REESTRUTURAR` responde às seis perguntas obrigatórias (problema, benefício, semântica a preservar, transformação, risco, validação). Uma divergência nova **proposta** (D-17, abrangência sistemática) — registrada como proposta, **não aprovada**.

16ª execução (2026-09-15): **mudança de identidade e de escopo**, por diretriz do responsável. (a) O sistema passa a chamar-se **OpenGSAN** — evolução **aberta** e moderna do GSAN, não projeto novo; (b) ⚠️ **a migração de instalações GSAN saiu do escopo deste projeto** e terá projeto próprio — facilidade de migração deixa de ser critério de desenho e **não pode mais justificar preservar estrutura inadequada**; (c) **software livre** passa a ser princípio orientador (neutralidade institucional, configuração antes de fork). ADRs 0003, 0005 e 0006 revisadas; 31 documentos de estado corrente renomeados; registros históricos preservam o nome SISAN. **Visão Conceitual Alvo do OpenGSAN produzida** — [dominio/visao-conceitual-opengsan.md](docs/modernizacao/dominio/visao-conceitual-opengsan.md).

**Leitura honesta do estado (calibrada em 2026-09-14).** Os dez mapas funcionais cobrem o fluxo principal Cadastro → Micromedição → Faturamento → Conta → Cobrança → Arrecadação, o ciclo de demanda/execução do Atendimento, identidade/autorização/abrangência/auditoria, processamento em lote, relatórios e integrações. **Isso não significa que a Fase 0 esteja pronta para orientar implementação**, por duas razões diferentes que não devem ser confundidas:

- **Incompletude normal da descoberta**: faltam o mapa de domínio, a análise de compatibilidade das estruturas centrais, o catálogo de funcionalidades futuras, o refinamento de dependências e a **especificação dos cenários críticos** (itens 3–8 do backlog). Permanecem dúvidas abertas registradas em cada mapa.
- **Defeitos corrigidos em artefatos antes dados por concluídos**: a revisão de 2026-09-14 encontrou afirmações publicadas erradas (fronteira de consumo, política de arredondamento, atribuição de método, inconsistência MD5/SHA-1, arquivo obsoleto citado como evidência) e um furo conceitual (critério de equivalência que obrigaria o SISAN a reproduzir falhas de segurança do legado). Todas corrigidas nesta execução e registradas em [`procedencia.md §4`](docs/modernizacao/procedencia.md).

Nenhuma implementação iniciada.

## FASE ATUAL

Fase 0 — Descoberta, compatibilidade e arquitetura do **OpenGSAN**. Objetivo: compreender o domínio e as regras do GSAN (mapa funcional, glossário, mapa de domínio), classificar as estruturas centrais (`PRESERVAR / MODERNIZAR / REESTRUTURAR / NÃO TRANSPORTAR`), catalogar funcionalidades futuras descobertas no `gsan_comercial` e estabelecer os princípios de compatibilidade GSAN→SISAN. Sem implementação.

## CONCLUÍDO

- Diagnóstico de runtime, build, frameworks, segurança e banco — [arquitetura legada](docs/modernizacao/arquitetura/arquitetura-legada.md).
- Inventário estrutural do `gsan_comercial` — [estrutura atual](docs/modernizacao/banco/estrutura-atual.md).
- Plano de trabalho (com aviso de revisão) — [plano de trabalho](docs/modernizacao/plano-de-trabalho.md).
- Revisão de impacto das novas premissas e correção da documentação afetada (2ª execução).
- ADRs 0003, 0004 (reescrita), 0005 e 0006 decididas como Aceitas.
- Glossário de domínio — 25 conceitos com definição, relações, evidências e 9 pontos de aprofundamento (3ª execução): [dominio/glossario.md](docs/modernizacao/dominio/glossario.md).
- Mapa funcional do módulo Cadastro (4ª execução): [modulos/cadastro.md](docs/modernizacao/modulos/cadastro.md) — imóvel/matrícula com DV, economia governada por `imovel_subcategoria`, situações paramétricas de ligação, cliente×imóvel com papel/vigência, três rotas com usos distintos, classificação preliminar de compatibilidade e 5 hipóteses arquiteturais.
- Mapa funcional da Micromedição (5ª execução): [modulos/micromedicao.md](docs/modernizacao/modulos/micromedicao.md) — equipamento×instalação com leituras de fronteira, ciclo dirigido pelo cronograma do grupo (8 atividades com datas por rota), par informado×faturamento, anormalidades paramétricas com ações escalonadas, consumo com origem tipificada, rota alternativa como override, variantes de controlador por companhia, 12 cenários de caracterização.
- Mapa funcional do Faturamento (6ª execução): [modulos/faturamento.md](docs/modernizacao/modulos/faturamento.md) — `gerarConta` único para lote e individual (unidade = rota), faturabilidade paramétrica, **consumo mantido pela Micromedição e usado como insumo, com uma exceção comprovada: a retificação escreve diretamente em `ConsumoHistorico` (corrigido em 2026-09-14)**, mínimo = Σ tarifa×economias por categoria, tarifa por vigência, esgoto por percentuais da ligação fotografados, ContaGeral como identidade estável (1:1 corrente/histórico), retificação por nova conta encadeada, cancelamento como estado, arquivamento no encerramento mensal, **arredondamento NÃO centralizado — 5 políticas semânticas distintas (corrigido em 2026-09-14)**, variação por companhia em 3 camadas, 13 golden masters.
- Mapa funcional da Cobrança (7ª execução): [modulos/cobranca.md](docs/modernizacao/modulos/cobranca.md) — estoque de dívida por consulta sobre identidades `*Geral` (imóvel ou cliente+papel), documento de cobrança com itens rastreáveis dívida a dívida, ações com predecessora/critério/situações-alvo/OS parametrizados, parcelamento com composição por item e memória financeira integral, desfazimento automático por entrada não paga com estornos tipificados, reparcelamento encadeado, negativação por cliente com critérios, terceirização por carteira, situação especial de cobrança com histórico, 14 cenários de caracterização.
- Mapa funcional dos Relatórios (12ª execução): [modulos/relatorios.md](docs/modernizacao/modulos/relatorios.md) — três conceitos distintos (definição catalogada, tarefa parametrizada, artefato materializado); **decisão automática online × assíncrono** por contagem de registros × limite por tipo em properties (sem limite ⇒ batch); motor comum Jasper (template `.jasper` compilado + datasource montado pela aplicação + exportadores PDF/RTF/XLS/HTML); caminho online sem persistência (bytes na resposta) × caminho batch que **persiste o artefato** (`RelatorioGerado`, binário no banco, ligado à `FuncionalidadeIniciada`); **aprovação operacional** de relatório pesado por parâmetro global, distinta de permissão de acesso; solicitante rastreável pelo processo iniciado e consulta de relatórios por usuário; relatório vazio como situação nomeada; solicitação preservada por serialização Java (a reestruturar). **Acesso ao artefato no download sem controle: dúvida ELEVADA A ACHADO CONFIRMADO em 2026-09-14** (cadeia completa de filtros verificada — achado 13 dos riscos).
- Mapa funcional do Batch (11ª execução): [modulos/batch.md](docs/modernizacao/modulos/batch.md) — framework próprio com **separação definição × execução em três níveis** (processo/etapa/unidade), cada um com estado, tempos, parâmetros e erro persistidos; etapas ancoradas no **catálogo de funcionalidades da segurança**, com ordem definida por dado (`sequencialExecucao`); **partição por processo** (rota no faturamento, localidade na arrecadação — em dois padrões: a tarefa resolve as unidades, ou elas são preparadas antes e entregues como parâmetro), com **retomada por unidade** (unidade já concluída não é reexecutada) e **reprocessamento por etapa**. ⚠️ **A atomicidade do trabalho de negócio *dentro* de uma unidade NÃO foi comprovada** — o framework garante estado por unidade, não ausência de efeito parcial ([batch.md §11](docs/modernizacao/modulos/batch.md)); disparo manual (com solicitante gravado), agendado por Quartz, distribuído por JMS/MDB e encadeado entre execuções; **autorização de processo** própria além da permissão de tela; camadas separadas (agendador, orquestrador, transporte, regra de negócio — o MDB é ponte, não dono da regra). Casos FATURAR_GRUPO e ENCERRAR_ARRECADACAO_MES confirmam que o padrão é do framework. **Abrangência no batch não foi localizada** — dúvida prioritária.
- Mapa funcional da Segurança (10ª execução): [modulos/seguranca.md](docs/modernizacao/modulos/seguranca.md) — complementa (não substitui) `seguranca/modelo-legado.md` e `riscos-identificados.md`: `FiltroSegurancaAcesso` (`*.do`) como **principal gate transversal para rotas web protegidas** — não uma política universal: a URL é classificada como funcionalidade **ou** operação (caminhos alternativos), há **lista de exceções no próprio filtro** (inclusive URLs contendo `pesquisar`/`relatorio`, portal, dispositivos móveis) e a abrangência é verificada **condicionalmente**; concessão por **união dos grupos** em `GrupoFuncionalidadeOperacao` (sem deny observado; dependência entre funcionalidades participa); **permissões especiais nomeadas** como exceções dentro da funcionalidade; **abrangência** territorial (gerência regional/unidade de negócio/elo-polo/localidade) como segundo eixo, porém **dependente de verificações explícitas em cada consulta** (risco estrutural); unidade organizacional como posicionamento de fluxo, não autorização; login por **consulta que casa login+hash SHA-1** (MD5 apenas em token efêmero de servlets auxiliares); situação, bloqueio de senha e expiração como eixos independentes; auditoria em **dois níveis** (operação efetuada + alteração por linha/coluna restrita ao que está anotado); identidade de sistema para batch e APIs fora do RBAC de tela; workflow de solicitação de acesso. Fronteira de autorização do Atendimento resolvida.
- Mapa funcional do Atendimento (9ª execução): [modulos/atendimento.md](docs/modernizacao/modulos/atendimento.md) — RA como protocolo da demanda × OS como unidade de execução (RA sem OS confirmado; existem origens de OS independentes de demanda individual — cobrança, fiscalização coletiva, ordem seletiva —, mas a persistência de OS sem RA associado permanece dúvida aberta); `SolicitacaoTipoEspecificacao` como núcleo paramétrico (prazo, obrigatoriedades, geração de OS, efeitos financeiros, encerramento automático, loja virtual); regras de serviço em dois níveis (especificação + tipo de serviço, que já traz DebitoTipo/CreditoTipo); tramitação como histórico auditável e `unid_idatual` como estado corrente; prazo original × atual; estados do RA (pendente/encerrado/bloqueado) e da OS (incl. **encerrada não executada**) com marcos geração/emissão/execução/encerramento; **efeito cadastral produzido pelas operações "Efetuar…", com indicadores na OS registrando que a atualização ocorreu**; reativação/duplicidade por encadeamento de protocolos; ausência de subclasses por companhia, com a parametrização como fonte importante (não exclusiva comprovada) de variabilidade; 22 cenários de caracterização identificados.
- Mapa funcional da Arrecadação (8ª execução): [modulos/arrecadacao.md](docs/modernizacao/modulos/arrecadacao.md) — recepção (movimento do arrecadador com registro bruto e totais de conferência) **separada** da classificação em lote; catálogo de situações do pagamento como semântica central (nenhum pagamento é descartado, situação anterior preservada); classificação busca o documento na versão corrente **e** no histórico e decide pela situação (retificada apropria; cancelada/prescrita/parcelada geram situação específica); excedente/devolução com guia própria; conciliação por aviso bancário (calculado × informado, acertos e deduções); débito automático em três níveis; encerramento mensal como **fechamento contábil** (retenções tributárias + consolidação do não classificado); PIX na branch é apenas gerador de QR Code estático (chave hard-coded — achado de segurança). Assimetria estrutural registrada: o pagamento **perde identidade** ao ser arquivado.

- Mapa de domínio consolidado (14ª execução): [dominio/mapa-de-dominio.md](docs/modernizacao/dominio/mapa-de-dominio.md) — **quatro padrões estruturais** atravessam o sistema inteiro (regra como dado · identidade estável + versão + linhagem · fotografia na operação · informado × efetivo); as dez áreas **não são dez domínios equivalentes** (Batch/Relatórios/Integrações têm natureza de plataforma); o **Atendimento é a ponte** e participa de 3 dos 7 ciclos; a **identidade do pagamento é a única anomalia** do padrão de identidade do sistema; **Economia, obrigação financeira e estoque de dívida** são conceitos centrais **sem entidade própria**. Correções de consistência aplicadas: descrição de `arquitetura-alvo.md` no sumário e serviço externo de relatórios (comprovado como `src/gcom/api/GsanApi.java`, OAuth2).

- Análise de compatibilidade das estruturas centrais (15ª execução): [compatibilidade/estruturas-centrais.md](docs/modernizacao/compatibilidade/estruturas-centrais.md) — **o GSAN acertou mais do que errou**: quase 6 em cada 10 decisões são `PRESERVAR`, e o **Faturamento é o mais preservado em proporção (7 de 10)** — apesar de ser o módulo de maior risco financeiro. Onde há dinheiro, o modelo do legado é bom. As reestruturações concentram-se em Segurança (implementação inadequada) e Cadastro (o Imóvel acumulou estado de outros domínios). **Cinco decisões dominam o risco**: identidade estável de documento (semântica inegociável, estrutura a reestruturar), **precisão financeira PRESERVADA** (as 5 políticas de arredondamento são comportamento, não dívida técnica), **snapshots da Conta PRESERVADOS** (parecem desnormalização, são auditoria retroativa), abrangência territorial (conceito preservado, aplicação reestruturada) e **regra como dado** (nenhuma das 16 famílias paramétricas é descartada).

## EM EXECUÇÃO

- Nada em execução no momento; próxima atividade definida abaixo.

## PRÓXIMAS ATIVIDADES (backlog restante da Fase 0, em ordem)

**Concluídos**: ✅ glossário de domínio (2026-08-14) · ✅ dez mapas funcionais, cadastro → integrações (2026-08-14 a 2026-09-14) · ✅ mapa de domínio consolidado (2026-09-14) · ✅ **análise de compatibilidade das estruturas centrais** (2026-09-14) · ✅ ADRs 0001 e 0002 formalizadas.

Sequência estabelecida (não remover a Visão Conceitual Alvo):

```text
Mapa de domínio atual  ✅
        ↓
Compatibilidade das estruturas centrais  ✅
        ↓
Visão conceitual alvo do OpenGSAN  ✅
        ↓
Documento de compatibilidade / migração
```

| # | Atividade | Observação |
| - | --------- | ---------- |
| — | ~~**Visão Conceitual Alvo do OpenGSAN**~~ ✅ **concluída em 2026-09-15** | Ainda **sem** modelo físico: conceitos, fronteiras, identidades e contratos do sistema alvo. Consome as 37 decisões `PRESERVAR` como restrições de desenho, as 15 que tocam `REESTRUTURAR` como problemas a resolver (com a semântica a preservar já explicitada) e as 14 hipóteses de [`estruturas-centrais.md §21`](docs/modernizacao/compatibilidade/estruturas-centrais.md) |
| 1 | **Catálogo de funcionalidades futuras** | Descobertas do `gsan_comercial` (PIX, fiscal/NF, SPED, mobile/campo, recadastramento, tarifa social, SPC/Serasa, APIs, BI, boleto registrado): funcionalidade, problema resolvido, módulo, dependências, prioridade preliminar. Sem modelagem de banco |
| 2 | **Refinamento das dependências / ordem de implementação** | O mapa de domínio já forneceu a evidência (ownership, fronteiras e **7 ciclos**); falta a decisão de ordem, registrando o motivo de qualquer mudança em `modulos/README.md` |
| 3 | **Documento de compatibilidade conceitual GSAN → OpenGSAN** | ⚠️ **Escopo reduzido em 2026-09-15**: trata de **continuidade conceitual, diferenças e correspondências** — a estratégia operacional de migração pertence a **outro projeto** |
| 4 | **Especificação dos cenários críticos** | Os ~110 cenários dos mapas são *inventário*, não especificação. **DEFINIR TESTES está dentro da Fase 0**, antes do PARAR. Modelo obrigatório em [`testes/estrategia-testes.md`](docs/modernizacao/testes/estrategia-testes.md) |
| 5 | **Decisão da ADR-0007 — arquitetura de interface** | ⚠️ **Bloqueia o piloto (Fase 6)**. Proposta registrada, decisão pendente |
| 6 | **Auditoria final e encerramento da Fase 0** | Critério de saída: itens 1–5 concluídos, dúvidas de alta prioridade endereçadas ou explicitamente aceitas como risco |

## RISCOS

1. Ausência de rede de testes/caracterização do legado (19 testes / 2,39M LOC) — maior risco para a equivalência funcional.
2. Perda ou deturpação de regras de negócio na reimplementação (~830 SQLs concatenados, 116 funções de banco, regras embutidas em Actions/EJBs).
3. Variabilidade de schemas entre instalações GSAN (drift comprovado no `gsan_comercial`, ex.: PIX fora das migrations) — inviabiliza migração futura se a compatibilidade não for requisito desde o início (ADR-0005).
4. Recriar a roda ou redesenhar por estética, quebrando o caminho de migração (mitigado pela ADR-0006).
5. Dificuldade de levantar o ambiente de referência do legado (JBoss 4/Java 5 em SO moderno) para caracterização.
6. OpenGSAN herdar padrões fracos de segurança do legado — **mitigado pelo [registro de divergências aprovadas](docs/modernizacao/compatibilidade/divergencias-aprovadas.md)**, criado em 2026-09-14 porque o critério `A = B`, sozinho, *obrigaria* a herança.
8. ⚠️ **Precisão financeira**: 5 políticas semânticas de arredondamento convivendo no núcleo de faturamento (21 usos de `RoundingMode.UP`; truncamento em base de imposto). Unificar sem caracterizar ponto a ponto produz divergência de centavos em massa.
9. ⚠️ **Segredo comprometido em circulação**: chave de API de SMS versionada em código e em properties (achado 11) — rotação obrigatória em qualquer instalação que use este código.
7. Inflação de escopo pelo catálogo de funcionalidades futuras antes do núcleo estar migrado.

Lista original de 10 riscos no plano de trabalho, com reinterpretação registrada na [revisão de premissas](docs/modernizacao/alteracoes/2026-08-13-revisao-premissas-fase0.md).

## DECISÕES ARQUITETURAIS

Registradas em [`docs/modernizacao/decisoes/`](docs/modernizacao/decisoes/README.md).

| ADR | Assunto | Status |
| --- | ------- | ------ |
| 0001 | Monólito modular Spring Boot | **Aceita** (revisada 2026-09-14) |
| 0002 | Flyway para migrations (schema OpenGSAN versionado desde V1, sem baseline do legado) | **Aceita** (formalizada 2026-09-14) |
| 0003 | Código novo em repositório próprio, fora do legado — ⚠️ **nome físico do repositório PENDENTE** | **Aceita** (revisada 2026-09-15) |
| 0004 | UTF-8 no OpenGSAN; encoding de origem tratado na migração | **Aceita** |
| 0005 | **OpenGSAN é a evolução aberta e moderna do GSAN**; migração de instalações **fora do escopo** deste projeto | **Aceita** (revisada 2026-09-15) |
| 0006 | Modelo de dados evolutivo (PRESERVAR/MODERNIZAR/REESTRUTURAR/NÃO TRANSPORTAR) | **Aceita** |
| 0007 | Arquitetura de interface do OpenGSAN (SSR × REST+SPA × híbrido) | **Proposta — bloqueia o piloto** |

## DÍVIDAS TÉCNICAS IDENTIFICADAS (legado — inalterado)

- Java 1.5/1.6, JBoss 4.0.1sp1, Struts 1.1, EJB 2.x, Hibernate 3, Quartz 1.5.2, JasperReports 1.2.2, Axis2 1.5.1, applet de impressão térmica — tudo EOL, sem caminho de upgrade direto.
- Build Ant com JARs vendorizados em `lib/`, sem gestão de dependências.
- ~830 pontos de SQL/HQL com concatenação de strings (superfície de SQL Injection).
- Senha de login em **SHA-1 sem salt** (MD5 é token efêmero de servlets auxiliares — correção 2026-09-14); `/api/pagamentoCredito/*` com "autenticação" que valida o host do próprio servidor; `/api/ordem-servico/*` **sem filtro algum**.
- Cadeia de filtros com dois elos decorativos: `FiltroSSO` com ramos `if/else` idênticos e `FiltroSessaoExpirada` com guarda inalcançável.
- Segredo (chave de API de SMS) versionado em código-fonte; `ServicoSMS` ignora o tipo da mensagem e envia sempre o mesmo texto.
- Integração UPA/SAM por **escrita direta no banco do sistema parceiro**, com falha silenciosa (`continue` + `System.out`).
- 212 tabelas de backup/manutenção no schema `public`; DDL manual sem migration correspondente.
- 19 classes de teste para ~2,39 milhões de linhas Java.

## DEPENDÊNCIAS BLOQUEADORAS

**Bloqueia o piloto (Fase 6)**: ADR-0007 — arquitetura de interface. Não bloqueia a Fase 0, mas precisa ser decidida antes de o piloto ser especificado, porque muda o desenho interno do módulo e o modelo de autorização.

Pendências **não bloqueadoras**: definição da infraestrutura da VPS (antes do primeiro deploy); obtenção (ou construção sintética) de uma base GSAN de referência para a caracterização (Fases 1–2).

## TESTES DISPONÍVEIS

19 classes JUnit no legado (`test/`), sem cobertura relevante. Baseline funcional automatizada: inexistente (objetivo da Fase 2, sobre ambiente de referência do legado + massa controlada).

## MÓDULOS MIGRADOS

Nenhum (implementação ainda não iniciada — Fase 0).

## MÓDULOS PENDENTES

Todos — ordem preliminar em [`docs/modernizacao/modulos/README.md`](docs/modernizacao/modulos/README.md) (refinamento é o item 6 do backlog).

## MIGRATIONS EXECUTADAS

Nenhuma. O schema do OpenGSAN nascerá versionado por Flyway desde `V1` (sem baseline copiada do `gsan_comercial`). Histórico legado: MyBatis Migrations em `gsan-migracoes` (301 scripts `comercial`, últimos de 2024-06; 5 `gerencial`) mantido como referência de evolução do GSAN.
