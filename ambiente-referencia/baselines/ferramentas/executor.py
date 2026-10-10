#!/usr/bin/env python3
"""Executor de cenários da Fase 2 — roda no contêiner `ferramentas` (rede interna).

  executor.py massa      CENARIO VARIACAO          arquivos da massa efetiva (base + deltas), em ordem
  executor.py modo       CENARIO [VARIACAO]        modo do EAR que o cenário (ou a variação) exige (Online | Batch)
  executor.py executar   CENARIO VARIACAO SAIDA    uma execução sobre o estado já restaurado
  executor.py consolidar capturar|verificar CENARIO VARIACAO SAIDA... [--substituir]
  executor.py lista      [LOTE]                    CENARIO:VARIACAO de um lote (ou de todos)

`executar` só observa: confere a massa efetiva e as pré-condições, autentica o operador sintético com
senha efêmera, roda o roteiro da operação, mede os efeitos no banco, projeta os observáveis da lista
fechada, normaliza e grava SAIDA/resultado.json (candidato) e SAIDA/evidencias/ (cru, nunca baseline).
`consolidar capturar` exige ≥ 2 execuções idênticas e só então grava golden/; `consolidar verificar`
compara com o golden e não escreve nele. Nenhum outro caminho escreve em golden/.
"""
import base64
import datetime
import glob
import hashlib
import json
import os
import re
import secrets
import subprocess
import sys

import roteiros
from gsan_http import Sessao, texto_visivel

BASE = '/referencia/baselines'
GOLDEN = os.path.join(BASE, 'golden')
GSAN = 'http://gsan:8080/gsan'
OPERADOR = 'fase2.oper'
FORMATO = 1

# Normalização: só o que não tem significado de negócio. Dinheiro, estado, referência, consumo,
# categoria e identidade funcional nunca são normalizados (estrategia-testes.md, modelo obrigatório).
REGRAS = ('identificador_tecnico', 'carimbo_tempo', 'data_execucao', 'ordem_sem_semantica')
PROIBIDO = re.compile(r'valor|total|consumo|situacao|referencia|matricula|economia|categoria|tarifa|faixa|minimo',
                      re.I)


# --- utilidades ---------------------------------------------------------------------------------
def canonico(obj):
    return json.dumps(obj, ensure_ascii=False, sort_keys=True, indent=2) + '\n'


def gravar(caminho, conteudo):
    os.makedirs(os.path.dirname(caminho), exist_ok=True)
    with open(caminho, 'w', encoding='utf-8', newline='\n') as f:
        f.write(conteudo)


