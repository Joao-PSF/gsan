#!/usr/bin/env python3
"""Mapeamento Hibernate do GSAN × schema do banco de referência.

As classes que o runtime carrega são as registradas em src/gcom/util/HibernateUtil.java:
`configuration` (java:/PostgresDS -> gsan_comercial) e `configurationGerencial`
(java:/PostgresGerencialDS -> gsan_gerencial). Cada classe é conferida contra o banco da sua
SessionFactory; classes não registradas não são carregadas e ficam de fora.

Conferido por classe: a tabela existe? Cada coluna de <id>, <composite-id>, <property>,
<many-to-one>, <version>, <timestamp> (inclusive em <component>) existe? A sequence do
<generator class="sequence"> existe? Coleções ficam de fora (suas colunas moram em outra tabela).

  verificar   <src> <export-dir> <tabelas-autorizadas.tsv> <saida.tsv>
      export-dir contém colunas-<banco>.tsv (schema, tabela, coluna) e
      sequencias-<banco>.tsv (schema, sequence) exportados de cada banco. Classifica cada
      divergência (complementado / transferido / excluido) e sai com erro se alguma que o P6
      deveria complementar continua aberta.
  complemento <src> <export-dir> <tabelas-autorizadas.tsv> <saida.sql>
      DDL determinístico do pré-requisito P6 para gsan_comercial. Política (banco/README.md):
      coluna ausente em tabela existente de classe carregada -> complementa (sem ela, toda
      leitura da entidade falha); tabela ausente -> só se autorizada, com justificativa;
      sequence -> só a de tabela complementada. Gerencial, views, bancos externos e defeitos de
      mapeamento não são complementados. Tipos do mapeamento; colunas anuláveis; PK pelo <id>.
"""
import hashlib
import os
import re
import sys
import xml.etree.ElementTree as ET

CAMPOS = ('id', 'property', 'many-to-one', 'key-property', 'key-many-to-one', 'version', 'timestamp')
BANCOS = ('comercial', 'gerencial')


# --- registros das SessionFactory ----------------------------------------------------------
def registros(src):
    texto = open(os.path.join(src, 'gcom/util/HibernateUtil.java'), 'rb').read().decode('latin-1')
    imports = dict((m.group(2), m.group(1) + '.' + m.group(2))
                   for m in re.finditer(r'import\s+([\w.]+)\.(\w+)\s*;', texto))

    def bloco(inicio, fim):
        i = texto.index(inicio)
        return texto[i:texto.index(fim, i)]

    reg = {}
    for banco, (ini, fim) in (('gerencial', ('configurationGerencial = new Configuration()', 'configurationGerencial.buildSessionFactory()')),
                              ('comercial', ('configuration = new Configuration()', 'configuration.buildSessionFactory()'))):
        for simples in re.findall(r'addClass\(\s*(\w+)\.class\s*\)', bloco(ini, fim)):
            reg[imports.get(simples, simples)] = banco
    return reg


# --- leitura dos hbm ------------------------------------------------------------------------
def tipo_sql(tipo, el):
    t = (tipo or '').strip()
    comprimento = el.get('length')
    precisao, escala = el.get('precision'), el.get('scale')
    for c in el.findall('column'):
        comprimento = comprimento or c.get('length')
        precisao, escala = precisao or c.get('precision'), escala or c.get('scale')
    if t in ('java.lang.Integer', 'int', 'integer'):
        return 'integer'
    if t in ('java.lang.Short', 'short'):
        return 'smallint'
    if t in ('java.lang.Long', 'long'):
        return 'bigint'
    if t in ('java.lang.String', 'string'):
        return f'varchar({comprimento})' if comprimento else 'text'
    if t == 'text':
        return 'text'
    if t in ('java.math.BigDecimal', 'big_decimal'):
        # Sem precisão/escala declaradas, numeric sem restrição guarda o valor exato recebido.
        return f'numeric({precisao},{escala or 0})' if precisao else 'numeric'
    if t in ('java.sql.Timestamp', 'timestamp', 'java.util.Date'):
        return 'timestamp without time zone'
    if t in ('java.sql.Date', 'date'):
        return 'date'
    if t in ('java.sql.Time', 'time'):
        return 'time without time zone'
    if t in ('java.lang.Boolean', 'boolean'):
        return 'boolean'
    if t in ('java.lang.Character', 'char', 'character'):
        return 'character(1)'
    if t in ('java.lang.Double', 'double'):
        return 'double precision'
    if t in ('java.lang.Float', 'float'):
        return 'real'
    if t in ('binary', 'byte[]'):
        return 'bytea'
    return None


