# [2026-09-14] Mapa funcional das Integrações + rodada de correções da revisão externa

- **Motivo**: (A) concluir o último mapa funcional pendente da Fase 0; (B) corrigir os defeitos apontados por revisão externa e confirmados por verificação no código.
- **Código analisado**: `HEAD = 2031c4ca762c3ec2597ea8c057db97aa388e5589`.
- **Testes**: n/a (documental) · **Risco**: baixo · **Rollback**: `git revert` do commit · **Migration**: nenhuma.

---

## Parte A — Mapa funcional das Integrações

**Documento criado**: [`modulos/integracoes.md`](../modulos/integracoes.md).

- **Descoberta central**: 🟢 **não existe uma camada de integração no GSAN**. O pacote `gcom.integracao` cobre uma só integração (UPA/SAM); as demais estão espalhadas por Actions, servlets, utilitários e controladores de negócio. São **sete padrões técnicos independentes**, sem política comum de autenticação, erro ou observabilidade.
- **Espectro de maturidade comprovado**: de OAuth2 *client credentials* com credencial em banco (`src/gcom/api/GsanApi.java:128-160` — o padrão mais maduro do repositório) até chave de API escrita em constante Java (`ServicoSMS:17`).
- **Entry points fora do gate** (`processarRequisicao*`): verificados vivos (mapeados em struts-config registrados no `web.xml:137-953`). Estão por desenho fora dos dois filtros — mas apenas **um dos três** autentica: o GIS, por assinatura `SHA1withDSA` (`AssinaturaDSA:68-95`). Dispositivo móvel (protocolo binário por opcode) e telemetria gravam dados de campo **sem identificar quem chama**.
- **Integração por banco compartilhado**: 🟢 `HibernateUtil.getStatelessSessionIntegracaoSAM()` — segunda `SessionFactory`; o GSAN **insere diretamente no banco do SAM** (`RepositorioIntegracaoHBM:88-108`), com idempotência por `ConstraintViolationException` engolida e falha de resolução de usuário **silenciosa** (`continue` + `System.out`).
- **22 cenários** identificados · **10 dúvidas abertas** registradas.
- **Conclusão para o SISAN**: preservar todas as capacidades funcionais sob **uma** camada com política única. Não é "portar integrações" — é criar a camada que nunca existiu.

## Parte B — Correções (revisão externa, todas verificadas no código)

| # | Defeito | Correção |
| - | ------- | -------- |
| 1 | `plano-de-trabalho.md` continha **duas estratégias incompatíveis**: o banner dizia que a coexistência fora superada, o corpo continuava descrevendo *strangler*, proxy e banco compartilhado | **Reescrito** (não mais remendado): premissas vigentes explícitas, §2 sem coexistência, §6 separando banco do SISAN × playbook de migração, §7 com dois oráculos, §9 substituída |
| 2 | ADR-0001 em *Proposta*, justificando decisão com "o prompt do projeto exige" e citando coexistência | **Reescrita e Aceita**: justificativa técnica a partir dos mapas funcionais, 4 alternativas com motivo de rejeição, premissa de coexistência removida |
| 3 | ADR-0002 em *Proposta* por inércia; menção a "equipe DBA" (inexistente) | **Formalizada como Aceita**, com alternativas comparadas (Liquibase, MyBatis, scripts à mão, `ddl-auto`) |
| 4 | Decisão de interface ausente, mas pré-requisito do piloto | **ADR-0007 criada** (Proposta) — marcada como bloqueio da Fase 6 |
| 5 | "Faturamento não regrava consumo" — conclusão extrapolada de busca negativa | **Corrigido** em `faturamento.md §5` e `micromedicao.md`: três casos distintos; a **retificação escreve diretamente** (`ControladorRetificarConta:267-273`). Descoberto no caminho: `setNumeroConsumoFaturadoMes(20)` fixo em código |
| 6 | "Arredondamento HALF_UP centralizado" | **Corrigido** em `faturamento.md §27`: **5 políticas semânticas** (HALF_UP 27, UP 21, DOWN 5, HALF_DOWN 2, FLOOR 2), truncamento em base de imposto (`:29943`), escopo de contagem declarado |
| 7 | `calcularValorFaturadoFaixaCAER` citado como método do núcleo da Micromedição | **Corrigido**: pertence a `ControladorFaturamentoFINAL` (Faturamento) |
| 8 | Inconsistência MD5/SHA-1 entre documentos | **Corrigido** em `riscos-identificados.md` e `plano-de-trabalho.md`: login usa SHA-1; MD5 é token efêmero |
| 9 | `api/GsanApi.java` (raiz, cópia obsoleta) citado como evidência | **Corrigido**: a árvore viva é `src/gcom/api/` |
| 10 | Critério `A = B` obrigaria o SISAN a reproduzir falhas de segurança do legado — contradição com a regra de segurança do projeto, não registrada | **Corrigido**: [dois oráculos](../testes/estrategia-testes.md) + [registro de divergências aprovadas](../compatibilidade/divergencias-aprovadas.md) com 16 divergências |
| 11 | Cenários tratados como se fossem especificação de teste | **Corrigido**: modelo de especificação obrigatório criado; item acrescentado ao backlog da Fase 0, apoiado na própria sequência do projeto (**DEFINIR TESTES vem antes do PARAR**) |
| 12 | Comparação de relatório sem método definido | **Corrigido**: comparação **semântica** (datasource → conteúdo extraído → totalizadores); byte a byte de PDF proibido |
| 13 | Rastreabilidade ausente (sem SHA, sem método de contagem, "LATIN1 confirmado") | **Corrigido**: [`procedencia.md`](../procedencia.md) criado; LATIN1 rebaixado a 🔵 indício |
| 14 | Sumário executivo mais confiante que os documentos técnicos | **Corrigido**: `MODERNIZACAO_GSAN.md` separa incompletude normal da descoberta × defeitos em artefatos dados por concluídos |

