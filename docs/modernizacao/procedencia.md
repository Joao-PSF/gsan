# Procedência das Fontes e Método de Verificação

Criado em 2026-09-14 em resposta à crítica de rastreabilidade da revisão externa. **Nenhuma afirmação da documentação da Fase 0 é verificável se a fonte não estiver identificada.** Este documento fixa as fontes e o método.

---

## 1. Fontes

| Fonte | Identificação | Uso |
| ----- | ------------- | --- |
| Código GSAN | repositório `Joao-PSF/gsan`, branch `claude/gsan-modernizacao-tecnica-rd5g60` | Fonte primária de comportamento |
| — commit dos mapas de módulo (cadastro → relatórios) | `2031c4ca762c3ec2597ea8c057db97aa388e5589` | Base das análises de 2026-08-13 a 2026-08-14 |
| — commit do mapa de Integrações e das correções | este commit | Base das análises de 2026-09-14 |
| DDL `gsan_comercial` | arquivo fornecido pelo usuário (`03056c39-gsan_comercial.txt`) | **Fonte complementar** — compatibilidade e descoberta funcional. Nunca é o schema alvo do SISAN (ADR-0006) |
| Migrations | repositório `Joao-PSF/gsan-migracoes` | Versionamento histórico do banco |

⚠️ **Limitação declarada**: o hash do arquivo DDL não foi registrado na época em que a análise do banco foi feita. Toda afirmação derivada do DDL está marcada como tal e deve ser reconferida contra o arquivo vigente antes de virar decisão. Este é um débito reconhecido, não uma omissão silenciosa.

---

## 2. Níveis de certeza

Convenção adotada a partir do mapa da Arrecadação e aplicada retroativamente nos mapas seguintes:

| Marca | Significado | Critério para usar |
| ----- | ----------- | ------------------ |
| 🟢 | **Fato** | Lido diretamente no código/DDL, com arquivo e linha citados. Reproduzível por terceiro |
| 🔵 | **Interpretação** | Conclusão sustentada por evidência 🟢, mas que envolve juízo sobre intenção ou consequência |
| 🟡 | **Hipótese** | Plausível, com indício parcial; não comprovada |
| ❔ | **Não compreendido** | Dúvida aberta e registrada. Nunca preenchida por suposição |

**Regra derivada dos erros cometidos**: ausência de evidência **não** é evidência de ausência. Uma busca que não encontra um nome não autoriza afirmar que o comportamento não existe — autoriza apenas afirmar que aquele nome não aparece naquele escopo. Afirmações de inexistência exigem busca **exaustiva e declarada** (escopo + comando + resultado).

---

## 3. Método de contagem

Todo número publicado deve declarar **o que conta** e **em que escopo**. Métricas diferentes sobre o mesmo objeto divergem legitimamente; o defeito não é divergir, é não dizer qual métrica é.

### 3.1 Classes EJB

| Métrica | Valor | Como obter |
| ------- | ----: | ---------- |
| Classes com `MessageDrivenBean` em `src/` | **166** | `grep -rl "MessageDrivenBean" src --include=*.java \| wc -l` |
| Classes com `SessionBean` em `src/` | 69 | `grep -rl "SessionBean" src --include=*.java \| wc -l` |
| — das quais abstratas | 1 | `ControladorComum.java:79` — `public abstract class ControladorComum implements SessionBean` |
| **Session Beans concretos** | **68** | 69 − 1 |
| **Total de classes EJB concretas** | **234** | 166 + 68 |

⚠️ **Não confundir com** as ~247 declarações de EJB nos descritores `META-INF/ejb-jar.xml`. Aquilo conta **deployments declarados**, não classes concretas distintas: há controlador sem descritor e descritor apontando para classe compartilhada. As duas métricas são válidas e medem coisas diferentes.

### 3.2 Modos de arredondamento (Faturamento)

Escopo declarado: **`ControladorFaturamentoFINAL.java` apenas** (o pacote inteiro não foi contado). Ver [`modulos/faturamento.md §27`](modulos/faturamento.md).

⚠️ Contar **modos semânticos**, não constantes: `BigDecimal.ROUND_HALF_UP` (int, depreciado) e `RoundingMode.HALF_UP` (enum) são **o mesmo modo** em duas APIs.

---

## 4. Correções de fato já aplicadas

Registro das afirmações que foram publicadas erradas e depois corrigidas, para que ninguém reuse a versão antiga.

| Data | Afirmação incorreta | Onde estava | Correção |
| ---- | ------------------- | ----------- | -------- |
| 2026-08-14 | `ContaGeral` preserva identidade "através da retificação" | `faturamento.md` | Identidade é estável **corrente↔histórico**; retificação cria documento novo com linhagem por origem |
| 2026-09-14 | "Faturamento não regrava consumo" | `faturamento.md §5`, `micromedicao.md` | Três casos distintos; a **retificação escreve diretamente** (`ControladorRetificarConta:273`) |
| 2026-09-14 | "Arredondamento HALF_UP centralizado" | `faturamento.md §27` | **Cinco políticas semânticas** distintas; 21 usos de `RoundingMode.UP`; truncamento na base de imposto |
| 2026-09-14 | `calcularValorFaturadoFaixaCAER` como exemplo do núcleo da Micromedição | `micromedicao.md` | Método pertence a `ControladorFaturamentoFINAL` (Faturamento) |
| 2026-09-14 | "Senhas com MD5/SHA-1" | `riscos-identificados.md`, `plano-de-trabalho.md` | Login usa **SHA-1**; MD5 é token efêmero de servlets auxiliares |
| 2026-09-14 | Acesso ao artefato de relatório como "dúvida prioritária" | `relatorios.md`, `seguranca.md` | **Achado confirmado** — cadeia completa de filtros verificada |
| 2026-09-14 | `api/GsanApi.java` (raiz) citado como evidência | `integracoes-identificadas.md` | Cópia obsoleta; a viva é `src/gcom/api/GsanApi.java` |
| 2026-09-14 | Codificação do banco "LATIN1 confirmado" | `banco/estrutura-atual.md` | Rebaixado a **indício forte** (🔵), não fato |

---

## 5. Regra permanente

1. Toda afirmação 🟢 cita **arquivo:linha**.
2. Todo número cita **métrica e escopo**.
3. Toda afirmação de **inexistência** declara o comando de busca e o escopo varrido.
4. Nenhum documento técnico justifica decisão por autoridade do pedido ("o prompt exige"). Justifica-se por evidência e argumento — o pedido é contexto do projeto, não razão técnica.
5. Correção de fato publicado entra na tabela §4, **não** é apagada silenciosamente.
