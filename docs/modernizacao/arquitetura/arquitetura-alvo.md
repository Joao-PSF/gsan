# Arquitetura Alvo

Versões confirmadas como estáveis/suportadas em 2026-08 — reconfirmar no início de cada fase.

> 🆕 **Revisão 2026-09-29 — segundo adendo pós-Fase 0 (ADR-0010)**: o monólito modular passa a ser implantado como **suíte modular** — nove módulos instaláveis, perfis de implantação sobre o mesmo código, sem microserviços nem HTTP interno ([`modulos-e-perfis-de-implantacao.md`](modulos-e-perfis-de-implantacao.md)).
>
> **Revisão 2026-09-29 (ADR-0007 aceita)**: a interface deixa de ser pendência — **canais sobre casos de uso**, backoffice **server-driven com aprimoramento progressivo**, contratos explícitos só para canais externos, autorização no caso de uso. A ADR-0007 é a **fonte autoritativa**; o texto abaixo que tratava a interface foi alinhado a ela.
>
> **Revisão 2026-09-15 (16ª execução)**: o sistema passa a chamar-se **OpenGSAN** — evolução aberta e moderna do GSAN (ADR-0005 revisada). A **migração de instalações GSAN saiu do escopo deste projeto** e terá projeto próprio.
>
> Revisão 2026-08-13 (2ª execução): banco próprio em UTF-8 e modelo de dados evoluído (ADR-0006). A coexistência com um GSAN em produção deixou de ser premissa de desenvolvimento — ver [revisão de premissas](../alteracoes/2026-08-13-revisao-premissas-fase0.md).

## Stack

| Camada | Tecnologia |
| ------ | ---------- |
| Linguagem | Java 25 LTS |
| Framework | Spring Boot 4.1.x (Spring Framework 7, Jakarta EE) |
| Web / canais | Spring MVC como adaptador de canal ([ADR-0007](../decisoes/0007-arquitetura-de-interface.md)): **backoffice server-driven com aprimoramento progressivo** — HTML no servidor, atualização parcial por fragmentos, JavaScript só em ilhas justificadas, sem SPA e sem *build* de frontend obrigatório; **API HTTP explícita só para canais externos** (integrações, campo, GIS, portal independente); portal como canal próprio. Biblioteca de templates e de atualização parcial escolhida na Etapa 0, dentro do padrão |
| Persistência | Spring Data JPA/Hibernate para CRUD; `JdbcTemplate`/SQL nativo para consultas complexas, relatórios e batch (não converter SQL funcional para ORM por estética) |
| Transações | Spring Transaction (`@Transactional`), substituindo CMT do EJB |
| Segurança | Spring Security (RBAC evoluído do modelo conceitual `seguranca.*` do GSAN — perfis, grupos, funcionalidades, permissões especiais, abrangência). 🔴 **Autorização no caso de uso**, sob uma política, para todo canal — nunca por rota. Credencial por classe de canal: sessão + cookie seguro + CSRF nos canais de navegador; identidade de sistema nas integrações; dispositivo + usuário no campo; cliente final separado do usuário interno (ADR-0007 §9) |
| Banco | PostgreSQL 18.x (18.6+), UTF-8 (ADR-0004); modelo de dados próprio do OpenGSAN, evoluído dos conceitos GSAN (ADRs 0005/0006) |
| Migrations | Flyway (ADR-0002); schema do OpenGSAN versionado desde `V1` — sem baseline copiada do legado |
| Build | Maven (convenção dominante no ecossistema Spring; multi-módulo) |
| Batch | Spring Batch + agendamento (Spring Scheduling; Quartz moderno apenas se necessidade real) |
| Relatórios | JasperReports atual para os `.jrxml` reaproveitáveis; reescrita seletiva apenas quando o layout exigir |
| Observabilidade | Spring Boot Actuator + Micrometer (logs estruturados, métricas, health checks) |
| Execução | Containers (Docker) + docker-compose para dev; primeiro ambiente: VPS de testes/homologação/demonstração (não é produção crítica); CI/CD com SAST/SCA/SBOM |

## Organização modular (monólito modular)

```text
opengsan (repositório próprio — nome físico PENDENTE, ADR-0003)
 ├── cadastro
 ├── faturamento
 ├── arrecadacao
 ├── cobranca
 ├── micromedicao
 ├── atendimento        (inclui ordens de serviço)
 ├── seguranca
 ├── relatorios
 ├── batch
 ├── integracoes        (infraestrutura de integração — os adapters ficam nos módulos donos; ver nota)
 └── shared             (tipos comuns, utilidades, convenções de persistência)
```

Cada módulo com separação `domain / application / infrastructure / web` **quando trouxer benefício real**; módulos simples (cadastros auxiliares) podem usar estrutura mais direta. Sem microserviços, mensageria ou Kubernetes sem necessidade técnica demonstrada.

🆕 **Canais (ADR-0007)**: `web` e `api` são **adaptadores de canal** do módulo; os casos de uso (`application`) existem **sem HTTP** e concentram autorização, validação e auditoria. Módulos conversam por **contratos internos em Java** — nunca por HTTP. Uma tela que compõe dados de vários módulos chama os contratos de cada um, nunca o repositório alheio.