## Parte C — Achados de segurança novos (análise estática, sem execução)

| # | Achado | Severidade |
| - | ------ | ---------- |
| 11 | **Chave de API de SMS em código-fonte** (`ServicoSMS:17`) e em properties versionado; trafega por `http://` fixo | **P0 — rotação obrigatória** |
| 12 | `/api/ordem-servico/*` **sem filtro**; `encerrar`/`fotos`/`programadas` sem credencial | Alta |
| 13 | **Artefato de relatório batch sem controle de acesso** — cadeia completa fechada; elevado de "dúvida prioritária" a **achado confirmado** | Alta |
| 14 | `FiltroSSO` com ramos `if/else` idênticos e `FiltroSessaoExpirada` com guarda inalcançável — **dois filtros decorativos** | Média |
| 15 | Entrada de dados de campo (coletor, telemetria) **sem autenticação** — alimenta faturamento | Alta |
| 16 | Assinatura DSA do GIS cobre **só o login** → portador estático, replicável | Média |
| 17 | `OrdemServicoAPI` com `request`/`response`/`resposta` como campos de instância | Média |
| 18 | Telefone real em `main()` (LGPD) | Baixa |
| 19 | UPA/SAM: escrita direta no banco parceiro + falha silenciosa | Média |

Defeito funcional correlato: `ServicoSMS.getJson` **ignora `tipoMensagem`** — o aviso de vencimento chega ao cliente como "Recebemos seu cadastro no Portal".

> Nenhuma exploração ofensiva foi realizada. Nenhum valor de segredo foi transcrito na documentação. A chave encontrada é considerada **comprometida** e entra na lista de rotação, conforme a regra do projeto.

## Impacto

- **Documentos criados**: `modulos/integracoes.md`, `procedencia.md`, `compatibilidade/divergencias-aprovadas.md`, `decisoes/0007-arquitetura-de-interface.md`.
- **Documentos reescritos**: `plano-de-trabalho.md`, `decisoes/0001-monolito-modular-spring-boot.md`.
- **Documentos corrigidos**: `modulos/{faturamento,micromedicao,seguranca,relatorios}.md`, `seguranca/riscos-identificados.md`, `testes/estrategia-testes.md`, `integracoes/integracoes-identificadas.md`, `banco/estrutura-atual.md`, `decisoes/{0002,README}.md`, `MODERNIZACAO_GSAN.md`, índices.
- **Nenhuma alteração de código, banco ou infraestrutura.**

## Lição de método registrada

Os erros corrigidos aqui têm duas raízes, ambas agora cobertas por regra em [`procedencia.md §5`](../procedencia.md):

1. **Generalização a partir de busca negativa** — "não achei X, logo X não existe" (fronteira de consumo, arredondamento, cobertura de filtro das APIs). Ausência de evidência não é evidência de ausência.
2. **Falha de propagação** — corrigir um documento e não os demais (MD5, atribuição do método CAER), produzindo documentos que se contradizem entre si.
