# MODERNIZAÇÃO GSAN → SISAN — Controle do Projeto

> Visão executiva e operacional da modernização. Documentação técnica detalhada em [`docs/modernizacao/`](docs/modernizacao/README.md).

## STATUS GERAL

Fase 0 em andamento. 1ª execução (2026-08-13): diagnóstico técnico do legado, inventário do `gsan_comercial` e plano de trabalho. 2ª execução (2026-08-13): premissas revisadas — **não há GSAN em produção neste projeto**; SISAN é **modernização evolutiva do GSAN** com banco próprio (UTF-8) e **migração de instalações GSAN como requisito arquitetural futuro**; repositório SISAN confirmado para o código novo; execução inicial em VPS. Registro completo em [alteracoes/2026-08-13-revisao-premissas-fase0.md](docs/modernizacao/alteracoes/2026-08-13-revisao-premissas-fase0.md). 3ª execução (2026-08-14): **glossário de domínio concluído** — 25 conceitos com evidências em [dominio/glossario.md](docs/modernizacao/dominio/glossario.md). 4ª execução (2026-08-14): **mapa funcional do Cadastro concluído** — [modulos/cadastro.md](docs/modernizacao/modulos/cadastro.md); dúvidas 1, 2 e 6 do glossário resolvidas. 5ª execução (2026-08-14): **mapa funcional da Micromedição concluído** — [modulos/micromedicao.md](docs/modernizacao/modulos/micromedicao.md); precedência das rotas resolvida; 12 cenários de caracterização identificados. 6ª execução (2026-08-14): **mapa funcional do Faturamento concluído** — [modulos/faturamento.md](docs/modernizacao/modulos/faturamento.md); mecanismo ContaGeral/histórico, retificação, cancelamento, tarifa por vigência e fronteira de consumo resolvidos; 13 golden masters financeiros identificados. 7ª execução (2026-08-14): **mapa funcional da Cobrança concluído** — [modulos/cobranca.md](docs/modernizacao/modulos/cobranca.md); identidade da dívida, ações parametrizadas, parcelamento/desfazer/reparcelamento e negativação compreendidos; 14 cenários de caracterização. 8ª execução (2026-08-14): **mapa funcional da Arrecadação concluído** — [modulos/arrecadacao.md](docs/modernizacao/modulos/arrecadacao.md); recepção × classificação, situações do pagamento, conciliação e encerramento contábil compreendidos; 20 cenários. 9ª execução (2026-08-14): **mapa funcional do Atendimento concluído** — [modulos/atendimento.md](docs/modernizacao/modulos/atendimento.md); RA×OS, especificação como núcleo paramétrico e mecanismo real do efeito cadastral esclarecidos; 22 cenários. 10ª execução (2026-08-14): **mapa funcional da Segurança concluído** — [modulos/seguranca.md](docs/modernizacao/modulos/seguranca.md); autorização central por filtro (URL → funcionalidade/operação, união de grupos), permissões especiais nomeadas, abrangência territorial com aplicação manual, ciclo do usuário e auditoria em dois níveis; 24 cenários; ajustes de precisão no mapa do Atendimento no mesmo commit. **O fluxo principal Cadastro → Micromedição → Faturamento → Conta → Cobrança → Arrecadação, o ciclo de demanda/execução do Atendimento e o modelo de identidade/autorização/abrangência/auditoria estão funcionalmente mapeados**, permanecendo regras de exceção, precedências específicas (notadamente o uso de restrições no cálculo de autorização) e variações por companhia para aprofundamento (ver dúvidas abertas em cada mapa) — e permanecem por analisar batch, relatórios e integrações. Nenhuma implementação iniciada.

## FASE ATUAL

Fase 0 — Descoberta, compatibilidade e arquitetura. Objetivo: compreender o domínio e as regras do GSAN (mapa funcional, glossário, mapa de domínio), classificar as estruturas centrais (`PRESERVAR / MODERNIZAR / REESTRUTURAR / NÃO TRANSPORTAR`), catalogar funcionalidades futuras descobertas no `gsan_comercial` e estabelecer os princípios de compatibilidade GSAN→SISAN. Sem implementação.

## CONCLUÍDO

