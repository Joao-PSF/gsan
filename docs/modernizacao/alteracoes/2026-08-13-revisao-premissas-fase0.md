# [2026-08-13] Revisão de premissas da Fase 0 (2ª execução)

- **Motivo**: novas definições do responsável pelo projeto: (a) não existe GSAN em produção neste projeto — sem banco real, usuários, DBA, coexistência obrigatória ou janela de corte; (b) SISAN é **modernização evolutiva do GSAN** (não sistema novo do zero), com migração de instalações GSAN existentes como **requisito arquitetural futuro**; (c) `gsan_comercial` é fonte complementar (compatibilidade + descoberta funcional), não o schema alvo; (d) repositório SISAN confirmado para o código novo; (e) execução inicial em VPS de testes/homologação.
- **Impacto**: somente documentação — nenhuma alteração de código ou banco.

## Continua válido (não retrabalhado)

Diagnóstico técnico do legado (runtime, frameworks, contagens, camadas, batch, relatórios); inventário estrutural do `gsan_comercial` (números e classificação preliminar); levantamento de segurança do legado (achados técnicos); levantamento de integrações; stack alvo (Java 25 LTS, Spring Boot 4.1.x, PostgreSQL 18.x, Flyway, Maven); monólito modular; estratégia de testes de caracterização/equivalência (princípio A=B); ordem preliminar dos módulos.

## Ajustado

- **Coexistência legado+novo no mesmo banco** deixou de ser premissa de desenvolvimento → vira cenário do playbook de migração futura de companhias usuárias (`arquitetura-alvo.md`).
- **Modelo de dados**: SISAN tem banco próprio (UTF-8), evoluído dos conceitos GSAN com classificação `PRESERVAR / MODERNIZAR / REESTRUTURAR / NÃO TRANSPORTAR` (ADR-0006) — não cópia do schema do legado (`arquitetura-alvo.md`, `banco/*`).
- **Flyway sem baseline do legado**: schema do SISAN nasce versionado desde `V1`; não haverá `V1__baseline.sql` copiada do `gsan_comercial` (ADR-0002 ajustada).
- **Documento de PostgreSQL** reestruturado em: (1) PostgreSQL do SISAN; (2) restauração de bases GSAN para análise; (3) estratégia futura de migração GSAN→SISAN (`banco/migracao-postgresql.md`).
- **Drift** migrations × banco: deixa de ser pendência a reconciliar com produção → vira **evidência de variabilidade entre instalações GSAN**, insumo do requisito de compatibilidade (`banco/estrutura-atual.md`).
- **Segurança**: prioridades P0 reinterpretadas — rotação de credenciais e proteção de APIs valem para instalações operantes e entram no checklist de migração futura; para o SISAN viram requisitos de nascimento (sem credencial padrão, autenticação real, TLS na VPS) (`seguranca/*`).
- **Testes**: massa de dados passa a ser sintética representativa (ou de base GSAN de referência, se obtida) — não "derivada de produção"; comparação legado×novo passa a ser semântica via mapeamento GSAN→SISAN quando schemas divergirem (`testes/estrategia-testes.md`).
- **Plano de trabalho**: recebe aviso de revisão no topo; fases 6/8/12 e "primeiro ciclo" reinterpretados (ver abaixo).

## Invalidado

- Dependências bloqueadoras de acesso a banco/DBA/infra de produção (itens 1–5 do "primeiro ciclo" da 1ª execução).
- Rotação imediata de credenciais como P0 deste projeto (não operamos a infraestrutura).
- Roteamento de telas por proxy entre GSAN e SISAN como estratégia de desenvolvimento.
- Corte de produção PostgreSQL (Fase 8 como "projeto de corte") e desativação de legado em produção (Fase 12) como atividades deste projeto.
- ADR-0004 original ("manter LATIN1 na primeira migração") — formulada sob premissa de migração de produção inexistente.

## Decisões (mudanças de status)

| ADR | Antes | Depois |
| --- | ----- | ------ |
| 0003 — Código novo no repositório SISAN | Proposta | **Aceita** |
| 0004 — Encoding | Proposta (manter LATIN1) | **Reescrita e Aceita**: UTF-8 no SISAN; encoding de origem tratado pela migração, caso a caso |
| 0005 — SISAN como modernização evolutiva e compatível do GSAN | — | **Nova, Aceita** |
| 0006 — Modelo de dados evolutivo (PRESERVAR/MODERNIZAR/REESTRUTURAR/NÃO TRANSPORTAR) | — | **Nova, Aceita** |
| 0001 (monólito modular) e 0002 (Flyway) | Proposta | Permanecem Proposta (0002 com baseline ajustada) |

- **Testes**: n/a (alteração documental).
- **Risco**: baixo.
- **Rollback**: `git revert` do commit desta revisão.
