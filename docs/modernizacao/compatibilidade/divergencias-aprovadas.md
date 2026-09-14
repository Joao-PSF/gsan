# Registro de Divergências Aprovadas (GSAN → SISAN)

Criado em 2026-09-14. Resolve a contradição entre duas regras do projeto que conviviam sem registro:

- *"MESMA ENTRADA → RESULTADO A = RESULTADO B"* (critério de equivalência)
- *"MD5/SHA-1, ausência de salt, pseudo-autenticação e segredos em código **não devem ser preservados tecnicamente no SISAN**"* (regra de segurança)

Onde o legado está errado, **equivalência literal seria o defeito**. Este arquivo registra cada ponto em que o SISAN **deve** divergir, para que o teste reconheça a diferença como esperada em vez de reportá-la como falha.

## Como usar

1. Toda divergência é registrada **antes** de a implementação começar.
2. O teste de equivalência consulta este registro: comportamento listado aqui é avaliado pelo **oráculo 2** ([`testes/estrategia-testes.md`](../testes/estrategia-testes.md)), não pelo 1.
3. Divergência **não registrada** é defeito, sem exceção. O registro é o que separa correção deliberada de regressão.
4. Nenhuma divergência pode **reduzir** um controle existente (expiração, bloqueio, histórico de senha, permissões especiais, abrangência, auditoria).

## Divergências

| # | Área | Comportamento do GSAN | Comportamento exigido do SISAN | Motivo | Status |
| - | ---- | --------------------- | ------------------------------ | ------ | ------ |
| D-01 | Autenticação | Senha em **SHA-1 sem salt** (`Criptografia.java:17`) | BCrypt/Argon2 com salt; autenticação contra hash legado apenas na migração, com re-hash no primeiro login | Regra de segurança do projeto (achado 1) | Proposta |
| D-02 | Autenticação auxiliar | Token **MD5** efêmero (`AcessarOperacionalServlet:48`, `AcessarNovoBatchServlet:98`) | Token com escopo e expiração | Achado 1b | Proposta |
| D-03 | Download de relatório | Artefato recuperável **por identificador**, sem verificação de propriedade e **sem usuário autenticado** (cadeia em `relatorios.md §17`) | Verificação de propriedade e abrangência no download; sem acesso anônimo | Achado 13 — a igualdade aqui seria reproduzir a falha | Proposta |
| D-04 | API de OS | `/api/ordem-servico/*` sem filtro; `encerrar`/`fotos`/`programadas` sem credencial (`OrdemServicoAPI:36-58`) | Autenticação de dispositivo/usuário em **todos** os endpoints; capacidade funcional preservada | Achado 12 | Proposta |
| D-05 | Coleta em campo | `ProcessarRequisicaoDipositivoMovelAction` e `...TelemetriaAction` gravam leitura **sem identificar a origem** | Autenticação de dispositivo obrigatória antes de qualquer escrita | Achado 15 — leitura alimenta faturamento | Proposta |
| D-06 | API de pagamento | `PagamentoCreditoFilter` valida o **host do próprio servidor**, não o chamador, e não bloqueia | Autenticação real do chamador; recusa no próprio filtro | Achado 3 | Proposta |
| D-07 | Cadeia de filtros | `FiltroSSO` com ramos `if/else` idênticos; `FiltroSessaoExpirada` com guarda inalcançável | Nenhum filtro decorativo; cada elo com responsabilidade única e teste que prove que barra | Achado 14 | Proposta |
| D-08 | Segredos | Chave de API de SMS **no código-fonte** (`ServicoSMS:17`) e em properties versionado | Segredo em cofre/variável de ambiente; **nunca** em código nem em properties versionado | Achado 11 — chave considerada comprometida, em rotação | Proposta |
| D-09 | Transporte | URL `http://` fixa no envio de SMS; domínios `http://` no filtro de pagamento | TLS obrigatório em toda integração | Achados 11 e 5 | Proposta |
| D-10 | Servlet com estado | `request`, `response`, `resposta` como campos de instância (`OrdemServicoAPI:32-34`) | Componentes sem estado por requisição | Achado 17 | Proposta |
| D-11 | Assinatura GIS | `SHA1withDSA` cobrindo **apenas o login**, sem corpo/nonce/timestamp → portador estático | Token/assinatura com expiração e escopo, cobrindo a requisição | Achado 16 — o conceito é preservado, a implementação é corrigida | Proposta |
| D-12 | Integração UPA/SAM | Escrita direta no **banco do sistema parceiro**; idempotência por `ConstraintViolationException` engolida; falha de usuário silenciosa (`continue` + `System.out`) | Contrato explícito; idempotência por chave de negócio; erro **durável e observável**, com fila de rejeição | Achado 19 | Proposta |
| D-13 | SMS por tipo | `getJson` **ignora `tipoMensagem`**: todo SMS envia o texto de cadastro no Portal | Cada tipo envia sua mensagem | Defeito funcional que alcança o cliente final — o legado está errado, não é regra de negócio | Proposta |
| D-14 | Fronteira de módulo | Retificação de conta escreve direto em `ConsumoHistorico` (`ControladorRetificarConta:273`) | Operação exposta pela Micromedição, com motivo e versionamento preservado | Fronteira de agregado (ADR-0001) | Proposta |
| D-15 | Consumo de fallback | `setNumeroConsumoFaturadoMes(20)` fixo em código (`ControladorFaturamentoFINAL:1880/1897`) | Parâmetro configurável | Constante mágica em caminho financeiro | Proposta |
| D-16 | Credenciais de banco | Roles `gsan_*` com senha = login, versionadas | Credencial por ambiente, contas distintas por finalidade, menor privilégio | Achado 2 | Proposta |