- Diagnóstico de runtime, build, frameworks, segurança e banco — [arquitetura legada](docs/modernizacao/arquitetura/arquitetura-legada.md).
- Inventário estrutural do `gsan_comercial` — [estrutura atual](docs/modernizacao/banco/estrutura-atual.md).
- Plano de trabalho (com aviso de revisão) — [plano de trabalho](docs/modernizacao/plano-de-trabalho.md).
- Revisão de impacto das novas premissas e correção da documentação afetada (2ª execução).
- ADRs 0003, 0004 (reescrita), 0005 e 0006 decididas como Aceitas.
- Glossário de domínio — 25 conceitos com definição, relações, evidências e 9 pontos de aprofundamento (3ª execução): [dominio/glossario.md](docs/modernizacao/dominio/glossario.md).
- Mapa funcional do módulo Cadastro (4ª execução): [modulos/cadastro.md](docs/modernizacao/modulos/cadastro.md) — imóvel/matrícula com DV, economia governada por `imovel_subcategoria`, situações paramétricas de ligação, cliente×imóvel com papel/vigência, três rotas com usos distintos, classificação preliminar de compatibilidade e 5 hipóteses arquiteturais.
- Mapa funcional da Micromedição (5ª execução): [modulos/micromedicao.md](docs/modernizacao/modulos/micromedicao.md) — equipamento×instalação com leituras de fronteira, ciclo dirigido pelo cronograma do grupo (8 atividades com datas por rota), par informado×faturamento, anormalidades paramétricas com ações escalonadas, consumo com origem tipificada, rota alternativa como override, variantes de controlador por companhia, 12 cenários de caracterização.
- Mapa funcional do Faturamento (6ª execução): [modulos/faturamento.md](docs/modernizacao/modulos/faturamento.md) — `gerarConta` único para lote e individual (unidade = rota), faturabilidade paramétrica, **no fluxo principal analisado o Faturamento utiliza o consumo mantido pela Micromedição como insumo — sem reprocessamento/gravação de `ConsumoHistorico` identificada nesse fluxo**, mínimo = Σ tarifa×economias por categoria, tarifa por vigência, esgoto por percentuais da ligação fotografados, ContaGeral como identidade estável (1:1 corrente/histórico), retificação por nova conta encadeada, cancelamento como estado, arquivamento no encerramento mensal, arredondamento HALF_UP centralizado, variação por companhia em 3 camadas, 13 golden masters.
- Mapa funcional da Cobrança (7ª execução): [modulos/cobranca.md](docs/modernizacao/modulos/cobranca.md) — estoque de dívida por consulta sobre identidades `*Geral` (imóvel ou cliente+papel), documento de cobrança com itens rastreáveis dívida a dívida, ações com predecessora/critério/situações-alvo/OS parametrizados, parcelamento com composição por item e memória financeira integral, desfazimento automático por entrada não paga com estornos tipificados, reparcelamento encadeado, negativação por cliente com critérios, terceirização por carteira, situação especial de cobrança com histórico, 14 cenários de caracterização.
- Mapa funcional da Segurança (10ª execução): [modulos/seguranca.md](docs/modernizacao/modulos/seguranca.md) — complementa (não substitui) `seguranca/modelo-legado.md` e `riscos-identificados.md`: autorização aplicada **centralmente** por `FiltroSegurancaAcesso` (`*.do`), com funcionalidade e operação resolvidas **pela URL** e concessão por **união dos grupos** em `GrupoFuncionalidadeOperacao` (sem deny observado; dependência entre funcionalidades participa); **permissões especiais nomeadas** como exceções dentro da funcionalidade; **abrangência** territorial (gerência regional/unidade de negócio/elo-polo/localidade) como segundo eixo, porém **dependente de verificações explícitas em cada consulta** (risco estrutural); unidade organizacional como posicionamento de fluxo, não autorização; login por **consulta que casa login+hash SHA-1** (MD5 apenas em token efêmero de servlets auxiliares); situação, bloqueio de senha e expiração como eixos independentes; auditoria em **dois níveis** (operação efetuada + alteração por linha/coluna restrita ao que está anotado); identidade de sistema para batch e APIs fora do RBAC de tela; workflow de solicitação de acesso. Fronteira de autorização do Atendimento resolvida.
- Mapa funcional do Atendimento (9ª execução): [modulos/atendimento.md](docs/modernizacao/modulos/atendimento.md) — RA como protocolo da demanda × OS como unidade de execução (RA sem OS confirmado; existem origens de OS independentes de demanda individual — cobrança, fiscalização coletiva, ordem seletiva —, mas a persistência de OS sem RA associado permanece dúvida aberta); `SolicitacaoTipoEspecificacao` como núcleo paramétrico (prazo, obrigatoriedades, geração de OS, efeitos financeiros, encerramento automático, loja virtual); regras de serviço em dois níveis (especificação + tipo de serviço, que já traz DebitoTipo/CreditoTipo); tramitação como histórico auditável e `unid_idatual` como estado corrente; prazo original × atual; estados do RA (pendente/encerrado/bloqueado) e da OS (incl. **encerrada não executada**) com marcos geração/emissão/execução/encerramento; **efeito cadastral produzido pelas operações "Efetuar…", com indicadores na OS registrando que a atualização ocorreu**; reativação/duplicidade por encadeamento de protocolos; ausência de subclasses por companhia, com a parametrização como fonte importante (não exclusiva comprovada) de variabilidade; 22 cenários de caracterização identificados.
- Mapa funcional da Arrecadação (8ª execução): [modulos/arrecadacao.md](docs/modernizacao/modulos/arrecadacao.md) — recepção (movimento do arrecadador com registro bruto e totais de conferência) **separada** da classificação em lote; catálogo de situações do pagamento como semântica central (nenhum pagamento é descartado, situação anterior preservada); classificação busca o documento na versão corrente **e** no histórico e decide pela situação (retificada apropria; cancelada/prescrita/parcelada geram situação específica); excedente/devolução com guia própria; conciliação por aviso bancário (calculado × informado, acertos e deduções); débito automático em três níveis; encerramento mensal como **fechamento contábil** (retenções tributárias + consolidação do não classificado); PIX na branch é apenas gerador de QR Code estático (chave hard-coded — achado de segurança). Assimetria estrutural registrada: o pagamento **perde identidade** ao ser arquivado.

