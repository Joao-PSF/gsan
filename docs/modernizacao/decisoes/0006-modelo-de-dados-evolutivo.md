# ADR-0006 — Modelo de dados evolutivo com classificação de estruturas

- **Status: Aceita** (diretriz do responsável do projeto) · Data: 2026-08-13 · **Calibrada em 2026-09-15**

> **Nota de calibração (2026-09-15)**: a ADR-0005 foi revisada — a migração de instalações GSAN saiu do escopo deste projeto. As **quatro classificações e o método permanecem válidos e as decisões já tomadas continuam valendo**; o que muda é o peso de um critério: onde se lia *"facilidade de migração"*, leia-se **"continuidade conceitual"**. ⚠️ Facilidade de migração **não é mais argumento** para preservar estrutura inadequada.

## Contexto
A premissa inicial de "mesmo schema do legado durante toda a modernização" foi corrigida: o OpenGSAN tem banco próprio (ADR-0004), mas é evolução compatível do GSAN (ADR-0005). É preciso uma regra objetiva para decidir, estrutura a estrutura, o que levar adiante e como — sem redesenho por estética e sem preservar estruturas ruins por apego ao legado.

## Decisão
Toda estrutura importante do GSAN analisada para o OpenGSAN recebe uma classificação registrada:

| Classificação | Significado |
| ------------- | ----------- |
| `PRESERVAR` | Estrutura adequada; mantida (ou com ajustes mínimos) — preferida quando reduz risco, preserva significado e a mudança não traria benefício suficiente |
| `MODERNIZAR` | Conceito mantido; forma atualizada de modo pequeno (tipos, nomes impronunciáveis, constraints ausentes) com transformação simples e mapeamento direto |
| `REESTRUTURAR` | Problemas relevantes justificam redesenho; exige registro de benefício, impacto na migração, transformação necessária, compatibilidade semântica e validação de dados |
| `NÃO TRANSPORTAR` | Não existe no OpenGSAN (backups/temporários, mecanismos obsoletos, redundâncias) — listada para o futuro migrador ignorar/relatar |

Regras: (1) a análise parte do **conceito** de negócio, não da tabela (`GSAN → conceito → qualidade da estrutura → impacto de mudança → continuidade conceitual → decisão preliminar`); (2) nesta etapa, analisar apenas estruturas centrais — não tabela a tabela de mais de mil tabelas; (3) toda classificação `REESTRUTURAR` registra **o problema, o benefício e a semântica a preservar** (a transformação de dados pertence ao projeto de migração, fora deste escopo); (4) decisões ficam no documento de análise de compatibilidade, revisáveis com nova evidência.

## Consequências
- (+) Critério único e auditável; equilíbrio entre modernização e migrabilidade; evita os dois extremos (cópia cega × redesenho total).
- (−) Custo de análise e registro por estrutura central; decisões preliminares poderão ser revistas quando os módulos forem aprofundados.

## Alternativas consideradas
Mesmo schema do legado (rejeitada: fossiliza problemas e não existe produção que o exija); redesenho livre sem critério (rejeitada: descartaria conhecimento funcional validado, contra a ADR-0005).

## Rollback
Classificações são revisáveis por documento; a regra em si só muda por nova ADR.
