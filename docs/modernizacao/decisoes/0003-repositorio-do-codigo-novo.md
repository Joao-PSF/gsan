# ADR-0003 — Código novo no repositório SISAN

- Status: **Aceita** (confirmada pelo responsável do projeto) · Data: 2026-08-13

## Contexto
Três repositórios existem: `gsan` (legado, ~2,39M LOC), `gsan-migracoes` (migrations) e `SISAN` (vazio, "Sistema Integrado de Gestão de Saneamento e Abastecimento"). O legado usa encoding ISO-8859-1, Ant e layout incompatível com um projeto Maven/Spring moderno.

## Decisão
O código do sistema modernizado nasce no repositório **SISAN** (Maven multi-módulo, UTF-8, CI/CD próprio). O repositório `gsan` permanece como legado em manutenção e recebe apenas correções e a documentação da modernização (`docs/modernizacao/`, que segue sendo a fonte de verdade documental). `gsan-migracoes` é substituído gradualmente pelo repositório de migrations Flyway (local a definir: dentro de SISAN em `db/migrations`).

## Consequências
- (+) Projeto novo limpo (sem herdar histórico de 2,39M LOC), pipelines independentes, sem risco de build cruzado com Ant.
- (−) Documentação em um repo e código novo em outro — mitigado por links e por replicar o sumário no README do SISAN quando o projeto nascer.

## Alternativas consideradas
Pasta `modern/` dentro do repo `gsan` (rejeitada: acopla pipelines e permissões, repo gigante); novo repositório dedicado além do SISAN (desnecessário: SISAN está vazio e nomeado para este fim).

## Rollback
Enquanto não houver código em produção, mover o projeto de repositório é barato; após produção, o repositório é definitivo.
