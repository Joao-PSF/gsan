# Cenários Críticos — Prestação de Informações (SINISA)

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md). Criado no **adendo pós-Fase 0** (2026-09-29) — [registro](../../alteracoes/2026-09-29-adendo-pos-fase0.md).
>
> 🔴 **Requisitos nativos do OpenGSAN — oráculo N.** O GSAN público não presta informações ao SINISA. O resultado esperado vem da [ADR-0009](../../decisoes/0009-sinisa-preenchimento-manual.md) e de [`regulatorio/sinisa.md`](../../regulatorio/sinisa.md). ⚠️ Ciclos, códigos, definições e valores são **sintéticos** (perfil SIN-01) — nenhum código oficial é afirmado.

🔵 **Leitura da área**: três cenários guardam a **V1** — declaração manual rastreável, glossário versionado, nenhum valor nascido de dado interno. Dois são **condicionados à automação futura**: não se aplicam à V1 e são **pré-requisito** para habilitar qualquer mapeamento.

---

## CEN-REG-001 — Declaração manual rastreável e retificação sem sobrescrever

- **Criticidade**: P0
- **Etapa OpenGSAN**: R — trilha regulatória (Workspace SINISA)
- **Conceitos relacionados**: declaração regulatória versionada (requisito nativo) · evidência de classe Regulatório · segregação de funções
- **Objetivo**: verificar que todo valor é **informado por pessoa**, com fonte, evidência e papéis registrados, e que a correção depois de submetido é **retificação** que preserva a declaração anterior
- **Pré-condições**: SIN-01 (ciclo N carregado); USR-12 (informante, revisor e aprovador; um usuário acumulando dois papéis); segregação de funções no padrão
- **Entrada**: V1 — informar → validar → aprovar → submeter, com comprovante; V2 — aprovar valor **sem fonte**; V3 — o mesmo usuário informa e aprova o mesmo valor; V4 — editar diretamente um valor **submetido**; V5 — retificação pedida pelo regulador na validação da versão preliminar
- **Operação GSAN**: não aplicável — sem prestação ao SINISA no GSAN público
- **Operação conceitual OpenGSAN**: declarar, validar, aprovar, submeter e retificar
- **Observações semânticas**: versões do valor · autor e papel em cada versão · fonte, memória de cálculo e evidência · ciclo e versão do glossário · conjunto submetido congelado · comprovante · motivo e origem da retificação
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — cada passo registrado com quem, quando, ciclo, glossário e evidência; o conjunto submetido fica **imutável**. V2 — **recusado**: sem fonte não há aprovação. V3 — **recusado** sob a segregação padrão; permitido só com configuração explícita da companhia, registrada. V4 — **recusado**: depois de submetido, só retificação. V5 — nova versão com motivo, origem do pedido, responsável e data; a declaração anterior e seu comprovante permanecem **intactos e consultáveis**; a retificação usa o glossário **do ciclo N**
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: identificadores, horários e valores sintéticos
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado da ADR-0009 (itens 1 e 7) e de [`sinisa.md`](../../regulatorio/sinisa.md) §8, §9, §13, §15
- **Gate que este cenário protege**: 1º ciclo SINISA — *declaração manual rastreável antes do primeiro ciclo declarado pelo OpenGSAN*
- **Evidência**: [`sinisa.md`](../../regulatorio/sinisa.md) §1 (regulador pede correção; publicação retificável), §8, §9, §13, §15; [ADR-0009](../../decisoes/0009-sinisa-preenchimento-manual.md)

---

## CEN-REG-002 — Mudança de glossário preserva a declaração anterior

