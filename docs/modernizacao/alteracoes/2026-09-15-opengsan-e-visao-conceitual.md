# [2026-09-15] SISAN → OpenGSAN: mudança de identidade e escopo + Visão Conceitual Alvo

- **Motivo**: duas diretrizes do responsável do projeto — (a) o sistema passa a chamar-se **OpenGSAN**, evolução **aberta** e moderna do GSAN; (b) a **migração de instalações GSAN existentes sai do escopo** deste projeto e terá projeto próprio. Em seguida, produzir a Visão Conceitual Alvo.
- **Método**: verificação de continuidade primeiro (HEAD real, backlog, existência de documento equivalente), depois revisão documental **pontual**, depois a atividade principal. **Nenhuma reanálise de código ou banco.**
- **Testes**: n/a (documental) · **Risco**: baixo · **Rollback**: `git revert` do commit · **Migration**: nenhuma.

## 0. Verificação de continuidade (obrigatória)

| Verificação | Resultado |
| ----------- | --------- |
| HEAD real | `745e6ff` — análise de compatibilidade; local = remoto; árvore limpa |
| Commits posteriores ao estado assumido no prompt | Nenhum |
| Documento de visão conceitual já existente | **Não existia** |
| Atividade realmente pendente | **Visão Conceitual Alvo** — confirmada |

## 1. Mudança de identidade

**SISAN → OpenGSAN.** ⚠️ Não é projeto novo: é a continuação direta das 15 execuções anteriores. Nada foi invalidado.

### Critério de renomeação (não foi substituição cega)

| Grupo | Tratamento | Racional |
| ----- | ---------- | -------- |
| **Documentos de estado corrente** (31 arquivos) | `SISAN` → `OpenGSAN` | O enunciado é o mesmo; muda o nome do sistema alvo |
| **Registros de alteração** (`alteracoes/*`) | **Preservam SISAN** | Registram o que foi decidido **quando** o sistema tinha esse nome |
| **Seções de histórico das ADRs** | **Preservam SISAN** | Idem — apagar destruiria o histórico decisório |
| **Nomes de arquivo** (`0005-sisan-...`) | **Preservados** | Mesma convenção já usada na ADR-0004; evita quebrar links |

## 2. Mudança de escopo — a mais importante

🔴 **A migração de instalações GSAN saiu do escopo.** Estratégia gradual, coexistência, sincronização, ETL, cutover e replicação passam a ser **projeto separado**.

**Consequência de desenho, que é o ponto**: a forma do legado **deixa de ser restrição**. Facilidade de migração não justifica mais manter tabelas ruins, acoplamentos, chaves artificiais ou segurança inadequada.

⚠️ **O que permanece**: continuidade conceitual — mas por razão diferente. Preserva-se conceito, regra e identidade **porque valem por si**, não porque facilitam transporte de dados.

### Verificação feita antes de afirmar que nada muda

Revisei as **37 decisões `PRESERVAR`** da análise de compatibilidade sob o novo critério: **nenhuma se apoiava apenas em facilidade de migração** — todas têm justificativa de qualidade estrutural ou de semântica de negócio. **As 64 classificações permanecem válidas.**

## 3. Documentos corrigidos

| Documento | O que mudou |
| --------- | ----------- |
| **ADR-0005** | Reescrita: OpenGSAN como evolução **aberta**; o item "facilidade de migração é requisito arquitetural" foi **substituído** por "migração fora do escopo + continuidade conceitual permanece"; software livre acrescentado como princípio; histórico preservado |
| **ADR-0003** | Revisada: o princípio (código fora do legado) permanece; o **nome físico do repositório volta a ser pendência aberta**, ligada à governança do projeto aberto |
| **ADR-0006** | Calibrada: método e classificações intactos; o critério "facilidade de migração" passa a ser **"continuidade conceitual"** |
| `arquitetura-alvo.md` | Item 3 invertido; coexistência/ETL/cutover explicitamente fora do projeto |
| `plano-de-trabalho.md` | Premissa 4 invertida; **Fase 8 (playbook de migração) removida do escopo**; Fase 12 reescrita para instalação nova |
| `banco/migracao-postgresql.md` | Parte (3) deixa de ser atividade deste projeto e vira insumo registrado |
| `compatibilidade/estruturas-centrais.md` | Banner de calibração; a balança de decisão perde "facilidade de migração"; §17 reposicionada como continuidade conceitual |
| `MODERNIZACAO_GSAN.md` | Título, 16ª execução, backlog renumerado, tabela de ADRs |
| `decisoes/README.md`, `README.md` | Status das ADRs; nota de nomenclatura e de escopo |

⚠️ **Não reescrevi** os dez mapas funcionais nem o mapa de domínio — apenas a nomenclatura foi atualizada neles, conforme o roteiro.