def colunas(el):
    nomes = [el.get('column')] if el.get('column') else []
    nomes += [c.get('name') for c in el.findall('column') if c.get('name')]
    if not nomes and el.tag in ('id', 'property', 'key-property', 'version', 'timestamp') \
            and el.get('name') and not el.get('formula'):
        nomes.append(el.get('name'))  # sem column, o Hibernate usa o nome da propriedade
    return [n.strip('`"').lower() for n in nomes]


def campos_da_classe(cls):
    """[(coluna, tipo_sql_ou_None, é_pk)] e a sequence do gerador, se houver."""
    saida, sequence = [], None

    def visitar(el, em_pk):
        for f in el:
            if f.tag in CAMPOS:
                if f.get('formula') or (f.tag == 'many-to-one' and not colunas(f)):
                    continue
                tipo = 'integer' if f.tag in ('many-to-one', 'key-many-to-one') else tipo_sql(f.get('type'), f)
                pk = em_pk or f.tag == 'id'
                for c in colunas(f):
                    saida.append((c, tipo, pk))
            if f.tag in ('composite-id', 'component', 'id'):
                visitar(f, em_pk or f.tag in ('composite-id', 'id'))
    visitar(cls, False)
    idel = cls.find('id')
    if idel is not None:
        g = idel.find('generator')
        if g is not None and g.get('class') == 'sequence':
            p = g.find("param[@name='sequence']")
            if p is not None and p.text:
                sequence = p.text.strip().lower()
    return saida, sequence


def classes_mapeadas(src):
    for raiz, _, arquivos in os.walk(src):
        for nome in sorted(arquivos):
            if not nome.endswith('.hbm.xml'):
                continue
            caminho = os.path.join(raiz, nome)
            texto = re.sub(rb'<!DOCTYPE[^>]*>', b'', open(caminho, 'rb').read(), flags=re.S)
            doc = ET.fromstring(texto)
            pacote = doc.get('package')
            for cls in doc.iter():
                if cls.tag not in ('class', 'subclass', 'joined-subclass') or not cls.get('table'):
                    continue
                nome_cls = cls.get('name')
                if pacote and '.' not in nome_cls:
                    nome_cls = pacote + '.' + nome_cls
                tabela = cls.get('table').strip('`"').lower()
                schema = (cls.get('schema') or doc.get('schema') or '').lower()
                if schema:
                    tabela = schema + '.' + tabela
                elif '.' not in tabela:
                    tabela = 'public.' + tabela
                yield os.path.relpath(caminho, src).replace(os.sep, '/'), nome_cls, tabela, cls


# --- schema exportado -------------------------------------------------------------------------
def carregar_schema(export, banco):
    colunas_bd, sequencias = {}, set()
    with open(os.path.join(export, f'colunas-{banco}.tsv'), encoding='latin-1') as f:
        for linha in f:
            s, t, c = linha.rstrip('\n').split('\t')
            colunas_bd.setdefault(f'{s}.{t}'.lower(), set()).add(c.lower())
    with open(os.path.join(export, f'sequencias-{banco}.tsv'), encoding='latin-1') as f:
        for linha in f:
            s, q = linha.rstrip('\n').split('\t')
            sequencias.add(f'{s}.{q}'.lower())
    return colunas_bd, sequencias


def exclusao(tabela):
    """Motivo para não reconstruir, ou None."""
    if tabela.count('.') > 1:
        return 'defeito de mapeamento: nome com mais de um qualificador (o PostgreSQL rejeita; a entidade já era inutilizável no legado)'
    if tabela.split('.')[-1].startswith('vw_'):
        return 'view: definição de produção desconhecida; não é reconstruída a partir do mapeamento'
    if tabela.startswith('dbo.'):
        return 'banco externo (integração UPA/SAM, SQL Server); a SessionFactory dessa integração nunca é construída'
    return None


