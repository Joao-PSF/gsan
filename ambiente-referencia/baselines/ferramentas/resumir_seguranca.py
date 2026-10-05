#!/usr/bin/env python3
"""Resumo legível das baselines de Segurança gravadas (golden/seguranca/*/*.json).

Só leitura, para conferência e para o relatório. Não escreve nada; não é parte do mecanismo de captura.
"""
import glob
import json
import os

BASE = os.path.normpath(os.path.join(os.path.dirname(__file__), '..'))


def rotulo_passo(p):
    t = p['passo']
    if t == 'login':
        return f"login {p['usuario']} ({p['senha']}) -> {p.get('resultado')}" + (
            f" [{p['mensagem']}]" if p.get('mensagem') else '')
    if t == 'situacao':
        return f"situacao {p['usuario']} = {p['situacao']}"
    if t == 'contexto':
        return f"contexto: autenticado={p['autenticado']} grupos={p.get('grupos_exibidos')} menu={p.get('menu')}"
    if t == 'contadores':
        return f"contadores {p['usuario']}: acessos={p['acessos']} bloqueios={p['bloqueios']}"
    if t == 'credenciais':
        return f"credenciais {p['usuarios']}: iguais={p['valores_iguais']} formatos={p['formatos']}"
    if t == 'acessar':
        s = f"acessar [{p['rotulo']}] http={p['http']} -> {p['decisao']}"
        if 'recurso_executado' in p:
            s += f" executado={p['recurso_executado']}"
        if 'dados_encontrados' in p:
            s += f" dados={p['dados_encontrados']}"
        if p.get('mensagem'):
            s += f" [{p['mensagem']}]"
        return s
    if t == 'trocar_senha':
        return f"trocar_senha {p['usuario']}: sucesso={p['sucesso']}" + (f" [{p['mensagem']}]" if p.get('mensagem') else '')
    if t == 'cookie':
        return (f"cookie: emitido={p['emitido']} HttpOnly={p['httponly']} Secure={p['secure']} "
                f"SameSite={p['samesite']} path={p['path']}")
    if t == 'sessao':
        return f"sessao (carregar={p.get('carregar')})"
    return json.dumps(p, ensure_ascii=False)


def main():
    for arq in sorted(glob.glob(os.path.join(BASE, 'golden', 'seguranca', '*', '*.json'))):
        g = json.load(open(arq, encoding='utf-8'))
        print(f"### {g['cenario']} {g['variacao']} — {g['descricao']}")
        print(f"    oráculo: {g['oraculo']} | efeitos: {g['efeitos_no_banco']}")
        for p in g['observaveis']['passos']:
            print('    -', rotulo_passo(p))
        print()


if __name__ == '__main__':
    main()