## 4. Visão Conceitual Alvo produzida

`docs/modernizacao/dominio/visao-conceitual-opengsan.md` — **31 seções**, 2 diagramas, matriz de ownership com 22 conceitos, tabela GSAN × OpenGSAN com 30 temas.

### Principais decisões conceituais

| # | Decisão |
| - | ------- |
| 1 | **Core × plataforma**: Cadastro…Arrecadação + Atendimento são domínio; Segurança, Processamento, Relatórios e Integrações são **plataforma** — não são dez módulos equivalentes |
| 2 | **Só o dono altera o estado do seu conceito** — três propriedades corrigidas: situação da ligação (vai para a Ligação), situação de cobrança (vai para a Cobrança), escrita de consumo (fica na Micromedição) |
| 3 | **Atendimento solicita, o dono aplica** — é ponte operacional, nunca dono de estado alheio |
| 4 | **Identidade ≠ versão ≠ linhagem** — formalizados como três conceitos, com a semântica obrigatória e a forma livre |
| 5 | **Seis mecanismos de histórico**, deliberadamente **não unificados** (cada um tem regra de escrita, leitura e retenção diferente) |
| 6 | **Auditoria ≠ histórico de negócio** — um é domínio, o outro é plataforma |
| 7 | **Parametrização tipada**, nunca achatada em chave-valor; versionada onde afeta resultado financeiro |
| 8 | **Extensibilidade em cinco níveis**: configuração → parametrização → política → extensão → código específico. **Fork é exceção** |
| 9 | **Precisão financeira preservada como comportamento**, com as políticas de arredondamento tornadas explícitas e nomeadas |
| 10 | **Obrigação financeira marcada `PROPOSTO`** — não criar superentidade sem esclarecer "Fatura" e o ciclo de vida comum |
| 11 | **Posição de dívida permanece derivada**, mas o conceito é nomeado (formalizar ≠ materializar) |
| 12 | **Integração não é dona do domínio** — traduz e entrega; o dono aplica |

### O que foi preservado do GSAN

Os quatro padrões estruturais (regra como dado · identidade+versão+linhagem · snapshot · informado × efetivo), a separação equipamento × instalação, os três valores de consumo com origem, a estrutura tarifária versionada, os snapshots da conta, a composição e memória do parcelamento, a separação recepção × classificação, RA ≠ OS, o modelo de três níveis do processamento, o RBAC com escopo territorial e a auditoria em dois níveis.

### O que foi reorganizado

Propriedade de estado (3 correções), Economia (3 representações → conceito + composição), chave da ligação, identidade do recebimento, concessão desacoplada da apresentação, escopo territorial por construção, contexto de execução legível, camada de integração criada, espera/reiteração com histórico.

## 5. Implicações de ser software livre

Registradas com consequência arquitetural, não como rótulo: neutralidade institucional (⚠️ nenhum nome de empresa, URL fixa ou campo institucional no núcleo — o GSAN falha nos três), configuração antes de fork, documentação e instalação reproduzíveis, testes sem dependência de base de companhia, e ausência de dependência desnecessária de fornecedor.

⚠️ **Licença, organização e mantenedores não decididos** — registrados como pendência de governança, ligada ao nome físico do repositório.

## 6. Decisões pendentes

**Bloqueiam a implementação inicial** (5): ADR-0007 (interface) · inventário das variantes por companhia · existência de mecanismo de negação na autorização · nome do repositório e governança do projeto aberto · aprovação da divergência D-17.

**Podem ser decididas ao implementar o módulo** (7): individualização de economia, histórico de situação da ligação, fórmulas de acréscimo, obrigação financeira, cardinalidade física RA↔OS, retenção de artefatos, granularidade de commit.

## 7. Impacto

- **Criado**: `dominio/visao-conceitual-opengsan.md`.
- **Reescritos**: ADR-0005, ADR-0003.
- **Revisados**: ADR-0006, `arquitetura-alvo.md`, `plano-de-trabalho.md`, `banco/migracao-postgresql.md`, `compatibilidade/estruturas-centrais.md`, `MODERNIZACAO_GSAN.md`, `decisoes/README.md`, `README.md`.
- **Renomeados** (nomenclatura): 31 documentos de estado corrente.
- **Preservados como histórico**: todos os registros em `alteracoes/` e as seções de histórico das ADRs.
- **Nenhuma alteração de código, banco ou infraestrutura.** Nenhum schema, migration, entidade, API ou renomeação de repositório. Nenhum domínio futuro modelado. ADR-0007 continua pendente.

## 8. Próxima atividade

**Catálogo de Funcionalidades Futuras** — PIX, fiscal/NF, SPED, mobile/campo, recadastramento, tarifa social, birô de crédito, APIs, BI, boleto registrado. Sem modelagem e sem incorporar ao núcleo.
