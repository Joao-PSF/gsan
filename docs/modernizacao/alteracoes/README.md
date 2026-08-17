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
| 2026-08-14 | [Mapa funcional do Cadastro](2026-08-14-mapa-funcional-cadastro.md) — `modulos/cadastro.md` criado; dúvidas 1, 2 e 6 do glossário resolvidas; próxima atividade: micromedição | Baixo |
| 2026-08-14 | [Mapa funcional da Micromedição](2026-08-14-mapa-funcional-micromedicao.md) — `modulos/micromedicao.md` criado; precedência de rotas resolvida; 12 cenários de caracterização; próxima atividade: faturamento | Baixo |
| 2026-08-14 | [Mapa funcional do Faturamento](2026-08-14-mapa-funcional-faturamento.md) — `modulos/faturamento.md` criado; ContaGeral/retificação/cancelamento/tarifa/esgoto/consumo resolvidos; 13 golden masters; próxima atividade: cobrança | Baixo |
| 2026-08-14 | [Mapa funcional da Cobrança](2026-08-14-mapa-funcional-cobranca.md) — `modulos/cobranca.md` criado; identidade da dívida, ações e parcelamento compreendidos; 14 cenários; próxima atividade: arrecadação | Baixo |
| 2026-08-14 | [Mapa funcional da Arrecadação](2026-08-14-mapa-funcional-arrecadacao.md) — `modulos/arrecadacao.md` criado; recepção × classificação, situações do pagamento, conciliação e encerramento contábil; correções de premissa (409, documento de cobrança); achado de chave PIX hard-coded; próxima atividade: atendimento | Baixo |
| 2026-08-14 | [Ajustes pós-revisão do Faturamento](2026-08-14-ajustes-pos-revisao-faturamento.md) — três formulações corrigidas (identidade/linhagem da Conta, absolutismo tarifário, nível de certeza do fluxo) e propagadas a Cobrança/Arrecadação/glossário; sem reanálise | Baixo |
| 2026-08-14 | [Mapa funcional do Atendimento](2026-08-14-mapa-funcional-atendimento.md) — `modulos/atendimento.md` criado; RA×OS, especificação paramétrica e mecanismo do efeito cadastral esclarecidos; correção residual de redação no controle; próxima atividade: segurança | Baixo |
| 2026-08-14 | [Ajustes de precisão no Atendimento](2026-08-14-ajustes-precisao-atendimento.md) — OS sem RA vira dúvida de persistência; variabilidade por companhia calibrada; cenários renomeados; propagações corrigidas | Baixo |
| 2026-08-14 | [Mapa funcional da Segurança](2026-08-14-mapa-funcional-seguranca.md) — `modulos/seguranca.md` criado (complementa o diagnóstico preliminar); filtro central de autorização, união de grupos, permissões especiais, abrangência com aplicação manual, auditoria em dois níveis; fronteira do Atendimento resolvida; próxima atividade: batch | Baixo |
| — | Nenhuma alteração de código/banco realizada até o momento (Fase 0 = análise e documentação) | — |
