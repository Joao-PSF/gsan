#!/usr/bin/env python3
"""Cobertura de baselines da Fase 2 — derivada, nunca escrita à mão.

Cruza a classificação (../caracterizacao.tsv), as definições executáveis (../cenarios/*.json) e as
baselines gravadas (../golden/**/*.json). Uma baseline só conta se o arquivo existir e declarar o
mesmo cenário e variação do caminho.

  cobertura.py gerar      reescreve docs/modernizacao/testes/fase2/cobertura-baselines.md
  cobertura.py verificar  falha se o arquivo versionado não for o que o script gera
"""
import csv
import glob
import json
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.normpath(os.path.join(AQUI, '..'))
RAIZ = os.path.normpath(os.path.join(BASE, '..', '..'))
SAIDA = os.path.join(RAIZ, 'docs', 'modernizacao', 'testes', 'fase2', 'cobertura-baselines.md')


def carregar():
    with open(os.path.join(BASE, 'caracterizacao.tsv'), encoding='utf-8') as f:
        matriz = {l['cenario']: l for l in csv.DictReader(f, delimiter='\t')}
    definicoes = {}
    for arq in sorted(glob.glob(os.path.join(BASE, 'cenarios', '*.json'))):
        with open(arq, encoding='utf-8') as f:
            c = json.load(f)
        definicoes[c['cenario']] = c
    golden = {}
    for arq in sorted(glob.glob(os.path.join(BASE, 'golden', '*', '*', '*.json'))):
        with open(arq, encoding='utf-8') as f:
            g = json.load(f)
        cen, var = os.path.basename(os.path.dirname(arq)), os.path.splitext(os.path.basename(arq))[0]
        assert (g['cenario'], g['variacao']) == (cen, var), arq
        golden.setdefault(cen, []).append(var)
    return matriz, definicoes, golden


def gerar():
    matriz, definicoes, golden = carregar()
    desconhecidos = (set(definicoes) | set(golden)) - set(matriz)
    assert not desconhecidos, f'cenário fora da matriz: {desconhecidos}'
    alvo = {k: l for k, l in matriz.items() if l['execucao'].startswith('Sim')}
    out = []
    w = out.append
    w('# Cobertura de baselines — Fase 2')
    w('')
    w('> ⚠️ **Gerado por script** — `ambiente-referencia/baselines/ferramentas/cobertura.py gerar`, a partir da')
    w('> [matriz de caracterização](matriz-caracterizacao.md), das definições executáveis')
    w('> (`ambiente-referencia/baselines/cenarios/`) e das baselines gravadas (`ambiente-referencia/baselines/golden/`).')
    w('> Não editar à mão. Leitura: [relatório da Fase 2](fase2-caracterizacao-baselines.md).')
    w('')
    w('## Totais')
    w('')
    w('| Classe | Cenários | Com definição executável | Com baseline | Massas iniciais (matriz) | Variações definidas | Baselines gravadas |')
    w('| ------ | -------- | ------------------------ | ------------ | ------------------------ | ------------------- | ------------------ |')
    for classe in 'AC':
        sel = [k for k, l in alvo.items() if l['classe'] == classe]
        w(f"| **{classe}** | {len(sel)} | {len([k for k in sel if k in definicoes])} | {len([k for k in sel if k in golden])} | "
          f"{sum(int(alvo[k]['massas']) for k in sel)} | {sum(len(definicoes[k]['variacoes']) for k in sel if k in definicoes)} | "
          f"{sum(len(golden.get(k, [])) for k in sel)} |")
    p0 = [k for k, l in alvo.items() if l['classe'] == 'A' and l['prioridade'] == 'P0']
    w('')
    w(f"**P0 da classe A com baseline**: {len([k for k in p0 if k in golden])} de {len(p0)}. "
      f"Cenários que exigem execução do GSAN (A + C com registro): {len(alvo)}; "
      f"com ao menos uma baseline: {len([k for k in alvo if k in golden])}.")
    w('')
    w('## Por domínio (classe A)')
    w('')
    w('| Domínio | Cenários A | Com baseline | Baselines gravadas |')
    w('| ------- | ---------- | ------------ | ------------------ |')
    for dom in sorted({l['dominio'] for l in alvo.values()}):
        sel = [k for k, l in alvo.items() if l['dominio'] == dom and l['classe'] == 'A']
        if sel:
            w(f"| {dom} | {len(sel)} | {len([k for k in sel if k in golden])} | {sum(len(golden.get(k, [])) for k in sel)} |")
    w('')
    w('## Cenários com definição executável')
    w('')
    w('| Cenário | Prioridade | Lote | Variações definidas | Baselines | Fora do lote | Fora desta fronteira |')
    w('| ------- | ---------- | ---- | ------------------- | --------- | ------------ | -------------------- |')
    for k in sorted(definicoes):
        c = definicoes[k]
        vs = list(c['variacoes'])
        gs = sorted(golden.get(k, []))
        fora = ', '.join(sorted(c.get('fora_do_lote', {}))) or '—'
        fronteira = ', '.join(c['observaveis'].get('fora_desta_fronteira', {})) or '—'
        w(f"| {k} | {matriz[k]['prioridade']} | {c.get('lote', '—')} | {', '.join(vs)} | "
          f"{', '.join(gs) if gs else '—'} | {fora} | {fronteira} |")
    w('')
    return '\n'.join(out)


def main():
    modo = sys.argv[1] if len(sys.argv) > 1 else ''
    conteudo = gerar()
    if modo == 'gerar':
        os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
        with open(SAIDA, 'w', encoding='utf-8', newline='\n') as f:
            f.write(conteudo)
        print('cobertura gerada: ' + os.path.relpath(SAIDA, RAIZ))
    elif modo == 'verificar':
        if not os.path.exists(SAIDA) or open(SAIDA, encoding='utf-8').read() != conteudo:
            print('desatualizado: ' + os.path.relpath(SAIDA, RAIZ))
            sys.exit(1)
        print('cobertura atualizada')
    else:
        print(__doc__)
        sys.exit(2)


if __name__ == '__main__':
    main()
