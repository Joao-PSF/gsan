# Plano de Trabalho — Modernização do GSAN → SISAN

Elaborado em 2026-08-13 após diagnóstico dos repositórios `gsan` e `gsan-migracoes` e do DDL do banco `gsan_comercial`. **Reescrito em 2026-09-14.** Detalhes em: [arquitetura legada](arquitetura/arquitetura-legada.md), [estrutura do banco](banco/estrutura-atual.md), [segurança](seguranca/riscos-identificados.md), [procedência das fontes](procedencia.md).

> **Nota de reescrita (2026-09-14)** — a versão original foi escrita sob a premissa de uma instalação GSAN **em produção** a ser migrada por coexistência (*strangler*), com roteamento em proxy e banco compartilhado. Essa premissa foi corrigida em 2026-08-13, mas a correção tinha sido registrada apenas como aviso no topo, enquanto o corpo continuava descrevendo a estratégia antiga — o documento se contradizia e não servia de base para decisão. Esta versão **remove** a estratégia superada do corpo. O histórico está em [revisão de premissas](alteracoes/2026-08-13-revisao-premissas-fase0.md).

## Premissas vigentes

1. **Não há GSAN em produção neste projeto.** Sem base real, sem usuários, sem DBA, sem janela de corte.
2. **O SISAN é modernização evolutiva do GSAN** (ADR-0005), não greenfield: conceitos e regras do legado são a especificação.
3. **O SISAN tem banco próprio, UTF-8** (ADR-0004), construído por decisões de compatibilidade (ADR-0006) — **nunca** por cópia do schema do `gsan_comercial`.
4. **Migrar instalações GSAN existentes é requisito arquitetural futuro**, não atividade deste projeto. O que este projeto produz é o *playbook* e a compatibilidade que tornam essa migração possível.
5. **`gsan_comercial` é fonte complementar** — compatibilidade e descoberta funcional apenas.

## 1. Estado atual

Monólito Java EE 1.4: Java 1.5/1.6 (encoding ISO-8859-1), JBoss 4.0.1sp1, EAR `gcom.ear`, build Ant com JARs vendorizados. ~2,39M linhas Java (7.900 classes), 1.618 JSPs, 3.012 Actions Struts 1.1, **234 classes EJB concretas** (166 MDB + 68 Session Beans; método de contagem em [`procedencia.md §3.1`](procedencia.md) — não confundir com as ~247 declarações nos descritores), Hibernate 3 com 812 `.hbm.xml` gerados por Middlegen, Quartz 1.5.2, JasperReports 1.2.2 (504 relatórios), Axis2 1.5.1, applet de impressão térmica. Fluxo: JSP → Action → Fachada → `Controlador*SEJB` (250) → `Repositorio*HBM` com ~4.500 consultas HQL/SQL, ~830 delas com concatenação de strings.

Banco `gsan_comercial` (🔵 encoding LATIN1 — **indício forte**, por `script_char_set=LATIN1` nas migrations e encoding ISO-8859-1 do build; não confirmado contra instância viva): 18 schemas, 1.838 tabelas, 849 sequences, 116 funções (56 em C — `dblink` e `pg_trgm` no estilo pré-extensão, indício de origem PostgreSQL 8.x), 46 views, 3 matviews, 2.371 índices, 2.940 FKs, ~212 tabelas de backup/manutenção no `public`. Customizações relevantes vs. GSAN público: fiscal/NF + SPED, mobile/campo, recadastramento (NIS/tarifa social), SPC/Serasa, APIs HTTP próprias, BI direto no banco.

Pontos críticos de partida: 19 classes de teste no total; migrations (MyBatis) paradas em 2024-06 enquanto o banco tem objetos de até 2026 (drift); repositório de código com último commit em 2023-10; **senha de login em SHA-1 sem salt** (MD5 é token efêmero de servlets auxiliares, não participa do login — ver [riscos](seguranca/riscos-identificados.md)); roles de banco com senha = login versionadas; APIs HTTP sem autenticação real.

## 2. Arquitetura alvo

