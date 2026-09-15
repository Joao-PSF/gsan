# Arquitetura Alvo

Versões confirmadas como estáveis/suportadas em 2026-08 — reconfirmar no início de cada fase.

> **Revisão 2026-09-15 (16ª execução)**: o sistema passa a chamar-se **OpenGSAN** — evolução aberta e moderna do GSAN (ADR-0005 revisada). A **migração de instalações GSAN saiu do escopo deste projeto** e terá projeto próprio.
>
> Revisão 2026-08-13 (2ª execução): banco próprio em UTF-8 e modelo de dados evoluído (ADR-0006). A coexistência com um GSAN em produção deixou de ser premissa de desenvolvimento — ver [revisão de premissas](../alteracoes/2026-08-13-revisao-premissas-fase0.md).

## Stack

| Camada | Tecnologia |
| ------ | ---------- |
| Linguagem | Java 25 LTS |
| Framework | Spring Boot 4.1.x (Spring Framework 7, Jakarta EE) |
| Web | Spring MVC; REST onde houver consumidor real; server-side rendering para telas internas (decisão da Fase 9) |
| Persistência | Spring Data JPA/Hibernate para CRUD; `JdbcTemplate`/SQL nativo para consultas complexas, relatórios e batch (não converter SQL funcional para ORM por estética) |
| Transações | Spring Transaction (`@Transactional`), substituindo CMT do EJB |
| Segurança | Spring Security (RBAC evoluído do modelo conceitual `seguranca.*` do GSAN — perfis, grupos, funcionalidades, permissões especiais, abrangência) |
| Banco | PostgreSQL 18.x (18.6+), UTF-8 (ADR-0004); modelo de dados próprio do OpenGSAN, evoluído dos conceitos GSAN (ADRs 0005/0006) |
| Migrations | Flyway (ADR-0002); schema do OpenGSAN versionado desde `V1` — sem baseline copiada do legado |
| Build | Maven (convenção dominante no ecossistema Spring; multi-módulo) |
| Batch | Spring Batch + agendamento (Spring Scheduling; Quartz moderno apenas se necessidade real) |
| Relatórios | JasperReports atual para os `.jrxml` reaproveitáveis; reescrita seletiva apenas quando o layout exigir |
| Observabilidade | Spring Boot Actuator + Micrometer (logs estruturados, métricas, health checks) |
| Execução | Containers (Docker) + docker-compose para dev; primeiro ambiente: VPS de testes/homologação/demonstração (não é produção crítica); CI/CD com SAST/SCA/SBOM |

## Organização modular (monólito modular)

```text
opengsan (repositório próprio — nome físico PENDENTE, ADR-0003)
 ├── cadastro
 ├── faturamento
 ├── arrecadacao
 ├── cobranca
 ├── micromedicao
 ├── atendimento        (inclui ordens de serviço)
 ├── seguranca
 ├── relatorios
 ├── batch
 ├── integracoes        (bancos/arrecadadores, SPC/Serasa, fiscal/SPED, mobile, GIS, UPA)
 └── shared             (tipos comuns, utilidades, convenções de persistência)
```

Cada módulo com separação `domain / application / infrastructure / web` **quando trouxer benefício real**; módulos simples (cadastros auxiliares) podem usar estrutura mais direta. Sem microserviços, mensageria ou Kubernetes sem necessidade técnica demonstrada.

## Modelo de dados evolutivo e continuidade conceitual GSAN → OpenGSAN (ADRs 0005/0006)

1. O OpenGSAN é a **evolução aberta e moderna do GSAN**, não sistema do zero: conceitos, módulos, regras de negócio, fluxos, nomenclaturas relevantes e relacionamentos conceituais são preservados sempre que adequados — **porque valem por si**, não para facilitar transporte de dados. Regra geral: *preservar quando adequado, modernizar quando necessário, redesenhar somente com justificativa*.
2. Banco próprio do OpenGSAN (PostgreSQL 18.x, UTF-8), com schema versionado por Flyway desde `V1`. Estruturas importantes do GSAN são classificadas como `PRESERVAR`, `MODERNIZAR`, `REESTRUTURAR` ou `NÃO TRANSPORTAR` — sem redesenho por estética e sem manter estrutura ruim apenas para ficar idêntico ao legado.
3. ⚠️ **Facilidade de migração NÃO é requisito deste projeto** (revisão 2026-09-15, ADR-0005): a migração de instalações GSAN existentes é **projeto separado**. O que permanece requisito é a **continuidade conceitual** — registrar a correspondência entre conceitos GSAN e OpenGSAN, sem detalhar transformação de dados. ⚠️ Facilidade de migração não justifica preservar estrutura inadequada.
4. O OpenGSAN não assume que toda companhia possui o mesmo schema GSAN: instalações reais divergem por versão, migrations, customizações e DDL manual (comprovado no `gsan_comercial`) — fato relevante para o futuro projeto de migração, registrado aqui.
5. ⚠️ Coexistência, sincronização, ETL, cutover e replicação **não pertencem a este projeto** — são objeto do **projeto de migração GSAN → OpenGSAN**, separado e posterior.

## O que não faremos

- Reescrita indiscriminada ou "recriar a roda" — ignorar o conhecimento consolidado no GSAN; microserviços por padrão; troca de SQL funcional por ORM por estética; redesenho de estruturas sem justificativa (ou preservação de estruturas ruins por apego ao legado); exposição de entidades JPA como contrato de API; cópia automática de tabelas/colunas/schemas do `gsan_comercial` para o OpenGSAN.
