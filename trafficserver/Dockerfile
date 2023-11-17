# syntax=docker/dockerfile:1
ARG FROM=ubuntu:22.04
FROM ${FROM}

# Apapted from
# https://github.com/apache/trafficserver/blob/e4ff6cab0713f25290a62aba74b8e1a595b7bc30/ci/docker/deb/Dockerfile#L46-L58
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata apt-utils && \
    # Compilers
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    ccache make pkgconf bison flex g++ clang gettext libc++-dev \
    cmake ninja-build \
    # tools to create deb packages
    debhelper dpkg-dev lsb-release xz-utils \
    # Various other tools
    dpkg-dev git distcc file wget openssl hwloc intltool-debian && \
    # Devel packages that ATS needs
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    libssl-dev libexpat1-dev libpcre3-dev libcap-dev \
    libhwloc-dev libunwind8 libunwind-dev zlib1g-dev \
    tcl-dev tcl8.6-dev libjemalloc-dev libluajit-5.1-dev liblzma-dev \
    libhiredis-dev libbrotli-dev libncurses-dev libgeoip-dev libmagick++-dev \
    libmaxminddb-dev libjansson-dev libcjose-dev

ARG SRC_DIR=/src
ARG BUILD_USER=build
RUN useradd -m -d ${SRC_DIR} ${BUILD_USER}

USER ${BUILD_USER}
WORKDIR ${SRC_DIR}
ARG REPO_URL=https://github.com/apache/trafficserver
RUN git clone --depth 1 ${REPO_URL}

ARG PKG_VERSION
RUN tar cf - --exclude=.git trafficserver | xz -c --best > trafficserver_${PKG_VERSION}.orig.tar.xz

WORKDIR ${SRC_DIR}/trafficserver
RUN git log -1

COPY --chown=build:build ./debian /src/trafficserver/debian/
ARG PKG_REL_DISTRIB
RUN sed -i "s/DebRelDistrib/${PKG_REL_DISTRIB}/;s/DebRelCodename/$(lsb_release -cs)/" /src/trafficserver/debian/changelog
RUN dpkg-buildpackage -us -uc

USER root