Java 25 LTS · Spring Boot 4.1.x (Spring Framework 7/Jakarta) · Spring Security (RBAC reproduzindo a semântica de `seguranca.*`) · Spring Data JPA para CRUD e `JdbcTemplate`/SQL nativo para consultas complexas e relatórios · Spring Batch · Maven multi-módulo · **Flyway a partir de `V1`, sem baseline copiada do banco legado** (ADR-0002) · PostgreSQL 18.x **em UTF-8** (ADR-0004) · Docker + CI/CD (SAST/SCA/SBOM/secrets) · Actuator/Micrometer.

Organização: **monólito modular** (ADR-0001) — `cadastro`, `micromedicao`, `faturamento`, `cobranca`, `arrecadacao`, `atendimento`, `seguranca`, `relatorios`, `batch`, `integracoes`, `shared` —, com fronteiras explícitas entre módulos.

**Não há coexistência, banco compartilhado nem roteamento por proxy.** O SISAN é um sistema próprio, com banco próprio. A relação com o GSAN é de **compatibilidade** — o legado é a referência de comportamento e a origem dos dados numa migração futura, não um parceiro de execução simultânea.

⚠️ **Arquitetura de interface não decidida** (ADR-0007) — pré-requisito do piloto.

Versões reconfirmadas a cada fase (em 2026-08: Spring Boot 4.1.0 estável; PostgreSQL 18.6 minor atual; PG 14 sai de suporte em 2026-11).

## 3. Principais riscos

| # | Risco | Mitigação principal |
| - | ----- | ------------------- |
| 1 | Ausência de rede de testes (19 testes / 2,39M LOC): regressões financeiras silenciosas | Fase 2 antes de qualquer implementação; equivalência por módulo sob os **dois oráculos** (§7) |
| 2 | Drift tripla: banco `gsan_comercial` × migrations (2024) × código (2023) | Catalogado na Fase 0 como evidência de **compatibilidade**; não há baseline de produção a congelar |
| 3 | Regras financeiras espalhadas em ~830 SQLs concatenados e 116 funções de banco | Caracterização antes de implementar; comparação ao centavo |
| 4 | **Arredondamento não uniforme**: 5 políticas semânticas convivendo no núcleo de faturamento, incluindo 21 usos de `RoundingMode.UP` e truncamento em base de imposto | Caracterizar **ponto a ponto**; proibido unificar em HALF_UP sem decisão registrada ([faturamento §27](modulos/faturamento.md)) |
| 5 | Segurança do legado frágil e, em vários pontos, **ausente** (SHA-1 sem salt, endpoints de escrita sem autenticação, artefato de relatório sem controle de acesso, segredo em código) | Registro de **divergências aprovadas** (§7); o SISAN nasce correto e a diferença é esperada, não falha de equivalência |
| 6 | Fronteiras de módulo impuras no legado (ex.: retificação de conta escreve em `ConsumoHistorico`) | Mapeadas nos mapas funcionais; corrigidas por contrato explícito no SISAN (D-14) |
| 7 | Batch crítico acoplado a EJB/MDB/JBoss/Quartz 1.5 | Batch por último; caracterização por competência antes de substituir |
| 8 | Dependências mortas sem upgrade direto (Jasper 1.2.2, Quartz 1.5, Axis2, applet de impressão) | Substituição planejada com teste de saída equivalente (relatórios: comparação **semântica**, §7) |
| 9 | Conhecimento tácito (customizações por companhia, integrações bancárias/fiscais pouco documentadas) | Mapas funcionais por módulo + fichas de integração antes de implementar |
| 10 | Serialização Java de tarefas batch/relatório no legado | Classificado REESTRUTURAR; não transportar o mecanismo |

## 4. Fases

