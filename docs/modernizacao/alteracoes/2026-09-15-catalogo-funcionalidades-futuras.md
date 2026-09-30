# [2026-09-15] Catálogo de Funcionalidades Futuras do OpenGSAN

- **Motivo**: o GSAN legado contém funcionalidades que **não pertencem ao núcleo comercial** e que o OpenGSAN pode precisar oferecer. O objetivo é **descobrir e classificar**, não incorporar: separar o que é capacidade genérica de saneamento do que é customização de uma companhia.
- **Método**: verificação de continuidade primeiro; depois **reuso** do inventário de banco e dos mapas funcionais já concluídos (nenhum foi refeito), com verificação dirigida em código apenas onde o inventário era ambíguo. Classificação por natureza, **maturidade da evidência** e horizonte.
- **Testes**: n/a (documental) · **Risco**: baixo · **Rollback**: `git revert` do commit · **Migration**: nenhuma.

## 0. Verificação de continuidade (obrigatória)

| Verificação | Resultado |
| ----------- | --------- |
| HEAD real | `73577c4` — OpenGSAN + Visão Conceitual; local = remoto; árvore limpa |
| Commits posteriores ao estado assumido no roteiro | Nenhum |
| `modulos/funcionalidades-futuras.md` já existente | **Não existia** |
| Atividade realmente pendente | **Catálogo de funcionalidades futuras** — confirmada (item 1 do backlog) |

## 1. Regra que governou o documento

🔴 **EXISTE NO `gsan_comercial` ≠ DEVE EXISTIR NO OpenGSAN.**

Consequência prática, aplicada em todos os itens: cada capacidade declara **de onde vem a evidência** e **quanto dela foi realmente compreendida**. Três níveis:

| Maturidade | Significado | Qtd |
| ---------- | ----------- | --: |
| **COMPROVADA** | Comportamento observado em código e/ou estrutura, com fluxo compreensível | 11 |
| **PARCIALMENTE COMPREENDIDA** | Existe e funciona, mas partes do fluxo não foram verificadas | 10 |
| **APENAS EVIDÊNCIA** | ⚠️ Há estrutura, **não há comportamento observável** nesta branch | 5 |

🔴 **"Tem tabela" não foi aceito como prova.** Duas áreas inteiras ficaram em `APENAS EVIDÊNCIA` por causa disso (fiscal e SPED), e é a decisão mais importante do documento: promovê-las a módulo por dedução criaria um módulo baseado em nada observável.

## 2. Resultado

`docs/modernizacao/modulos/funcionalidades-futuras.md` — **27 seções, 26 capacidades**.

| Natureza | Qtd |
| -------- | --: |
| CORE FUTURO | 11 |
| MÓDULO OPCIONAL | 7 |
| INTEGRAÇÃO | 5 |
| EXIGE APROFUNDAMENTO | 2 |
| EXTENSÃO DE COMPANHIA | 1 |

Horizonte preliminar: **H1 = 9 · H2 = 11 · H3 = 5 · ESPECÍFICA = 1**. ⚠️ Horizonte **não é ordem de implementação** — é proximidade ao núcleo. A ordem sai da próxima atividade.

🟢 **Os três eixos somam 26 e foram conferidos por script contra a tabela do §4** (ver §4.1 deste registro).

## 3. Os três achados que mudam o desenho

### 3.1 🔴 O portal de autoatendimento não tem dono

🟢 **47 classes em `gcom.gui.portal`**: 2ª via, extrato de débitos, parcelamento online, certidões, solicitação de serviços, consulta de canais/lojas, estrutura tarifária, cadastro de login do cliente, conta em braile.

⚠️ **Nenhum dos dez mapas funcionais cobriu isso** — não por descuido de um mapa específico, mas porque **nenhum módulo é seu dono**: o portal atravessa Faturamento (2ª via), Cobrança (parcelamento, certidão), Atendimento (solicitação) e Cadastro (dados do imóvel).

