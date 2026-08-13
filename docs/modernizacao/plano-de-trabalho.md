# Plano de Trabalho — Modernização do GSAN

Elaborado em 2026-08-13 após diagnóstico dos repositórios `gsan` e `gsan-migracoes` e do DDL do banco `gsan_comercial`. Detalhes em: [arquitetura legada](arquitetura/arquitetura-legada.md), [estrutura do banco](banco/estrutura-atual.md), [segurança](seguranca/riscos-identificados.md).

## 1. Estado atual

Monólito Java EE 1.4: Java 1.5/1.6 (encoding ISO-8859-1), JBoss 4.0.1sp1, EAR `gcom.ear`, build Ant com JARs vendorizados. ~2,39M linhas Java (7.900 classes), 1.618 JSPs, 3.012 Actions Struts 1.1, 234 EJBs 2.x (166 MDBs; 246 deployments de batch separados), Hibernate 3 com 812 `.hbm.xml` gerados por Middlegen, Quartz 1.5.2, JasperReports 1.2.2 (504 relatórios), Axis2 1.5.1, applet de impressão térmica. Fluxo: JSP → Action → Fachada → `Controlador*SEJB` (250) → `Repositorio*HBM` com ~4.500 consultas HQL/SQL, ~830 delas com concatenação de strings.

Banco `gsan_comercial` (LATIN1): 18 schemas, 1.838 tabelas, 849 sequences, 116 funções (56 em C — `dblink` e `pg_trgm` instalados no estilo pré-extensão, indício de origem PostgreSQL 8.x), 46 views, 3 matviews, 2.371 índices, 2.940 FKs, ~212 tabelas de backup/manutenção no `public`. Customizações relevantes vs. GSAN público: fiscal/NF + SPED, mobile/campo, recadastramento (NIS/tarifa social), SPC/Serasa, APIs HTTP próprias, BI direto no banco.

Pontos críticos de partida: 19 classes de teste no total; migrations (MyBatis) paradas em 2024-06 enquanto o banco tem objetos de até 2026 (drift); repositório de código com último commit em 2023-10 (confirmar se reflete produção); senhas MD5/SHA-1 sem salt; roles de banco com senha = login versionadas; API de pagamento com pseudo-autenticação por domínio HTTP.

## 2. Arquitetura alvo

Java 25 LTS · Spring Boot 4.1.x (Spring Framework 7/Jakarta) · Spring MVC + Spring Security (RBAC reproduzindo `seguranca.*`) · Spring Data JPA para CRUD e `JdbcTemplate`/SQL nativo para consultas complexas e relatórios · Spring Batch · Maven multi-módulo · Flyway com baseline do banco real · PostgreSQL 18.x · Docker + CI/CD (SAST/SCA/SBOM/secrets) · Actuator/Micrometer para observabilidade. Organização: **monólito modular** (cadastro, faturamento, arrecadacao, cobranca, micromedicao, atendimento, seguranca, relatorios, batch, integracoes, shared), separação domain/application/infrastructure/web onde houver benefício real. Coexistência: legado e novo compartilham o mesmo banco (fonte de verdade), roteamento por funcionalidade em proxy reverso, sequences do banco, sem redesenho de tabelas durante a migração de módulos. Versões reconfirmadas a cada fase (em 2026-08: Spring Boot 4.1.0 é a linha estável; PostgreSQL 18.6 é a minor atual; PG 14 sai de suporte em 2026-11).

## 3. Principais riscos

