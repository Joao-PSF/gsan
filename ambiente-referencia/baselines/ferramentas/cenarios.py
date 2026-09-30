#!/usr/bin/env python3
"""Extrai as especificações de cenário (docs/modernizacao/testes/cenarios/*.md) para uma tabela.

Cada especificação começa em `## CEN-<ÁREA>-<NNN> — <título>` e traz os campos do modelo
obrigatório (estrategia-testes.md). Este módulo só lê — a classificação da Fase 2 fica em
caracterizacao.py.
"""
import glob
import os
import re

RAIZ = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
DIR_CENARIOS = os.path.join(RAIZ, 'docs', 'modernizacao', 'testes', 'cenarios')


def campo(bloco, nome):
    m = re.search(r'^- \*\*' + re.escape(nome) + r'\*\*:\s*(.*)$', bloco, re.M)
    return m.group(1).strip() if m else ''


def variacoes(bloco):
    """Variações de entrada declaradas na seção Entrada (V1, V2, ... — tabela ou texto corrido).

    Intervalos `V1–V3` são expandidos. Sem nenhuma variação declarada, a entrada é única.
    """
    m = re.search(r'^- \*\*Entrada\*\*(.*?)^- \*\*Operação GSAN\*\*', bloco, re.M | re.S)
    entrada = m.group(1) if m else ''
    ids = set()
    for a, b in re.findall(r'\bV(\d+)\s*[–-]\s*V(\d+)\b', entrada):
        ids |= {f'V{n}' for n in range(int(a), int(b) + 1)}
    ids |= set(re.findall(r'\b(V\d+[a-z]?)\b', entrada))
    return sorted(ids, key=lambda v: (int(re.sub(r'\D', '', v)), v))


def ler():
    cenarios = []
    for arquivo in sorted(glob.glob(os.path.join(DIR_CENARIOS, '*.md'))):
        texto = open(arquivo, encoding='utf-8').read()
        partes = re.split(r'^(## CEN-[A-Z]+-\d{3} — .*)$', texto, flags=re.M)
        for i in range(1, len(partes), 2):
            titulo = partes[i]
            bloco = partes[i + 1]
            m = re.match(r'## (CEN-([A-Z]+)-\d{3}) — (.*)', titulo)
            cenarios.append({
                'id': m.group(1),
                'area': m.group(2),
                'titulo': m.group(3).strip(),
                'arquivo': os.path.basename(arquivo),
                'criticidade': re.sub(r'[^P0-9]', '', campo(bloco, 'Criticidade'))[:2],
                'etapa': campo(bloco, 'Etapa OpenGSAN'),
                'oraculo': campo(bloco, 'Oráculo'),
                'baseline': campo(bloco, 'Baseline concreta do legado'),
                'divergencia': campo(bloco, 'Divergência permitida'),
                'variacoes': variacoes(bloco),
            })
    return cenarios


if __name__ == '__main__':
    for c in ler():
        print('\t'.join([c['id'], c['criticidade'], c['oraculo'][:60], c['baseline'][:40], str(len(c['variacoes']))]))
