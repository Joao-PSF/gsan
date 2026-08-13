# Decisões Arquiteturais (ADRs)

Uma decisão por arquivo, numerada. Status: Proposta → Aceita → (Substituída/Revertida). Nenhuma ADR "Proposta" autoriza implementação.

| ADR | Título | Status | Data |
| --- | ------ | ------ | ---- |
| [0001](0001-monolito-modular-spring-boot.md) | Monólito modular com Spring Boot 4.1.x / Java 25 LTS | Proposta | 2026-08-13 |
| [0002](0002-flyway-para-migrations.md) | Flyway como ferramenta de migrations (schema SISAN desde `V1`, sem baseline do legado) | Proposta | 2026-08-13 |
| [0003](0003-repositorio-do-codigo-novo.md) | Código novo no repositório SISAN | **Aceita** | 2026-08-13 |
| [0004](0004-encoding-latin1-na-primeira-migracao.md) | UTF-8 no SISAN; encoding de origem tratado pela migração (substitui proposta "manter LATIN1") | **Aceita** | 2026-08-13 |
| [0005](0005-sisan-modernizacao-evolutiva-do-gsan.md) | SISAN é modernização evolutiva e compatível do GSAN; migração como requisito arquitetural | **Aceita** | 2026-08-13 |
| [0006](0006-modelo-de-dados-evolutivo.md) | Modelo de dados evolutivo (`PRESERVAR/MODERNIZAR/REESTRUTURAR/NÃO TRANSPORTAR`) | **Aceita** | 2026-08-13 |

Obs.: o arquivo da ADR-0004 mantém o nome original (`0004-encoding-latin1-na-primeira-migracao.md`) para preservar links; o conteúdo registra a decisão vigente (UTF-8) e o histórico da substituição.

## Modelo

```markdown
# ADR-NNNN — Título
- Status / Data / Decisores
## Contexto
## Decisão
## Consequências (positivas, negativas, riscos)
## Alternativas consideradas
## Rollback
```