## Divergências PROPOSTAS (⚠️ não aprovadas — não valem como oráculo 2)

⚠️ Seção distinta das aprovadas. Uma divergência **proposta** ainda é avaliada pelo oráculo 1 (equivalência estrita) até receber aprovação. Registrada aqui apenas para não se perder.

| # | Área | Comportamento do GSAN | Comportamento proposto | Motivo | Origem |
| - | ---- | --------------------- | ---------------------- | ------ | ------ |
| **D-17** | Abrangência territorial | Em superfícies onde `verificarAcessoAbrangencia` não é chamado, o usuário acessa dados **fora de sua abrangência** — o modelo está correto, a aplicação depende de disciplina | Escopo territorial aplicado **sistematicamente** em toda consulta | Vazamento por omissão (LGPD); o SISAN não deve herdar a garantia frágil | [`estruturas-centrais.md §19.10`](estruturas-centrais.md) (SEG-03) |

⚠️ **Por que exige aprovação**: altera comportamento **visível** — consultas que hoje retornam dados passariam a restringi-los. É correção, não regressão, mas operadores podem perceber como perda de acesso.

## Fora deste registro (equivalência estrita — oráculo 1)

Para evitar leitura errada: **nada** do comportamento financeiro e funcional entra aqui sem justificativa própria. Cálculo de conta, tarifa por vigência e faixas, mínimos, esgoto, impostos, **os modos de arredondamento ponto a ponto** ([`faturamento.md §27`](../modulos/faturamento.md)), baixa de pagamento, parcelamento, consumo e média — tudo isso é avaliado pelo **oráculo 1**, com igualdade exigida ao centavo.

⚠️ Em particular: **arredondamento não é candidato a "melhoria"**. As cinco políticas semânticas convivendo no legado produzem resultados específicos, e "corrigir para HALF_UP em tudo" seria alterar valores cobrados do cliente sem decisão de negócio. Se em algum ponto a mudança for desejada, ela vira divergência **registrada aqui, com aprovação**, nunca uma decisão técnica silenciosa.

## Aprovação

Cada linha exige aprovação registrada antes de sair de *Proposta*. Enquanto o projeto não tem companhia operante, a aprovação é do responsável técnico; em migração futura de uma instalação real, cada divergência precisa de aceite do dono do negócio, porque várias mudam comportamento visível ao usuário.
