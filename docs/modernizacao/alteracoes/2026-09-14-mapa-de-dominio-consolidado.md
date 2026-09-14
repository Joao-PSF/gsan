# [2026-09-14] Mapa de domínio consolidado GSAN

- **Motivo**: transformar os dez mapas funcionais separados em **uma** visão integrada do domínio, base para a análise de compatibilidade das estruturas centrais.
- **Método**: consolidação documental. **Nenhuma reanálise de código** — a leitura de fonte limitou-se à verificação de duas inconsistências (§ correções). Fontes: `MODERNIZACAO_GSAN.md`, `procedencia.md`, `glossario.md` e os dez mapas de `modulos/`.
- **Testes**: n/a (documental) · **Risco**: baixo · **Rollback**: `git revert` do commit · **Migration**: nenhuma.

## Documento criado

`docs/modernizacao/dominio/mapa-de-dominio.md` — 23 seções, três diagramas Mermaid (macro dos domínios, núcleo comercial com Atendimento transversal, identidades financeiras).

## Descobertas da consolidação

Coisas que **só aparecem quando os dez mapas são lidos juntos** — nenhuma delas estava explícita em mapa individual:

| # | Descoberta | Consequência |
| - | ---------- | ------------ |
| 1 | **Quatro padrões estruturais atravessam o sistema inteiro**: regra como dado · identidade estável + versão + linhagem · fotografia na operação · informado × efetivo | 🔵 São a "gramática" do GSAN. Modernizar sem preservá-los = escrever outro sistema |
| 2 | **As dez áreas não são dez domínios equivalentes** | Batch, Relatórios e Integrações têm natureza de **plataforma**; Cadastro…Arrecadação e Atendimento são domínios de negócio |
| 3 | **O Atendimento participa de 3 dos 7 ciclos** confirmados | É o nó mais conectado depois do Imóvel; sua natureza de **ponte** é estrutural, não acidental |
| 4 | **A linhagem é padrão de domínio, não peculiaridade do faturamento** | Aparece em conta retificada, RA reativado/duplicado, OS de referência e reparcelamento: **o GSAN nunca reescreve um documento, cria outro e liga ao anterior** |
| 5 | **O par "informado × efetivo" não é da micromedição** | Aparece em 8 lugares (leitura, anormalidade, consumo em 3 valores, prazo, prioridade, valor de serviço, situação atual/anterior, aviso calculado/informado): é auditoria embutida no modelo |
| 6 | **A identidade perdida do pagamento é a única anomalia** do padrão de identidade do sistema | Todos os documentos de dívida usam `*Geral`; só o pagamento recebe **novo id** ao arquivar |
| 7 | **Três conceitos centrais não têm entidade**: Economia, obrigação financeira e estoque de dívida | Economia é a unidade tarifária; obrigação financeira foi apontada independentemente por três mapas; estoque de dívida "nasce por consulta" |
| 8 | **A variação por companhia concentra-se onde há cálculo financeiro e formato externo** | Micromedição, Faturamento, Cobrança e Arrecadação têm subclasses; Atendimento, Segurança e Batch **não** — estes absorveram a variação por parametrização |
| 9 | **O GSAN parametriza *o quê* e *quando*; deixa em código *como se calcula*** | Divisão coerente — e o SISAN herda exatamente essa divisão, não outra |
| 10 | **Os riscos de modernização ordenam-se por silêncio da falha** | Arredondamento, identidade × linhagem, fotografias e abrangência falham **silenciosamente** — os mais perigosos |

## Conteúdo produzido

- **Conceitos centrais** classificados conceitualmente (entidade/valor/histórico/snapshot/parametrização/processo/artefato/identidade estável), com marcação explícita onde a classificação não ficou clara.
- **12 identidades estáveis** com: objeto que a representa, estabilidade, versionamento, quem guarda referência e **criticidade para migração**.
- **Quatro mecanismos de tempo** distinguidos (estado corrente · histórico como série · versão/arquivamento · fotografia) — com a explicação de por que a fotografia não pode ser "normalizada".
- **Tabela de ownership** conceito → dono → consumidores, com observação de fronteira.
- **14 fronteiras** com o que atravessa, direção, dono e efeito de retorno.
- **7 dependências circulares confirmadas**, registradas sem tentativa de resolução.
- **16 famílias de regra-como-dado** + o que ficou deliberadamente em código.
- **5 mecanismos de variação por companhia**, classificados por qualidade.
- **5 conceitos sobrecarregados** (Imóvel, Conta, Usuário, OS, Especificação) — com a distinção entre sobrecarga **justificada** (Conta) e acúmulo histórico (Imóvel).
- **9 conceitos implícitos** candidatos a formalização futura.
- **10 pontos de maior risco**, ordenados por gravidade × silêncio da falha.
- **12 hipóteses** para a visão conceitual alvo — registradas, **não decididas**.
- **20 dúvidas** consolidadas, separadas por impacto no modelo de domínio.

## Correções de consistência aplicadas

Encontradas na consolidação e corrigidas (não escondidas para produzir diagrama limpo):

| Documento | Antes | Depois |
| --------- | ----- | ------ |
| `docs/modernizacao/README.md` | Descrição de `arquitetura-alvo.md` mencionava "estratégia de coexistência" | Princípios de compatibilidade; coexistência é cenário do **playbook de migração futura**, não premissa do projeto |
| `modulos/relatorios.md §22` | Serviço externo de relatórios como 🟡 hipótese, citando `api/GsanApi.java` (cópia obsoleta) | 🟢 Mecanismo comprovado: `src/gcom/api/GsanApi.java:128-160`, OAuth2 *client credentials* com credencial em banco. **Uso** (quais relatórios) permanece ❔ |
| `dominio/glossario.md` | "não é o mapa de domínio definitivo — item 3 do backlog" | Aponta para o mapa de domínio agora existente |

⚠️ Nenhuma contradição de **conteúdo** entre os dez mapas foi encontrada — as divergências residuais eram de **referência** (documento apontando estado superado). Isso é consequência direta da rodada de correções anterior.

## Impacto

- **Criado**: `dominio/mapa-de-dominio.md`.
- **Atualizados**: `MODERNIZACAO_GSAN.md` (14ª execução; backlog reestruturado em 8 itens, com a **Visão Conceitual Alvo do SISAN** explicitamente na sequência), `docs/modernizacao/README.md`, `dominio/glossario.md`, `modulos/relatorios.md`.
- **Nenhuma alteração de código, banco ou infraestrutura.** Nenhuma tabela, entidade, schema, migration ou API projetada. Nenhuma hipótese virou ADR.

## Próxima atividade

**Análise de Compatibilidade das Estruturas Centrais** — classificação `PRESERVAR / MODERNIZAR / REESTRUTURAR / NÃO TRANSPORTAR` sobre os conceitos consolidados, considerando benefício, custo, impacto, dificuldade de migração, dependências e compatibilidade semântica.
