# ADR-0001 — Monólito modular com Spring Boot 4.1.x / Java 25 LTS

- Status: Proposta · Data: 2026-08-13

## Contexto
GSAN legado é um monólito Java EE 1.4 (JBoss 4, Struts 1.1, EJB 2.x, Hibernate 3) com ~2,39M LOC, forte acoplamento ao banco e equipe/infra dimensionadas para um sistema único. O prompt do projeto exige modernização incremental com coexistência sobre o mesmo banco.

## Decisão
Novo sistema como **monólito modular** Spring Boot 4.1.x sobre Java 25 LTS (módulos: cadastro, faturamento, arrecadacao, cobranca, micromedicao, atendimento, seguranca, relatorios, batch, integracoes, shared), build Maven multi-módulo, deploy containerizado único. Sem microserviços, mensageria ou Kubernetes sem necessidade técnica demonstrada.

## Consequências
- (+) Transações locais simples (crítico para regras financeiras); operação e observabilidade mais baratas; separação futura possível pelos limites de módulo.
- (−) Deploy único: um módulo problemático afeta o todo — mitigado por feature flags e roteamento por funcionalidade no proxy.

## Alternativas consideradas
Microserviços (rejeitada: custo operacional e transações distribuídas sem necessidade); modernização in-place do EAR (rejeitada: JBoss 4/EJB 2.x sem caminho de upgrade).

## Rollback
Enquanto a Fase 12 não desativa funcionalidades do legado, desligar o roteamento para o novo sistema restaura o comportamento anterior.
