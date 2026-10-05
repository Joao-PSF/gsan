#!/usr/bin/env python3
"""Classificação A/B/C/N das 103 especificações de cenário (Fase 2).

Deriva, só dos campos das especificações (docs/modernizacao/testes/cenarios/*.md):

  A  baseline do GSAN necessária — o oráculo 1 (ou a decisão pendente) depende de executar o legado;
  B  evidência estática suficiente — o observável é um artefato versionado, já lido (JÁ COMPROVADA);
  C  divergência aprovada — oráculo 2 puro: o esperado vem da divergência registrada, e a execução do
     legado, quando pedida, só registra o comportamento de que se diverge (não é oráculo);
  N  requisito nativo — sem equivalente no GSAN; o esperado vem da norma ou da decisão.

Regras (em ordem): oráculo N → N; baseline JÁ COMPROVADA → B; oráculo 2 sem 1 nem PENDENTE → C; resto → A.
Ajustes manuais, sempre com justificativa, em ../caracterizacao-ajustes.tsv.

"Massas iniciais" conta as variações de entrada a capturar (uma entrada única quando a especificação não
declara variações): é o limite superior do número de massas efetivas — variações que só diferem na entrada
compartilham a mesma massa (ver o lote piloto). Variações sob oráculo 2 de um cenário A e as marcadas
"não é comparado" ficam fora da contagem de A e aparecem na justificativa.

Uso:
  caracterizacao.py gerar      reescreve a matriz (docs) e o TSV
  caracterizacao.py verificar  falha se os arquivos versionados não forem os que o script gera
"""
import os
import re
import sys

import cenarios

AQUI = os.path.dirname(os.path.abspath(__file__))
AJUSTES = os.path.join(AQUI, '..', 'caracterizacao-ajustes.tsv')
TSV = os.path.join(AQUI, '..', 'caracterizacao.tsv')
MATRIZ = os.path.join(cenarios.RAIZ, 'docs', 'modernizacao', 'testes', 'fase2', 'matriz-caracterizacao.md')

DOMINIOS = {
    'arrecadacao.md': 'Arrecadação', 'batch-relatorios-integracoes.md': 'Batch, relatórios e integrações',
    'cadastro-atendimento.md': 'Cadastro e atendimento', 'cobranca.md': 'Cobrança', 'faturamento.md': 'Faturamento',
    'financeiro-operacional.md': 'Financeiro e operacional', 'fiscal.md': 'Fiscal', 'micromedicao.md': 'Micromedição',
    'modularidade.md': 'Modularidade', 'pcm-paradas.md': 'PCM e paradas', 'regulatorio.md': 'Regulatório',
    'seguranca.md': 'Segurança',
}
CLASSES = {
    'A': 'baseline GSAN necessária', 'B': 'evidência estática suficiente',
    'C': 'divergência aprovada', 'N': 'requisito nativo',
}


def expandir(texto):
    ids = []
    for a, b in re.findall(r'\bV(\d+)\s*[–-]\s*V(\d+)\b', texto):
        ids += [f'V{n}' for n in range(int(a), int(b) + 1)]
    ids += re.findall(r'\bV\d+[a-z]?\b', texto)
    return sorted(set(ids), key=lambda v: (int(re.sub(r'\D', '', v)), v))


def oraculo_por_variacao(oraculo):
    """{variação: '1' | '2' | 'PENDENTE'} quando o campo Oráculo reparte por variação (não por observável)."""
    mapa = {}
    for rotulo, parenteses in re.findall(r'\*\*(1|2|PENDENTE DE [A-ZÇÃÉ]+)\*\*\s*\(([^)]*)\)', oraculo):
        for v in expandir(parenteses):
            mapa[v] = 'PENDENTE' if rotulo.startswith('PENDENTE') else rotulo
    for v in re.findall(r'\b(V\d+[a-z]?)\s+PENDENTE DE', oraculo):
        mapa[v] = 'PENDENTE'
    return mapa


def nao_comparadas(oraculo):
    return expandir(' '.join(re.findall(r'(V\d+(?:\s*(?:,|e|[–-])\s*V\d+)*)\s+não (?:é|são) comparad', oraculo)))


def tipo_oraculo(oraculo):
    if oraculo.startswith('**N**'):
        return 'N'
    tem1 = '**1**' in oraculo
    tem2 = '**2**' in oraculo
    pend = 'PENDENTE' in oraculo
    partes = (['1'] if tem1 else []) + (['2'] if tem2 else [])
    rotulo = '+'.join(partes)
    if pend:
        rotulo = (rotulo + ' · ' if rotulo else '') + 'PENDENTE'
    return rotulo


