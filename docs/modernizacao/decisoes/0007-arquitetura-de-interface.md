# ADR-0007 — Arquitetura de interface do OpenGSAN

- **Status: Proposta** · Data: 2026-09-14 · **Decisão requerida antes do piloto (Fase 6)**

> Criada em resposta à revisão externa, que apontou corretamente: o piloto (cadastros auxiliares + atendimento) não pode ser especificado sem que a arquitetura de interface esteja decidida, porque ela muda o desenho interno do módulo — não só a camada de apresentação.

## Contexto

### O que o legado faz hoje

🟢 O GSAN serve **JSP + Struts 1.1**, com autorização amarrada à URL da Action (`FiltroSegurancaAcesso` sobre `*.do`) e o menu derivado da árvore de funcionalidades ([`modulos/seguranca.md`](../modulos/seguranca.md)).

🟢 Três características do legado dependem diretamente do modelo de interface:

1. **A unidade de autorização é a URL**, não o caso de uso. Funcionalidade e operação são registros de banco associados a caminhos `*.do`.
2. **O relatório online devolve bytes na resposta** e o batch entrega por Action dedicada ([`modulos/relatorios.md`](../modulos/relatorios.md)).
3. **Existem consumidores que não são navegador** — coletores de campo, telemetria, GIS, app de OS ([`modulos/integracoes.md`](../modulos/integracoes.md)) —, hoje atendidos por Actions e servlets fora do gate.

🔵 Ou seja: a decisão de interface **é** uma decisão de segurança e de integração, não de front-end.

### Por que não pode ser adiada

O piloto envolve telas de CRUD (cadastros auxiliares) e um módulo com fluxo real de usuário (atendimento). Em qualquer das opções abaixo o módulo é escrito de forma diferente: o que é um `Controller` que devolve modelo e view em uma opção, é um recurso REST com contrato versionado em outra — e o modelo de autorização muda junto.

## Opções

| # | Opção | Implicação no módulo | Implicação na autorização | Implicação nas integrações |
| - | ----- | -------------------- | ------------------------- | -------------------------- |
| A | **Server-side rendering** (Thymeleaf no próprio Spring Boot) | Controller devolve view; sessão no servidor | Mais próximo do legado: autorização por rota, sessão HTTP | APIs externas continuam sendo superfície separada |
| B | **API REST + SPA** | Módulo expõe contrato; front separado | Token/JWT, autorização por caso de uso; CSRF deixa de ser o problema central | Uma só camada de API serve tela e integração |
| C | **Híbrido**: SSR para telas de manutenção, REST para integrações e telas ricas | Dois estilos convivendo | Dois mecanismos de autenticação a manter coerentes | Integrações usam a mesma API que as telas ricas |

## Critérios de decisão (a aplicar, não pré-julgados)

1. **Continuidade de operação** — usuários do GSAN conhecem telas densas de formulário; SSR reduz atrito de treinamento.
2. **Custo de manter dois mecanismos de autenticação** (opção C).
3. **Necessidade real de riqueza de interface** por módulo — a maioria das telas mapeadas é formulário + grade + relatório, não interação complexa.
4. **Reuso pela integração**: quanto do contrato de tela serve também a coletor/app de OS.
5. **Tamanho da equipe** — duas *stacks* de front custam mais que uma.

## Decisão

**Pendente.** Não será decidida por inércia nem no meio da implementação do piloto.

🟡 **Inclinação preliminar registrada, não decidida**: opção **C restrita** — SSR para as telas de manutenção do piloto e REST desde o início **apenas** para a camada de integração (que precisa existir de qualquer forma, ver ADR pendente sobre integrações). Isso evita construir uma SPA antes de a fronteira de domínio estar validada, sem impedir a evolução para B depois. **Requer confirmação explícita antes da Fase 6.**

## Consequências de não decidir

O piloto seria escrito com um modelo implícito e a decisão ficaria tomada de fato, sem registro nem alternativa avaliada — exatamente o defeito que o registro de ADRs existe para evitar.

## Pendências relacionadas

- Modelo de autorização do OpenGSAN (por rota × por caso de uso) depende desta ADR.
- Entrega de relatórios (bytes na resposta × artefato referenciado por URL assinada) depende desta ADR — e precisa corrigir o achado 13 de [`riscos-identificados.md`](../seguranca/riscos-identificados.md).