def divergencias(src, export):
    reg = registros(src)
    schemas = {b: carregar_schema(export, b) for b in BANCOS}
    saida = []
    for arquivo, nome_cls, tabela, cls in classes_mapeadas(src):
        banco = reg.get(nome_cls)
        if banco is None:
            continue
        cols_bd, seqs_bd = schemas[banco]
        campos, sequence = campos_da_classe(cls)
        if tabela not in cols_bd:
            saida.append((banco, arquivo, nome_cls, tabela, 'tabela-ausente', '', campos, sequence))
        else:
            for c, tipo, pk in campos:
                if c not in cols_bd[tabela]:
                    saida.append((banco, arquivo, nome_cls, tabela, 'coluna-ausente', c, [(c, tipo, pk)], None))
        if sequence:
            seq = sequence if '.' in sequence else 'public.' + sequence
            if seq not in seqs_bd:
                saida.append((banco, arquivo, nome_cls, tabela, 'sequence-ausente', seq, [], seq))
    return saida, reg


def carregar_autorizadas(caminho):
    """Tabelas ausentes que o P6 cria: banco<TAB>tabela<TAB>justificativa."""
    autorizadas = {}
    with open(caminho, encoding='utf-8') as f:
        for linha in f:
            if linha.startswith('#') or not linha.strip():
                continue
            banco, tabela, justificativa = linha.rstrip('\n').split('\t')
            autorizadas[(banco, tabela.lower())] = justificativa
    return autorizadas


def tratamento(div, autorizadas, schemas_existentes):
    """(classe, motivo) de uma divergência — a política do P6 (ver banco/README.md)."""
    banco, _, cls, tabela, tipo, det, _, seq = div
    motivo = exclusao(tabela)
    if motivo:
        return 'excluido', motivo
    if banco == 'gerencial':
        return 'transferido', ('NÃO RELEVANTE PARA A FASE — SessionFactory gerencial (resumos e indicadores '
                               'do consumidor analítico); não é exigida pelo runtime nem pelo oráculo da Fase 1')
    if tipo == 'coluna-ausente':
        return 'complementado', 'coluna de entidade carregada: sem ela, toda leitura da entidade falha'
    if tipo == 'tabela-ausente':
        if (banco, tabela) in autorizadas:
            return 'complementado', autorizadas[(banco, tabela)]
        return 'transferido', ('BLOQUEIA SOMENTE CENÁRIO FUTURO — entidade de funcionalidade específica; '
                               'criar quando um cenário a exigir, com evidência do DDL de produção')
    if tipo == 'sequence-ausente':
        if (banco, tabela) in autorizadas:
            return 'complementado', f'gerador da tabela complementada {tabela}'
        if seq.split('.')[0] not in schemas_existentes[banco]:
            return 'excluido', 'defeito do legado: o nome da sequence aponta para schema inexistente'
        return 'transferido', 'BLOQUEIA SOMENTE CENÁRIO FUTURO — só afeta a inclusão de novos registros da entidade'
    return 'transferido', ''


def schemas_de(export):
    return {b: {linha.split('\t')[0].lower() for linha in open(os.path.join(export, f'colunas-{b}.tsv'), encoding='latin-1')}
            for b in BANCOS}


def cmd_verificar(src, export, autorizadas_tsv, saida_tsv):
    """Sai com erro se alguma divergência que o P6 deveria ter complementado continua aberta."""
    divs, reg = divergencias(src, export)
    autorizadas, schemas = carregar_autorizadas(autorizadas_tsv), schemas_de(export)
    tratadas = [(d, *tratamento(d, autorizadas, schemas)) for d in divs]
    with open(saida_tsv, 'w', encoding='utf-8') as f:
        f.write('banco\tarquivo\tclasse\ttabela\ttipo\tdetalhe\ttratamento\tmotivo\n')
        for (banco, arquivo, cls, tabela, tipo, det, _, _), trat, motivo in tratadas:
            f.write('\t'.join((banco, arquivo, cls, tabela, tipo, det, trat, motivo)) + '\n')
    abertas = 0
    for banco in BANCOS:
        d = [(x, t) for x, t, _ in tratadas if x[0] == banco]
        cont = lambda trat: sum(1 for _, t in d if t == trat)
        abertas += cont('complementado')
        print(f'mapeamento {banco}: {sum(1 for v in reg.values() if v == banco)} classes registradas; '
              f'{len(d)} divergência(s): {cont("complementado")} a complementar ainda abertas, '
              f'{cont("transferido")} transferidas com classificação, {cont("excluido")} excluídas com motivo')
    return abertas


