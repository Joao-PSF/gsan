# MODERNIZAÇÃO GSAN — Controle do Projeto

> Visão executiva e operacional da modernização. Documentação técnica detalhada em [`docs/modernizacao/`](docs/modernizacao/README.md).

## STATUS GERAL

Fase 0 (Inventário) iniciada em 2026-08-13. Diagnóstico técnico inicial concluído a partir do código (`gsan`), das migrations (`gsan-migracoes`) e do DDL do banco `gsan_comercial`. Nenhuma alteração de código de produção realizada.

## FASE ATUAL

Fase 0 — Inventário e diagnóstico.

## CONCLUÍDO

- Diagnóstico inicial de runtime, build, frameworks, segurança e banco — [arquitetura legada](docs/modernizacao/arquitetura/arquitetura-legada.md).
- Inventário estrutural do banco a partir do DDL fornecido — [estrutura atual](docs/modernizacao/banco/estrutura-atual.md).
- Plano de trabalho da modernização — [plano de trabalho](docs/modernizacao/plano-de-trabalho.md).

## EM EXECUÇÃO

- Validação das premissas do diagnóstico com a equipe (ver "Dependências bloqueadoras").

## PRÓXIMAS ATIVIDADES

1. Inventário do banco real de produção (versão, roles, grants, extensões, tamanhos, jobs agendados).
2. Reconciliação DDL real × `gsan-migracoes` × dump fornecido (drift 2024–2026).
3. Rotação de credenciais comprometidas e inventário de secrets.
4. Ambiente reproduzível do legado (Fase 1).
5. Definição de massa de dados de teste anonimizada.

## RISCOS

Top 10 no [plano de trabalho, seção 3](docs/modernizacao/plano-de-trabalho.md#3-principais-riscos). Críticos: ausência de rede de testes; drift banco × migrations × código; PostgreSQL de origem antiga (artefatos da era 8.x); regras financeiras em SQL concatenado; senhas MD5/SHA-1 e credenciais padrão versionadas.

## DECISÕES ARQUITETURAIS

Registradas em [`docs/modernizacao/decisoes/`](docs/modernizacao/decisoes/README.md).

| ADR | Assunto | Status |
| --- | ------- | ------ |
| 0001 | Monólito modular Spring Boot | Proposta |
| 0002 | Flyway para migrations | Proposta |
| 0003 | Código novo no repositório SISAN | Proposta |
| 0004 | Manter encoding LATIN1 na 1ª migração de banco | Proposta |

## DÍVIDAS TÉCNICAS IDENTIFICADAS

- Java 1.5/1.6, JBoss 4.0.1sp1, Struts 1.1, EJB 2.x, Hibernate 3, Quartz 1.5.2, JasperReports 1.2.2, Axis2 1.5.1, applet de impressão térmica — tudo EOL, sem caminho de upgrade direto.
- Build Ant com JARs vendorizados em `lib/`, sem gestão de dependências.
- ~830 pontos de SQL/HQL com concatenação de strings (superfície de SQL Injection).
- Senhas de usuário com MD5/SHA-1 sem salt; API HTTP com pseudo-autenticação por domínio.
- 212 tabelas de backup/manutenção no schema `public`; DDL manual em produção sem migration correspondente.
- 19 classes de teste para ~2,39 milhões de linhas Java.

## DEPENDÊNCIAS BLOQUEADORAS

- Confirmar versão exata do PostgreSQL de produção (roles/grants não constam no DDL exportado; necessário inventário no banco real).
- Confirmar se o repositório `gsan` (último commit 2023-10) reflete o código em produção; localizar os fontes das mudanças de banco de 2024–2026.
- Acesso a ambiente de homologação com capacidade para restore da base.

## TESTES DISPONÍVEIS

19 classes JUnit no legado (`test/`), sem cobertura relevante. Baseline funcional automatizada: inexistente (objetivo da Fase 2).

## MÓDULOS MIGRADOS

Nenhum.

## MÓDULOS PENDENTES

Todos — ordem prevista em [`docs/modernizacao/modulos/README.md`](docs/modernizacao/modulos/README.md).

## MIGRATIONS EXECUTADAS

Nenhuma pela modernização. Histórico legado: MyBatis Migrations em `gsan-migracoes` (301 scripts `comercial`, últimos de 2024-06; 5 `gerencial`). Baseline Flyway: pendente da reconciliação do drift.