- **Criticidade**: P0
- **Etapa OpenGSAN**: R — trilha regulatória (Workspace SINISA)
- **Conceitos relacionados**: ciclo SINISA e glossário versionado (requisito nativo) · identidade *código + versão do glossário*
- **Objetivo**: verificar que um glossário novo **não altera** o que foi declarado sob o anterior, que o mesmo código em versões distintas é tratado como **duas definições**, e que nada do ciclo anterior é copiado para o novo
- **Pré-condições**: SIN-01 — ciclo N declarado e submetido sob o glossário vN; ciclo N+1 carregado com vN+1: campo X com definição **alterada sob o mesmo código**, Y inalterado, Z removido, W novo; referência de apoio configurada para X
- **Entrada**: V1 — abrir o ciclo N+1; V2 — consultar a declaração do ciclo N; V3 — comparar X e Y entre os ciclos; V4 — retificar o ciclo N depois da carga de vN+1
- **Operação GSAN**: não aplicável — sem prestação ao SINISA no GSAN público
- **Operação conceitual OpenGSAN**: carregar ciclo novo; declarar; comparar; retificar
- **Observações semânticas**: versão do glossário de cada declaração · valores do ciclo N+1 na abertura · comparação de X e de Y · estado da referência de apoio de X · glossário usado na retificação do ciclo N · presença de Z e de W
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — todos os campos de N+1 **vazios** — nada copiado; W presente; Z ausente de N+1. V2 — declaração de N **intacta**, presa a vN, com Z incluído. V3 — Y comparável; X marcado *definição mudou — comparação não aplicável*; referência de apoio de X *a revisar*. V4 — retificação sob **vN**, não sob vN+1
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: identificadores e textos sintéticos
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado da ADR-0009 (itens 6 e 7) e de [`sinisa.md`](../../regulatorio/sinisa.md) §5, §6, §9, §15, §16.4
- **Gate que este cenário protege**: 1º ciclo SINISA — *glossário versionado antes do primeiro ciclo declarado pelo OpenGSAN*
- **Evidência**: [`sinisa.md`](../../regulatorio/sinisa.md) §1 (glossários publicados por ciclo e componente), §5, §6, §16.4

---

## CEN-REG-003 — Métrica interna não vira valor SINISA implicitamente

- **Criticidade**: P0
- **Etapa OpenGSAN**: R — trilha regulatória (Workspace SINISA)
- **Conceitos relacionados**: métrica interna × informação SINISA (requisito nativo) · referência rotulada
- **Objetivo**: verificar que, na V1, **nenhum** valor SINISA nasce de dado interno — o campo começa vazio, a referência aparece rotulada e fora do campo, e nome igual não cria vínculo
- **Pré-condições**: SIN-01; MET-01 (métrica com nome **idêntico** ao do campo X e valor no período); referência de apoio configurada pela companhia para o campo Y apontando a MET-01; **nenhum** mapeamento
- **Entrada**: V1 — abrir o campo Y; V2 — abrir o campo X; V3 — abrir um campo de escolha e um campo declarado no ciclo anterior; V4 — painel do Gerencial; V5 — exportar a declaração com Y ainda pendente
- **Operação GSAN**: não aplicável — sem prestação ao SINISA no GSAN público
- **Operação conceitual OpenGSAN**: preencher campo SINISA; consultar referência; acompanhar progresso; exportar
- **Observações semânticas**: valor do campo · presença e posição da referência · rótulo `REFERÊNCIA — NÃO É VALOR SINISA` · ações disponíveis · vínculo criado por nome · números presentes no painel e na exportação
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — campo **vazio**; referência exibida **ao lado**, rotulada, com código, versão, período e recorte da métrica; **nenhuma ação** transfere o número. V2 — **nada** exibido: nome igual não cria associação. V3 — nenhuma opção pré-selecionada; o valor do ciclo anterior **não** é copiado. V4 — só progresso; nenhum número apresentado como valor SINISA. V5 — Y sai **pendente**; nenhum valor de métrica aparece na exportação
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: identificadores e valores sintéticos
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado da ADR-0009 (itens 1–3 e 9) e de [`sinisa.md`](../../regulatorio/sinisa.md) §3, §10–§12
- **Gate que este cenário protege**: 1º ciclo SINISA — *nenhum valor declarado nasce de dado interno*
- **Evidência**: [`sinisa.md`](../../regulatorio/sinisa.md) §2, §3, §10, §11; [catálogo de métricas](../../analytics/catalogo-de-metricas.md) §4 (regra 7), §5; [`gerencial-analytics.md`](../../analytics/gerencial-analytics.md) §9.3

---

## CEN-REG-004 — Mapeamento futuro nunca ativado automaticamente