| # | Risco | Mitigação principal |
| - | ----- | ------------------- |
| 1 | Ausência de rede de testes (19 testes / 2,39M LOC): regressões financeiras silenciosas | Fase 2 antes de qualquer mudança; equivalência A=B por módulo |
| 2 | Drift tripla: banco real × migrations (2024) × código (2023) — fonte de verdade incerta | Reconciliação e nova baseline na Fase 0; confirmar origem do código de produção |
| 3 | PostgreSQL de origem muito antiga (artefatos 8.x, LATIN1, contribs em C): restore direto em PG 18 falha | Projeto próprio (Fase 8) com homolog, conversão para extensões e bateria de validação |
| 4 | Regras financeiras espalhadas em ~830 SQLs concatenados e 116 funções de banco | Caracterização antes de migrar; SQL nativo preservado; comparação ao centavo |
| 5 | Segurança atual frágil (MD5/SHA-1, credenciais padrão, API sem autenticação real, sem TLS) | Ações P0 imediatas (rotação, TLS no proxy); Fase 5 reproduz e fortalece |
| 6 | Coexistência legado+novo no mesmo banco (Hibernate 3 × JPA moderno: locks, sequences, cache) | Regras de coexistência (sem cache L2 compartilhado, sequences do banco); piloto valida |
| 7 | Batch crítico acoplado a EJB/MDB/JBoss (246 deployments): janela de faturamento não pode falhar | Batch migra por último; execução paralela comparada por competência |
| 8 | Dependências mortas sem upgrade direto (Jasper 1.2.2, Quartz 1.5, Axis2, applet de impressão) | Substituição planejada por equivalente moderno, com teste de saída idêntica |
| 9 | Conhecimento tácito (customizações por companhia, integrações bancárias/fiscais pouco documentadas) | Fichas de integração e documentação por módulo antes de implementar |
| 10 | Capacidade de infra/equipe para CI/CD, containers e dois sistemas em produção simultâneos | Fase 1 entrega ambiente reproduzível; fases só avançam com critério de aceite cumprido |

## 4. Fases

| Fase | Objetivo | Atividades | Dependências | Entrega | Critério de aceite |
| ---- | -------- | ---------- | ------------ | ------- | ------------------ |
| 0 — Inventário | Mapa técnico completo | Diagnóstico código/banco/infra/integrações; inventário do banco real (versão, roles, grants, jobs); reconciliação do drift; classificação de objetos; fichas de integração | Acesso ao banco real e à infra de produção | Mapa técnico + baseline documental (`docs/modernizacao/`) | Premissas confirmadas pela equipe; drift catalogado; nenhuma pergunta aberta bloqueante |
| 1 — Ambiente reproduzível | Legado executável de forma controlada | Documentar build Ant/JBoss; ambiente dev + homolog com restore da base; config por ambiente; Docker do legado se viável | Fase 0 | GSAN legado rodando em homolog reproduzível | Build + deploy do EAR reproduzidos do zero seguindo somente a documentação |
| 2 — Rede de segurança | Baseline funcional automatizada | Massa de dados anonimizada congelada; golden masters de batch/cálculos; testes HTTP das telas críticas; catálogo + resultados de consultas críticas; baseline de performance | Fase 1 | Suíte de caracterização executável | Rodadas repetidas produzem resultados idênticos; cobre os 7 comportamentos priorizados |
| 3 — Build e Java | Compilação moderna do legado | Migrar build Ant→Maven (mantendo Java alvo do JBoss 4); gestão de dependências; CI compilando | Fase 1 | Build Maven reproduzível do legado | EAR gerado por Maven idêntico em conteúdo ao gerado por Ant |
| 4 — Fundação Spring Boot | Núcleo moderno funcionando | Projeto SISAN (Maven multi-módulo); datasource/pool no banco GSAN; profiles; logging; exception handling; Actuator; Flyway baseline; esqueleto de segurança | Fases 0–2 | Aplicação Spring Boot conectada ao banco em homolog | Health checks OK; leitura de tabelas reais; baseline Flyway aplicada em banco limpo = schema real |
| 5 — Segurança | Modelo equivalente ou superior | Reproduzir autenticação (compatível com hashes atuais + re-hash BCrypt/Argon2), RBAC completo (grupos, funcionalidades, permissões especiais, abrangência), auditoria; secrets por ambiente; TLS; contas de banco segregadas | Fase 4 | Login + autorização no sistema novo contra `seguranca.*` | Matriz perfil×funcionalidade idêntica à do legado nos testes; nenhum controle atual reduzido |
| 6 — Piloto | Validar arquitetura ponta a ponta | Migrar 1 módulo de risco moderado (cadastro auxiliar + consulta + 1 tela de atendimento com 1 relatório); roteamento por funcionalidade no proxy; deploy containerizado | Fases 4–5 | Funcionalidade real em produção na nova stack | Equivalência A=B comprovada; usuários validaram; rollback testado (desligar roteamento) |
| 7 — Migração dos módulos | Substituição progressiva | Ordem da seção 5; por módulo: documentar comportamento → testes → implementar → comparar → validar segurança/performance → produção com rollback | Fase 6 | Módulos em produção incremental | Cada módulo cumpre o ciclo completo antes do próximo crítico começar |
| 8 — PostgreSQL | Banco na versão alvo | Ensaios de dump/restore em homolog PG 18; conversão contribs→extensões; bateria de validação (schema, contagens, financeiro, performance); ensaio cronometrado; corte com janela e rollback | Fases 0–2 (pode rodar em paralelo às fases 6–7) | `gsan_comercial` em PostgreSQL 18.x | Zero divergência em contagens e somas financeiras; batch de referência idêntico; janela dentro do acordado |
| 9 — Interface | Eliminar Struts/JSP | Decidir opção A (Spring MVC + templates) × B (REST + frontend) com base no custo/equipe; migrar telas junto com os módulos | Fase 6 | Telas migradas sem Struts | Nenhuma tela nova depende de Struts/JSP; usuários validaram as telas críticas |
| 10 — Observabilidade | Operação visível | Logs estruturados com ID de transação, métricas, alertas para financeiro e batch, auditoria centralizada | Fase 4+ | Monitoramento em produção | Erros de batch/financeiro detectados por alerta antes do usuário reportar |
| 11 — CI/CD | Pipeline completo | build → testes → análise estática → SCA/SAST → SBOM → scan de secrets → homolog → deploy controlado | Fases 3–4 | Pipeline nos repositórios | Nenhum deploy manual; pipeline bloqueia vulnerabilidade crítica |
| 12 — Desativação do legado | Desligar com segurança | Por funcionalidade: equivalência em produção, validação de usuários, logs estáveis, rollback disponível; descomissionar EAR/JBoss ao final | Fase 7 completa | Legado desativado | Zero funcionalidades ativas no legado; infraestrutura JBoss desligada |

