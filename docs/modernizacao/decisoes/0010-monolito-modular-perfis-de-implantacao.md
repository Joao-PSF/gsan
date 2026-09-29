# ADR-0010 — Monólito modular com perfis de implantação

- **Status: Aceita** (decisão do responsável do projeto) · Data: 2026-09-29 · Segundo adendo pós-Fase 0 — refinamento arquitetural antes da Fase 1
- **Especializa a [ADR-0001](0001-monolito-modular-spring-boot.md)** — não a contradiz nem a substitui

## Contexto

A ADR-0001 decidiu o **monólito modular**: um artefato, deploy único, módulos com fronteira explícita, sem microserviços — porque as transações financeiras atravessam módulos e a equivalência ao centavo é critério de aceitação. Ela pensava em **uma companhia usando o sistema inteiro**.

Desde então o produto cresceu: núcleo comercial, micromedição, atendimento e execução, Gestão de Ativos com PCM, Gestão Operacional com Paradas, Redes/GIS, Workspace SINISA, Gerencial & Analytics. E companhias reais **já têm sistemas** — ERP, sistema comercial, CMMS, GIS, leitura — que não serão trocados de uma vez. Para um software livre de saneamento, exigir a suíte inteira é barreira de adoção.

A evidência do domínio mostra onde as fronteiras aguentam e onde não ([`modulos-e-perfis-de-implantacao.md`](../arquitetura/modulos-e-perfis-de-implantacao.md)):