| Fase | Objetivo | Atividades | Dependências | Entrega | Critério de aceite |
| ---- | -------- | ---------- | ------------ | ------- | ------------------ |
| **0 — Descoberta** | Compreender o comportamento atual | Diagnóstico código/banco; glossário; **mapas funcionais por módulo**; fronteiras; compatibilidade; hipóteses; **especificação dos cenários críticos**; ADRs | — | Baseline documental em `docs/modernizacao/` | Mapas completos; cenários críticos **especificados** (não só listados); ADRs estruturais aceitas; dúvidas abertas registradas |
| 1 — Ambiente de referência | Legado executável de forma controlada | Documentar build Ant/JBoss; ambiente do GSAN de referência com massa sintética; config por ambiente | Fase 0 | GSAN de referência rodando | Build + deploy do EAR reproduzidos do zero seguindo apenas a documentação |
| 2 — Rede de segurança | Baseline funcional automatizada | Massa congelada; *harness*; captura dos golden masters (preenche o "resultado esperado" das especificações da Fase 0); baseline de performance | Fase 1 | Suíte de caracterização executável | Rodadas repetidas produzem resultados idênticos; cobre os comportamentos priorizados |
| 3 — Build | Compilação moderna do legado de referência | Ant→Maven mantendo o Java alvo; CI compilando | Fase 1 | Build reproduzível | EAR gerado por Maven equivalente ao gerado por Ant |
| 4 — Fundação SISAN | Núcleo moderno funcionando | Projeto Maven multi-módulo; **banco próprio UTF-8 versionado por Flyway desde `V1`**; profiles; logging; exception handling; Actuator; esqueleto de segurança | Fases 0–2 | Aplicação Spring Boot com schema próprio | Health checks OK; `V1` aplicada em banco limpo produz o schema esperado |
| 5 — Segurança | Modelo equivalente **ou superior** | Autenticação com BCrypt/Argon2 (compatibilidade com hash legado apenas no caminho de migração); RBAC completo (grupos, funcionalidades, permissões especiais, abrangência); auditoria; secrets por ambiente; TLS; contas de banco segregadas | Fase 4 | Login + autorização no SISAN | Concessões legítimas preservadas; **divergências do registro aplicadas e testadas**; nenhum controle atual reduzido |
| 6 — Piloto | Validar arquitetura ponta a ponta | Cadastros auxiliares + consulta + 1 fluxo de atendimento com 1 relatório | Fases 4–5 + **ADR-0007** | Módulo completo na nova stack | Equivalência sob o oráculo 1; divergências do oráculo 2 registradas; fronteiras de módulo verificadas |
| 7 — Módulos | Construção progressiva | Ordem da §5; por módulo: mapa → especificação → implementação → comparação → segurança → performance | Fase 6 | Módulos entregues incrementalmente | Cada módulo cumpre o ciclo completo antes de o próximo crítico começar |
| 8 — Playbook de migração | Tornar possível migrar uma instalação GSAN | Procedimento de extração/conversão LATIN1→UTF-8; mapeamento GSAN→SISAN por tabela; bateria de validação (contagens, somas financeiras, sequences); ensaio cronometrado | Fases 0, 4, 7 parcial | Playbook + scripts validados em ensaio | Ensaio com massa de referência: zero divergência em contagens e somas financeiras |
| 9 — Interface | Concluir a decisão da ADR-0007 | Implementar a arquitetura decidida; telas acompanham os módulos | Fase 6 | Telas na stack decidida | Usuários validam as telas críticas |
| 10 — Observabilidade | Operação visível | Logs estruturados com ID de transação, métricas, alertas para financeiro e batch, auditoria centralizada | Fase 4+ | Monitoramento | Erros de batch/financeiro detectados por alerta |
| 11 — CI/CD | Pipeline completo | build → testes → análise estática → SCA/SAST → SBOM → *secret scan* → deploy controlado | Fases 3–4 | Pipeline nos repositórios | Nenhum deploy manual; pipeline bloqueia vulnerabilidade crítica e segredo commitado |
| 12 — Adoção | Companhia operando o SISAN | Aplicável **apenas** quando existir instalação a migrar: execução do playbook (Fase 8), validação por usuários reais, desativação do legado daquela instalação | Fases 7, 8 | Instalação migrada | Critérios acordados com a companhia |

## 5. Ordem dos módulos

```text
1. cadastros auxiliares   → CRUD simples, valida a stack com risco baixo (parte do piloto)
2. consultas              → somente leitura; mede performance
3. atendimento (RA)       → risco moderado, alto valor; completa o piloto
4. ordens de serviço      → encadeia com atendimento; toca integração de campo
5. micromedição           → leituras/consumo/média alimentam o faturamento
6. cobrança               → financeiro com janelas de correção maiores (inclui parcelamento)
7. arrecadação            → crítico: baixas e retornos bancários
8. faturamento            → núcleo financeiro de maior risco
9. batch críticos         → por último, comparados por competência
```

