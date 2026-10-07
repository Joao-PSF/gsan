# Registro de Divergências Aprovadas (GSAN → OpenGSAN)

Criado em 2026-09-14. Resolve a contradição entre duas regras do projeto que conviviam sem registro:

- *"MESMA ENTRADA → RESULTADO A = RESULTADO B"* (critério de equivalência)
- *"MD5/SHA-1, ausência de salt, pseudo-autenticação e segredos em código **não devem ser preservados tecnicamente no OpenGSAN**"* (regra de segurança)

Onde o legado está errado, **equivalência literal seria o defeito**. Este arquivo registra cada ponto em que o OpenGSAN **deve** divergir, para que o teste reconheça a diferença como esperada em vez de reportá-la como falha.

## Como usar

1. Toda divergência é registrada **antes** de a implementação começar.
2. O teste de equivalência consulta este registro: comportamento listado aqui é avaliado pelo **oráculo 2** ([`testes/estrategia-testes.md`](../testes/estrategia-testes.md)), não pelo 1.
3. Divergência **não registrada** é defeito, sem exceção. O registro é o que separa correção deliberada de regressão.
4. Nenhuma divergência pode **reduzir** um controle existente (expiração, bloqueio, histórico de senha, permissões especiais, abrangência, auditoria).

## Divergências

| # | Área | Comportamento do GSAN | Comportamento exigido do OpenGSAN | Motivo | Status |
| - | ---- | --------------------- | ------------------------------ | ------ | ------ |
| D-01 | Autenticação | Senha em **SHA-1 sem salt** (`Criptografia.java:17`) | BCrypt/Argon2 com salt; autenticação contra hash legado apenas na migração, com re-hash no primeiro login | Regra de segurança do projeto (achado 1) | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-02 | Autenticação auxiliar | Token **MD5** efêmero (`AcessarOperacionalServlet:48`, `AcessarNovoBatchServlet:98`) | Token com escopo e expiração | Achado 1b | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-03 | Download de relatório | Artefato recuperável **por identificador**, sem verificação de propriedade e **sem usuário autenticado** (cadeia em `relatorios.md §17`) | Verificação de propriedade e abrangência no download; sem acesso anônimo | Achado 13 — a igualdade aqui seria reproduzir a falha | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-04 | API de OS | `/api/ordem-servico/*` sem filtro; `encerrar`/`fotos`/`programadas` sem credencial (`OrdemServicoAPI:36-58`) | Autenticação de dispositivo/usuário em **todos** os endpoints; capacidade funcional preservada | Achado 12 | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-05 | Coleta em campo | `ProcessarRequisicaoDipositivoMovelAction` e `...TelemetriaAction` gravam leitura **sem identificar a origem** | Autenticação de dispositivo obrigatória antes de qualquer escrita | Achado 15 — leitura alimenta faturamento | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-06 | API de pagamento | `PagamentoCreditoFilter` valida o **host do próprio servidor**, não o chamador, e não bloqueia | Autenticação real do chamador; recusa no próprio filtro | Achado 3 | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-07 | Cadeia de filtros | `FiltroSSO` com ramos `if/else` idênticos; `FiltroSessaoExpirada` com guarda inalcançável | Nenhum filtro decorativo; cada elo com responsabilidade única e teste que prove que barra | Achado 14 | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-08 | Segredos | Chave de API de SMS **no código-fonte** (`ServicoSMS:17`) e em properties versionado | Segredo em cofre/variável de ambiente; **nunca** em código nem em properties versionado | Achado 11 — chave considerada comprometida, em rotação | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-09 | Transporte | URL `http://` fixa no envio de SMS; domínios `http://` no filtro de pagamento | TLS obrigatório em toda integração | Achados 11 e 5 | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-10 | Servlet com estado | `request`, `response`, `resposta` como campos de instância (`OrdemServicoAPI:32-34`) | Componentes sem estado por requisição | Achado 17 | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-11 | Assinatura GIS | `SHA1withDSA` cobrindo **apenas o login**, sem corpo/nonce/timestamp → portador estático | Token/assinatura com expiração e escopo, cobrindo a requisição | Achado 16 — o conceito é preservado, a implementação é corrigida | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-12 | Integração UPA/SAM | Escrita direta no **banco do sistema parceiro**; idempotência por `ConstraintViolationException` engolida; falha de usuário silenciosa (`continue` + `System.out`) | Contrato explícito; idempotência por chave de negócio; erro **durável e observável**, com fila de rejeição | Achado 19 | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-13 | SMS por tipo | `getJson` **ignora `tipoMensagem`**: todo SMS envia o texto de cadastro no Portal | Cada tipo envia sua mensagem | Defeito funcional que alcança o cliente final — o legado está errado, não é regra de negócio | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-14 | Fronteira de módulo | Retificação de conta escreve direto em `ConsumoHistorico` (`ControladorRetificarConta:273`) | Operação exposta pela Micromedição, com motivo e versionamento preservado | Fronteira de agregado (ADR-0001) | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-15 | Consumo de fallback | `setNumeroConsumoFaturadoMes(20)` fixo em código (`ControladorFaturamentoFINAL:1880/1897`) | Parâmetro configurável | Constante mágica em caminho financeiro | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-16 | Credenciais de banco | Roles `gsan_*` com senha = login, versionadas | Credencial por ambiente, contas distintas por finalidade, menor privilégio | Achado 2 | **Aprovada** — registro de 2026-09-29 (§Registro de aprovação) |
| D-18 | Sessão e requisição forjada | Cookie de sessão **sem** `HttpOnly`/`Secure`/`SameSite` — `gcom/WEB-INF/web.xml` não tem `session-config` (Servlet 2.x não oferece os atributos) — e **nenhuma proteção anti-CSRF**: zero ocorrências de token de formulário (`saveToken`/`isTokenValid`) em `src/`; requisição que altera estado é aceita com a sessão do usuário, venha de onde vier | Cookie de sessão com `HttpOnly`, `Secure` e `SameSite`; token anti-CSRF exigido em **toda** requisição que altera estado, inclusive nas atualizações parciais | Achado 6 — decidido na [ADR-0007 §9.4](../decisoes/0007-arquitetura-de-interface.md). 🆕 Registrada na auditoria final: o controle **tem antecedente observável** no legado (a sessão e o cookie existem; a proteção não) | **Aprovada** — ADR-0007 aceita (2026-09-29) |

