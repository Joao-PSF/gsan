# [2026-10-05] Fase 2 — lote de Segurança: autenticação e autorização

> Segundo lote de baselines da Fase 2. **Não implementa o OpenGSAN** e **não altera o legado**. A Fase 2 **continua em
> andamento**.

- **Motivo**: primeiro item da ordem de captura da [estratégia de testes](../testes/estrategia-testes.md#priorização-da-baseline-fase-2)
  — autenticação e autorização.
- **Impacto**: 6 definições executáveis de Segurança (`ambiente-referencia/baselines/cenarios/CEN-SEG-*.json`), 7
  deltas de massa, 19 baselines em `golden/seguranca/`; roteiro `seguranca` por passos; executor com autenticação pelo
  roteiro e senhas efêmeras por rótulo; cliente HTTP que registra respostas de erro; guarda de conexões que espera o
  PostgreSQL encerrar os backends. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo.
- **Testes**: captura com 2 execuções idênticas por variação; verificação independente do lote e **regressão** do
  piloto (o executor mudou); `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, usuários sintéticos, senhas efêmeras). **Rollback**: `git revert`.
  **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `0e70e43` (acesso remoto à instância de inspeção, sobre o piloto `88746a8`). Cobertura:
3 de 42 P0 da classe A.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| 6 cenários, 19 baselines — SEG-001, 002, 004, 005 (A) e SEG-010, 012 (C, registro) | `ambiente-referencia/baselines/golden/seguranca/` |
| Política de segurança da instância, com evidência e inferência separadas | [relatório §16.2](../testes/fase2/fase2-caracterizacao-baselines.md#162-política-de-segurança--parâmetros-da-instância) |
| Achados F2-13 a F2-25; achados de segurança 26–29; candidatos CAND-06 e CAND-07 | [relatório §16.8](../testes/fase2/fase2-caracterizacao-baselines.md#168-achados), [`riscos-identificados.md`](../seguranca/riscos-identificados.md), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência) |
| Cobertura (gerada): **7 de 42** P0 da classe A | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-07** | Depois do bloqueio, a senha correta mostra a recusa **e autentica a sessão** | Situação recusada nunca cria sessão |
| **CAND-06** | Negação por operação contornada pela entrada da funcionalidade | Autorização por caso de uso em toda execução |
| **CAND-04** (sustentado) | `pesquisar`/`relatorio` dispensam autorização e devolvem dado | Nenhuma exceção por nome |
| **CAND-03** (sustentado) | Tentativas distribuídas em sessões não bloqueiam | Contador persistente |

Nenhum foi aprovado aqui: aprovar é registro em [`divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md).

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§16 e §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) ·
`testes/cenarios/seguranca.md` (campo *Baseline concreta* de SEG-001, 002, 004, 005, 010, 012) ·
`testes/cenarios-criticos.md` §11 · `testes/estrategia-testes.md` · `compatibilidade/divergencias-aprovadas.md` ·
`seguranca/riscos-identificados.md` (achados 26–29) · `ambiente-referencia/baselines/README.md` · `alteracoes/README.md`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote de Segurança capturado com determinismo; P0 da classe A: 3 → **7 de 42**. Próximo
lote recomendado: **Segurança restante** — auditoria (SEG-006) e abrangência (SEG-007), ambas P0.
