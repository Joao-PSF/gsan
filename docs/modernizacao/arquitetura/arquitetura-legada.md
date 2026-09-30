# Arquitetura Legada do GSAN

Mapa técnico levantado em 2026-08-13 a partir do repositório `gsan` (branch base `master`, último commit 2023-10) e do repositório `gsan-migracoes`.

## Runtime e build

| Item | Situação |
| ---- | -------- |
| Java | Compilação `source/target 1.5`, encoding `ISO-8859-1` (build.xml); infra documentada para Java 1.5/1.6 |
| Servidor | JBoss 4.0.1sp1 (Java EE 1.4 / EJB 2.x), empacotamento `gcom.ear` contendo `gcom.war` |
| Build | Ant (`build.xml` + `build.properties` local); Middlegen (`middlegen-build.xml`) para gerar mapeamentos Hibernate a partir do banco |
| Dependências | JARs vendorizados em `lib/` sem gestão (Maven/Gradle inexistentes) |
| Datasource | JNDI `java:/PostgresDS` configurado no JBoss (`*-ds.xml` fora do repositório, nos servidores) |
| Driver | `postgresql-42.2.23.jre6.jar` |

## Dimensões

| Métrica | Valor |
| ------- | ----- |
| Linhas de código Java | ~2.394.000 |
| Classes Java | 7.900 |
| JSPs | 1.618 |
| Classes `*Action` (Struts 1.1) | 3.012 (2.736 action mappings nos XMLs de módulos) |
| EJBs (SessionBean/MDB) | 234 classes, sendo 166 MDBs |
| Deployments EJB separados (`descriptors/`) | 246 (majoritariamente processos batch; inclui variantes por companhia: CAEMA, CAER, CAERN, COMPESA) |
| Mapeamentos Hibernate (`*.hbm.xml`) | 812 |
| Relatórios Jasper (`*.jrxml`) | 504 |
| Controladores de negócio (`Controlador*SEJB`) | 250 |
| Classes de teste | 19 |

## Frameworks e bibliotecas principais (todas EOL)

Struts 1.1, EJB 2.x (Session + Message-Driven), Hibernate 3 (HQL + SQL nativo), Quartz 1.5.2 (schema `quartz` no banco), JasperReports 1.2.2 + iText 1.3.1 + POI 2.5.1, Axis2 1.5.1 (web services SOAP), JSTL 1.x, taglibs próprias (`gsanLib`, `menus-taglib`, `pager-taglib`), log4j 1.x, commons-* antigos, applet Java de impressão térmica (`aAppletImpressaoTermica.jar`), JavaHelp (`jhgcom.jar`).

## Camadas (fluxo típico de uma funcionalidade)

```text
JSP (gcom/jsp, scriptlets + taglibs)
  → ActionServlet Struts (*.do) → *Action (gcom.gui.*)
    → Fachada / FachadaBatch (singleton, gcom.fachada)
      → Controlador*SEJB (EJB 2.x, gcom.<modulo>)
        → IRepositorio* / Repositorio*HBM (gcom.<modulo>)
          → Hibernate 3 (HQL/SQL concatenado) → PostgreSQL
```

- Transações: gerenciadas pelo container (EJB CMT) via JBoss.
- Sessão HTTP: dados de navegação e usuário em `HttpSession`; wizard de telas com objetos em sessão.
- Consultas: ~4.500 chamadas `createQuery`/`createSQLQuery`; ~830 pontos com concatenação de parâmetros em cláusulas (superfície de SQL Injection — ver segurança).

## Batch

- Framework próprio (`gcom.batch` + schemas `batch`/`auxiliarbatch`): processos, funcionalidades e unidades de processamento registrados em tabelas; disparo via Quartz 1.5.2 e MDBs (JBossMQ); `VerificadorProcessosIniciados` monitora execução.
- Cada rotina batch relevante é um deployment EJB próprio em `descriptors/` (246 diretórios), buildado seletivamente via Ant.
- Servlet `AcessarNovoBatchServlet` indica existência de mecanismo batch "novo" paralelo ao antigo.

## Relatórios

- 504 `.jrxml` (JasperReports 1.2.2) embutidos, exportação PDF/XLS.
- Serviço externo `gsan-relatorios` acessado via REST (Jersey client 1.18 + Gson, classe `api/GsanApi.java` com token) — relatórios fora do EAR.

## APIs HTTP adicionais (pós-GSAN público)

- `gcom.api.*`: servlets REST-like `/api/pagamentoCredito/*` e `/api/ordem-servico/*` + `AutocompleteGenericoServlet` (`/autocomplete`). Autenticação frágil (ver segurança).
- `seguranca.token` (migration 2024-06) para tokens de API.

## Pontos de atenção específicos deste fork

- Customizações por companhia em `descriptors/` e validadores (`validator-compesa.xml`); domínio hard-coded `gsan.cosanpa.pa.gov.br` em filtro de API.
- Módulos adicionais vs. GSAN público: `spcserasa` (negativação), `portal`, `api`, `fiscal`/NF-e + SPED (schema `fiscal`, `integracao`), mobile/campo (schema `mobile`), atualização cadastral (recadastramento com NIS/Bolsa Água), qualidade da água.
- Repositório de código parou em 2023-10, mas migrations vão até 2024-06 e o banco contém objetos nomeados até 2026 → **o repositório pode não refletir produção; confirmar antes de qualquer implementação** (dependência bloqueadora da Fase 0).
