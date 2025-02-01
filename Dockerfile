# syntax=docker/dockerfile:1
ARG OS_TYPE=ubuntu
ARG OS_VERSION=24.04
FROM ${OS_TYPE}:${OS_VERSION} AS build_trafficserver

# Apapted from
# https://github.com/apache/trafficserver/blob/e4ff6cab0713f25290a62aba74b8e1a595b7bc30/ci/docker/deb/Dockerfile#L46-L58
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    tzdata apt-utils curl \
    build-essential ccache pkgconf bison flex gettext \
    debhelper dpkg-dev lsb-release xz-utils \
    dpkg-dev git distcc file wget openssl hwloc intltool-debian \
    libssl-dev libexpat1-dev libpcre3-dev libcap-dev \
    libhwloc-dev zlib1g-dev \
    tcl-dev tcl8.6-dev libjemalloc-dev liblzma-dev \
    libhiredis-dev libbrotli-dev libncurses-dev libgeoip-dev libmagick++-dev \
    libmaxminddb-dev libjansson-dev libcjose-dev libunwind-dev \
    graphviz libboost-dev default-libmysqlclient-dev python3-sphinx plantuml \
    python3-sphinxcontrib.plantuml libcurl4-openssl-dev libkyotocabinet-dev \
    libmemcached-dev libcrypto++-dev \
    python3 python3-pip python3-virtualenv \
    python3-gunicorn python3-requests python3-httpbin

# Note: install pipenv with pip3 on Ubuntu 22.04 (jammy) since pipenv deb package is too old.
# Also install pipenv as root user since root privilege is needed to run all tests in autest.
RUN set -x; if [ $(lsb_release -sc) = "jammy" ]; then \
    pip3 install pipenv; \
    else \
    env DEBIAN_FRONTEND=noninteractive apt-get -y install pipenv; \
    fi

ARG LUAJIT_DEB_VERSION
ARG LUAJIT_DEB_OS_ID
RUN mkdir -p /depends
RUN curl -sSL https://github.com/hnakamur/openresty-luajit-deb-docker/releases/download/${LUAJIT_DEB_VERSION}${LUAJIT_DEB_OS_ID}/openresty-luajit-${LUAJIT_DEB_VERSION}${LUAJIT_DEB_OS_ID}.tar.gz | tar zxf - -C /depends --strip-components=2
RUN dpkg -i /depends/*.deb

ARG SRC_DIR=/src
ARG BUILD_USER=build
RUN useradd -m -d ${SRC_DIR} -s /bin/bash ${BUILD_USER}

COPY --chown=${BUILD_USER}:${BUILD_USER} ./trafficserver/ ${SRC_DIR}/trafficserver/
USER ${BUILD_USER}
WORKDIR ${SRC_DIR}
ARG PKG_VERSION
RUN tar cf - trafficserver | xz -c > trafficserver_${PKG_VERSION}.orig.tar.xz

COPY --chown=${BUILD_USER}:${BUILD_USER} ./debian ${SRC_DIR}/trafficserver/debian/
WORKDIR ${SRC_DIR}/trafficserver
ARG PKG_REL_DISTRIB
RUN sed -i "s/DebRelDistrib/${PKG_REL_DISTRIB}/;s/UNRELEASED/$(lsb_release -cs)/" ${SRC_DIR}/trafficserver/debian/changelog
RUN dpkg-buildpackage -us -uc

USER root

## setup_autest target
FROM build_trafficserver AS setup_autest
ARG GO_VERSION=1.23.5
RUN curl -sSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar zx -C /usr/local/
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
    quilt telnet ncat nghttp2-client
RUN /usr/local/go/bin/go install github.com/mccutchen/go-httpbin/v2/cmd/go-httpbin@latest && \
    mv /root/go/bin/go-httpbin /usr/local/bin/go-httpbin
RUN /usr/local/go/bin/go install github.com/summerwind/h2spec/cmd/h2spec@latest && \
    mv /root/go/bin/h2spec /usr/local/bin/h2spec

RUN apt-get install -y ${SRC_DIR}/*.deb
RUN chown -R ${BUILD_USER}:${BUILD_USER} /opt/trafficserver
RUN mkdir -p /test

USER ${BUILD_USER}
ENV LANG=C
RUN QUILT_PATCHES=debian/patches quilt push -a

USER root

## run_autest target
FROM setup_autest AS run_autest
USER ${BUILD_USER}
WORKDIR ${SRC_DIR}/trafficserver/tests
RUN ./autest.sh --ats-bin /usr/bin 2>&1 | tee /src/autest.log || :
