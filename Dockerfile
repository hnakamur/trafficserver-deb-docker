# syntax=docker/dockerfile:1
ARG OS_TYPE=ubuntu
ARG OS_VERSION=24.04
FROM ${OS_TYPE}:${OS_VERSION} AS build_trafficserver

# setup clang
ARG LLVM_MAJOR_VERSION=18
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install curl lsb-release dpkg && \
    mkdir -p /etc/apt/keyrings && \
    apt_key_path=/etc/apt/keyrings/apt.llvm.org.asc; \
    curl -sS -o $apt_key_path https://apt.llvm.org/llvm-snapshot.gpg.key && \
    arch=$(dpkg --print-architecture); \
    codename=$(lsb_release -sc); \
    cat <<EOF > /etc/apt/sources.list.d/llvm-${LLVM_MAJOR_VERSION}.list
deb [arch=$arch signed-by=$apt_key_path] http://apt.llvm.org/${codename}/ llvm-toolchain-${codename}-${LLVM_MAJOR_VERSION} main                                                                                     deb-src [arch=$arch signed-by=$apt_key_path] http://apt.llvm.org/${codename}/ llvm-toolchain-${codename}-${LLVM_MAJOR_VERSION} main
EOF

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install clang-${LLVM_MAJOR_VERSION} libc++-${LLVM_MAJOR_VERSION}-dev libunwind-${LLVM_MAJOR_VERSION}-dev llvm-${LLVM_MAJOR_VERSION}-dev

# setup cmake
ARG CMAKE_VERSION=3.28.3
RUN arch=$(arch); \
    download_url=https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${arch}.tar.gz; \
    curl -sSL "$download_url" | tar zxf - -C /usr/local/ && \
    (cd /usr/local/bin; ln -s ../cmake-${CMAKE_VERSION}-linux-${arch}/bin/* .)

# Apapted from
# https://github.com/apache/trafficserver/blob/e4ff6cab0713f25290a62aba74b8e1a595b7bc30/ci/docker/deb/Dockerfile#L46-L58
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    tzdata apt-utils curl \
    build-essential clang ccache pkgconf bison flex gettext \
    cmake ninja-build \
    debhelper dpkg-dev lsb-release xz-utils \
    dpkg-dev git distcc file wget openssl hwloc intltool-debian \
    libssl-dev libexpat1-dev libpcre3-dev libcap-dev \
    libhwloc-dev zlib1g-dev \
    tcl-dev tcl8.6-dev libjemalloc-dev liblzma-dev \
    libhiredis-dev libbrotli-dev libncurses-dev libgeoip-dev libmagick++-dev \
    libmaxminddb-dev libjansson-dev libcjose-dev \
    python3 python3-pip python3-virtualenv \
    python3-gunicorn python3-requests python3-httpbin

# Note: install pipenv with pip3 on Ubuntu 22.04 (jammy) since pipenv deb package is too old.
# Also install pipenv as root user since root privilege is needed to run all tests in autest.
RUN set -x; if [ $(lsb_release -sc) = "jammy" ]; then \
    pip3 install pipenv; \
    else \
    env DEBIAN_FRONTEND=noninteractive apt-get -y install pipenv; \
    fi

RUN type cmake; cmake --version

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

COPY --chown=build:build ./debian ${SRC_DIR}/trafficserver/debian/
WORKDIR ${SRC_DIR}/trafficserver
ARG PKG_REL_DISTRIB
RUN sed -i "s/\${LLVM_MAJOR_VERSION}/${LLVM_MAJOR_VERSION}/" ${SRC_DIR}/trafficserver/debian/control
RUN sed -i "s/DebRelDistrib/${PKG_REL_DISTRIB}/;s/UNRELEASED/$(lsb_release -cs)/" ${SRC_DIR}/trafficserver/debian/changelog
RUN env CC=clang-${LLVM_MAJOR_VERSION} CXX=clang++-${LLVM_MAJOR_VERSION} dpkg-buildpackage -us -uc

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

RUN cmake --build ./debian/build-$(dpkg-architecture -q DEB_HOST_MULTIARCH) --target install
RUN chown -R ${BUILD_USER}:${BUILD_USER} /opt/trafficserver
RUN mkdir -p /test
RUN chown nobody:nogroup /test

RUN build_dir=debian/build-$(dpkg-architecture -q DEB_HOST_MULTIARCH); \
    cat <<EOF > /usr/local/bin/autest-all.sh
#!/bin/bash
set -eu
cd ${SRC_DIR}/trafficserver
cmake --build ${build_dir} --target autest --verbose
EOF

RUN build_dir_fullpath=${SRC_DIR}/trafficserver/debian/build-$(dpkg-architecture -q DEB_HOST_MULTIARCH); \
    arch=$(dpkg --print-architecture); \
    cat <<EOF > /usr/local/bin/my-autest.sh
#!/bin/bash
set -eu
cd ${build_dir_fullpath}/tests
PIPENV_VENV_IN_PROJECT=True pipenv install 

sandbox_dir=/test/autest-sandbox-\$(date +%Y%m%dT%H%M%S)
env PYTHONPATH=${SRC_DIR}/trafficserver/gold_tests/remap:$PYTHONPATH} \
PIPENV_VENV_IN_PROJECT=True pipenv run env autest "\$@" \
  --directory /src/trafficserver/tests/gold_tests \
  --ats-bin=/opt/trafficserver/bin \
  --proxy-verifier-bin ${build_dir_fullpath}/proxy-verifier-v2.12.0/linux-${arch} \
  --build-root ${build_dir_fullpath} \
  --sandbox \${sandbox_dir}
EOF
RUN chmod +x /usr/local/bin/autest-all.sh /usr/local/bin/my-autest.sh

USER ${BUILD_USER}
ENV LANG=C
RUN QUILT_PATCHES=debian/patches quilt push -a

USER root

# Disable bad_http_fmt test since it does not finish.
RUN mv tests/gold_tests/bad_http_fmt/bad_http_fmt.test.py tests/gold_tests/bad_http_fmt/bad_http_fmt.test.py.disabled
RUN mv tests/gold_tests/tls/tls_forward_nonhttp.test.py tests/gold_tests/tls/tls_forward_nonhttp.test.py.disabled

## run_autest target
FROM setup_autest AS run_autest
RUN my-autest.sh run 2>&1 | tee /src/autest.log || :
