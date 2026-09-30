# [2026-09-15] Compatibilidade Conceitual GSAN → OpenGSAN

- **Motivo**: a Fase 0 já sabia *como o GSAN funciona*, *o que preservar*, *como o alvo se organiza*, *quais capacidades futuras existem* e *em que ordem construir*. Faltava uma resposta única e consultável para: **em que sentido o OpenGSAN continua sendo o GSAN — e onde escolhemos deliberadamente deixar de ser iguais?**
- **Método**: verificação de continuidade; correções pontuais de consistência; depois **reuso** das 64 decisões estruturais, das 16 divergências, do mapa de domínio e da visão conceitual. ⚠️ **Nenhum módulo reanalisado; nenhuma das 64 decisões reclassificada.**
- **Testes**: n/a (documental) · **Risco**: baixo · **Rollback**: `git revert` do commit · **Migration**: nenhuma.

## 0. Verificação de continuidade (obrigatória)

| Verificação | Resultado |
| ----------- | --------- |
| HEAD real | `7841224` — dependências e ordem de implementação; local = remoto; árvore limpa |
| Commits posteriores ao estado assumido no roteiro | Nenhum |
| `compatibilidade/gsan-opengsan.md` já existente | **Não existia** |
| Backlog | Item 1 = compatibilidade conceitual — **confirmado pendente** |

## 1. Correções pontuais aplicadas antes da atividade

⚠️ **Somente os pontos incompatíveis com a decisão da 18ª execução.** O plano **não** foi reescrito nem renumerado.

| Documento | Correção |
| --------- | -------- |
| `plano-de-trabalho.md` **§4 — Fase 5** | Segurança deixa de ser etapa completa posterior à Fundação: **S1** (identidade, autenticação, concessão, auditoria mínima) na Fundação · **S2** (abrangência) só **após a estrutura territorial do Cadastro**, dependente de D-17 · **S3** (administração, fluxos, políticas) progressivo |
| `plano-de-trabalho.md` **§4 — Fase 6** | O piloto passa a ser a **primeira fatia vertical** (autenticar → consultar → abrir e tramitar RA), não "cadastros auxiliares + consulta"; a ADR-0007 é citada como bloqueio **apenas da superfície de entrega** |
| `plano-de-trabalho.md` **§4 — Fase 7** | Construção por **capacidade**, com o gate da etapa, apontando para o documento definitivo |
| `plano-de-trabalho.md` **§5** | Título passa a *Ordem de implementação*; a sequência antiga é declarada **hipótese preliminar substituída**; entra a ordem em 9 etapas e a cadeia financeira com direção única |
| `testes/estrategia-testes.md` | ⚠️ **Referência órfã corrigida**: a camada de teste 4 apontava para a "Fase 8", removida do escopo em 2026-09-15. A bateria fica registrada como **insumo** do projeto de migração |

🔴 **Cuidado de nomenclatura aplicado na §5**: escrito que **a obrigação financeira nasce com o documento**; o que depende dos recebimentos é a **posição em aberto**. Não foi escrito que "a dívida nasce depois do pagamento" — seria falso nos dois sistemas.

## 2. O que foi produzido

`docs/modernizacao/compatibilidade/gsan-opengsan.md` — **26 seções**, cobrindo as dez áreas mais identidades, históricos, parametrização, variação por companhia, divergências, funcionalidades futuras e oráculos.

### 2.1 Classificação

**145 conceitos centrais** em cinco classes. ⚠️ Contagem **conferida por script** (regra permanente 6), com a composição declarada no próprio documento: 132 linhas com classe explícita em §6–§15, mais 11 divergências de §12.2 e 2 pendências de §12.3.

| Classe | Qtd |
| ------ | --: |
| **C1 — Equivalente** | 90 |
| **C2 — Equivalente com reorganização** | 25 |
| **C3 — Divergência deliberada** | 17 (**16 distintas** — D-03 aparece em Segurança e Relatórios) |
| **C4 — Sem equivalente** | 5 |
| **C4-i — Sem antecedente no GSAN** | 1 |
| **C5 — Pendente** | 7 |

### 2.2 🟢 A resposta à pergunta central

**115 dos 145 conceitos (C1 + C2) mantêm a semântica** — 90 sem qualquer mudança. O OpenGSAN é reconhecível como evolução do GSAN com margem larga.

As 16 divergências distintas: **segurança (11)** · fronteira e mecanismo (4: D-12, D-14, D-15, D-16) · **um defeito funcional** (D-13). 🔴 **Nenhuma atinge cálculo financeiro.**

## 3. Contribuição nova — a classe determina o oráculo

🔵 O achado mais útil desta execução, e a ponte direta para a próxima atividade:

| Classe | Oráculo | Exigência | Se der diferente |
| ------ | ------- | --------- | ---------------- |
| **C1** | 1 | Igualdade — ao centavo no financeiro | Defeito |
| **C2** | 1 | Igualdade por **mapeamento semântico**, nunca estrutural | Defeito |
| **C3** | 2 | 🔴 **Diferença exigida**, conforme `D-xx` | ⚠️ **Igualdade é defeito** |
| **C4** | — | Nada a comparar | ⚠️ Afirmar equivalência é **erro de categoria** |
| **C5** | — | 🔴 Cenário **não especificável** ainda | — |

⚠️ Registradas também **três armadilhas de comparação**: comparar C2 estruturalmente; comparar relatório byte a byte (o PDF falharia até do legado contra si mesmo); comparar pagamento por identificador (🔴 no legado ele **muda ao arquivar**).

