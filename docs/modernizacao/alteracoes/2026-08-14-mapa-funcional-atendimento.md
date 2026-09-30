# [2026-08-14] Mapa funcional do Atendimento + correção residual de redação

- **Atividade**: análise funcional do Atendimento (RA, estados, especificação da solicitação, matrícula/local da ocorrência, prazo/espera/reiteração, tramitação, encerramento/reativação/duplicidade, OS, estados, RA↔OS, serviço e prioridade, programação/execução, encerramento da OS, OS referenciada, cobrança do serviço, efeito cadastral, fronteiras com os demais módulos, canais, agência reguladora, parametrização, variações por companhia) seguindo os fluxos de execução. Nenhuma implementação realizada.
- **Correção residual**: `MODERNIZACAO_GSAN.md` — a formulação "consumo nunca regravado pelo faturamento" foi substituída por "no fluxo principal analisado o Faturamento utiliza o consumo mantido pela Micromedição como insumo; não foi identificado nesse fluxo reprocessamento/gravação de `ConsumoHistorico`", alinhando o resumo ao nível de certeza já aplicado em `faturamento.md` no commit `4aabc06`. Nenhuma reanálise de Faturamento.
- **Documentos criados**: `docs/modernizacao/modulos/atendimento.md` (com níveis de certeza 🟢/🔵/🟡/❔).
- **Documentos alterados** (só onde houve resolução real): `modulos/cadastro.md` (mecanismo do efeito cadastral precisado), `modulos/micromedicao.md` (origem das alterações de hidrômetro e fronteira de propriedade do dado), `dominio/glossario.md` (termos RA e Imóvel precisados), `modulos/README.md`, `docs/modernizacao/README.md`, `MODERNIZACAO_GSAN.md`.

## Principais descobertas

- **RA = protocolo da demanda; OS = unidade de execução**, com vínculo **opcional nos dois sentidos**: RA sem OS (encerramento com parecer/automático) e **OS sem RA** confirmada por três caminhos (ação de cobrança com `cbdo_id`, fiscalização coletiva, comando de ordem seletiva).
- **`SolicitacaoTipoEspecificacao` é o núcleo paramétrico do módulo**: prazo, obrigatoriedade de matrícula/cliente/solicitante/documento, verificação de débito, geração de OS, geração de débito/crédito e valor, cobrança de juros, urgência, encerramento automático, informar conta/pagamento em duplicidade, alterar vencimento e loja virtual.
- **Regras de serviço em dois níveis**: especificação (o que foi pedido) + `ServicoTipo` (o que se executa), que já referencia `DebitoTipo` e `CreditoTipo`.
- **Mecanismo real do efeito cadastral** (dúvida herdada de Cadastro e Micromedição): não é gatilho do encerramento — são as operações "Efetuar ligação/religação/instalação/substituição/retirada…" que atualizam o domínio dono e **marcam a OS** (`orse_iccomercialatualizado`, `orse_icatualizaagua/esgoto`) como registro de que a atualização ocorreu.
- **Encerrar ≠ executar**: a OS tem descrição explícita "encerrada porém não foi executada"; e distingue **geração, emissão e execução** como marcos separados, além do estado **AGUARDANDO_LIBERAÇÃO**.
- **Tramitação é histórico auditável** (unidade origem/destino, usuário responsável × usuário que registrou, parecer), com `unid_idatual` como estado corrente.
- **Prazo tem memória** (data prevista original × atual) e base paramétrica em dias, com utilitários de dias úteis.
- **Reativação e duplicidade encadeiam protocolos distintos** — mesmo princípio de linhagem da retificação de contas; os códigos "RA referência/atual/anterior" são **rótulos de tela**, não versionamento (correção de premissa).
- **Matrícula**: o banco permite `registro_atendimento.imov_id` NULL e existem demandas de rede/área (falta d'água generalizada por bairro-área, ocorrências com coordenadas sem logradouro); porém o mapping Hibernate exige imóvel — necessidade de negócio confirmada, forma de persistência em aberto.
- **Sem subclasses por companhia** nos controladores de RA/OS: a variação é absorvida por parametrização — o módulo é o melhor exemplo interno de "regra como dado".
- **Fronteiras financeiras confirmadas**: débito de serviço gerado a partir da OS (com parcelas), crédito a realizar e crédito a transferir no fluxo do RA, retificação de conta disparada pelo atendimento, e pagamento em duplicidade → devolução (com a Arrecadação como dona).

- **Cenários de caracterização**: 22 candidatos comprovados; **11 dúvidas abertas** mantidas explicitamente, incluindo a fronteira de autorização, que foi registrada como pauta para o mapa de Segurança.
- **Dependências**: nenhuma. **Testes**: n/a (documental). **Risco**: baixo. **Rollback**: `git revert` do commit.