def ler_ajustes():
    ajustes = {}
    if not os.path.exists(AJUSTES):
        return ajustes
    for linha in open(AJUSTES, encoding='utf-8'):
        if not linha.strip() or linha.startswith('#'):
            continue
        cen, classe, massas, justificativa = linha.rstrip('\n').split('\t')
        assert classe in CLASSES, (cen, classe)
        assert justificativa.strip(), f'{cen}: ajuste sem justificativa'
        ajustes[cen] = (classe, int(massas) if massas else None, justificativa)
    return ajustes


def classificar(c, ajustes):
    oraculo, baseline = c['oraculo'], c['baseline']
    tipo = tipo_oraculo(oraculo)
    variacoes = c['variacoes']
    por_var = oraculo_por_variacao(oraculo)
    fora = nao_comparadas(oraculo)
    notas = []

    if tipo == 'N':
        classe = 'N'
        execucao = 'Não — sem equivalente no GSAN público'
        massas = 0
        notas.append('esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado')
    elif 'JÁ COMPROVADA' in baseline:
        classe = 'B'
        execucao = 'Não — o observável é artefato versionado, já lido'
        massas = 0
        notas.append('baseline JÁ COMPROVADA na Fase 0: ler o artefato é observá-lo')
        if '2' in tipo.split('+'):
            notas.append('oráculo 2: o OpenGSAN deve divergir')
    elif tipo == '2':
        classe = 'C'
        # A CAPTURAR (Fase 0) ou CAPTURADA (Fase 2): a execução do legado existe para registrar a divergência.
        if 'A CAPTURAR' in baseline or 'CAPTURADA' in baseline:
            execucao = 'Sim — só registro do comportamento de que se diverge (não é oráculo)'
            massas = len(variacoes) or 1
        else:
            execucao = 'Não'
            massas = 0
        notas.append('esperado vem da divergência aprovada; igualdade com o legado seria o defeito')
    else:
        classe = 'A'
        execucao = 'Sim'
        notas.append('oráculo 1: o resultado concreto só existe executando o GSAN'
                     if tipo in ('1', '1+2', '1 · PENDENTE') else 'oráculo decidido pela própria baseline')
        if variacoes:
            dois = [v for v in variacoes if por_var.get(v) == '2']
            a_capturar = [v for v in variacoes if v not in dois and v not in fora]
            massas = len(a_capturar)
            if dois:
                notas.append('variações sob oráculo 2 (só registro): ' + ', '.join(dois))
            if fora:
                notas.append('não comparadas: ' + ', '.join(fora))
        else:
            massas = 1
            notas.append('entrada única (sem variações declaradas)')
        pendentes = sorted(v for v, o in por_var.items() if o == 'PENDENTE')
        if 'PENDENTE DE CARACTERIZAÇÃO' in oraculo:
            alvo = ('em ' + ', '.join(pendentes) + ', ') if pendentes else ''
            notas.append(alvo + 'a própria baseline decide entre oráculo 1 e divergência')
        elif pendentes:
            notas.append('decisão pendente em ' + ', '.join(pendentes) + ' — capturar informa a decisão')
        if tipo == '1+2' and not any(o == '2' for o in por_var.values()):
            notas.append('oráculo 2 só em observáveis, não em variações')

    if c['id'] in ajustes:
        classe, massas_aj, justificativa = ajustes[c['id']]
        if massas_aj is not None:
            massas = massas_aj
        notas.insert(0, 'AJUSTE: ' + justificativa)
        execucao = {'A': 'Sim', 'B': 'Não — evidência estática', 'N': 'Não — sem equivalente no GSAN público'}.get(
            classe, execucao)

    return {
        'cenario': c['id'], 'dominio': DOMINIOS[c['arquivo']], 'prioridade': c['criticidade'],
        'oraculo': tipo, 'classe': classe, 'execucao': execucao, 'massas': massas,
        'variacoes': len(variacoes), 'justificativa': '; '.join(notas), 'titulo': c['titulo'],
        'arquivo': c['arquivo'], 'etapa': c['etapa'],
    }


def matriz():
    ajustes = ler_ajustes()
    linhas = [classificar(c, ajustes) for c in cenarios.ler()]
    desconhecidos = set(ajustes) - {l['cenario'] for l in linhas}
    assert not desconhecidos, f'ajuste para cenário inexistente: {desconhecidos}'
    return linhas


def ancora(l):
    titulo = f"{l['cenario']} — {l['titulo']}".lower()
    titulo = re.sub(r'[^\w\s-]', '', titulo, flags=re.U).strip()
    return re.sub(r'\s', '-', titulo)


def gerar_tsv(linhas):
    cab = ['cenario', 'dominio', 'prioridade', 'oraculo', 'classe', 'execucao', 'massas', 'variacoes', 'justificativa']
    saida = ['\t'.join(cab)]
    for l in linhas:
        saida.append('\t'.join(str(l[k]) for k in cab))
    return '\n'.join(saida) + '\n'


