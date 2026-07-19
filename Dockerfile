# syntax=docker/dockerfile:1
ARG OS_TYPE=ubuntu
ARG OS_VERSION=24.04
FROM ${OS_TYPE}:${OS_VERSION} AS build_trafficserver

# setup clang
ARG LLVM_MAJOR_VERSION=22
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install curl lsb-release dpkg && \
    codename=$(lsb_release -sc); \
    if [ "${codename}" != resolute ]; then \
      mkdir -p /etc/apt/keyrings && \
      apt_key_path=/etc/apt/keyrings/apt.llvm.org.asc; \
      curl -sS -o $apt_key_path https://apt.llvm.org/llvm-snapshot.gpg.key && \
      arch=$(dpkg --print-architecture); \
      (echo "deb [arch=$arch signed-by=$apt_key_path] http://apt.llvm.org/${codename}/ llvm-toolchain-${codename}-${LLVM_MAJOR_VERSION} main"; \
       echo "deb-src [arch=$arch signed-by=$apt_key_path] http://apt.llvm.org/${codename}/ llvm-toolchain-${codename}-${LLVM_MAJOR_VERSION} main") \
      > /etc/apt/sources.list.d/llvm-${LLVM_MAJOR_VERSION}.list; \
    fi; \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install clang-${LLVM_MAJOR_VERSION} libc++-${LLVM_MAJOR_VERSION}-dev libunwind-${LLVM_MAJOR_VERSION}-dev llvm-${LLVM_MAJOR_VERSION}-dev

# setup cmake
ARG CMAKE_VERSION=3.28.3
RUN set -x; if [ $(lsb_release -sc) = "jammy" ]; then \
      arch=$(arch); \
      download_url=https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${arch}.tar.gz; \
      curl -sSL "$download_url" | tar zxf - -C /usr/local/ && \
      (cd /usr/local/bin; ln -s ../cmake-${CMAKE_VERSION}-linux-${arch}/bin/* .); \
    else \
      DEBIAN_FRONTEND=noninteractive apt-get -y install cmake; \
    fi

# Apapted from
# https://github.com/apache/trafficserver/blob/e4ff6cab0713f25290a62aba74b8e1a595b7bc30/ci/docker/deb/Dockerfile#L46-L58
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    tzdata apt-utils curl \
    build-essential clang ccache pkgconf bison flex gettext \
    cmake ninja-build \
    debhelper dpkg-dev lsb-release xz-utils \
    dpkg-dev git distcc file wget openssl hwloc intltool-debian \
    libssl-dev libexpat1-dev libpcre2-dev libcap-dev \
    libhwloc-dev zlib1g-dev netcat-openbsd \
    tcl-dev tcl8.6-dev libjemalloc-dev liblzma-dev \
    libhiredis-dev libbrotli-dev libncurses-dev libgeoip-dev libmagick++-dev \
    libmaxminddb-dev libjansson-dev libcjose-dev \
    python3 python3-pip python3-virtualenv \
    python3-gunicorn python3-requests python3-httpbin

RUN set -x; if [ $(lsb_release -sc) != "resolute" ]; then \
    env DEBIAN_FRONTEND=noninteractive apt-get -y install libpcre3-dev; \
    fi

RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

RUN set -x; if [ $(lsb_release -sc) = "resolute" ]; then \
      mkdir -p /depends-libpcre3 && \
      curl -sSL https://github.com/hnakamur/libpcre3-deb-docker/releases/download/8.39-15.1hn1ubuntu26.04/libpcre3-8.39-15.1hn1ubuntu26.04.tar.gz | tar zx -C /depends-libpcre3 --strip-components=2 && \
      dpkg -i /depends-libpcre3/*.deb; \
    fi

ARG LUAJIT_DEB_VERSION
ARG LUAJIT_DEB_OS_ID
RUN mkdir -p /depends
RUN curl -sSL https://github.com/hnakamur/openresty-luajit-deb-docker/releases/download/${LUAJIT_DEB_VERSION}${LUAJIT_DEB_OS_ID}/openresty-luajit-${LUAJIT_DEB_VERSION}${LUAJIT_DEB_OS_ID}.tar.gz | tar zxf - -C /depends --strip-components=2
RUN dpkg -i /depends/*.deb

ARG SRC_DIR=/src
WORKDIR ${SRC_DIR}
ARG GIT_TAG
RUN git clone --depth 1 --branch ${GIT_TAG} https://github.com/apache/trafficserver
ARG PKG_VERSION
RUN tar cf - trafficserver | xz -c > trafficserver_${PKG_VERSION}.orig.tar.xz

COPY --chown=root:root ./debian ${SRC_DIR}/trafficserver/debian/
WORKDIR ${SRC_DIR}/trafficserver
ARG PKG_REL_DISTRIB
RUN sed -i "s/\${LLVM_MAJOR_VERSION}/${LLVM_MAJOR_VERSION}/" ${SRC_DIR}/trafficserver/debian/control
RUN sed -i "s/DebRelDistrib/${PKG_REL_DISTRIB}/;s/UNRELEASED/$(lsb_release -cs)/" ${SRC_DIR}/trafficserver/debian/changelog
RUN env CC=clang-${LLVM_MAJOR_VERSION} CXX=clang++-${LLVM_MAJOR_VERSION} dpkg-buildpackage -us -uc

## setup_autest target
FROM build_trafficserver AS setup_autest
ARG GO_VERSION=1.25.0
RUN curl -sSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar zx -C /usr/local/
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
    quilt telnet ncat nghttp2-client
RUN /usr/local/go/bin/go install github.com/mccutchen/go-httpbin/v2/cmd/go-httpbin@latest && \
    mv /root/go/bin/go-httpbin /usr/local/bin/go-httpbin
RUN /usr/local/go/bin/go install github.com/summerwind/h2spec/cmd/h2spec@latest && \
    mv /root/go/bin/h2spec /usr/local/bin/h2spec

RUN cmake --build ./debian/build-$(dpkg-architecture -q DEB_HOST_MULTIARCH) --target install

ENV LANG=C
RUN QUILT_PATCHES=debian/patches quilt push -a

## run_autest target
FROM setup_autest AS run_autest

WORKDIR ${SRC_DIR}/trafficserver
RUN cmake --build debian/build-$(dpkg-architecture -q DEB_HOST_MULTIARCH) --target autest --verbose 2>&1 | tee /src/autest.log || :