Transversais: `seguranca` na Fase 5; `relatorios` e `integracoes` acompanham o módulo dono; `fiscal`/SPED junto de faturamento/financeiro. Justificativa: risco crescente, dependências respeitadas (micromedição antes de faturamento), financeiro por último com a plataforma madura.

## 6. Estratégia PostgreSQL

Detalhe em [banco/migracao-postgresql.md](banco/migracao-postgresql.md). Duas frentes **distintas**, antes confundidas:

**(a) Banco do SISAN** — PostgreSQL 18.x, **UTF-8**, schema construído pelas decisões de compatibilidade (ADR-0006) e versionado por Flyway desde `V1` (ADR-0002). Sem herança direta do schema legado.

**(b) Playbook de migração de instalações GSAN (Fase 8)** — para quando existir base real a migrar: extração da origem (tipicamente LATIN1, possivelmente PG 8.x), conversão de encoding caso a caso (tamanhos de campo, caracteres inválidos, ordenações), substituição de `dblink`/`pg_trgm`/`plpgsql_call_handler` pré-extensão por `CREATE EXTENSION`, mapeamento GSAN→SISAN por tabela, e validação obrigatória: diff de schema mapeado, contagem de 100% das tabelas, somas financeiras por competência com **tolerância zero**, sequences, re-execução de batch de referência.

## 7. Estratégia de testes

Detalhe em [testes/estrategia-testes.md](testes/estrategia-testes.md). **Dois oráculos independentes** — a regra única `A = B` foi corrigida em 2026-09-14 porque, sozinha, obrigaria o SISAN a reproduzir falhas de segurança do legado:

- **Oráculo 1 — funcional/financeiro**: mesma entrada ⇒ mesmo resultado. Financeiro **exato ao centavo**. Diferença = defeito.
- **Oráculo 2 — técnico/segurança**: o SISAN **deve divergir** nos pontos do [registro de divergências aprovadas](compatibilidade/divergencias-aprovadas.md). Igualdade = defeito.

Comparação **semântica via mapeamento GSAN→SISAN** (os schemas divergem por decisão). Relatórios comparados pelo *datasource* ou por conteúdo extraído — **nunca** byte a byte de PDF. Camadas: caracterização do legado (golden masters sobre massa congelada) → equivalência por módulo → testes do SISAN (JUnit 5 + Testcontainers PG 18 sobre o schema real, nunca H2) → validação de migração (§6b) → matriz de autorização.

Prioridade: autenticação/autorização → cálculo de conta → baixa de pagamento → parcelamento → consumo/média → OS → resumos financeiros.

## 8. Segurança

Detalhe em [seguranca/riscos-identificados.md](seguranca/riscos-identificados.md). Três níveis:

- **P0\*** — obrigatório em qualquer instalação GSAN operante e item do checklist de migração futura (**não** é atividade de execução deste projeto): rotação de roles `gsan_*` com senha = login; **rotação da chave de API de SMS** (achado 11, considerada comprometida); bloqueio de `/api/ordem-servico/*` e dos entry points de campo até haver autenticação; proteção do download de relatório batch; TLS no proxy.
- **P1 — requisito de nascimento do SISAN**, antes do primeiro deploy acessível: BCrypt/Argon2 preservando expiração/bloqueio/histórico; Spring Security consumindo a semântica do RBAC legado; cookies seguros, CSRF, headers, sessão controlada; **secrets fora do código, por ambiente**; contas de banco segregadas com menor privilégio; **nenhum filtro decorativo** (achado 14).
- **P2 — durante os módulos**: queries 100% parametrizadas; validação de upload centralizada; anonimização de massas (LGPD); auditoria preservada e centralizada; pipeline com SAST/SCA/SBOM/*secret scan*.

OAuth2/OIDC apenas se houver infraestrutura de identidade; não é pré-requisito.

## 9. Situação da execução

O controle vivo de atividades, backlog e pendências está em [`MODERNIZACAO_GSAN.md`](../../MODERNIZACAO_GSAN.md). A lista de "primeiro ciclo" que ocupava esta seção foi removida: ela pressupunha produção, DBA e acesso a banco real — nada disso existe neste projeto, e o que restava de válido já está no backlog da Fase 0.