def contar(linhas, chave):
    total = {}
    for l in linhas:
        total[l[chave]] = total.get(l[chave], 0) + 1
    return total


def gerar_md(linhas):
    por_classe = contar(linhas, 'classe')
    out = []
    w = out.append
    w('# Matriz de caracterização — Fase 2')
    w('')
    w('> ⚠️ **Gerado por script** — `ambiente-referencia/baselines/ferramentas/caracterizacao.py gerar`, a partir das')
    w('> especificações em [`../cenarios/`](../cenarios/) e dos ajustes justificados em')
    w('> [`caracterizacao-ajustes.tsv`](../../../../ambiente-referencia/baselines/caracterizacao-ajustes.tsv). Não editar à mão.')
    w('> Critérios e leitura: [`fase2-caracterizacao-baselines.md`](fase2-caracterizacao-baselines.md) §3.')
    w('')
    w('## Totais')
    w('')
    w('| Classe | Significado | Cenários | P0 | P1 | P2 | Massas iniciais |')
    w('| ------ | ----------- | -------- | -- | -- | -- | --------------- |')
    for k in 'ABCN':
        sel = [l for l in linhas if l['classe'] == k]
        pr = contar(sel, 'prioridade')
        w(f"| **{k}** | {CLASSES[k]} | {len(sel)} | {pr.get('P0', 0)} | {pr.get('P1', 0)} | {pr.get('P2', 0)} | "
          f"{sum(l['massas'] for l in sel)} |")
    pr = contar(linhas, 'prioridade')
    w(f"| **Total** | | **{len(linhas)}** | {pr.get('P0', 0)} | {pr.get('P1', 0)} | {pr.get('P2', 0)} | "
      f"**{sum(l['massas'] for l in linhas)}** |")
    w('')
    execucao = [l for l in linhas if l['execucao'].startswith('Sim')]
    w(f"**Precisam de execução do GSAN**: {len(execucao)} cenários — {por_classe.get('A', 0)} como oráculo (A) e "
      f"{len([l for l in execucao if l['classe'] == 'C'])} só como registro da divergência (C). "
      f"Variações declaradas nas especificações: {sum(l['variacoes'] for l in linhas)}.")
    w('')
    w('## Por domínio')
    w('')
    w('| Domínio | A | B | C | N | Massas iniciais (A) |')
    w('| ------- | - | - | - | - | ------------------- |')
    for dom in sorted(set(l['dominio'] for l in linhas)):
        sel = [l for l in linhas if l['dominio'] == dom]
        pc = contar(sel, 'classe')
        w(f"| {dom} | {pc.get('A', 0)} | {pc.get('B', 0)} | {pc.get('C', 0)} | {pc.get('N', 0)} | "
          f"{sum(l['massas'] for l in sel if l['classe'] == 'A')} |")
    w('')
    w('## Matriz')
    w('')
    w('| Cenário | Domínio | Prioridade | Classe | Tipo de oráculo | Precisa execução GSAN? | Massas iniciais | Justificativa |')
    w('| ------- | ------- | ---------- | ------ | --------------- | ---------------------- | --------------- | ------------- |')
    for l in linhas:
        link = f"[{l['cenario']}](../cenarios/{l['arquivo']}#{ancora(l)})"
        w(f"| {link} | {l['dominio']} | {l['prioridade']} | **{l['classe']}** | {l['oraculo']} | {l['execucao']} | "
          f"{l['massas']} | {l['justificativa']} |")
    w('')
    return '\n'.join(out)


def main():
    modo = sys.argv[1] if len(sys.argv) > 1 else ''
    linhas = matriz()
    alvos = [(TSV, gerar_tsv(linhas)), (MATRIZ, gerar_md(linhas))]
    if modo == 'gerar':
        for caminho, conteudo in alvos:
            os.makedirs(os.path.dirname(caminho), exist_ok=True)
            with open(caminho, 'w', encoding='utf-8', newline='\n') as f:
                f.write(conteudo)
        pc = contar(linhas, 'classe')
        print(f"{len(linhas)} cenários — " + ', '.join(f"{k}: {pc.get(k, 0)}" for k in 'ABCN')
              + f" — massas iniciais: {sum(l['massas'] for l in linhas)}")
    elif modo == 'verificar':
        ruins = [c for c, conteudo in alvos
                 if not os.path.exists(c) or open(c, encoding='utf-8').read() != conteudo]
        if ruins:
            print('desatualizado: ' + ', '.join(os.path.relpath(r, cenarios.RAIZ) for r in ruins))
            sys.exit(1)
        print('matriz de caracterização atualizada')
    else:
        print(__doc__)
        sys.exit(2)


if __name__ == '__main__':
    main()