## 5. Ordem dos módulos

```text
1. cadastros auxiliares   → CRUD simples, valida a stack com risco baixo (parte do piloto)
2. consultas              → somente leitura sobre o schema real; mede performance
3. atendimento (RA)       → risco moderado, alto valor; completa o piloto
4. ordens de serviço      → encadeia com atendimento; toca integração mobile
5. micromedição           → leituras/consumo/média alimentam o faturamento
6. cobrança               → financeiro com janelas de correção maiores (inclui parcelamento)
7. arrecadação            → crítico: baixas e retornos bancários
8. faturamento            → núcleo financeiro de maior risco
9. batch críticos         → por último, com execução paralela comparada por competência
```

Transversais: `seguranca` na Fase 5; `relatorios` e `integracoes` migram junto do módulo dono; `fiscal`/SPED junto de faturamento/financeiro. Justificativa geral: risco crescente, dependências respeitadas (micromedição antes de faturamento), financeiro por último com a plataforma já madura.

## 6. Estratégia PostgreSQL

Resumo (detalhe em [banco/migracao-postgresql.md](banco/migracao-postgresql.md)):

1. **Inventário real primeiro**: versão de origem, encoding/collation, roles/GRANTs (ausentes no DDL exportado), tamanho, consumidores diretos (BI/OLAP/dblink/sincronismo `admindb`), jobs externos.
2. **Homologação PG 18.x** via `pg_dump -Fc`/restore com correções scriptadas: substituir `dblink`/`pg_trgm`/`plpgsql_call_handler` pré-extensão por `CREATE EXTENSION`; revalidar as 46 views, funções PL/pgSQL e matviews; manter LATIN1 (ADR-0004).
3. **Estratégia de corte**: dump/restore com janela e freeze é o padrão (pg_upgrade inviável pelos contribs antigos e salto de versões; replicação lógica só se a origem confirmar versão que a suporte). Ensaio cronometrado define a janela; origem preservada intocada como rollback.
4. **Validação obrigatória**: diff de schema; contagem de 100% das tabelas; somas financeiras por competência (contas, pagamentos, devoluções, créditos, débitos, parcelamentos, saldos, hidrômetros, OS) com **tolerância zero**; re-execução de batch de referência; performance das consultas críticas.
5. **Versionamento**: baseline Flyway do DDL real; depois, nenhuma alteração estrutural sem migration (alterações emergenciais geram migration retroativa em 1 dia útil).

