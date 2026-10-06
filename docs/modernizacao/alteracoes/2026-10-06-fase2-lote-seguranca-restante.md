# [2026-10-06] Fase 2 — Segurança restante: auditoria, abrangência e ciclo de vida da credencial

> Terceiro lote de baselines da Fase 2. **Não implementa o OpenGSAN** e **não altera o legado**. A Fase 2 **continua em
> andamento**.

- **Motivo**: o restante do item 1 da [ordem de captura](../testes/estrategia-testes.md#priorização-da-baseline-fase-2) —
  auditoria (CEN-SEG-006) e abrangência (CEN-SEG-007), ambas P0 — e o ciclo de vida da credencial (CEN-SEG-003, P1), que
  usa a mesma fronteira e a mesma massa.
- **Impacto**: 3 definições executáveis (`ambiente-referencia/baselines/cenarios/CEN-SEG-003/006/007.json`), 8 deltas de
  massa, 15 baselines novas em `golden/seguranca/` e 1 substituída com justificativa (CEN-SEG-012 V1); passos novos no
  roteiro `seguranca` (redefinição de senha, credencial antes/depois, auditoria, datas, histórico); leitura da mensagem
  de "Atenção" servida com HTTP 500; correção da classificação do login. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo.
- **Testes**: captura com 2 execuções idênticas por variação; verificação independente de todo o lote de Segurança e
  regressão do piloto; `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, usuários sintéticos, senhas efêmeras). **Rollback**: `git revert`.
  **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `2d5c652` (lote de Segurança, ambiente recriado com a senha atual do `admin`). Cobertura:
7 de 42 P0 da classe A; 30 baselines.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| CEN-SEG-006 (V1–V3), CEN-SEG-007 (V1–V5), CEN-SEG-003 (V1–V6, V5b) — 15 baselines | `ambiente-referencia/baselines/golden/seguranca/` |
| Achados F2-26 a F2-36; achados de segurança 30–32; candidatos CAND-08 e CAND-09 | [relatório §17](../testes/fase2/fase2-caracterizacao-baselines.md#17-lote-2b--segurança-restante-2026-10-06), [`riscos-identificados.md`](../seguranca/riscos-identificados.md), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência) |
| Política de senha: inferência de §16.2 confirmada por execução; aviso de expiração observado | [relatório §17.8](../testes/fase2/fase2-caracterizacao-baselines.md#178-política-de-senha--o-que-mudou-de-estado) |
| Cobertura (gerada): **9 de 42** P0 da classe A — todos os P0 de Segurança | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-08** | A operação 818 redefine a senha de qualquer login para um **valor fixo no código**, sem impor troca | Credencial aleatória de uso único, com troca obrigatória |
| **CAND-09** | PENDENTE e expirado veem a troca imposta, mas a **sessão já dá acesso** às funcionalidades concedidas | Sessão restrita à troca até ela acontecer |

Nenhum foi aprovado aqui. 🔴 O valor da senha fixa (achado 30) **não foi transcrito** em nenhum documento nem baseline:
registram-se local, natureza, risco e tratamento — e, pela regra de [`riscos-identificados.md`](../seguranca/riscos-identificados.md#regras-desde-já),
ele é considerado comprometido.

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§17, §12–§16.2) · `testes/fase2/cobertura-baselines.md` e
`matriz-caracterizacao.md` (gerados) · `testes/cenarios/seguranca.md` (campo *Baseline concreta* de SEG-003, 006, 007) ·
`testes/cenarios-criticos.md` §11 · `testes/estrategia-testes.md` · `compatibilidade/divergencias-aprovadas.md` ·
`seguranca/riscos-identificados.md` (achados 30–32) · `modulos/seguranca.md` (ramo de abrangência do filtro; redefinição
de senha) · `ambiente-referencia/baselines/README.md` · `alteracoes/README.md`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Segurança restante capturada com determinismo (15/15 idênticas); verificação independente **Segurança 34/34** e **piloto 11/11** — as 45 baselines conferem com o roteiro final. P0 da classe A: 7 → **9 de 42** —
todos os P0 de Segurança cobertos. Próximo lote recomendado: **3 — Cadastro e faturamento online** (CAD-004 e FAT-003,
P0), que reaproveita a massa IMV-* e a fronteira da simulação do piloto.
