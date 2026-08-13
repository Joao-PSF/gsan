# Arquitetura Alvo

Versões confirmadas como estáveis/suportadas em 2026-08 — reconfirmar no início de cada fase.

## Stack

| Camada | Tecnologia |
| ------ | ---------- |
| Linguagem | Java 25 LTS |
| Framework | Spring Boot 4.1.x (Spring Framework 7, Jakarta EE) |
| Web | Spring MVC; REST onde houver consumidor real; server-side rendering para telas internas (decisão da Fase 9) |
| Persistência | Spring Data JPA/Hibernate para CRUD; `JdbcTemplate`/SQL nativo para consultas complexas, relatórios e batch (não converter SQL funcional para ORM por estética) |
| Transações | Spring Transaction (`@Transactional`), substituindo CMT do EJB |
| Segurança | Spring Security (RBAC reproduzindo o modelo `seguranca.*` atual, depois fortalecido) |
| Banco | PostgreSQL 18.x (18.6+); mesmo schema do legado durante a coexistência |
| Migrations | Flyway (ADR-0002), baseline a partir do DDL real de produção |
| Build | Maven (convenção dominante no ecossistema Spring; multi-módulo) |
| Batch | Spring Batch + agendamento (Spring Scheduling; Quartz moderno apenas se necessidade real) |
| Relatórios | JasperReports atual para os `.jrxml` reaproveitáveis; reescrita seletiva apenas quando o layout exigir |
| Observabilidade | Spring Boot Actuator + Micrometer (logs estruturados, métricas, health checks) |
| Execução | Containers (Docker) + docker-compose para dev; CI/CD com SAST/SCA/SBOM |

## Organização modular (monólito modular)

```text
gsan (novo código — repositório SISAN, ADR-0003)
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

## Estratégia de coexistência

1. Legado e novo sistema compartilham o mesmo banco (fonte de verdade) durante toda a transição.
2. O novo sistema **não** redesenha tabelas ao migrar um módulo; mapeia o schema existente (nomes de colunas `xxxx_id`, `int2/int4`, timestamps `_tmultimaalteracao`).
3. Roteamento por funcionalidade: proxy reverso direciona telas migradas para o novo sistema; o restante segue no legado. Sessões separadas; SSO simples entre os dois (mesma base `seguranca.usuario`).
4. Cuidados de coexistência: sequences compartilhadas (usar as sequences do banco, nunca geradores próprios), sem cache de segundo nível sobre tabelas escritas pelos dois lados, mesmas regras de bloqueio/isolamento.
5. Desativação do legado por funcionalidade somente após equivalência comprovada (Fase 12).

## O que não faremos

- Reescrita completa em uma única etapa; microserviços por padrão; troca de SQL funcional por ORM; alteração de banco e aplicação simultaneamente sem isolamento; exposição de entidades JPA como contrato de API.
