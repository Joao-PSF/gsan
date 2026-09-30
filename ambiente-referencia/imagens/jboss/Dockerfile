# Imagem do servidor de aplicação do GSAN de referência: JDK 6 + JBoss 4.0.1SP1
# configurado pela receita oficial + Ant para o build do EAR.
#
# Estágio 1 (obter): baixa e confere os binários e as receitas. Estágio 2: Debian
# atual (glibc com vDSO) com o JDK 6 da Azul — a glibc 2.13 do wheezy derruba a JVM
# em kernels sem emulação de vsyscall (Docker Desktop/WSL2).

ARG IMG_ALPINE
ARG IMG_DEBIAN

FROM ${IMG_ALPINE} AS obter
ARG JDK6_URL
ARG JDK6_SHA256
ARG JBOSS_URL
ARG JBOSS_SHA1
ARG ANT_URL
ARG ANT_SHA512
ARG PRODIGA_TI_REPO
ARG PRODIGA_TI_COMMIT
ARG JBOSS_LIBS_REPO
ARG JBOSS_LIBS_COMMIT
RUN apk add --no-cache bash curl git grep sed unzip
WORKDIR /obter

RUN curl -fsSL -o jdk.tar.gz "$JDK6_URL" \
 && echo "$JDK6_SHA256  jdk.tar.gz" | sha256sum -c - \
 && mkdir jdk6 && tar -xzf jdk.tar.gz -C jdk6 --strip-components=1 && rm jdk.tar.gz

RUN curl -fsSL -o jboss.zip "$JBOSS_URL" \
 && echo "$JBOSS_SHA1  jboss.zip" | sha1sum -c - \
 && unzip -q jboss.zip && rm jboss.zip

RUN curl -fsSL -o ant.tar.gz "$ANT_URL" \
 && echo "$ANT_SHA512  ant.tar.gz" | sha512sum -c - \
 && tar -xzf ant.tar.gz && rm ant.tar.gz

# Repositórios da receita, fixados por commit.
RUN git init -q ti && git -C ti fetch -q --depth 1 "$PRODIGA_TI_REPO" "$PRODIGA_TI_COMMIT" \
 && git -C ti checkout -q FETCH_HEAD \
 && git init -q jboss-libs && git -C jboss-libs fetch -q --depth 1 "$JBOSS_LIBS_REPO" "$JBOSS_LIBS_COMMIT" \
 && git -C jboss-libs checkout -q FETCH_HEAD

COPY aplicar-receita.sh /obter/
RUN bash /obter/aplicar-receita.sh /obter/jboss-4.0.1sp1 /obter/ti /obter/jboss-libs

FROM ${IMG_DEBIAN}
# Fontes para o AWT headless (preenchimento e exportação dos relatórios JasperReports) e o
# locale do servidor da receita oficial (configure_locale_latin: LANG=pt_BR, ISO-8859-1).
# O locale não é cosmético: o JasperReports gera e compila classes Java com o nome e as
# variáveis dos relatórios (há identificadores com acento) na codificação do sistema.
RUN apt-get update \
 && apt-get install -y --no-install-recommends fontconfig fonts-dejavu-core locales \
 && rm -rf /var/lib/apt/lists/* \
 && localedef -i pt_BR -c -f ISO-8859-1 -A /usr/share/locale/locale.alias pt_BR.ISO-8859-1

ENV LANG=pt_BR.ISO-8859-1 \
    JAVA_HOME=/opt/jdk6 \
    JBOSS_HOME=/opt/jboss \
    ANT_HOME=/opt/apache-ant-1.9.16 \
    TZ=America/Belem
ENV PATH=$JAVA_HOME/bin:$ANT_HOME/bin:$PATH

RUN useradd --uid 1000 --home-dir /opt/jboss --no-create-home --shell /bin/sh jboss

COPY --from=obter /obter/jdk6 /opt/jdk6
COPY --from=obter --chown=jboss:jboss /obter/jboss-4.0.1sp1 /opt/jboss-4.0.1sp1
COPY --from=obter /obter/apache-ant-1.9.16 /opt/apache-ant-1.9.16
COPY --from=obter /obter/ti/docs/scripts/templates/gsan/postgres-ds.xml /opt/gsan-referencia/postgres-ds.xml.modelo
# Driver JDBC versionado no próprio fork (lib/driver-postgres), entregue por
# contexto adicional do build. A receita usa o driver 8.1 do jboss-libs.
COPY --from=driver --chown=jboss:jboss postgresql-42.2.23.jre6.jar /opt/jboss-4.0.1sp1/server/default/lib/
COPY --chmod=755 entrypoint.sh build-legado.sh /opt/gsan-referencia/

# Pontos de montagem criados com o dono certo: volumes nomeados herdam a posse.
RUN ln -s /opt/jboss-4.0.1sp1 /opt/jboss \
 && install -d -o jboss -g jboss /opt/jboss/server/default/deploy/gcom.ear \
      /opt/jboss/server/default/log /saida

USER jboss
WORKDIR /opt/jboss
EXPOSE 8080
ENTRYPOINT ["/opt/gsan-referencia/entrypoint.sh"]
