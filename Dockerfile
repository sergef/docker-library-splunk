FROM sergef/docker-library-alpine:edge

ENV GLIBC_RSA_PUB_URL https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub
ENV GLIBC_VERSION 2.25-r0
ENV GLIBC_URL https://github.com/sgerrand/alpine-pkg-glibc/releases/download
ENV GLIBC_PACKAGE_FILENAME glibc-${GLIBC_VERSION}.apk
ENV GLIBC_BIN_PACKAGE_FILENAME glibc-bin-${GLIBC_VERSION}.apk
ENV GLIBC_I18N_PACKAGE_FILENAME glibc-i18n-${GLIBC_VERSION}.apk

ENV SPLUNK_VERSION 6.6.3
ENV SPLUNK_BUILD e21ee54bc796

ENV SPLUNK_PASSWORD password

ENV SPLUNK_FILENAME splunk-${SPLUNK_VERSION}-${SPLUNK_BUILD}-Linux-x86_64.tgz
ENV SPLUNK_URL https://download.splunk.com/products/splunk/releases/${SPLUNK_VERSION}/linux/${SPLUNK_FILENAME}

ENV SPLUNK_SHA256SUM 3256b011e25b97af0a1279ea97f4a394ed5a2004b547c655a36e7cf012f6c4d4

ENV SPLUNK_HOME /opt/splunk
ENV SPLUNK_HTTP_INPUT_TOKEN 00000000-0000-0000-0000-000000000000
ENV LANG en_US.utf8

WORKDIR ${SPLUNK_HOME}

EXPOSE 8000 8088 8089 8191 9997 8517 514

ADD ${GLIBC_RSA_PUB_URL} /etc/apk/keys/sgerrand.rsa.pub
ADD ${GLIBC_URL}/${GLIBC_VERSION}/${GLIBC_PACKAGE_FILENAME} /tmp/downloads/
ADD ${GLIBC_URL}/${GLIBC_VERSION}/${GLIBC_BIN_PACKAGE_FILENAME} /tmp/downloads/
ADD ${GLIBC_URL}/${GLIBC_VERSION}/${GLIBC_I18N_PACKAGE_FILENAME} /tmp/downloads/
ADD ${SPLUNK_URL} /tmp/downloads/

COPY etc/apps/splunk_httpinput/local/inputs.conf.tmpl ${SPLUNK_HOME}/etc/apps/splunk_httpinput/local/inputs.conf.tmpl
COPY entrypoint.sh /entrypoint.sh
COPY setup.sh /setup.sh

RUN echo "${SPLUNK_SHA256SUM}  /tmp/downloads/${SPLUNK_FILENAME}" | sha256sum -c - \
  && tar -xf /tmp/downloads/${SPLUNK_FILENAME} --strip-components 1 -C ${SPLUNK_HOME} \
  && apk add \
    --no-cache \
    bash \
    procps \
    /tmp/downloads/${GLIBC_PACKAGE_FILENAME} \
    /tmp/downloads/${GLIBC_BIN_PACKAGE_FILENAME} \
    /tmp/downloads/${GLIBC_I18N_PACKAGE_FILENAME} \
  && chmod +x /entrypoint.sh \
  && chmod +x /setup.sh \
  && /setup.sh \
  && rm -rf \
    /tmp/* \
    /var/cache/apk/*

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
