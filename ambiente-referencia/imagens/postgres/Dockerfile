# PostgreSQL do GSAN de referência — versão e locale da receita oficial
# (postgresql.server.version = 9.5; configure_locale_latin: cluster criado com
# locale pt_BR.ISO-8859-1, bancos em LATIN1).
ARG IMG_POSTGRES
FROM ${IMG_POSTGRES}

RUN localedef -i pt_BR -c -f ISO-8859-1 -A /usr/share/locale/locale.alias pt_BR.ISO-8859-1

# Diretório do tablespace `indices`, criado pela migração 20160118183216 com
# LOCATION '/opt/pgsql/indices'. Vazio e do usuário postgres, como o
# PostgreSQL exige; montado em volume próprio para sobreviver à recriação.
RUN install -d -o postgres -g postgres -m 700 /opt/pgsql/indices

ENV POSTGRES_INITDB_ARGS="--locale=pt_BR.ISO-8859-1 --encoding=LATIN1"