## Divergências PROPOSTAS (⚠️ não aprovadas — não valem como oráculo 2)

⚠️ Seção distinta das aprovadas. Uma divergência **proposta** ainda é avaliada pelo oráculo 1 (equivalência estrita) até receber aprovação. Registrada aqui apenas para não se perder.

| # | Área | Comportamento do GSAN | Comportamento proposto | Motivo | Origem |
| - | ---- | --------------------- | ---------------------- | ------ | ------ |
| **D-17** | Abrangência territorial | Em superfícies onde `verificarAcessoAbrangencia` não é chamado, o usuário acessa dados **fora de sua abrangência** — o modelo está correto, a aplicação depende de disciplina | Escopo territorial aplicado **sistematicamente** em toda consulta | Vazamento por omissão (LGPD); o OpenGSAN não deve herdar a garantia frágil | [`estruturas-centrais.md §19.10`](estruturas-centrais.md) (SEG-03) |
| 🆕 **D-19** | Autorização e regras de cobrança no servidor | A **permissão especial** EFETUAR_LIGACAO_DE_AGUA_SEM_RA e as **regras de cobrança do serviço** (quantidade de parcelas, valor, percentual, motivo de não cobrança) existem **só na tela**: o servidor aceita o POST com valores que a tela não deixaria enviar (`EfetuarLigacaoAguaAction:106-173`, `:282-292`) | Toda permissão especial e toda regra de cobrança avaliadas **no servidor**, no caso de uso; requisição fora da regra é recusada | Achados de segurança 33–34; um controle que o usuário contorna não é controle. **Reforça** permissões especiais — não as reduz (regra 4) | Fase 2, lote 4 (2026-10-06): CAND-10 — baselines CEN-SEG-008 V2, CEN-ATE-008 V1b e V3b |

⚠️ **Por que exige aprovação**: altera comportamento **visível** — consultas que hoje retornam dados passariam a restringi-los. É correção, não regressão, mas operadores podem perceber como perda de acesso.

