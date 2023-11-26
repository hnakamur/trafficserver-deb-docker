# syntax=docker/dockerfile:1
ARG FROM=ubuntu:22.04
FROM ${FROM}

ARG LLVM_MAJOR_VERSION=16
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install curl lsb-release dpkg && \
    mkdir -p /etc/apt/keyrings && \
    apt_key_path=/etc/apt/keyrings/apt.llvm.org.asc; \
    curl -sS -o $apt_key_path https://apt.llvm.org/llvm-snapshot.gpg.key && \
    arch=$(dpkg --print-architecture); \
    codename=$(lsb_release -sc); \
    cat <<EOF > /etc/apt/sources.list.d/llvm-${LLVM_MAJOR_VERSION}.list
deb [arch=$arch signed-by=$apt_key_path] http://apt.llvm.org/${codename}/ llvm-toolchain-${codename}-${LLVM_MAJOR_VERSION} main
deb-src [arch=$arch signed-by=$apt_key_path] http://apt.llvm.org/${codename}/ llvm-toolchain-${codename}-${LLVM_MAJOR_VERSION} main
EOF
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install clang-${LLVM_MAJOR_VERSION}

# Apapted from
# https://github.com/apache/trafficserver/blob/e4ff6cab0713f25290a62aba74b8e1a595b7bc30/ci/docker/deb/Dockerfile#L46-L58
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata apt-utils && \
    # Compilers
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    ccache pkgconf bison flex gettext libc++-dev \
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
    libmaxminddb-dev libjansson-dev libcjose-dev \
    # packages that autest needs
    python3-full python3-pip python3-virtualenv \
    python3-gunicorn python3-requests python3-httpbin

ARG SRC_DIR=/src
ARG BUILD_USER=build
RUN useradd -m -d ${SRC_DIR} ${BUILD_USER}

USER ${BUILD_USER}
RUN pip3 install pipenv

COPY --chown=${BUILD_USER}:${BUILD_USER} ./trafficserver/ /src/trafficserver/
WORKDIR ${SRC_DIR}
ARG PKG_VERSION
RUN tar cf - --exclude=.git trafficserver | xz -c --best > trafficserver_${PKG_VERSION}.orig.tar.xz

COPY --chown=build:build ./debian /src/trafficserver/debian/
WORKDIR ${SRC_DIR}/trafficserver
ARG PKG_REL_DISTRIB
RUN sed -i "s/DebRelDistrib/${PKG_REL_DISTRIB}/;s/DebRelCodename/$(lsb_release -cs)/" /src/trafficserver/debian/changelog
RUN dpkg-buildpackage -us -uc

USER root
