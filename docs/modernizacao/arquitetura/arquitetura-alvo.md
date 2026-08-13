# Arquitetura Alvo

Versões confirmadas como estáveis/suportadas em 2026-08 — reconfirmar no início de cada fase.

> Revisão 2026-08-13 (2ª execução): SISAN é **modernização evolutiva do GSAN** (ADR-0005), com banco próprio em UTF-8 e modelo de dados evoluído (ADR-0006). A coexistência com um GSAN em produção deixou de ser premissa de desenvolvimento — ver [revisão de premissas](../alteracoes/2026-08-13-revisao-premissas-fase0.md).

## Stack

| Camada | Tecnologia |
| ------ | ---------- |
| Linguagem | Java 25 LTS |
| Framework | Spring Boot 4.1.x (Spring Framework 7, Jakarta EE) |
| Web | Spring MVC; REST onde houver consumidor real; server-side rendering para telas internas (decisão da Fase 9) |
| Persistência | Spring Data JPA/Hibernate para CRUD; `JdbcTemplate`/SQL nativo para consultas complexas, relatórios e batch (não converter SQL funcional para ORM por estética) |
| Transações | Spring Transaction (`@Transactional`), substituindo CMT do EJB |
| Segurança | Spring Security (RBAC evoluído do modelo conceitual `seguranca.*` do GSAN — perfis, grupos, funcionalidades, permissões especiais, abrangência) |
| Banco | PostgreSQL 18.x (18.6+), UTF-8 (ADR-0004); modelo de dados próprio do SISAN, evoluído dos conceitos GSAN (ADRs 0005/0006) |
| Migrations | Flyway (ADR-0002); schema do SISAN versionado desde `V1` — sem baseline copiada do legado |
| Build | Maven (convenção dominante no ecossistema Spring; multi-módulo) |
| Batch | Spring Batch + agendamento (Spring Scheduling; Quartz moderno apenas se necessidade real) |
| Relatórios | JasperReports atual para os `.jrxml` reaproveitáveis; reescrita seletiva apenas quando o layout exigir |
| Observabilidade | Spring Boot Actuator + Micrometer (logs estruturados, métricas, health checks) |
| Execução | Containers (Docker) + docker-compose para dev; primeiro ambiente: VPS de testes/homologação/demonstração (não é produção crítica); CI/CD com SAST/SCA/SBOM |

## Organização modular (monólito modular)

```text
sisan (repositório SISAN — ADR-0003, aceita)
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

## Modelo de dados evolutivo e compatibilidade GSAN → SISAN (ADRs 0005/0006)

1. O SISAN é **evolução do GSAN**, não sistema do zero: conceitos, módulos, regras de negócio, fluxos, nomenclaturas relevantes e relacionamentos conceituais são preservados sempre que adequados. Regra geral: *preservar quando adequado, modernizar quando necessário, redesenhar somente com justificativa*.
2. Banco próprio do SISAN (PostgreSQL 18.x, UTF-8), com schema versionado por Flyway desde `V1`. Estruturas importantes do GSAN são classificadas como `PRESERVAR`, `MODERNIZAR`, `REESTRUTURAR` ou `NÃO TRANSPORTAR` — sem redesenho por estética e sem manter estrutura ruim apenas para ficar idêntico ao legado.
3. **Facilidade de migração é requisito arquitetural**: toda divergência estrutural relevante em relação ao GSAN registra seu mapeamento/transformação GSAN→SISAN no documento de compatibilidade, para viabilizar o futuro migrador (`identificação de versão/schema → análise de compatibilidade → mapeamento → transformações → validação → migração`).
4. O SISAN não assume que toda companhia possui o mesmo schema GSAN: instalações reais divergem por versão, migrations, customizações e DDL manual (comprovado no `gsan_comercial`).
5. Coexistência com um GSAN operante **não é premissa deste projeto** (não há produção aqui). Padrões de coexistência/corte gradual ficam registrados como cenário suportado do playbook de migração de companhias usuárias, quando essa migração existir.

## O que não faremos

- Reescrita indiscriminada ou "recriar a roda" — ignorar o conhecimento consolidado no GSAN; microserviços por padrão; troca de SQL funcional por ORM por estética; redesenho de estruturas sem justificativa (ou preservação de estruturas ruins por apego ao legado); exposição de entidades JPA como contrato de API; cópia automática de tabelas/colunas/schemas do `gsan_comercial` para o SISAN.