## EM EXECUÇÃO

- Nada em execução no momento; próxima atividade definida abaixo.

## PRÓXIMAS ATIVIDADES (backlog restante da Fase 0, em ordem)

1. **Glossário de domínio** — ✅ concluído em 2026-08-14: [`dominio/glossario.md`](docs/modernizacao/dominio/glossario.md) (25 conceitos, mapa de relações, 9 pontos de aprofundamento).
2. **Mapa funcional por módulo** (➡ próxima atividade: **batch**) — um documento por módulo em `docs/modernizacao/modulos/`. Ordem: ~~cadastro~~ ✅ → ~~micromedição~~ ✅ → ~~faturamento~~ ✅ → ~~cobrança~~ ✅ → ~~arrecadação~~ ✅ → ~~atendimento~~ ✅ → ~~segurança~~ ✅ ([modulos/seguranca.md](docs/modernizacao/modulos/seguranca.md), 2026-08-14) → batch → relatórios → integrações. O mapa do batch deve fechar: framework próprio de processos/funcionalidades/unidades de processamento, agendamento (Quartz + MDBs) e os 246 deployments, controle de execução e reprocessamento, commits parciais e paralelismo, **autorização e abrangência nos fluxos batch** (dúvida encaminhada por seguranca.md §21) e a orquestração do FATURAR_GRUPO e dos encerramentos mensais.
3. **Mapa de domínio** — entidades conceituais e relacionamentos (não confundir com classes/tabelas/DTOs/telas), em `docs/modernizacao/dominio/mapa-de-dominio.md`, após glossário + primeiros módulos.
4. **Análise de compatibilidade das estruturas centrais** — classificação PRESERVAR/MODERNIZAR/REESTRUTURAR/NÃO TRANSPORTAR (imóvel, cliente, estrutura territorial, ligações, medição, conta e composição, débitos/créditos, pagamentos, RA/OS, RBAC), com impacto de migração por decisão.
5. **Catálogo de funcionalidades futuras** — consolidar descobertas do `gsan_comercial` (PIX — `arrecadacao_pix`/`conta_qrcode_pix`/`GeradorQrCodePIX` —, fiscal/NF, SPED, mobile/campo, recadastramento, tarifa social, SPC/Serasa, APIs, BI, boleto registrado): funcionalidade, problema resolvido, módulo, dependências, prioridade preliminar. Sem modelagem de banco.
6. **Dependências entre módulos** — refinar a ordem preliminar com base nos mapas funcionais; registrar motivo de qualquer mudança.
7. **Compatibilidade GSAN → SISAN** — documento conceitual (o que permanece reconhecível; códigos/identificadores; schemas divergentes entre companhias; registro de transformações; validação de migração), em `docs/modernizacao/compatibilidade/`.
8. **Encerramento da Fase 0** — critério de saída: itens 1–7 concluídos + ADRs 0001/0002 formalizadas.