- **Criticidade**: P0
- **Etapa OpenGSAN**: R — trilha regulatória; ⚠️ **condicionado à automação futura** — fora da ordem inicial
- **Conceitos relacionados**: mapeamento SINISA configurado pela companhia (requisito nativo futuro) · `autoPreenchimento`
- **Objetivo**: verificar que **nenhuma via** — criação, importação, atualização de versão ou mudança de glossário — ativa mapeamento ou preenchimento sem decisão da instituição, e que mudança de glossário leva à revalidação
- **Pré-condições**: capacidade de mapeamento implementada; SIN-01; MET-01; USR-12 com papel de responsável pela configuração
- **Entrada**: V1 — criar mapeamento; V2 — importar mapeamento de outra instalação; V3 — atualizar a versão do OpenGSAN com mapeamentos existentes; V4 — carregar o glossário vN+1 com mapeamento ATIVO para o campo X; V5 — pedir mapeamento por semelhança de nome
- **Operação GSAN**: não aplicável — sem prestação ao SINISA no GSAN público
- **Operação conceitual OpenGSAN**: configurar, validar, ativar e revalidar mapeamento
- **Observações semânticas**: estado inicial · transições e autor de cada uma · `autoPreenchimento` e modo de cada mapeamento antes e depois da atualização · valores produzidos · declarações anteriores
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — nasce **RASCUNHO**; só chega a ATIVO passando por EM VALIDAÇÃO e aprovação registrada. V2 — entra como **RASCUNHO**. V3 — `autoPreenchimento` e modos **inalterados**; nenhum mapeamento muda de estado. V4 — o mapeamento de X vai para **REVALIDAÇÃO NECESSÁRIA** e **não produz valor**; declarações do ciclo N intactas. V5 — não oferecido: não existe mapeamento por semelhança
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: identificadores sintéticos
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado da ADR-0009 (itens 4–6) e de [`sinisa.md`](../../regulatorio/sinisa.md) §16
- **Gate que este cenário protege**: automação SINISA — *pré-requisito para habilitar qualquer mapeamento*
- **Evidência**: [`sinisa.md`](../../regulatorio/sinisa.md) §16.1–§16.5; [ADR-0009](../../decisoes/0009-sinisa-preenchimento-manual.md)

---

## CEN-REG-005 — Override futuro auditado

- **Criticidade**: P1
- **Etapa OpenGSAN**: R — trilha regulatória; ⚠️ **condicionado à automação futura** — fora da ordem inicial
- **Conceitos relacionados**: modos SUGERIDO e AUTOMÁTICO (requisito nativo futuro) · override
- **Objetivo**: verificar que aplicar ou alterar um valor vindo de mapeamento deixa **rastro completo** e não transfere a responsabilidade da declaração ao sistema
- **Pré-condições**: mapeamento ATIVO e compatível com o glossário vigente para o campo Y, em modo SUGERIDO; outro campo com mapeamento em modo AUTOMÁTICO
- **Entrada**: V1 — aplicar o valor sugerido; V2 — aplicar e depois alterar; V3 — alterar sem justificativa; V4 — valor automático segue o fluxo
- **Operação GSAN**: não aplicável — sem prestação ao SINISA no GSAN público
- **Operação conceitual OpenGSAN**: aplicar sugestão; sobrescrever; revisar; aprovar
- **Observações semânticas**: origem do valor (mapeamento e versão) · informante registrado · valor calculado × valor final · justificativa · estado do mapeamento após o override · estados do fluxo
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — valor com origem *sugestão* (mapeamento e versão); o usuário é o **informante**. V2 — override registrado: valor calculado, regra e versão, valor final, justificativa, usuário e momento; o mapeamento **não muda**. V3 — **recusado**. V4 — o valor automático entra como *informado*; a submissão **não** é automática (ADR-0009, item 8). ⚠️ Revisão e aprovação humanas mesmo no AUTOMÁTICO são **proposta** a confirmar quando a automação for especificada
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: identificadores, horários e valores sintéticos
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado da ADR-0009 (itens 4 e 8) e de [`sinisa.md`](../../regulatorio/sinisa.md) §16.3
- **Gate que este cenário protege**: automação SINISA — *override auditado antes de habilitar SUGERIDO ou AUTOMÁTICO*
- **Evidência**: [`sinisa.md`](../../regulatorio/sinisa.md) §16.3; [ADR-0009](../../decisoes/0009-sinisa-preenchimento-manual.md)
