# ADR-0006 — Modelo de dados evolutivo com classificação de estruturas

- Status: **Aceita** (diretriz do responsável do projeto) · Data: 2026-08-13

## Contexto
A premissa inicial de "mesmo schema do legado durante toda a modernização" foi corrigida: o SISAN tem banco próprio (ADR-0004), mas é evolução compatível do GSAN (ADR-0005). É preciso uma regra objetiva para decidir, estrutura a estrutura, o que levar adiante e como — sem redesenho por estética e sem preservar estruturas ruins por apego ao legado.

## Decisão
Toda estrutura importante do GSAN analisada para o SISAN recebe uma classificação registrada:

| Classificação | Significado |
| ------------- | ----------- |
| `PRESERVAR` | Estrutura adequada; mantida (ou com ajustes mínimos) — preferida quando reduz risco, facilita migração, preserva significado e evita transformação desnecessária de dados |
| `MODERNIZAR` | Conceito mantido; forma atualizada de modo pequeno (tipos, nomes impronunciáveis, constraints ausentes) com transformação simples e mapeamento direto |
| `REESTRUTURAR` | Problemas relevantes justificam redesenho; exige registro de benefício, impacto na migração, transformação necessária, compatibilidade semântica e validação de dados |
| `NÃO TRANSPORTAR` | Não vai ao SISAN (backups/temporários, mecanismos obsoletos, redundâncias) — listada para o migrador ignorar/relatar |

Regras: (1) a análise parte do **conceito** de negócio, não da tabela (`GSAN → conceito → qualidade da estrutura → impacto de mudança → facilidade de migração → decisão preliminar`); (2) nesta etapa, analisar apenas estruturas centrais — não tabela a tabela de mais de mil tabelas; (3) toda classificação `REESTRUTURAR` registra a transformação GSAN→SISAN correspondente; (4) decisões ficam no documento de análise de compatibilidade, revisáveis com nova evidência.

## Consequências
- (+) Critério único e auditável; equilíbrio entre modernização e migrabilidade; evita os dois extremos (cópia cega × redesenho total).
- (−) Custo de análise e registro por estrutura central; decisões preliminares poderão ser revistas quando os módulos forem aprofundados.

## Alternativas consideradas
Mesmo schema do legado (rejeitada: fossiliza problemas e não existe produção que o exija); redesenho livre por módulo (rejeitada: quebraria a migrabilidade exigida pela ADR-0005).

## Rollback
Classificações são revisáveis por documento; a regra em si só muda por nova ADR.
