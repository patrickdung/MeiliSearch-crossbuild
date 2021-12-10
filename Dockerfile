# SPDX-License-Identifier: Apache-2.0
#
# Copyright (c) 2021 Patrick Dung

FROM docker.io/debian:bullseye-slim
# FROM gcr.io/distroless/base-debian11

#ARG MEILISEARCH_VERSION="v0.25.0rc0"
ARG MEILISEARCH_VERSION=""
#ARG ARCH="amd64"
ARG ARCH=""

# With Docker's buildx, TARGETARCH gives out amd64/arm64
ARG TARGETARCH

#ARG SOURCE_BINARY_BASEURL="https://github.com/meilisearch/MeiliSearch/releases/download"
ARG SOURCE_BINARY_BASEURL=""

## Offical
##https://github.com/meilisearch/MeiliSearch/releases/download/v0.23.0rc0/meilisearch-linux-amd64
##https://github.com/meilisearch/MeiliSearch/releases/download/v0.23.0rc0/meilisearch-linux-armv8

RUN set -eux && \
    apt-get -y update && \
    apt-get -y install --no-install-suggests \
      bash tini curl file procps coreutils && \
    groupadd \
      --gid 1000 \
      meilisearch && \
    useradd --no-log-init \
      --create-home \
      --home-dir /home/meilisearch \
      --shell /bin/bash \
      --uid 1000 \
      --gid 1000 \
      --key MAIL_DIR=/dev/null \
      meilisearch && \
    mkdir -p /meilisearch /data.ms /home/meilisearch/bin && \
    chown meilisearch:meilisearch /meilisearch /data.ms /home/meilisearch/bin && \
    chmod 755 /home/meilisearch/bin && \
    cd /home/meilisearch/bin/ && \
    curl -L -v -O ${SOURCE_BINARY_BASEURL}/${MEILISEARCH_VERSION}/meilisearch-linux-$(/bin/uname -m)-stripped \
    && curl -L -v -o meilisearch.sha256sum ${SOURCE_BINARY_BASEURL}/${MEILISEARCH_VERSION}/meilisearch-linux-$(/bin/uname -m)-stripped.sha256sum \
    && sha256sum --check --strict meilisearch.sha256sum \
    && ln -s meilisearch-linux-$(/bin/uname -m)-stripped meilisearch \
    && chown -R meilisearch:meilisearch /home/meilisearch/bin \
    && chmod 755 /home/meilisearch/bin/meilisearch \
    && ls -lR /home/meilisearch/bin \
    && apt-get -y upgrade && apt-get -y autoremove && apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

##RUN set -eux && if [ "${ARCH}" = "x86_64" ] ; then curl -L -v -o /home/meilisearch/bin/meilisearch ${SOURCE_BINARY_BASEURL}/${MEILISEARCH_VERSION}/meilisearch-linux-aarch64; ls -l /home/meilisearch/bin/meilisearch; /usr/bin/aarch64-linux-gnu-strip --strip-debug --target=elf64-littleaarch64 /home/meilisearch/bin/meilisearch; fi
##RUN set -eux && if [ "${ARCH}" = "aarch" ] ; then curl -L -v -o /home/meilisearch/bin/meilisearch ${SOURCE_BINARY_BASEURL}/${MEILISEARCH_VERSION}/meilisearch-linux-amd64; ls -l /home/meilisearch/bin/meilisearch; /usr/bin/strip --strip-debug /home/meilisearch/bin/meilisearch; fi

## Inside GH actions, uname -p => "unknown"
## RUN /bin/uname -m > /tmp/arch

##RUN set -eux && ARCH=$(cat /tmp/arch) echo TARGETARCH-${TARGETARCH} ARCH-${ARCH} && ARCH=$(cat /tmp/arch) curl -L -v -o /home/meilisearch/bin/meilisearch ${SOURCE_BINARY_BASEURL}/${MEILISEARCH_VERSION}/meilisearch-linux-${ARCH}

USER meilisearch

# Matches the official helm chart in
# https://github.com/meilisearch/meilisearch-kubernetes/blob/main/charts/meilisearch/values.yaml
VOLUME /data.ms
WORKDIR /data.ms

ENV     MEILI_HTTP_ADDR 0.0.0.0:7700
EXPOSE  7700/tcp

ENTRYPOINT ["tini", "--"]
CMD     ["/home/meilisearch/bin/meilisearch"]