## 4. Distinções que o documento fixa

| Tema | O que ficou registrado |
| ---- | ---------------------- |
| **C4 tem duas direções** | Existe no GSAN e não vai adiante (5) × existe no OpenGSAN **sem antecedente** (1: a camada de integração). ⚠️ Tratar o segundo como C2 afirmaria uma semântica preservada que **nunca existiu** |
| **Identidade documental** | `ContaGeral + Conta + ContaHistorico` → identidade + versão + histórico + linhagem. 🔴 A compatibilidade está na semântica: um pagamento ou parcela **continua apontando para o documento depois de retificado, cancelado ou arquivado**. A forma é livre |
| **Snapshot** | Comportamento **preservado**, não estrutura tolerada: responder *"com quais dados esta conta foi calculada"* mesmo que o Cadastro tenha mudado depois |
| **Posição de dívida** | 🔴 Continua **derivada**. A obrigação nasce com o documento; formalizar ≠ materializar |
| **Seis mecanismos de histórico** | Série · estado · versão · linhagem · snapshot · auditoria. ⚠️ Chamar todos de "histórico" cria **falsa compatibilidade** — cada um tem retenção diferente, e uma abstração única obrigaria a pior política a valer para todos |
| **Identidade externa ≠ PK** | Um identificador pode precisar permanecer **reconhecível** sem ser chave física. Evita preservar chave técnica como se fosse regra, e descartar identificador que o usuário reconhece |
| **Economia** | Regra financeira idêntica (multiplica tarifa e mínimo); o que não se preserva é a **obrigação de manter três representações sincronizadas** — redundância não é regra de negócio |
| **Efeitos da OS** | **C2, não C3**: o resultado funcional é o mesmo; o que muda é quem aplica |
| **Identidade do pagamento** | **C2** — ⚠️ e **não se inventou `D-xx`** para ela, conforme o roteiro |
| **Canal digital** | Confirmado como **canal consumidor**: não é dono de Conta, Atendimento, Parcelamento nem Cliente |

## 5. 🔴 Dois candidatos a divergência — encontrados, **não aprovados**

⚠️ Comportamentos que **talvez** devam divergir e não estão registrados. Marcados como candidatos, nunca como C3, e **ambos condicionais à caracterização** — nenhum afirma que o legado está errado.

| # | Conceito | Se a caracterização confirmar… |
| - | -------- | ------------------------------ |
| **CAND-01** | Valores denormalizados no Imóvel (total de economias, categoria principal) | …que há valores **defasados** no legado, o derivado do OpenGSAN divergirá. Precisa virar divergência **registrada e aprovada** — não aceito em silêncio nem "corrigido" sem decisão |
| **CAND-02** | Atomicidade dentro da unidade de processamento | …que efeitos parciais ocorrem, garanti-los no OpenGSAN é **mudança de comportamento observável** e exige divergência registrada |

🔵 **Por que importa**: sem esse registro, a primeira comparação que acusar diferença terá duas leituras — defeito ou melhoria — e a escolha seria feita sob pressão de prazo.

## 6. Correção de precisão sobre as pendências

⚠️ Ao conferir as contagens, uma afirmação inicial do documento mostrou-se imprecisa e foi corrigida **antes do commit**: as **nove pendências** de compatibilidade **não** são todas conceitos `C5`.

- **Sete são `C5`** — o conceito inteiro está indeciso e nenhum cenário seu pode ser especificado.
- **Duas não são**: individualização de economia e variantes por companhia afetam conceitos **já decididos como `C2`**. Falta **granularidade** e **inventário**, não a decisão. 🔵 Seus cenários podem ser especificados no nível já decidido.

## 7. O que este documento deliberadamente não faz

- ⚠️ **Não duplica** `estruturas-centrais.md` (que responde *o que fazer com a estrutura*) nem a Visão Conceitual §26/§30. O §2.1 declara, linha a linha, o que cada um já cobre e **o que só existe aqui** — a classificação, a semântica dos dois lados, o oráculo, os conceitos que nenhuma lista anterior cobria e os candidatos a divergência.
- 🔴 **Nenhuma migração**: sem ETL, scripts, coexistência, sincronização, cutover, replicação, ordem de importação, transformação de coluna ou chave primária física.
- Nenhuma das 64 decisões reclassificada; ordem de implementação não reaberta; ADR-0007 não decidida; nenhum cenário de teste especificado.

## 8. Impacto

- **Criado**: `compatibilidade/gsan-opengsan.md`.
- **Corrigidos pontualmente**: `plano-de-trabalho.md` (§4 Fases 5–7, §5 Ordem), `testes/estrategia-testes.md` (camada 4).
- **Atualizados**: `MODERNIZACAO_GSAN.md`, `docs/modernizacao/README.md`, `alteracoes/README.md`.
- **Não alterados**: os dez mapas funcionais, o mapa de domínio, a visão conceitual, `estruturas-centrais.md`, `divergencias-aprovadas.md`, o catálogo e a ordem de implementação.
- **Nenhuma alteração de código, banco ou infraestrutura.** D-17 continua **proposta**; ADR-0007 continua pendente.

## 9. Próxima atividade

**Especificação dos Cenários Críticos** — transformar o inventário de ~110 cenários em casos documentados com resultado esperado, conforme o modelo obrigatório de [`testes/estrategia-testes.md`](../testes/estrategia-testes.md). 🔵 Cada cenário herda o **oráculo** da classe de compatibilidade do conceito que exercita; os **7 conceitos `C5`** são os que ainda não podem ser especificados.
