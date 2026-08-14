# Documentação da Modernização do GSAN

Sumário da documentação técnica. A visão executiva do projeto está em [`MODERNIZACAO_GSAN.md`](../../MODERNIZACAO_GSAN.md) na raiz do repositório.

## Documentos

| Documento | Conteúdo |
| --------- | -------- |
| [plano-de-trabalho.md](plano-de-trabalho.md) | Plano de trabalho da modernização: estado atual, arquitetura alvo, riscos, fases, ordem dos módulos, estratégias |
| [dominio/glossario.md](dominio/glossario.md) | Glossário de domínio: 25 conceitos estruturantes com definição, relações, evidências (código/banco) e pontos de aprofundamento |
| [modulos/cadastro.md](modulos/cadastro.md) | Mapa funcional do módulo Cadastro: imóvel/matrícula, economia, cliente×imóvel, ligações, categorias, território, estados, dependências e compatibilidade |
| [arquitetura/arquitetura-legada.md](arquitetura/arquitetura-legada.md) | Mapa técnico do GSAN legado: runtime, build, frameworks, camadas, batch, relatórios |
| [arquitetura/arquitetura-alvo.md](arquitetura/arquitetura-alvo.md) | Stack alvo, organização modular e estratégia de coexistência |
| [banco/estrutura-atual.md](banco/estrutura-atual.md) | Inventário do banco `gsan_comercial`: schemas, objetos, classificação, drift |
| [banco/migracao-postgresql.md](banco/migracao-postgresql.md) | Estratégia de atualização do PostgreSQL e versionamento do banco |
| [seguranca/modelo-legado.md](seguranca/modelo-legado.md) | Modelo de autenticação/autorização atual (RBAC próprio) |
| [seguranca/riscos-identificados.md](seguranca/riscos-identificados.md) | Achados de segurança e ações requeridas |
| [testes/estrategia-testes.md](testes/estrategia-testes.md) | Estratégia de testes de caracterização e equivalência legado × novo |
| [integracoes/integracoes-identificadas.md](integracoes/integracoes-identificadas.md) | Integrações externas identificadas no código e no banco |
| [modulos/README.md](modulos/README.md) | Ordem de migração dos módulos e status |
| [decisoes/README.md](decisoes/README.md) | Registro de decisões arquiteturais (ADRs) |
| [alteracoes/README.md](alteracoes/README.md) | Registro de alterações realizadas pela modernização |

## Convenções

- Cada alteração relevante gera/atualiza um registro em `alteracoes/` com motivo, impacto, dependências, testes, risco e rollback.
- Decisões estruturais viram ADR em `decisoes/` antes da implementação.
- Documentos por módulo serão criados em `modulos/` conforme cada módulo entrar em análise (nunca programar antes de documentar o comportamento atual).

## Pastas planejadas (backlog da Fase 0)

- `dominio/` — criada; contém o glossário. Receberá ainda o mapa de domínio (`mapa-de-dominio.md`).
- `compatibilidade/` — análise de compatibilidade das estruturas centrais (classificação `PRESERVAR/MODERNIZAR/REESTRUTURAR/NÃO TRANSPORTAR`, ADR-0006) e princípios de migração GSAN→SISAN (ADR-0005).
- `modulos/` — receberá os mapas funcionais por módulo (próxima atividade: cadastro) e o catálogo de funcionalidades futuras descobertas no `gsan_comercial` (`funcionalidades-futuras.md`).