## RISCOS

1. Ausência de rede de testes/caracterização do legado (19 testes / 2,39M LOC) — maior risco para a equivalência A=B.
2. Perda ou deturpação de regras de negócio na reimplementação (~830 SQLs concatenados, 116 funções de banco, regras embutidas em Actions/EJBs).
3. Variabilidade de schemas entre instalações GSAN (drift comprovado no `gsan_comercial`, ex.: PIX fora das migrations) — inviabiliza migração futura se a compatibilidade não for requisito desde o início (ADR-0005).
4. Recriar a roda ou redesenhar por estética, quebrando o caminho de migração (mitigado pela ADR-0006).
5. Dificuldade de levantar o ambiente de referência do legado (JBoss 4/Java 5 em SO moderno) para caracterização.
6. SISAN herdar padrões fracos de segurança do legado (MD5, credenciais padrão, APIs sem autenticação real).
7. Inflação de escopo pelo catálogo de funcionalidades futuras antes do núcleo estar migrado.

Lista original de 10 riscos no plano de trabalho, com reinterpretação registrada na [revisão de premissas](docs/modernizacao/alteracoes/2026-08-13-revisao-premissas-fase0.md).

## DECISÕES ARQUITETURAIS

Registradas em [`docs/modernizacao/decisoes/`](docs/modernizacao/decisoes/README.md).

| ADR | Assunto | Status |
| --- | ------- | ------ |
| 0001 | Monólito modular Spring Boot | Proposta |
| 0002 | Flyway para migrations (schema SISAN versionado desde V1, sem baseline do legado) | Proposta |
| 0003 | Código novo no repositório SISAN | **Aceita** |
| 0004 | UTF-8 no SISAN; encoding de origem tratado na migração | **Aceita** |
| 0005 | SISAN como modernização evolutiva e compatível do GSAN; migração como requisito arquitetural | **Aceita** |
| 0006 | Modelo de dados evolutivo (PRESERVAR/MODERNIZAR/REESTRUTURAR/NÃO TRANSPORTAR) | **Aceita** |

## DÍVIDAS TÉCNICAS IDENTIFICADAS (legado — inalterado)

- Java 1.5/1.6, JBoss 4.0.1sp1, Struts 1.1, EJB 2.x, Hibernate 3, Quartz 1.5.2, JasperReports 1.2.2, Axis2 1.5.1, applet de impressão térmica — tudo EOL, sem caminho de upgrade direto.
- Build Ant com JARs vendorizados em `lib/`, sem gestão de dependências.
- ~830 pontos de SQL/HQL com concatenação de strings (superfície de SQL Injection).
- Senhas de usuário com MD5/SHA-1 sem salt; API HTTP com pseudo-autenticação por domínio.
- 212 tabelas de backup/manutenção no schema `public`; DDL manual sem migration correspondente.
- 19 classes de teste para ~2,39 milhões de linhas Java.

## DEPENDÊNCIAS BLOQUEADORAS

Nenhuma no momento. Pendências **não bloqueadoras**: definição da infraestrutura da VPS (posterior, antes do primeiro deploy); formalização das ADRs 0001/0002; obtenção (ou construção sintética) de uma base GSAN de referência com dados para a futura caracterização (Fases 1–2).

## TESTES DISPONÍVEIS

19 classes JUnit no legado (`test/`), sem cobertura relevante. Baseline funcional automatizada: inexistente (objetivo da Fase 2, sobre ambiente de referência do legado + massa controlada).

## MÓDULOS MIGRADOS

Nenhum (implementação ainda não iniciada — Fase 0).

## MÓDULOS PENDENTES

Todos — ordem preliminar em [`docs/modernizacao/modulos/README.md`](docs/modernizacao/modulos/README.md) (refinamento é o item 6 do backlog).

## MIGRATIONS EXECUTADAS

Nenhuma. O schema do SISAN nascerá versionado por Flyway desde `V1` (sem baseline copiada do `gsan_comercial`). Histórico legado: MyBatis Migrations em `gsan-migracoes` (301 scripts `comercial`, últimos de 2024-06; 5 `gerencial`) mantido como referência de evolução do GSAN.
