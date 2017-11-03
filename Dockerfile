FROM debian:jessie-slim

ARG JAVA_DOWNLOAD_URL
ARG JAVA_DOWNLOAD_SHASUM=bad9a731639655118740bee119139c1ed019737ec802a630dd7ad7aab4309623
ARG JAVA_VERSION=1.7.0_80

ENV JAVA_HOME=/opt/java/jdk${JAVA_VERSION}
ENV PATH=$PATH:$JAVA_HOME/bin

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        wget \
        ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && JAVA_TARBALL="${JAVA_DOWNLOAD_URL##*/}" \
    && wget "$JAVA_DOWNLOAD_URL" \
    && echo "$JAVA_DOWNLOAD_SHASUM *$JAVA_TARBALL" | sha256sum -c \
    && mkdir -p /opt/java \
    && tar -xzf "$JAVA_TARBALL" -C /opt/java \
    && chown -R root:root "$JAVA_HOME" \
    && rm "$JAVA_HOME/src.zip" \
    && rm "$JAVA_TARBALL" \
    && useradd -m weblogic \
    && mkdir -p /opt/weblogic /srv/weblogic \
    && chown weblogic /opt/weblogic /srv/weblogic

ARG WEBLOGIC_DOWNLOAD_URL
ARG WEBLOGIC_DOWNLOAD_SHASUM=2a53e63feeb1959bc4aee1cf728486a0c29a9e8f2cdc53c463cb937e84fe951e

ENV WEBLOGIC_DOMAIN=mydomain \
    WEBLOGIC_PWD= \
    WEBLOGIC_MEM_ARGS= \
    WEBLOGIC_PRE_CLASSPATH=

USER weblogic
COPY --chown=weblogic silent.xml /opt/weblogic/

RUN cd /opt/weblogic \
    && mkdir -p scripts/setup \
    && sed -i "s|###JAVA_HOME###|$JAVA_HOME|" silent.xml \
    && WEBLOGIC_INSTALLER_JAR="${WEBLOGIC_DOWNLOAD_URL##*/}" \
    && wget "$WEBLOGIC_DOWNLOAD_URL" \
    && echo "$WEBLOGIC_DOWNLOAD_SHASUM *$WEBLOGIC_INSTALLER_JAR" | sha256sum -c \
    && java -jar "$WEBLOGIC_INSTALLER_JAR" -mode=silent -silent_xml=silent.xml \
    && rm "$WEBLOGIC_INSTALLER_JAR" silent.xml

COPY --chown=weblogic run-weblogic.sh /opt/weblogic/

VOLUME /opt/weblogic/scripts/setup
VOLUME /srv/weblogic
EXPOSE 7001

CMD ["/opt/weblogic/run-weblogic.sh"]
