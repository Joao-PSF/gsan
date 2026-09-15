# ADR-0001 — Monólito modular com Spring Boot 4.1.x / Java 25 LTS

- **Status: Aceita** · Data: 2026-08-13 · **Revisada em 2026-09-14**

> **Histórico da revisão**: a versão original ficou em *Proposta* e justificava a decisão com "o prompt do projeto exige modernização incremental com coexistência sobre o mesmo banco". Duas correções: (1) documento técnico não se justifica por autoridade do pedido — a justificativa abaixo é técnica; (2) a premissa de **coexistência sobre o mesmo banco** foi derrubada em 2026-08-13 (não há GSAN em produção neste projeto; o OpenGSAN nasce com banco próprio UTF-8 — ADR-0004/0005/0006) e foi removida.

## Contexto

O GSAN legado é um monólito Java EE 1.4 (JBoss 4.0.1sp1, Struts 1.1, EJB 2.x, Hibernate 3) com ~2,39M LOC e **234 classes EJB concretas** (166 MDB + 68 Session Beans — método de contagem em [`procedencia.md §3.1`](../procedencia.md)).

Os mapas funcionais concluídos (cadastro → relatórios → integrações) expõem três características do domínio que são determinantes para esta decisão:

1. **Transações atravessam módulos por natureza.** Faturar uma conta lê cadastro e consumo, grava documento financeiro, consome débitos a cobrar e créditos a realizar, e calcula imposto — em uma operação. Arrecadar baixa conta, atualiza débito e movimenta conta contábil. A retificação de conta chega a escrever em `ConsumoHistorico`, entidade da Micromedição ([`faturamento.md §5`](../modulos/faturamento.md)).
2. **Equivalência ao centavo é critério de aceitação.** Qualquer fronteira de rede introduzida entre módulos financeiros vira ponto de falha parcial em cálculo que precisa ser reproduzível.
3. **O domínio é único e a operação é de uma companhia.** Não há requisito de escala independente por módulo, nem times separados por serviço.

## Decisão

OpenGSAN como **monólito modular** em Spring Boot 4.1.x sobre Java 25 LTS. Módulos: `cadastro`, `micromedicao`, `faturamento`, `cobranca`, `arrecadacao`, `atendimento`, `seguranca`, `relatorios`, `batch`, `integracoes`, `shared`. Build Maven multi-módulo, deploy containerizado único.

Fronteiras internas explícitas: cada módulo expõe uma interface de aplicação e **não** acessa entidades de outro módulo diretamente (o caso da retificação escrevendo em `ConsumoHistorico` é exatamente o antipadrão a não reproduzir — ver registro de divergências aprovadas).

Sem microserviços, mensageria distribuída ou Kubernetes sem necessidade técnica demonstrada e registrada em ADR própria.

## Alternativas consideradas

| Alternativa | Por que foi rejeitada |
| ----------- | --------------------- |
| **Microserviços por módulo** | Transações financeiras cruzam módulos (ver Contexto, item 1). Exigiria saga/compensação em cálculo que precisa ser determinístico e comparável ao legado. Custo operacional desproporcional para uma companhia |
| **Modernização *in-place* do EAR** | JBoss 4.0.1sp1 e EJB 2.x não têm caminho de upgrade suportado; Struts 1.1 está EOL. Reescrever dentro da stack antiga não resolve o problema de sustentação |
| **Monólito não modular (pacote único)** | Reproduziria o acoplamento do legado, onde controladores de 60k+ linhas misturam módulos. As fronteiras dos mapas funcionais perderiam efeito prático |
| **Modular monolith com módulos como JARs independentes versionados** | Considerada e adiada: acrescenta cerimônia de versionamento antes de as fronteiras estarem validadas pelo piloto. Reavaliar após a Fase 6 |

## Consequências

- (+) Transações locais simples — crítico para as regras financeiras.
- (+) Operação e observabilidade mais baratas; um artefato, um pipeline.
- (+) Separação futura em serviços continua possível **pelos limites de módulo**, se e quando houver necessidade demonstrada.
- (−) Deploy único: um módulo problemático afeta o todo. Mitigação: *feature flags* por funcionalidade e cobertura de teste por módulo.
- (−) Disciplina de fronteira depende de convenção e verificação automatizada (ex.: ArchUnit ou equivalente) — sem isso, o modular degrada para não modular.

## Rollback

Decisão estrutural: o rollback real é a reversão do repositório do OpenGSAN a um estado anterior. Não há sistema em produção a restaurar (não existe GSAN operante neste projeto — ADR-0005).

## Pendência ligada

A **arquitetura de interface** (JSP/Thymeleaf servido pelo próprio Spring Boot × API + SPA) **não** está decidida aqui e é pré-requisito do piloto — ver **ADR-0007**.
