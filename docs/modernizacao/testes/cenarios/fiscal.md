# Cenários Críticos — Fiscal (NFAg)

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md). Criado na [auditoria final da Fase 0](../../auditoria/auditoria-final-fase0.md) (2026-09-29).
>
> 🔴 **Requisito nativo do OpenGSAN — oráculo N.** O GSAN público não emite documento fiscal eletrônico (o schema `fiscal` da instalação de referência não tem código), então **não há baseline a capturar** nem comparação com o legado: o resultado esperado vem da **obrigação** e do leiaute oficial vigente. Onde a regra ainda não foi confirmada, o cenário registra `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` — nunca um resultado inventado.

🔵 **Leitura da área**: *Conta ≠ NFAg*. Os três cenários verificam que o documento fiscal nasce **do fato tributável publicado pelo Faturamento**, tem identidade e ciclo **próprios**, e que nenhuma conta fica em estado fiscal indefinido. Mapa: [`modulos/fiscal.md`](../../modulos/fiscal.md).

---

## CEN-FIS-001 — Emissão da NFAg a partir da conta: autorização e rejeição

- **Criticidade**: P0
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: documento fiscal (requisito nativo) · identidade documental da Conta (C2) · fato tributável
- **Objetivo**: verificar que uma conta emitida produz um documento fiscal **autorizado** — ou uma **rejeição rastreável** — sem que o motor tarifário carregue regra fiscal
- **Pré-condições**: DOC-01 (conta vigente emitida); determinação tributária vigente parametrizada com vigência e origem normativa; certificado de **homologação**; ambiente autorizador de homologação disponível
- **Entrada**: V1 — conta válida; V2 — conta com dado que o ambiente autorizador rejeita (motivo de rejeição do leiaute vigente); V3 — mesma conta reenviada após autorização (reenvio idempotente)
- **Operação GSAN**: não aplicável — sem equivalente no GSAN público
- **Operação conceitual OpenGSAN**: emitir documento fiscal a partir do fato tributável
- **Observações semânticas**: vínculo *versão da conta ↔ documento fiscal* · chave de acesso · série e número · situação fiscal (autorizada / rejeitada) · protocolo · motivo da rejeição · documento autorizado guardado · DANFAG gerável a partir do documento autorizado · coerência dos totais do documento fiscal com os do documento comercial · nenhum recálculo tarifário no Fiscal
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — documento **autorizado**, com chave, protocolo e vínculo à versão da conta; totais coerentes com a conta. V2 — **rejeição registrada com motivo**; a conta **não** fica "sem fiscal" em silêncio — o estado fiscal pendente é consultável e a correção segue pelo dono do dado (Faturamento ou Fiscal). V3 — **um** documento fiscal para a mesma versão da conta. ⚠️ Recepção síncrona e lista de rejeições: conforme o MOC vigente
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: chave, número e protocolo concretos (dependem do ambiente)
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; esperado derivado do leiaute oficial e de [`fiscal.md`](../../modulos/fiscal.md) §3–§5
- **Gate que este cenário protege**: 4 → 5 — *conta emitida produz documento fiscal autorizado em homologação ou rejeição rastreável*
- **Evidência**: [`modulos/fiscal.md`](../../modulos/fiscal.md) §1, §3–§5; Portal NFAg (SVRS); Ato Conjunto RFB/CGIBS nº 4/2026

---

## CEN-FIS-002 — Contingência e transmissão posterior

