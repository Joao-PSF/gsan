# ADR-0005 — SISAN é modernização evolutiva e compatível do GSAN

- Status: **Aceita** (diretriz do responsável do projeto) · Data: 2026-08-13

## Contexto
O GSAN concentra décadas de conhecimento de gestão comercial de saneamento (conceitos, módulos, regras, fluxos, relatórios, processos, integrações). Instalações GSAN reais existem em companhias e divergem entre si (versões, customizações, DDL manual — comprovado pelo `gsan_comercial`). Este projeto não opera uma produção, mas companhias usuárias do GSAN deverão ter caminho viável para adotar o SISAN no futuro.

## Decisão
1. O SISAN **não** é um sistema criado do zero: é a modernização evolutiva do GSAN, aproveitando ao máximo conceitos, módulos, regras de negócio, fluxos, nomenclaturas relevantes, relacionamentos conceituais, relatórios, processos e regras comerciais consolidados.
2. Regra geral: **preservar quando adequado, modernizar quando necessário, redesenhar somente com justificativa**. Não recriar a roda.
3. **Facilidade de migração GSAN→SISAN é requisito arquitetural**: cada decisão estrutural do SISAN considera seu impacto sobre a futura migração; divergências relevantes registram mapeamento/transformação no documento de compatibilidade; o migrador seguirá o pipeline `identificação de versão/schema → análise de compatibilidade → mapeamento → transformações → validação → migração`.
4. O SISAN não assume schema único entre companhias — a análise de compatibilidade é por instalação.
5. O repositório `gsan` permanece como referência de comportamento, regras, entidades, fluxos, relatórios, batch e integrações; o `gsan_comercial` como fonte complementar de compatibilidade e descoberta funcional.

## Consequências
- (+) Reduz risco de perda de regras de negócio; encurta a curva de entendimento; cria caminho comercial/técnico para companhias GSAN; evita reinvenção.
- (−) Disciplina extra: cada mudança estrutural carrega o custo de registrar compatibilidade; tentações de redesenho "limpo" precisam ser justificadas (ADR-0006).

## Alternativas consideradas
Greenfield sem compromisso com o GSAN (rejeitada: descarta conhecimento consolidado e inviabiliza migração de companhias); port 1:1 do GSAN (rejeitada: perpetuaria dívidas estruturais e de segurança).

## Rollback
Diretriz de projeto — mudá-la exige nova ADR e revisão do plano.