def sha256(caminho):
    with open(caminho, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


def sql(consulta, banco='gsan_comercial'):
    r = subprocess.run(['psql', '-X', '-At', '-v', 'ON_ERROR_STOP=1', '-F', '\t', '-d', banco, '-c', consulta],
                       capture_output=True, text=True, encoding='latin-1')
    if r.returncode:
        raise RuntimeError(f'SQL falhou: {consulta}\n{r.stderr}')
    return r.stdout.rstrip('\n')


def cenario(ident):
    with open(os.path.join(BASE, 'cenarios', ident + '.json'), encoding='utf-8') as f:
        c = json.load(f)
    assert c['cenario'] == ident, ident
    return c


def dominio(c):
    return c['dominio']


# --- massa efetiva -----------------------------------------------------------------------------
# Campos que uma variação pode declarar para si (lote 5e): a mesma especificação, observada noutra fronteira — o
# faturamento em grupo de um cenário cuja definição nasceu na simulação, por exemplo. Ausentes na variação, valem os do
# cenário: as variações que não os declaram não mudam em nada.
SOBREPONIVEIS = ('lote', 'modo', 'fronteira', 'autenticacao', 'usuarios', 'precondicoes', 'efeitos', 'normalizacoes',
                 'oraculo', 'ressalvas', 'observaveis')


def efetivo(c, variacao):
    """A definição que vale para a variação: a do cenário, com o que a variação sobrepõe."""
    v = c['variacoes'][variacao]
    return {**c, **{k: v[k] for k in SOBREPONIVEIS if k in v}}


def modo_ear(c):
    """Modo do EAR que o cenário exige: Online (padrão) ou Batch (agendador de processos)."""
    m = c.get('modo', 'Online')
    if m not in ('Online', 'Batch'):
        raise SystemExit(f'modo inválido em {c["cenario"]}: {m}')
    return m


def massa_efetiva(c, variacao):
    arquivos = sorted(glob.glob(os.path.join(BASE, 'massas', 'base', '*.sql')))
    for delta in c['variacoes'][variacao].get('massa', []):
        caminho = os.path.join(BASE, delta)
        if not os.path.isfile(caminho):
            raise SystemExit(f'delta de massa ausente: {delta}')
        arquivos.append(caminho)
    return arquivos


def conferir_massa(c, variacao):
    esperada = [(os.path.relpath(a, BASE), sha256(a)) for a in massa_efetiva(c, variacao)]
    aplicada = [tuple(l.split('\t')[1:]) for l in
                sql('select ordem, arquivo, sha256 from public.baseline_massa order by ordem').splitlines()]
    if aplicada != esperada:
        raise SystemExit(f'massa aplicada ≠ massa efetiva de {c["cenario"]} {variacao}:\n'
                         f'  aplicada: {aplicada}\n  esperada: {esperada}')
    return [{'arquivo': a, 'sha256': h} for a, h in esperada]


# --- observação --------------------------------------------------------------------------------
def medir(efeitos):
    """Estado das tabelas vigiadas: contagem de linhas ou, no modo "conteudo", resumo de todo o conteúdo."""
    estado = {}
    for e in efeitos:
        tab, modo = (e, 'contagem') if isinstance(e, str) else (e['tabela'], e.get('modo', 'contagem'))
        if modo == 'conteudo':
            estado[tab] = sql(f"select md5(coalesce(string_agg(t::text, '|' order by t::text), '')) from {tab} t")
        else:
            estado[tab] = int(sql(f'select count(*) from {tab}'))
    return estado


def efeito(antes, depois):
    if isinstance(antes, int):
        return depois - antes
    return 'inalterado' if antes == depois else 'alterado'


def projetar(bruto, campos):
    """`chave` copia o valor; `chave[a,b]` projeta uma lista de objetos nos campos a e b."""
    saida = {}
    for campo in campos:
        m = re.fullmatch(r'(\w+)\[([\w,]+)\]', campo)
        if m:
            chave, subcampos = m.group(1), m.group(2).split(',')
            saida[chave] = [{k: item.get(k) for k in subcampos} for item in bruto.get(chave) or []]
        else:
            saida[campo] = bruto.get(campo)
    return saida


def normalizar(obs, regras, hoje):
    mapa_ids = {}
    for regra in regras:
        caminho, tipo = regra['caminho'], regra['regra']
        if tipo not in REGRAS:
            raise SystemExit(f'regra de normalização desconhecida: {tipo}')
        if tipo == 'ordem_sem_semantica':
            # Só reordena uma lista cuja ordem o legado não define (sem ORDER BY); nenhum valor muda.
            dono, _, chave = caminho.rpartition('.')
            alvo = obs.get(chave) if not dono else None
            if not isinstance(alvo, list):
                raise SystemExit(f'ordem_sem_semantica: {caminho} não é lista de primeiro nível')
            alvo.sort(key=lambda item: [str(item.get(k)) for k in regra['chaves']])
            continue
        if PROIBIDO.search(caminho):
            raise SystemExit(f'normalização proibida em {caminho}: dinheiro, estado e identidade não se normalizam')

        def aplicar(valor):
            if valor is None:
                return None
            if tipo == 'identificador_tecnico':
                return mapa_ids.setdefault((caminho, valor), f'<id-{len(mapa_ids) + 1}>')
            if tipo == 'carimbo_tempo':
                return '<carimbo>'
            dias = (datetime.date.fromisoformat(str(valor)[:10]) - hoje).days
            return '<hoje>' if dias == 0 else f'<hoje{dias:+d}>'

        partes = caminho.split('.')
        alvos = [obs]
        for p in partes[:-1]:
            prox = []
            for a in alvos:
                v = a.get(p.rstrip('[*]')) if isinstance(a, dict) else None
                prox += v if isinstance(v, list) else ([v] if v is not None else [])
            alvos = prox
        for a in alvos:
            if isinstance(a, dict) and partes[-1] in a:
                a[partes[-1]] = aplicar(a[partes[-1]])
    return obs


def credencial_efemera():
    senha = secrets.token_urlsafe(18)
    hash_ = base64.b64encode(hashlib.sha1(senha.encode('utf-8')).digest()).decode()  # formato do legado
    subprocess.run(['psql', '-X', '-q', '-v', 'ON_ERROR_STOP=1', '-d', 'gsan_comercial', '-v', 'h=' + hash_],
                   input=f"UPDATE seguranca.usuario SET usur_nmsenha = :'h' WHERE usur_nmlogin = '{OPERADOR}';",
                   text=True, check=True, capture_output=True)
    return senha


def credenciais_efemeras(usuarios):
    """{login: rótulo} → {login: senha}. Uma senha aleatória por RÓTULO (logins com o mesmo rótulo recebem a
    mesma senha, como o perfil USR-01B exige); só o hash, no formato do legado, vai ao banco."""
    por_rotulo, senhas, args, comandos = {}, {}, [], []
    for i, (login, rotulo) in enumerate(sorted(usuarios.items())):
        if not re.fullmatch(r'[a-z0-9.]{1,11}', login):
            raise SystemExit(f'login inválido no cenário: {login!r}')
        senha = por_rotulo.setdefault(rotulo, secrets.token_urlsafe(18))
        senhas[login] = senha
        args += ['-v', f'h{i}=' + base64.b64encode(hashlib.sha1(senha.encode('utf-8')).digest()).decode()]
        comandos.append(f"UPDATE seguranca.usuario SET usur_nmsenha = :'h{i}' WHERE usur_nmlogin = '{login}';")
    if comandos:
        subprocess.run(['psql', '-X', '-q', '-v', 'ON_ERROR_STOP=1', '-d', 'gsan_comercial'] + args,
                       input='\n'.join(comandos), text=True, check=True, capture_output=True)
    return senhas


def executar(ident, variacao, saida):
    c = efetivo(cenario(ident), variacao)
    v = c['variacoes'][variacao]
    inicio = datetime.datetime.now(datetime.timezone.utc)
    hoje = datetime.date.fromisoformat(sql('select current_date'))
    massa = conferir_massa(c, variacao)

    precondicoes = []
    for p in c.get('precondicoes', []):
        obtido = sql(p['sql'])
        precondicoes.append({'descricao': p['descricao'], 'obtido': obtido, 'esperado': p['esperado']})
        if obtido != p['esperado']:
            raise SystemExit(f'pré-condição falhou: {p["descricao"]} (obtido {obtido!r}, esperado {p["esperado"]!r})')

    vigiadas = c.get('efeitos', [])
    antes = medir(vigiadas)
    roteiro = roteiros.ROTEIROS[v.get('roteiro', c.get('roteiro'))]
    erro = None
    if c.get('autenticacao') == 'roteiro':
        # Segurança: o próprio roteiro autentica os usuários SINTÉTICOS do cenário; o operador não entra.
        ctx = roteiros.Contexto(GSAN, credenciais_efemeras(c.get('usuarios', {})), sql)
        try:
            bruto = roteiro(ctx, v['entrada'])
        except Exception as e:  # a execução falhou: vira evidência, nunca baseline
            bruto, erro = None, f'{type(e).__name__}: {e}'
        del ctx._senhas, ctx._novas, ctx._marcas
        respostas = ctx.respostas()
    else:
        sessao = Sessao(GSAN)
        senha = credencial_efemera()
        sessao.entrar(OPERADOR, senha)
        del senha
        try:
            bruto = roteiro(sessao, v['entrada'])
        except Exception as e:  # a execução falhou: vira evidência, nunca baseline
            bruto, erro = None, f'{type(e).__name__}: {e}'
        respostas = sessao.respostas
    versao = None
    for r in respostas:
        versao = re.search(r'Vers[ãa]o:\s*([^<]*?)\s*(?:<|\d{2}/\d{2}/\d{4})', texto_visivel(r['html']) + '<')
        if versao:
            break
    depois = medir(vigiadas)
    # O rodapé do legado traz o modo gravado no build ("referencia (Online|Batch)"): o EAR no ar tem de ser o que o
    # cenário exige — uma baseline online capturada no EAR Batch (ou o contrário) não é a mesma baseline.
    modo = modo_ear(c)
    if versao and f'({modo})' not in versao.group(1):
        erro = erro or f'EAR no ar ({versao.group(1).strip()}) não é do modo {modo} que o cenário exige'
    elif not versao and modo != 'Online':
        erro = erro or f'modo {modo} exigido e a versão exibida não foi encontrada'

    evid = os.path.join(saida, 'evidencias')
    for i, r in enumerate(respostas):
        nome = f'{i:02d}-{r["metodo"]}-{re.sub(r"[^A-Za-z0-9]+", "_", r["caminho"].split("?")[0])}.html'
        gravar(os.path.join(evid, nome), r['html'])
    gravar(os.path.join(evid, 'requisicoes.json'),
           canonico([{k: r[k] for k in ('metodo', 'caminho', 'parametros', 'estado')} for r in respostas]))
    gravar(os.path.join(evid, 'bruto.json'), canonico(bruto))
    manifesto = {
        'cenario': ident, 'variacao': variacao, 'inicio': inicio.isoformat(timespec='seconds'),
        'fim': datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds'),
        'data_do_banco': hoje.isoformat(), 'versao_exibida': versao.group(1).strip() if versao else None,
        'tabelas_antes': antes, 'tabelas_depois': depois, 'precondicoes': precondicoes, 'erro': erro,
    }
    gravar(os.path.join(saida, 'manifesto.json'), canonico(manifesto))
    if erro:
        raise SystemExit(f'{ident} {variacao}: execução falhou — {erro} (evidências em {saida})')

    obs = projetar(bruto, c['observaveis']['campos'])
    obs = normalizar(obs, c.get('normalizacoes', []), hoje)
    resultado = {
        'formato': FORMATO,
        'cenario': ident, 'titulo': c['titulo'], 'variacao': variacao, 'descricao': v['descricao'],
        'especificacao': c['especificacao'], 'oraculo': c['oraculo'],
        'legado': {
            'commit': os.environ.get('GSAN_COMMIT_LEGADO'), 'migracoes': os.environ.get('GSAN_MIGRACOES_COMMIT'),
            'versao_exibida': manifesto['versao_exibida'], 'variante': os.environ.get('GSAN_VARIANTE') or None,
            'complemento_p6_sha256': sql('select sha256 from public.referencia_complemento order by 1 limit 1'),
        },
        'massa': massa,
        'operacao': {'fronteira': c['fronteira'], 'roteiro': v.get('roteiro', c.get('roteiro')), 'entrada': v['entrada']},
        'normalizacoes': c.get('normalizacoes', []),
        'observaveis': obs,
        'efeitos_no_banco': {t: efeito(antes[t], depois[t]) for t in antes},
        'fora_desta_fronteira': c['observaveis'].get('fora_desta_fronteira', {}),
    }
    # Só em cenários que as declaram (as baselines anteriores não mudam de forma).
    if c.get('ressalvas'):
        resultado['ressalvas'] = c['ressalvas']
    if c.get('usuarios'):
        resultado['usuarios_sinteticos'] = sorted(c['usuarios'])
    gravar(os.path.join(saida, 'resultado.json'), canonico(resultado))
    print(f'{ident} {variacao}: executado — {saida}')


# --- consolidação ------------------------------------------------------------------------------
def caminho_golden(c, variacao):
    return os.path.join(GOLDEN, dominio(c), c['cenario'], variacao + '.json')


def diferencas(a, b, prefixo=''):
    if isinstance(a, dict) and isinstance(b, dict):
        out = []
        for k in sorted(set(a) | set(b)):
            out += diferencas(a.get(k), b.get(k), f'{prefixo}.{k}' if prefixo else k)
        return out
    if isinstance(a, list) and isinstance(b, list) and len(a) == len(b):
        out = []
        for i, (x, y) in enumerate(zip(a, b)):
            out += diferencas(x, y, f'{prefixo}[{i}]')
        return out
    return [] if a == b else [f'{prefixo}: {json.dumps(a, ensure_ascii=False)} ≠ {json.dumps(b, ensure_ascii=False)}']


def consolidar(modo, ident, variacao, execucoes, substituir):
    c = cenario(ident)
    textos = []
    for d in execucoes:
        with open(os.path.join(d, 'resultado.json'), encoding='utf-8') as f:
            textos.append(f.read())
    primeiro = json.loads(textos[0])
    for d, t in zip(execucoes[1:], textos[1:]):
        if t != textos[0]:
            print(f'NÃO DETERMINÍSTICO — {ident} {variacao}: {execucoes[0]} × {d}')
            for linha in diferencas(primeiro, json.loads(t)):
                print('  ' + linha)
            sys.exit(3)
    golden = caminho_golden(c, variacao)
    rel = os.path.relpath(golden, BASE)
    if modo == 'capturar':
        if len(execucoes) < 2:
            raise SystemExit('captura exige pelo menos 2 execuções a partir do estado limpo')
        if os.path.exists(golden) and not substituir:
            with open(golden, encoding='utf-8') as f:
                if f.read() == textos[0]:
                    print(f'{ident} {variacao}: {len(execucoes)} execuções idênticas; baseline já existente e igual — {rel}')
                    return
            raise SystemExit(f'{rel} já existe e difere — use --substituir só com justificativa registrada')
        gravar(golden, textos[0])
        print(f'{ident} {variacao}: {len(execucoes)} execuções idênticas → baseline gravada em {rel}')
    else:
        if not os.path.exists(golden):
            raise SystemExit(f'sem baseline para {ident} {variacao} ({rel}) — capture antes de verificar')
        with open(golden, encoding='utf-8') as f:
            esperado = f.read()
        if esperado == textos[0]:
            print(f'{ident} {variacao}: CONFERE com {rel} ({len(execucoes)} execução(ões))')
            return
        print(f'{ident} {variacao}: DIVERGE de {rel}')
        for linha in diferencas(json.loads(esperado), primeiro):
            print('  ' + linha)
        sys.exit(4)


def lista(lote):
    for arq in sorted(glob.glob(os.path.join(BASE, 'cenarios', '*.json'))):
        with open(arq, encoding='utf-8') as f:
            c = json.load(f)
        for v, d in c['variacoes'].items():
            if lote and d.get('lote', c.get('lote')) != lote:
                continue
            print(f"{c['cenario']}:{v}")


def main():
    a = sys.argv[1:]
    if not a:
        print(__doc__)
        sys.exit(2)
    if a[0] == 'massa':
        print('\n'.join(massa_efetiva(cenario(a[1]), a[2])))
    elif a[0] == 'modo':  # modo CENARIO [VARIACAO]
        c = cenario(a[1])
        print(modo_ear(efetivo(c, a[2]) if len(a) > 2 else c))
    elif a[0] == 'executar':
        executar(a[1], a[2], a[3])
    elif a[0] == 'consolidar':
        substituir = '--substituir' in a
        resto = [x for x in a[1:] if x != '--substituir']
        consolidar(resto[0], resto[1], resto[2], resto[3:], substituir)
    elif a[0] == 'lista':
        lista(a[1] if len(a) > 1 else None)
    else:
        print(__doc__)
        sys.exit(2)


if __name__ == '__main__':
    main()