🆕 ⚠️ **Nota de evidência sobre D-15 (Fase 2, 2026-10-07 — o status não muda)**: a baseline de CEN-FAT-011 V1 mostra que, no **faturamento do imóvel**, sem consumo registrado o GSAN fatura **0 m³ pela tarifa mínima**; as linhas que D-15 cita (`ControladorFaturamentoFINAL:1880/1897`) pertencem a `obterValoresCreditosBolsaAgua` — o 20 fixo é o volume do **crédito Bolsa Água**, aplicado sempre. D-15 permanece aprovada como "constante mágica vira parâmetro", mas a leitura derivada em CEN-FAT-011 ("padrão 20 no motor de conta") **não se sustenta**: tornar 20 o fallback do faturamento **mudaria** o valor cobrado. Decisão pendente do responsável: o alvo de D-15 é o crédito Bolsa Água ([relatório da Fase 2, F2-67](../testes/fase2/fase2-caracterizacao-baselines.md#207-achados)).

⚠️ **D-19 — pendente de aprovação (registrada em 2026-10-06)**: até a decisão, as baselines CEN-SEG-008 V2 e CEN-ATE-008 V1b/V3b registram o que o GSAN faz, com a ressalva de que não é comportamento a reproduzir; **nenhum outro cenário depende desta decisão**. Por que exige aprovação: um operador que hoje informa parcelas ou valor fora da tela (por integração, script ou navegador alterado) passaria a ser recusado — é correção, mas muda o resultado de requisições que hoje são aceitas.

## Fora deste registro (equivalência estrita — oráculo 1)

Para evitar leitura errada: **nada** do comportamento financeiro e funcional entra aqui sem justificativa própria. Cálculo de conta, tarifa por vigência e faixas, mínimos, esgoto, impostos, **os modos de arredondamento ponto a ponto** ([`faturamento.md §27`](../modulos/faturamento.md)), baixa de pagamento, parcelamento, consumo e média — tudo isso é avaliado pelo **oráculo 1**, com igualdade exigida ao centavo.

⚠️ Em particular: **arredondamento não é candidato a "melhoria"**. As cinco políticas semânticas convivendo no legado produzem resultados específicos, e "corrigir para HALF_UP em tudo" seria alterar valores cobrados do cliente sem decisão de negócio. Se em algum ponto a mudança for desejada, ela vira divergência **registrada aqui, com aprovação**, nunca uma decisão técnica silenciosa.

## Aprovação

Cada linha exige aprovação registrada antes de sair de *Proposta*. Enquanto o projeto não tem companhia operante, a aprovação é do responsável técnico; em migração futura de uma instalação real, cada divergência precisa de aceite do dono do negócio, porque várias mudam comportamento visível ao usuário.

### 🆕 Registro de aprovação (auditoria final da Fase 0, 2026-09-29)

⚠️ **Inconsistência corrigida**: a tabela acima trazia D-01…D-16 com status *Proposta*, enquanto o projeto inteiro — a especificação dos cenários, a compatibilidade conceitual e as instruções do responsável técnico — as tratava como **aprovadas** e as usava como oráculo 2. A aprovação **existia e não estava registrada na coluna**. Esta seção registra a origem de cada uma; ⚠️ **nenhuma candidata foi aprovada por arrasto**.

| Divergências | Base da aprovação |
| ------------ | ----------------- |
| **D-01, D-02, D-08, D-16** | Regras permanentes do responsável técnico: *"MD5/SHA-1, ausência de salt, pseudo-autenticação e segredos em código não devem ser preservados tecnicamente"* e *"secrets fora do código; credenciais por ambiente; contas distintas de banco por finalidade; menor privilégio no PostgreSQL"* |
| **D-04, D-05, D-06, D-07, D-09, D-11** | Mesmas regras — pseudo-autenticação, endpoint sem credencial, filtro decorativo, transporte em claro |
| **D-03** | Mesmas regras + [ADR-0007 §11](../decisoes/0007-arquitetura-de-interface.md), aceita: obter artefato é caso de uso autorizado |
| **D-14** | [ADR-0001](../decisoes/0001-monolito-modular-spring-boot.md), aceita: nenhum módulo escreve no estado de outro |
| **D-13** | Instrução explícita do responsável na especificação dos cenários (2026-09-28): *"D-13 deve possuir cenário explícito… OpenGSAN deve respeitar o tipo. Oráculo 2"* |
| **D-10, D-12, D-15** | Instrução do responsável nas execuções de compatibilidade (2026-09-14/15): divergências **já registradas neste arquivo** são referenciadas sem exigir equivalência técnica, e candidatas novas ficam `PROPOSTA` — distinção que só faz sentido se as registradas estão aprovadas |
| **D-18** | ADR-0007 §9.4, aceita em 2026-09-29 |

**Estado em 2026-09-29**: **17 aprovadas** (D-01…D-16 e D-18) · **1 proposta** (D-17) · candidatas CAND-01…CAND-05 **não aprovadas** ([`gsan-opengsan.md §20.3`](gsan-opengsan.md)). ⚠️ CAND-03 e CAND-04 continuam pendentes: não há decisão explícita nem caracterização que as sustente. 🆕 **Fase 2 (2026-10-05)**: a caracterização agora **sustenta** CAND-03 e CAND-04 e acrescentou **CAND-06** (negação por operação contornada pela entrada da funcionalidade) e **CAND-07** (bloqueio de senha que não bloqueia a sessão) — todas **candidatas**, nenhuma aprovada por efeito da baseline ([`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência)). 🆕 **Segurança restante (2026-10-06)**: **CAND-08** (redefinição de senha para valor fixo) e **CAND-09** (troca de senha imposta que não restringe a sessão) — candidatas; a abrangência caracterizada (CEN-SEG-007) **não altera D-17**, que segue proposta: confirma que a verificação só existe onde a aplicação a chama. 🆕 **Lote 4 (2026-10-06)**: **CAND-10** (controle de tela sem verificação no servidor) — 🆕 registrada como **D-19 — PROPOSTA, pendente de aprovação** (§Divergências PROPOSTAS). **Estado em 2026-10-06**: 17 aprovadas · **2 propostas** (D-17, D-19) · candidatas CAND-01…CAND-09 não aprovadas. 🆕 **Lote 5 (2026-10-07)**: **CAND-02 caracterizado** (efeitos parciais dentro da unidade de faturamento) e **CAND-11** (novo disparo de comando já realizado fatura a referência seguinte — controle só na tela, mesma família de D-19) — candidatas, **nenhuma aprovada nem proposta por efeito da baseline**; nota de evidência sobre o alvo de D-15 (acima). **Estado em 2026-10-07**: 17 aprovadas · 2 propostas (D-17, D-19) · candidatas CAND-01…CAND-09 e CAND-11 não aprovadas.