🔵 Consequências registradas, nenhuma decidida aqui:
- É **candidato a capacidade própria** ("canal digital do cliente"), com o contra-argumento honesto de que pode ser apresentação sobre capacidades existentes.
- Depende da **identidade do cliente final** — modelo distinto do usuário interno do RBAC, que a Visão Conceitual tratou como identidade de plataforma.
- ⚠️ **Depende da ADR-0007** (arquitetura de interface), que já estava pendente e agora tem uma entrada nova a considerar.

### 3.2 ⚠️ O fiscal é o maior desconhecido

🟢 Schema `fiscal` com **14 tabelas**; 🟢 SPED presente como `integracao.sped_documento` + `sp1_gerar_integracao_sped`. 🟢 **Zero classes Java correspondentes nesta branch** — o SPED está implementado **no banco**.

Ambos ficaram `APENAS EVIDÊNCIA`. O documento registra explicitamente o risco de tratar schema como funcionalidade, e a dependência que impede pular etapas: **SPED → documento fiscal → documento comercial**.

### 3.3 PIX é o mais urgente e o menos pronto

🟢 O que existe é `GeradorQrCodePIX` (QR estático, chave em código — divergência D-08) e tabelas fora das migrations oficiais. A **capacidade** é CORE FUTURO H1; **esta implementação** está na lista de não candidatos.

## 4. Correção de método aplicada durante o levantamento

⚠️ **Falsos positivos identificados e descartados**, registrados porque a contagem por busca textual é falível:

| Busca ingênua | O que realmente apareceu | Tratamento |
| ------------- | ------------------------ | ---------- |
| `nota fiscal` | **Nota fiscal de aquisição de hidrômetro** — dado de compra do equipamento | Excluído do fiscal; registrado em §22 para evitar recorrência |
| `gis` | Casava com `registro`, `regis…` | Substituído por padrões precisos (`ProcessarRequisicaoGisAction`, `GisHelper`) |

🔵 Mesma lição já registrada em [`procedencia.md §5`](../procedencia.md): toda afirmação de existência declara escopo, comando e resultado.

## 4.1 🔴 Erro de contagem detectado **antes** de publicar

⚠️ A primeira redação do §3 do catálogo trazia totais **divergentes da própria tabela do §4**, nos três eixos:

| Eixo | Publicado na 1ª redação | Real (conferido por script) |
| ---- | ----------------------- | --------------------------- |
| Natureza | 8 core · 7 opcional · 6 integração · 3 extensão · 2 aprofundamento | **11 core · 7 opcional · 5 integração · 2 aprofundamento · 1 extensão** |
| Maturidade | 15 · 7 · 4 | **11 · 10 · 5** |
| Horizonte | 9 · 9 · 5 · 3 | **9 · 11 · 5 · 1** |

🟢 **Causa**: os totais foram escritos por leitura, não por contagem — o mesmo defeito que produziu os números errados de [`estruturas-centrais.md`](../compatibilidade/estruturas-centrais.md) na 15ª execução. A diferença é que desta vez a conferência foi feita **antes do commit**, pelo mesmo método que expôs o erro anterior: script sobre a tabela.

⚠️ **Duas correções de conteúdo, não só de número**, saíram da conferência:

1. 🔴 **Fiscal e SPED deixaram de ser `MÓDULO OPCIONAL` e passaram a `EXIGE APROFUNDAMENTO`.** Chamar de "opcional" afirma que o núcleo passa sem a capacidade — e isso **depende do comportamento que não foi observado**. A tabela contradizia o §20, que classifica Fiscal como candidato cuja decisão *depende de esclarecer o comportamento*. Justificativa acrescentada no §6.3 e no §7.
2. A lista `ESPECÍFICA` do §24 misturava **capacidades catalogadas** com **instâncias do §21** (variantes de cálculo, campos institucionais), que não são capacidades. Corrigida para 1, com a distinção explicitada.

🔵 **Lição registrada**: em documento cujo valor está na classificação, **o resumo não pode ser escrito à mão** — ou ele é derivado da tabela, ou ele mente. A nota de conferência ficou no próprio §3 para que a próxima revisão saiba que o número foi verificado, e como.

