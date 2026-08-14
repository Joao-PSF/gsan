# Registro de Alterações da Modernização

Toda alteração relevante (código, banco, infraestrutura, segurança) gera um registro aqui, **antes** do merge. Um arquivo por alteração: `AAAA-MM-DD-descricao-curta.md`.

## Modelo obrigatório

```markdown
# [data] Título da alteração
- **Motivo**:
- **Impacto**: (funcionalidades, módulos, integrações afetadas)
- **Dependências**:
- **Testes**: (quais provam equivalência/correção; onde estão)
- **Risco**: (baixo/médio/alto + descrição)
- **Rollback**: (procedimento concreto)
- **Migration**: (versão Flyway, se houver)
```

## Registros

| Data | Alteração | Risco |
| ---- | --------- | ----- |
| 2026-08-13 | [Revisão de premissas da Fase 0](2026-08-13-revisao-premissas-fase0.md) — sem produção neste projeto; SISAN como evolução compatível do GSAN; ADRs 0003–0006 decididas | Baixo |
| 2026-08-14 | [Glossário de domínio](2026-08-14-glossario-de-dominio.md) — 25 conceitos com evidências em `dominio/glossario.md`; item 1 do backlog concluído | Baixo |
| — | Nenhuma alteração de código/banco realizada até o momento (Fase 0 = análise e documentação) | — |