1. **O núcleo comercial não se separa**: não há dívida sem documento, a posição de dívida só se valida com recebimentos, o documento fiscal decorre da conta e a contabilização, dos fatos — dependências #6, #7 e #8 e ciclos internos da ordem de implementação.
2. **A OS não depende do RA**: no GSAN, a ação de cobrança gera OS a partir do documento de cobrança, **sem RA** (`ControladorCobranca:24135–24142`; `ControladorOrdemServicoSEJB:1032–1086`; `rgat_id` nulo no DDL). Execução pode ter origem fora do atendimento.
3. **A Micromedição precisa do Cadastro só por referência**: imóvel, ligação, situação, rota, categoria e economias — não do cadastro comercial inteiro.
4. **O ecossistema GSAN já separou módulos em processos** — o satélite `gsan-operacional` e o GIS GeoSan — e o preço está documentado: acesso ao satélite por redirecionamento com token MD5 (achado 1b), indicadores que leem tabelas de três módulos e credencial em `dblink` (achado 20; [`operacional.md §6.3`](../modulos/operacional.md#63--o-que-a-função-geraindicador-revela)). Separar processo não trouxe fronteira; trouxe acoplamento pior.
5. **Sem fronteira de implantação desde o início, "opcional" vira impossível**: um núcleo que importa o repositório de outro módulo não sobe sem ele — e tornar isso opcional depois é refatoração transversal.

## Decisão

1. **O OpenGSAN continua monólito modular** (ADR-0001): um código, **uma versão da suíte**, **um processo por instalação**. ❌ Microserviços, *service mesh*, HTTP entre módulos internos, banco por serviço, deploy independente por processo e fila interna obrigatória.
2. **Suíte modular na implantação**: *módulo de domínio ≠ módulo instalável ≠ microserviço*. Os módulos instaláveis são **Platform, Commercial, Metering, Services, Assets, Operations, Networks, SINISA e Analytics**, cada um reunindo módulos de domínio.
3. **Perfil de implantação** = módulos habilitados + provedores externos declarados. **Perfis de referência** enumerados e testados; outra combinação é permitida se a validação passar, mas não é garantida. ❌ Fork, *branch* ou edição por perfil — nenhum `if edition == …`.
4. **Toda dependência é declarada** como **REQUIRED**, **OPTIONAL** ou **EXTERNALIZABLE** — esta com marca de provedor obrigatório quando o módulo não opera sem ela. O único REQUIRED dos módulos funcionais é a **Platform**.
5. **Dependência opcional nunca é *import* direto**: passa por **contrato do consumidor**, atendido por adapter interno — a ponte, que só existe com os dois módulos ativos — ou por **adapter externo**. Dentro do monólito, contrato em Java, nunca HTTP.
6. **Commercial é coeso** — cadastro, tarifa, benefício, faturamento, cobrança, arrecadação, pagamentos, contabilização e Fiscal/NFAg num só instalável. **PCM fica no Assets; Paradas, na Operations; Fiscal, no Commercial.** **SINISA** (REQUIRED só a Platform; V1 manual — ADR-0009 integral) e **Analytics** (consumidor) são independentes.
7. **Platform pequena**: só entra o que **todo** perfil usa, sem conceito de negócio próprio e sem depender de módulo funcional. A **capacidade GIS vai para o Networks**. O escopo territorial é **mecanismo** da Platform com **dimensões registradas pelos módulos** — o que resolve o ciclo Cadastro ↔ Segurança por inversão.
8. **Módulo desligado não registra nada** — menu, tela, permissão, endpoint, job, adapter, relatório, evento. **Ativação ≠ autorização**: a autorização continua no caso de uso (ADR-0007), e ativar módulo não concede nada.
9. **Perfil inválido falha na inicialização**, com diagnóstico.
10. **Atualização de versão nunca ativa módulo**: módulo novo nasce desabilitado.
11. **Coexistência** é integração operacional por contrato entre sistemas vivos — **não** é migração, sincronização massiva nem *cutover*, que continuam fora do projeto (ADR-0005).
12. **Nomenclatura**: módulo instalável com nome de produto; módulo de domínio com o nome do domínio em português; ferramenta — QGIS, Giswater — nunca é nome de módulo.

**Esta ADR não decide**: mecanismo de ativação, formato de configuração, estrutura Maven ou de pacotes, adoção de Spring Modulith, ferramenta de teste arquitetural, estratégia de migrations dos módulos desabilitados, interfaces Java, tabelas, mensageria — tudo para a **Etapa 0**, antes da primeira funcionalidade.

## Consequências

- (+) Adoção total, incremental ou em coexistência, **com o mesmo código**.
- (+) Fronteiras que eram convenção passam a ter **prova**: perfil que sobe sem o vizinho, teste arquitetural que reprova *import* indevido.
- (+) Módulos que atendem sistemas de terceiros — Metering, Services, SINISA, Analytics — viram porta de entrada do projeto.
- (+) A Platform fica pequena por critério, não por intenção.
- (−) Contratos a mais onde bastaria uma chamada direta; pontes entre módulos para manter.
- (−) Mais combinações para testar — contidas pelos perfis de referência.
- (−) Referência externa com snapshot aumenta o dado a guardar e exige disciplina para não virar cadastro paralelo.
- ⚠️ Risco: a restrição só vale se nascer na **Etapa 0**; retrofit de modularidade opcional é caro — por isso os cenários de ativação e de fronteira estão no gate 0 → 1.
- ⚠️ Risco: "provedor externo" virar desculpa para empurrar regra ao adapter — a regra continua do dono; o adapter traduz.

## Alternativas consideradas

| Alternativa | Motivo da rejeição |
| ----------- | ------------------ |
| **Microserviços por módulo instalável** | Os motivos da ADR-0001 continuam — transação financeira atravessa módulos, equivalência ao centavo, custo operacional desproporcional para uma companhia |
| **Um produto ou fork por perfil** | Duplica código e correção; os perfis divergem e param de conversar |
| **Edições por *flag*** (`if edition == …`) | Espalha a decisão pelo código e não impede o *import* indevido — o núcleo continua dependendo do vizinho |
| **Tudo sempre ativo** | Não permite adoção incremental; obriga a companhia a operar módulos que duplicam sistemas que ela já tem |
| **JARs versionados de forma independente por módulo** | A ADR-0001 já os adiou; versão por módulo multiplica a matriz de compatibilidade antes de as fronteiras serem provadas |
| **Plugins carregados dinamicamente em execução** | Complexidade de carga e de isolamento sem necessidade: o perfil é escolhido na implantação, não a quente |
| **Commercial fragmentado** — Faturamento, Cobrança, Arrecadação, PIX, Fiscal | A dependência entre eles é alta demais: cada fatia exigiria as outras por contrato |

## Relação com outras ADRs

| ADR | Relação |
| --- | ------- |
| **0001** | Especializada: continua o monólito modular com deploy único **por instalação**; o que varia é o conjunto ativo. As *feature flags* por funcionalidade da ADR-0001 são **mitigação de deploy**, não mecanismo de módulo |
| **0002** | Flyway desde `V1` continua; a estratégia para módulos desabilitados é questão da Etapa 0 |
| **0005** | Coexistência deste adendo **não** é a migração que a ADR-0005 deixou fora do escopo |
| **0007** | Autorização no caso de uso; canais sobre casos de uso; nenhum HTTP entre módulos — inalterados |
| **0008** | Giswater opcional; identidade corporativa do ativo emitida pelo Assets **quando presente** |
| **0009** | Integral; o SINISA isolado a aplica sem nenhum outro módulo |

## Rollback

Decisão conceitual, sem código. Revertê-la exige nova ADR que diga como a suíte seria adotada sem perfis — ou que decida separar processos, o que reabre a ADR-0001.