## 7. Estratégia de testes

Regra central: mesma entrada no legado e no novo ⇒ mesmo resultado (`A = B`); diferenças só quando deliberadas, documentadas e aprovadas; financeiro comparado ao centavo. Camadas: (1) caracterização do legado com golden masters sobre massa anonimizada congelada; (2) harness de equivalência por módulo comparando estado do banco, arquivos e relatórios gerados; (3) testes do sistema novo com JUnit 5 + Testcontainers PG 18 sobre o schema real (nunca H2); (4) validação da migração de banco (seção 6); (5) matriz de autorização perfil×funcionalidade. Prioridade de cobertura: autenticação/autorização → cálculo de conta → baixa de pagamento → parcelamento → consumo/média → OS → resumos financeiros. Detalhe em [testes/estrategia-testes.md](testes/estrategia-testes.md).

## 8. Segurança

Imediatas (P0, independem da modernização): rotacionar roles `gsan_*` com senha = login (comprometidas por script público) e credenciais dos `*-ds.xml`; avaliar exposição das APIs `/api/*` (pseudo-autenticação por domínio HTTP) e proteger com TLS + token real via proxy. Na fundação (P1): hashes BCrypt/Argon2 com re-hash no primeiro login preservando expiração/bloqueio/histórico atuais; Spring Security consumindo o RBAC `seguranca.*` sem substituí-lo antes do mapeamento completo; cookies seguros, CSRF, headers, sessão controlada; secrets fora do código por ambiente; contas de banco segregadas com menor privilégio. Contínuas (P2): queries 100% parametrizadas no novo; validação de upload centralizada; anonimização de massas de teste (LGPD); auditoria preservada e centralizada; pipeline com SAST/SCA/SBOM/secret-scan. OAuth2/OIDC apenas se houver infraestrutura de identidade; não é pré-requisito. Detalhe em [seguranca/riscos-identificados.md](seguranca/riscos-identificados.md).

## 9. Primeiro ciclo de execução

Somente estas tarefas agora (sem produção de código de aplicação):

1. **Validar premissas com a equipe**: o repo `gsan` (2023-10) reflete produção? Onde estão os fontes das mudanças 2024–2026? Qual a versão exata do PostgreSQL/SO de produção? Quais integrações estão ativas? SISAN é mesmo o destino do código novo (ADR-0003)?
2. **Inventário do banco real** (somente leitura): versão, encoding/collation, roles e GRANTs, tamanhos, extensões/contribs, jobs, replicação, consumidores diretos.
3. **Reconciliar o drift**: diff DDL real × `gsan-migracoes` × dump fornecido; catalogar objetos sem migration; decidir e registrar a baseline (ADR-0002).
4. **Classificar com o DBA** as ~212 tabelas de backup/manutenção (nada será removido).
5. **Rotação de credenciais** (P0 de segurança) + inventário de secrets nos servidores.
6. **Ambiente reproduzível do legado** (Fase 1): documentação de build validada do zero + restore de homolog.
7. **Massa de teste**: definir recorte representativo e regras de anonimização.
8. **Formalizar ADRs 0001–0004** (aceitar/ajustar) e reconfirmar versões alvo.
9. **Especificar os 3 primeiros testes de caracterização** (login/autorização; cálculo de conta individual; baixa de pagamento) — especificação, não implementação, até o ambiente da Fase 1 existir.
