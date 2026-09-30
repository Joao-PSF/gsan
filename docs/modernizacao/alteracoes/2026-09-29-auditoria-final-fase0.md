# [2026-09-29] Auditoria final e encerramento da Fase 0

- **Motivo**: a Fase 0 só restava fechar — mas encerrá-la sem uma varredura de omissões arriscava descobrir, já implementando, uma obrigação como a NFAg com o Faturamento construído. A auditoria procurou omissões **funcionais, regulatórias e arquiteturais**, corrigiu só as lacunas reais e decidiu o encerramento.
- **Impacto**: novo módulo **Fiscal**; PIX e boleto registrado na Etapa 5, Pix Automático na 6; Tarifa Social nacional e NFAg nas Etapas 4 e 7; dois bloqueios de cenário e o "único bloqueio de dia 1" resolvidos por evidência de código; D-18; 87 especificações.
- **Dependências**: nenhuma nova. **Testes**: nenhum executado. **Risco**: baixo (documental). **Rollback**: `git revert` do commit. **Migration**: nenhuma.

## 0. Verificação de continuidade

| Verificação | Resultado |
| ----------- | --------- |
| HEAD real | `9993ac1` — ADR-0007 aceita; local = remoto; árvore limpa |
| Commits posteriores | Nenhum |
| Auditoria já iniciada | Não |

## 1. Método

Hierarquia de evidência do projeto; **fonte oficial primeiro** para obrigação atual; classes L0–L6 por tema; resultado por tema (já coberto · corrigido · incorporado · deferido · não aplicável · pendente por fonte); contagens por script. ⚠️ Leitura direta de `www.gov.br`, `www.planalto.gov.br` e `dfe-portal.svrs.rs.gov.br` **bloqueada** pela política de rede — fontes oficiais lidas por resumo de busca, com a certeza rebaixada onde só havia fonte secundária.

## 2. O que se encontrou

| Achado | Natureza | Tratamento |
| ------ | -------- | ---------- |
| 🔴 **NFAg obrigatória** (modelo 75) — tratada como `EXIGE APROFUNDAMENTO`, H2, fora da ordem | Omissão regulatória estrutural | Módulo e [mapa Fiscal](../modulos/fiscal.md); **Conta ≠ NFAg**; Etapas 4 e 7; CEN-FIS-001 a 003 |
| 🔴 **Devolução personalizada (cashback) de IBS/CBS** na conta de água e esgoto | Omissão regulatória **fora do roteiro** | Regra do Fiscal, apresentação no Faturamento; parâmetros pendentes de validação fiscal |
| **Tarifa Social nacional** com concessão automática (Lei 14.898/2024; NR ANA 13/2025) | Obrigação | Capacidade regulatória necessária; CadÚnico/BPC; CEN-FAT-012 |
| PIX na Etapa 8 (canais) | Erro de posição | Arrecadação/Pagamentos — Etapa 5; Pix Automático na 6 |
| Contexto institucional e parâmetro regulado ausentes | Lacuna fundacional | Visão §23.2 e §27.3 — sem decidir multi-tenancy |
| 🔴 **Restrição por usuário "não observada"** na autorização | Afirmação errada | **Comprovada** no código (`ControladorAcessoSEJB:3104`, `:3517`) — o "único bloqueio de dia 1" deixou de existir; CAND-05 |
| "Fatura" C5 (BLQ-04) | Pendência resolvível | Documento **agregador** do cliente responsável — CEN-ARR-011 |
| Achado 6 sem `D-xx`; CSRF "sem antecedente" | Inconsistência | **D-18**, CEN-SEG-012; ADR-0007 corrigida |
| D-01…D-16 com status *Proposta* | Registro incompleto | Aprovação registrada com a origem |
| Nomes de roles ao lado de "senha = login" | Transcrição indireta de credencial | Lista retirada em dois documentos |

## 3. Números (por script)

| | Antes | Depois |
| - | ----: | -----: |
| Mapas funcionais | 12 | **13** (+ Fiscal) |
| Especificações | 79 | **87** (49 P0 · 38 P1; 6 com oráculo N) |
| Bloqueados por decisão | 4 | **2** (D-17) |
| Divergências aprovadas | 16 (registradas como *Proposta*) | **17** |
| Compatibilidade — 145 conceitos | 90 · 25 · 17 · 5 · 1 · 7 | **91 · 25 · 17 · 5 · 1 · 6** |
| Estruturas centrais — 64 decisões | 37 · 14 · 6 · 5 · 2 | **38 · 14 · 6 · 4 · 2** |
| Catálogo — natureza | 12 · 6 · 5 · 2 aprof. · 1 | **11 · 6 · 6 · 2 regulatórias · 1** (+ 3 sem origem no legado) |
| Completude | — | **50 temas**: 10 já cobertos · 20 corrigidos · 10 incorporados · 5 deferidos · 3 não aplicáveis · 2 pendentes por fonte |

## 4. Documentos

Criados: [`auditoria/auditoria-final-fase0.md`](../auditoria/auditoria-final-fase0.md) · [`auditoria/completude-funcional-regulatoria.md`](../auditoria/completude-funcional-regulatoria.md) · [`modulos/fiscal.md`](../modulos/fiscal.md) · [`testes/cenarios/fiscal.md`](../testes/cenarios/fiscal.md). Alterados: lista completa no [relatório, §18](../auditoria/auditoria-final-fase0.md#18-correções-realizadas).

## 5. O que ficou deliberadamente de fora

Código, migration, API, banco, execução do GSAN, baseline, integração fiscal, chamada Pix, envio ao SINISA ou ao SISAGUA · nenhum módulo *Regulação*, *Pagamentos*, *Tarifa Social*, *Laboratório* ou *LGPD* · nenhum PSP, leiaute, plataforma IoT ou biblioteca escolhidos · multi-tenancy **não decidido** · CAND-03 e CAND-04 **não aprovados**.

## 6. Veredito

**FASE 0 CONCLUÍDA** — não há lacuna estrutural P0/P1 não tratada. Pendências aceitas, riscos transferidos e próximo estágio no [relatório](../auditoria/auditoria-final-fase0.md#21-veredito-da-fase-0).
