# ADR-0004 — Manter LATIN1 na primeira migração de banco

- Status: Proposta · Data: 2026-08-13

## Contexto
`gsan_comercial` usa LATIN1; o legado compila e opera em ISO-8859-1 (JSPs, arquivos bancários posicionais, relatórios). A migração para PostgreSQL 18 já muda versão, collation provider e hardware. Converter para UTF-8 na mesma janela adicionaria mais uma variável a um passo de risco financeiro.

## Decisão
A primeira migração (Fase 8) mantém o banco em **LATIN1**. O sistema novo trabalha internamente em UTF-8 (JDBC converte via `client_encoding`) e valida desde o piloto que nenhum dado fora do LATIN1 seja aceito em campos persistidos. Conversão do banco para UTF-8 vira projeto posterior, quando o legado estiver desativado ou próximo disso.

## Consequências
- (+) Janela de migração menor e comparações antes/depois byte a byte; arquivos bancários/fiscais posicionais permanecem idênticos.
- (−) Caracteres fora do LATIN1 (ex.: emojis em campos de texto) continuam impossíveis; a conversão futura exigirá projeto próprio com revalidação de ordenações.

## Alternativas consideradas
Converter para UTF-8 na mesma janela (rejeitada por acúmulo de risco: ordenação, tamanho de campos, arquivos posicionais e comparação de resultados deixariam de ser diretos).

## Rollback
Nenhum — a decisão preserva o estado atual; a conversão futura terá ADR própria.
