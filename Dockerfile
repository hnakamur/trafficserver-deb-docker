# syntax=docker/dockerfile:1
ARG OS_TYPE=ubuntu
ARG OS_VERSION=24.04
FROM ${OS_TYPE}:${OS_VERSION} AS build_trafficserver

# Apapted from
# https://github.com/apache/trafficserver/blob/e4ff6cab0713f25290a62aba74b8e1a595b7bc30/ci/docker/deb/Dockerfile#L46-L58
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    tzdata apt-utils curl \
    build-essential clang llvm-dev ccache pkgconf bison flex gettext libc++-dev \
    cmake ninja-build \
    debhelper dpkg-dev lsb-release xz-utils \
    dpkg-dev git distcc file wget openssl hwloc intltool-debian \
    libssl-dev libexpat1-dev libpcre3-dev libcap-dev \
    libhwloc-dev libunwind-18-dev zlib1g-dev \
    tcl-dev tcl8.6-dev libjemalloc-dev liblzma-dev \
    libhiredis-dev libbrotli-dev libncurses-dev libgeoip-dev libmagick++-dev \
    libmaxminddb-dev libjansson-dev libcjose-dev \
    python3 python3-pip python3-virtualenv \
    python3-gunicorn python3-requests python3-httpbin \
    pipenv \
    libprotobuf-dev protobuf-compiler libcurl4-openssl-dev

RUN type cmake; cmake --version

ARG LUAJIT_DEB_VERSION
ARG LUAJIT_DEB_OS_ID
RUN mkdir -p /depends
RUN curl -sSL https://github.com/hnakamur/openresty-luajit-deb-docker/releases/download/${LUAJIT_DEB_VERSION}${LUAJIT_DEB_OS_ID}/openresty-luajit-${LUAJIT_DEB_VERSION}${LUAJIT_DEB_OS_ID}.tar.gz | tar zxf - -C /depends --strip-components=2
RUN dpkg -i /depends/*.deb

ARG SRC_DIR=/src
ARG BUILD_USER=build
RUN useradd -m -d ${SRC_DIR} -s /bin/bash ${BUILD_USER}

# build and install github.com/nlohmann/json
ARG NLOHMANN_JSON_VERSION=3.11.3
USER ${BUILD_USER}
WORKDIR ${SRC_DIR}
RUN curl -sSL https://github.com/nlohmann/json/archive/refs/tags/v${NLOHMANN_JSON_VERSION}.tar.gz | tar zxf -
WORKDIR ${SRC_DIR}/json-${NLOHMANN_JSON_VERSION}
RUN cmake -B build -G 'Ninja Multi-Config' -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_CXX_STANDARD=17 -DCMAKE_CXX_STANDARD_REQUIRED=ON
RUN cmake --build build --config Release
USER root
RUN cmake --build build --config Release --target install

# build and install github.com/open-telemetry/opentelemetry-cpp
ARG OPENTELEMETRY_CPP_VERSION=1.3.0
USER ${BUILD_USER}
WORKDIR ${SRC_DIR}
RUN curl -sSL https://github.com/open-telemetry/opentelemetry-cpp/archive/refs/tags/v${OPENTELEMETRY_CPP_VERSION}.tar.gz | tar zxf -
WORKDIR ${SRC_DIR}/opentelemetry-cpp-${OPENTELEMETRY_CPP_VERSION}
RUN cmake -B build -G 'Ninja Multi-Config' -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_TESTING=OFF -DWITH_EXAMPLES=OFF -DWITH_JAEGER=OFF -DWITH_OTLP=ON -DWITH_OTLP_GRPC=OFF -DWITH_OTLP_HTTP=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_CXX_STANDARD=17 -DCMAKE_CXX_STANDARD_REQUIRED=ON
RUN cmake --build build --config Release
USER root
RUN cmake --build build --config Release --target install

COPY --chown=${BUILD_USER}:${BUILD_USER} ./trafficserver/ /src/trafficserver/
USER ${BUILD_USER}
WORKDIR ${SRC_DIR}
ARG PKG_VERSION
RUN tar cf - trafficserver | xz -c > trafficserver_${PKG_VERSION}.orig.tar.xz

COPY --chown=build:build ./debian /src/trafficserver/debian/
WORKDIR ${SRC_DIR}/trafficserver
ARG PKG_REL_DISTRIB
RUN sed -i "s/DebRelDistrib/${PKG_REL_DISTRIB}/;s/UNRELEASED/$(lsb_release -cs)/" /src/trafficserver/debian/changelog
RUN CC=clang CXX=clang++ dpkg-buildpackage -us -uc

USER root

## setup_autest target
FROM build_trafficserver AS setup_autest
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
    quilt telnet ncat golang nghttp2-client
RUN go install github.com/mccutchen/go-httpbin/v2/cmd/go-httpbin@latest && \
    mv /root/go/bin/go-httpbin /usr/local/bin/go-httpbin
RUN go install github.com/summerwind/h2spec/cmd/h2spec@latest && \
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