🆕 **Módulos acrescentados pela revisão de escopo (2026-09-28)**: `contabilizacao` e `operacional` (Gestão Operacional) — domínio GSAN a recuperar; Gestão de Ativos e Redes seguem a **trilha estrutural** ([ADR-0008](../decisoes/0008-gestao-de-ativos-nativa.md)). 🆕 **Auditoria final (2026-09-29)**: `fiscal` — documento fiscal de água e saneamento (NFAg), requisito nativo com ciclo próprio; **Conta ≠ NFAg**; o adapter do ambiente autorizador é do Fiscal, sobre a infraestrutura de `integracoes` ([`modulos/fiscal.md`](../modulos/fiscal.md)). Nenhum módulo `regulacao`, `pagamentos` ou `tarifasocial`: são regra, parâmetro regulado, integração ou capacidade transversal.

🆕 **Suíte modular (ADR-0010, especializa a ADR-0001)**: os módulos de domínio acima são **agrupados** em módulos instaláveis — **Platform · Commercial · Metering · Atendimento · Assets · Operations · Networks · SINISA · Analytics** — habilitados por **perfil de implantação**. Um código, uma versão, um processo por instalação. Dependência entre módulos instaláveis opcionais só por **contrato do consumidor** — nunca *import* direto, nunca HTTP. Módulo desligado não registra nada; atualização de versão não ativa módulo. Estrutura Maven e de pacotes, mecanismo de ativação e migrations de módulo desabilitado: **Etapa 0**. ⚠️ Módulo Maven ≠ microserviço.

🆕 **Revisão consolidada (2026-09-30) — onde fica cada adapter.** `integracoes` é **infraestrutura** da Platform — convenções, identidade de sistema, idempotência, erro durável, segredo fora do código —, **não** dona das integrações. Cada adapter é do módulo que integra e só existe com ele ativo: bancos e arrecadadores, PSP Pix, birôs de crédito, ambiente autorizador da NFAg, bases de elegibilidade e exportação contábil → **Commercial**; coleta móvel de leitura e AMI → **Metering**; aplicativo de campo e executante terceirizado (UPA/SAM) → **Atendimento**; Giswater e QGIS → **Networks**; arquivo oficial do SINISA, se existir → **SINISA**. A lista do diagrama acima registra a origem dessas capacidades no GSAN, não a posição dos adapters ([`modulos-e-perfis-de-implantacao.md §14`](modulos-e-perfis-de-implantacao.md#14-platform--pequena-e-transversal)).

## Modelo de dados evolutivo e continuidade conceitual GSAN → OpenGSAN (ADRs 0005/0006)

1. O OpenGSAN é a **evolução aberta e moderna do GSAN**, não sistema do zero: conceitos, módulos, regras de negócio, fluxos, nomenclaturas relevantes e relacionamentos conceituais são preservados sempre que adequados — **porque valem por si**, não para facilitar transporte de dados. Regra geral: *preservar quando adequado, modernizar quando necessário, redesenhar somente com justificativa*.
2. Banco próprio do OpenGSAN (PostgreSQL 18.x, UTF-8), com schema versionado por Flyway desde `V1`. Estruturas importantes do GSAN são classificadas como `PRESERVAR`, `MODERNIZAR`, `REESTRUTURAR` ou `NÃO TRANSPORTAR` — sem redesenho por estética e sem manter estrutura ruim apenas para ficar idêntico ao legado.
3. ⚠️ **Facilidade de migração NÃO é requisito deste projeto** (revisão 2026-09-15, ADR-0005): a migração de instalações GSAN existentes é **projeto separado**. O que permanece requisito é a **continuidade conceitual** — registrar a correspondência entre conceitos GSAN e OpenGSAN, sem detalhar transformação de dados. ⚠️ Facilidade de migração não justifica preservar estrutura inadequada.
4. O OpenGSAN não assume que toda companhia possui o mesmo schema GSAN: instalações reais divergem por versão, migrations, customizações e DDL manual (comprovado no `gsan_comercial`) — fato relevante para o futuro projeto de migração, registrado aqui.
5. ⚠️ Coexistência, sincronização, ETL, cutover e replicação **não pertencem a este projeto** — são objeto do **projeto de migração GSAN → OpenGSAN**, separado e posterior. 🆕 *Coexistência* aqui é **dois sistemas com o mesmo dado durante uma transição**; a coexistência da ADR-0010 é outra coisa — **integração operacional por contrato** entre um módulo OpenGSAN e um sistema vivo, sem sincronização de bancos nem *cutover*.

## O que não faremos

- 🆕 Interface (ADR-0007): SPA no backoffice; microfrontends; BFF obrigatório; HTTP entre módulos do monólito; integração consumindo endpoint de tela; autorização por rota; regra de negócio ou autorização no cliente; "API = domínio".
- Reescrita indiscriminada ou "recriar a roda" — ignorar o conhecimento consolidado no GSAN; microserviços por padrão; troca de SQL funcional por ORM por estética; redesenho de estruturas sem justificativa (ou preservação de estruturas ruins por apego ao legado); exposição de entidades JPA como contrato de API; cópia automática de tabelas/colunas/schemas do `gsan_comercial` para o OpenGSAN.
