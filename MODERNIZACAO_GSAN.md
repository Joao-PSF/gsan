# MODERNIZAÇÃO GSAN → SISAN — Controle do Projeto

> Visão executiva e operacional da modernização. Documentação técnica detalhada em [`docs/modernizacao/`](docs/modernizacao/README.md).

## STATUS GERAL

Fase 0 em andamento. 1ª execução (2026-08-13): diagnóstico técnico do legado, inventário do `gsan_comercial` e plano de trabalho. 2ª execução (2026-08-13): premissas revisadas — **não há GSAN em produção neste projeto**; SISAN é **modernização evolutiva do GSAN** com banco próprio (UTF-8) e **migração de instalações GSAN como requisito arquitetural futuro**; repositório SISAN confirmado para o código novo; execução inicial em VPS. Registro completo em [alteracoes/2026-08-13-revisao-premissas-fase0.md](docs/modernizacao/alteracoes/2026-08-13-revisao-premissas-fase0.md). 3ª execução (2026-08-14): **glossário de domínio concluído** — 25 conceitos com evidências em [dominio/glossario.md](docs/modernizacao/dominio/glossario.md). 4ª execução (2026-08-14): **mapa funcional do Cadastro concluído** — [modulos/cadastro.md](docs/modernizacao/modulos/cadastro.md); dúvidas 1, 2 e 6 do glossário resolvidas. Nenhuma implementação iniciada.

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

## EM EXECUÇÃO

- Nada em execução no momento; próxima atividade definida abaixo.

## PRÓXIMAS ATIVIDADES (backlog restante da Fase 0, em ordem)

1. **Glossário de domínio** — ✅ concluído em 2026-08-14: [`dominio/glossario.md`](docs/modernizacao/dominio/glossario.md) (25 conceitos, mapa de relações, 9 pontos de aprofundamento).
2. **Mapa funcional por módulo** (➡ próxima atividade: **micromedição**) — um documento por módulo em `docs/modernizacao/modulos/`. Ordem: ~~cadastro~~ ✅ ([modulos/cadastro.md](docs/modernizacao/modulos/cadastro.md), 2026-08-14) → micromedição → faturamento → cobrança → arrecadação → atendimento → segurança → batch → relatórios → integrações. O mapa da micromedição deve fechar: precedência das rotas no processo de leitura, ciclo leitura→consumo (tipos/média/críticas com os parâmetros da Categoria) e o vínculo com o cronograma do grupo de faturamento.
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
