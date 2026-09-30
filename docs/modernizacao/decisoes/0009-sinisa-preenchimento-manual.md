# ADR-0009 — SINISA: preenchimento manual por padrão; automação só por mapeamento configurado pela companhia, desligada por padrão

- **Status: Aceita** (decisão do responsável do projeto) · Data: 2026-09-29 · Adendo pós-Fase 0 — refinamento arquitetural antes da Fase 1

## Contexto

A auditoria final da Fase 0 reconheceu o SINISA como obrigação anual — condição de acesso a recursos federais — e concluiu, corretamente, que **não é BI**: exige dado primário, validação, responsável, submissão e histórico do que foi prestado. Mas registrou um caminho: dados nos donos, **consolidação no Analytics**, **submissão por Integrações** ([`auditoria-final-fase0.md §12`](../auditoria/auditoria-final-fase0.md#12-sinisa)). Implícita nesse caminho está a premissa de que uma métrica interna pode **produzir** uma informação do SINISA.

Essa premissa é perigosa, pela natureza do que se declara ([`regulatorio/sinisa.md §1–§2`](../regulatorio/sinisa.md)):

1. **Divergência semântica potencial GSAN/OpenGSAN × SINISA.** Cada informação do SINISA tem definição própria — ressalvas, inclusões, exclusões, critério e ponto de medição, período, unidade, recorte. *"Volume produzido"* no OpenGSAN e *"volume produzido"* no glossário podem divergir por água bruta × tratada, produzido × disponibilizado, perdas e volumes de processo, importação e exportação entre sistemas, competência, estimativa e exclusões do ciclo.
2. **O glossário muda por ciclo** — publicado por ciclo e por componente. Uma equivalência verdadeira num ano pode ser falsa no seguinte, sob o **mesmo código**.
3. **O contexto muda por companhia** — prestador regional ou local, sistemas integrados, medição disponível. Uma regra que vale numa instalação não vale em outra; o OpenGSAN é software livre para muitas.
4. **O custo do erro é regulatório e não é do software.** Um valor preenchido por equivalência presumida vira **declaração da companhia** a um sistema federal que condiciona recursos, é acompanhado pelo regulador e emite certidão. O erro é silencioso: o número *parece* certo.
5. **Valor pré-preenchido ancora a revisão.** Um número já presente tende a ser aceito; a revisão humana degenera em confirmação.
6. Nenhum mecanismo oficial de importação por arquivo foi encontrado nas fontes consultadas; o preenchimento conhecido é o formulário online.

## Decisão

1. **O SINISA é manual por padrão e, na versão inicial, exclusivamente manual.** Todo valor é **digitado pelo usuário**, com fonte, memória de cálculo e evidência. A V1 não calcula, não preenche, não pré-seleciona, não infere e não sugere número.
2. **Não existe mapeamento universal.** O produto não relaciona código SINISA a métrica interna, não distribui mapeamentos e **nunca** infere relação por semelhança de nome, heurística ou modelo. **Métrica OpenGSAN ≠ informação SINISA**, mesmo quando parecem equivalentes.
3. **Dados internos são referência, nunca valor**: podem aparecer ao lado do campo, rotulados `REFERÊNCIA — NÃO É VALOR SINISA`; a associação campo ↔ referência é configurada pela companhia ou escolhida pelo usuário, nunca pelo produto.
4. **Automação futura é configurável e é decisão da companhia**: só um **mapeamento** criado, validado e aprovado pela instituição — campo e versão do glossário, fonte interna, regra, filtros, agregação, responsável, aprovação, vigência, status e histórico — pode produzir valor, nos modos futuros **SUGERIDO** ou **AUTOMÁTICO**.
5. **Automação sempre desativada por padrão**: `autoPreenchimento = false`; mapeamento nasce **Rascunho**; nenhuma atualização de versão, migration ou importação ativa nada.
6. **Mudança de glossário exige revalidação**: nova versão do glossário, novo ciclo ou mudança de definição levam todo mapeamento afetado a **REVALIDAÇÃO NECESSÁRIA** — a única transição automática, e no sentido da segurança.
7. **A declaração é versionada e imutável depois de submetida**; correção é **retificação**, que preserva a declaração anterior, o valor novo, o motivo, o responsável e a data.
8. **Submissão não automatizada por padrão**; arquivo oficial, se existir, entra por **adapter** acionado por pessoa, e o leiaute nunca entra no domínio.
9. **O SINISA não depende do Analytics.** O Workspace funciona sem nenhuma métrica; o Gerencial & Analytics oferece referências e mostra o SINISA só como **progresso**.

**Esta ADR não decide**: schema, motor de validação, formato de exportação, lista de campos ou códigos, segregação de funções além do padrão proposto, nem se o princípio se estende ao SISAGUA e ao regulador local.

## Consequências

- (+) Nenhuma declaração regulatória nasce de equivalência presumida; o erro possível passa a ser **humano, visível e rastreável** — com fonte, evidência e responsável.
- (+) O Workspace pode existir **cedo**: não espera Analytics nem os módulos de negócio.
- (+) Mudança de glossário deixa de ser risco silencioso — vira evento que exige revalidação.
- (+) A companhia que quiser automatizar pode, **por decisão própria e auditada**, sem que o produto assuma a responsabilidade semântica.
- (−) Esforço manual a cada ciclo — transcrição, fonte, evidência.
- (−) O erro humano continua possível — mitigado por validação formal, referências rotuladas, revisão e aprovação, sem ancoragem por número pré-preenchido.
- ⚠️ Risco: pressão por "automatizar logo". A resposta está na própria decisão — o caminho existe, mas passa por mapeamento validado, versionado e desligado por padrão.

## Alternativas consideradas

| Alternativa | Motivo da rejeição |
| ----------- | ------------------ |
| **Mapeamento universal no produto** — código SINISA → métrica interna | Presume equivalência semântica que depende do glossário do ciclo e do contexto de cada companhia; faria do software o autor da declaração regulatória |
| **Consolidação no Analytics + submissão por Integrações** — a premissa anterior | Mesma presunção, e ainda faz o SINISA esperar o Analytics completo; confunde métrica gerencial com informação oficial |
| **Sugestão automática por padrão, com revisão humana** | Ancoragem: o número presente tende a ser aceito, e a revisão vira carimbo; mantida só como modo **SUGERIDO** futuro, por mapeamento da companhia |
| **Mapeamento por semelhança de nome, heurística ou modelo** | É exatamente o erro a evitar — a semântica prevalece sobre o nome |
| **Sem Workspace** — SINISA fora do OpenGSAN, em planilhas | Perde fonte, evidência, responsável, versão, retificação e histórico do que foi prestado — as exigências que a auditoria identificou |
| **Submissão automática ao sistema oficial** | Nenhum mecanismo oficial por arquivo encontrado; exigiria guardar credencial do prestador; a submissão é ato de responsabilidade da companhia |

## Rollback

Decisão conceitual, sem código. Revertê-la exige nova ADR que diga **quem é o autor semântico** da declaração regulatória e **como a equivalência é validada a cada versão do glossário** — e que reavalie as consequências para o Workspace SINISA, o catálogo de métricas e os cenários CEN-REG-001 a 005.