- **Criticidade**: P0
- **Etapa OpenGSAN**: 7 — Escala
- **Conceitos relacionados**: documento fiscal (requisito nativo) · processamento em lote (C1)
- **Objetivo**: verificar que a indisponibilidade do ambiente autorizador não impede a emissão e que todo documento emitido em contingência termina **autorizado ou tratado**
- **Pré-condições**: lote de contas de uma rota; ambiente autorizador **indisponível** durante a emissão e restabelecido depois
- **Entrada**: V1 — emissão em contingência seguida de transmissão bem-sucedida; V2 — transmissão posterior **rejeitada** para um dos documentos; V3 — reprocessamento do lote durante a contingência (não pode duplicar documentos)
- **Operação GSAN**: não aplicável — sem equivalente no GSAN público
- **Operação conceitual OpenGSAN**: emitir em contingência; transmitir e reconciliar depois
- **Observações semânticas**: modalidade de emissão (normal / contingência) · marca de contingência no documento auxiliar · fila de transmissão posterior · situação final de cada documento · reconciliação (quantos emitidos em contingência × quantos autorizados × quantos tratados) · unicidade por versão da conta
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: V1 — todos emitidos em contingência, com a marca exigida, e depois **autorizados**; a reconciliação fecha. V2 — o rejeitado fica **visível e tratável**; nenhum documento em estado indefinido. V3 — nenhum documento duplicado. ⚠️ Prazos e regras da contingência offline: conforme o MOC vigente — `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA`. ⚠️ Emissão **em campo** (impressão simultânea) é pendência própria (`fiscal.md` §6.1) e **não** é coberta por este cenário
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: chaves, números, protocolos e horários concretos
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo
- **Gate que este cenário protege**: 7 → operação — *nenhuma conta sem documento fiscal autorizado ou em contingência registrada*
- **Evidência**: [`modulos/fiscal.md`](../../modulos/fiscal.md) §6.1, §11; MOC NFAg — Visão Geral (contingência offline)

---

## CEN-FIS-003 — Retificação e cancelamento de conta com NFAg autorizada

- **Criticidade**: P0
- **Etapa OpenGSAN**: 7 — Escala
- **Conceitos relacionados**: documento fiscal (requisito nativo) · retificação e linhagem (C2) · cancelamento (C1)
- **Objetivo**: verificar que retificar ou cancelar uma conta **nunca altera** um documento fiscal autorizado e produz o **tratamento fiscal vigente**, com as identidades comercial e fiscal separadas
- **Pré-condições**: DOC-03 (conta A retificada por B) com documento fiscal de A autorizado; DOC-04 (conta cancelada) com documento fiscal autorizado; regra fiscal vigente de retificação e cancelamento parametrizada
- **Entrada**: V1 — retificação de valor de A (gera B); V2 — cancelamento de uma conta dentro do prazo fiscal; V3 — cancelamento **fora** do prazo fiscal
- **Operação GSAN**: não aplicável — no GSAN a retificação e o cancelamento existem (CEN-FAT-007, CEN-FAT-008), mas sem documento fiscal eletrônico
- **Operação conceitual OpenGSAN**: publicar fato de alteração do documento comercial; aplicar o tratamento fiscal vigente
- **Observações semânticas**: documento fiscal de A inalterado · evento ou novo documento produzido · vínculo entre o documento fiscal original e o que o sucede · vínculo *versão da conta ↔ documento fiscal* para A e B · linhagem comercial A → B preservada (C2) · pagamento já vinculado a A **não migra** (CEN-ARR-005)
- **Localizadores GSAN**: não aplicável
- **Resultado semântico esperado**: 🔴 **Invariantes** (independem da norma): o documento fiscal autorizado **não é alterado**; identidade comercial e identidade fiscal permanecem **separadas**; toda ação fiscal fica vinculada à versão da conta que a motivou; a retificação continua passando pela Micromedição (D-14). ⚠️ **Qual ação fiscal** cada variante exige — substituição, cancelamento seguido de nova emissão, outro instrumento — e o tratamento de V3: `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` (`fiscal.md` §7.1, pendência 2). O cenário **não** fecha antes dessa resposta
- **Baseline concreta do legado**: ➖ NÃO APLICÁVEL — requisito nativo
- **Normalizações**: chaves, números e protocolos concretos
- **Divergência permitida**: não aplicável
- **Oráculo**: **N** — requisito nativo; ⚠️ esperado de V1–V3 pendente de validação fiscal, invariantes já fixados
- **Gate que este cenário protege**: 7 → operação — *retificação e cancelamento com o tratamento fiscal vigente*
- **Evidência**: [`modulos/fiscal.md`](../../modulos/fiscal.md) §7.1, §12; [`compatibilidade/gsan-opengsan.md §8.3`](../../compatibilidade/gsan-opengsan.md); eventos de substituição e cancelamento descritos na documentação da NFAg (resumo de fonte especializada — confirmar no MOC)