def cmd_complemento(src, export, autorizadas_tsv, saida_sql):
    """DDL do P6 para gsan_comercial: só o que a política marca como `complementado`."""
    divs, _ = divergencias(src, export)
    autorizadas, schemas = carregar_autorizadas(autorizadas_tsv), schemas_de(export)
    ddl, tabelas_novas, fora = [], {}, {}
    for d in divs:
        banco, arquivo, cls, tabela, tipo, det, campos, seq = d
        trat, motivo = tratamento(d, autorizadas, schemas)
        if trat != 'complementado':
            fora[trat] = fora.get(trat, 0) + 1
            continue
        if tipo == 'tabela-ausente':
            t = tabelas_novas.setdefault(tabela, {'cols': {}, 'pk': [], 'classes': set(), 'motivo': motivo, 'seq': None})
            t['classes'].add(f'{cls} ({arquivo})')
            for c, tp, pk in campos:
                if tp is None:
                    raise SystemExit(f'{tabela}.{c}: tipo do mapeamento sem correspondência conhecida')
                t['cols'].setdefault(c, tp)
                if pk and c not in t['pk']:
                    t['pk'].append(c)
        elif tipo == 'coluna-ausente':
            c, tp, _ = campos[0]
            if tp is None:
                raise SystemExit(f'{tabela}.{c}: tipo do mapeamento sem correspondência conhecida')
            ddl.append(f'-- {cls} ({arquivo}): {motivo}\nALTER TABLE {tabela} ADD COLUMN {c} {tp};')
        elif tipo == 'sequence-ausente':
            tabelas_novas.setdefault(tabela, {'cols': {}, 'pk': [], 'classes': set(), 'motivo': '', 'seq': None})['seq'] = seq
    for tabela in sorted(tabelas_novas):
        t = tabelas_novas[tabela]
        linhas = [f'  {c} {tp}' for c, tp in t['cols'].items()]
        if t['pk']:
            linhas.append(f'  PRIMARY KEY ({", ".join(t["pk"])})')
        bloco = (f'-- {"; ".join(sorted(t["classes"]))}\n-- {t["motivo"]}\n'
                 f'CREATE TABLE {tabela} (\n' + ',\n'.join(linhas) + '\n);')
        if t['seq']:
            bloco += f'\nCREATE SEQUENCE {t["seq"]};'
        ddl.append(bloco)
    cabecalho = [
        '-- P6 — complemento estrutural de gsan_comercial derivado do mapeamento Hibernate do código.',
        '-- GERADO por ambiente-referencia/scripts/mapeamento.py — não editar à mão; a política e a',
        '-- classificação de cada divergência estão em banco/README.md.',
        '-- Objetos que o código (commit legado fixado em versoes.env) mapeia, que a SessionFactory',
        '-- comercial carrega e que nenhuma migração do gsan-migracoes cria: em produção vieram de DDL',
        '-- manual. Tipos derivados do mapeamento; colunas anuláveis; PK pelo <id>. Não é o DDL de',
        '-- produção: é o mínimo para que essas entidades carreguem.',
        f'-- Itens: {len(ddl)}. Divergências não complementadas: '
        + ', '.join(f'{v} {k}' for k, v in sorted(fora.items())) + ' (ver verificação).',
    ]
    conteudo = '\n'.join(cabecalho) + '\n\n' + '\n\n'.join(ddl) + '\n'
    with open(saida_sql, 'w', encoding='utf-8', newline='\n') as f:
        f.write(conteudo)
    print(f'complemento: {len(ddl)} item(ns) de DDL — sha256 {hashlib.sha256(conteudo.encode()).hexdigest()[:16]}')


if __name__ == '__main__':
    modo = sys.argv[1] if len(sys.argv) > 1 else ''
    if modo == 'verificar' and len(sys.argv) == 6:
        sys.exit(1 if cmd_verificar(*sys.argv[2:6]) else 0)
    elif modo == 'complemento' and len(sys.argv) == 6:
        cmd_complemento(*sys.argv[2:6])
    else:
        print(__doc__)
        sys.exit(2)
