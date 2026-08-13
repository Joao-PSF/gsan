# ADR-0004 — UTF-8 no SISAN; encoding de origem tratado pela migração

- Status: **Aceita** · Data: 2026-08-13
- Histórico: substitui a proposta anterior desta ADR ("manter LATIN1 na primeira migração"), formulada sob a premissa — corrigida em 2026-08-13 — de que existiria uma migração concreta de banco de produção neste projeto. Não existe produção aqui; o SISAN nasce com banco próprio.

## Contexto
O GSAN opera historicamente em LATIN1/ISO-8859-1 (banco, código, JSPs). O SISAN é um sistema novo em evolução compatível (ADR-0005), sem restrição herdada de encoding; UTF-8 é o padrão do ecossistema atual (Java, Spring, PostgreSQL, web). O ponto de contato com LATIN1 passa a ser exclusivamente a futura migração de instalações GSAN.

## Decisão
1. O SISAN usa **UTF-8** de ponta a ponta: banco PostgreSQL (encoding UTF-8, collation explícita e documentada na criação), código-fonte, templates, APIs e logs.
2. Exceção deliberada: arquivos de intercâmbio com layout posicional definido por terceiros (bancários/arrecadadores, fiscais) são gerados/lidos no encoding que o layout exigir, tratado na borda da integração.
3. A futura ferramenta de migração GSAN→SISAN **detecta o encoding da instalação de origem** (tipicamente LATIN1) e converte para UTF-8 com validação caso a caso: caracteres inválidos, tamanhos de campo (bytes × caracteres), ordenações e comparações.

## Consequências
- (+) Suporte pleno a caracteres; alinhamento com todo o ecossistema alvo; sem dívida de encoding no sistema novo.
- (−) A migração de bases LATIN1 tem uma etapa adicional de conversão validada; ordenações podem diferir das do GSAN de origem (collation diferente) — diferenças documentadas na validação da migração.

## Alternativas consideradas
Manter LATIN1 no SISAN para "igualar" o legado (rejeitada: propagaria uma limitação histórica a um sistema novo sem produção a preservar; a compatibilidade necessária é semântica, não de encoding).

## Rollback
Antes da primeira migration `V1`, trocar encoding não tem custo. Depois, conversão de banco — evitar; a decisão é estrutural.