## 5. O que mais foi registrado

- **6 padrões transversais (T1–T6)** — entre eles, "evidência anexada a objeto de negócio" (o mesmo problema resolvido 4+ vezes no legado) e "campanha/comando em massa", que 🔵 **o GSAN já resolveu bem** na Cobrança e reaproveitou em recadastramento e negativação.
- **4 candidatos a novos módulos** — Fiscal, Analytics, GIS, Canal digital. ⚠️ **Marcação, não criação**: cada um traz contra-argumento e condição de decisão.
- **8 especificidades de companhia remapeadas** para capacidade genérica (programas sociais nomeados, variantes de faixa, DV específico…). 🔵 O padrão é consistente: quase toda "customização" é **instância de algo genérico que o GSAN já tinha** — o erro não foi criar a necessidade, foi nomeá-la no núcleo.
- **6 não candidatos** — applet de impressão térmica, atendimento manual, códigos de exibição de RA, gerador de QR PIX com segredo, "nota fiscal" de hidrômetro, tabelas de backup.
- **9 lacunas e dúvidas**, incluindo ❔ simulação hidráulica: 🟢 **nenhuma evidência no legado** — permanece visão futura já estabelecida, fora deste catálogo baseado em evidência.

## 6. Atualizações de controle

| Documento | O que mudou |
| --------- | ----------- |
| `MODERNIZACAO_GSAN.md` | 17ª execução registrada; artefato acrescentado à lista de concluídos; backlog renumerado — **a próxima atividade passa a ser o refinamento das dependências**; riscos 3, 4 e 7 atualizados e **risco 10 criado** (deduzir comportamento a partir de estrutura) |
| `docs/modernizacao/README.md` | Documento indexado; pasta `modulos/` deixa de listá-lo como pendente |
| `docs/modernizacao/modulos/README.md` | Nota de que a pasta contém o catálogo, que **não** é um módulo, e a pergunta aberta sobre o portal |
| `alteracoes/README.md` | Esta entrada |
| `procedencia.md` | **Regra permanente 6** criada: total de tabela classificatória é derivado por script, nunca escrito à mão (ver §4.1) |

⚠️ **Correção de consistência no mesmo commit**: a entrada da **Visão Conceitual Alvo (16ª execução) faltava na lista de artefatos concluídos** do `MODERNIZACAO_GSAN.md` — a execução foi registrada no histórico, mas não no inventário. Acrescentada retroativamente, com a omissão declarada na própria entrada. Os riscos 3 e 4 também continuavam redigidos sob a premissa de migração, revogada em 2026-09-15; foram reescritos — o risco 3 **não foi apagado**, foi reinterpretado como risco de **evidência** (o que se observa em uma instalação pode ser a customização dela, não o GSAN).

## 7. Impacto

- **Criado**: `modulos/funcionalidades-futuras.md`.
- **Atualizados**: `MODERNIZACAO_GSAN.md`, `docs/modernizacao/README.md`, `docs/modernizacao/modulos/README.md`, `alteracoes/README.md`, `procedencia.md`.
- **Não alterados**: os dez mapas funcionais, o mapa de domínio, a visão conceitual, a análise de compatibilidade e as ADRs — ⚠️ **nenhuma classificação anterior foi revista**; o catálogo trata de capacidades futuras, não de estruturas existentes.
- **Nenhuma alteração de código, banco ou infraestrutura.** Nenhum schema, migration, entidade, API ou módulo criado. **Nenhuma prioridade com data.** ADR-0007 continua pendente e D-17 continua proposta.

## 8. Próxima atividade

**Refinamento das Dependências e Ordem de Implementação** — combinar mapa de domínio (ownership, fronteiras, 7 ciclos), Visão Conceitual, compatibilidade das estruturas e este catálogo para definir a sequência mais segura de construção, registrando o motivo de qualquer mudança de ordem em `modulos/README.md`.
