# syntax=docker/dockerfile:1
ARG OS_TYPE=ubuntu
ARG OS_VERSION=22.04
FROM ${OS_TYPE}:${OS_VERSION} as base

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
    python3 python3-pip python3-virtualenv \
    python3-gunicorn python3-requests python3-httpbin
RUN set -x; if [ $(lsb_release -is) = "Debian" ]; then \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    pipenv; \
    fi

ARG SRC_DIR=/src
ARG BUILD_USER=build
RUN useradd -m -d ${SRC_DIR} -s /bin/bash ${BUILD_USER}

USER ${BUILD_USER}
RUN set -x; if [ $(lsb_release -is) = "Ubuntu" ]; then \
    pip3 install --user pipenv; \
    fi

COPY --chown=${BUILD_USER}:${BUILD_USER} ./trafficserver/ /src/trafficserver/
WORKDIR ${SRC_DIR}
ARG PKG_VERSION
RUN tar cf - trafficserver | xz -c --best > trafficserver_${PKG_VERSION}.orig.tar.xz

COPY --chown=build:build ./debian /src/trafficserver/debian/
WORKDIR ${SRC_DIR}/trafficserver
ARG PKG_REL_DISTRIB
RUN sed -i "s/DebRelDistrib/${PKG_REL_DISTRIB}/;s/DebRelCodename/$(lsb_release -cs)/" /src/trafficserver/debian/changelog
RUN dpkg-buildpackage -us -uc

USER root

FROM base as autest
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
    quilt telnet
RUN cmake --build ./debian/build-$(dpkg-architecture -q DEB_HOST_MULTIARCH) --target install
RUN chown -R ${BUILD_USER}:${BUILD_USER} /opt/trafficserver

RUN build_dir=debian/build-$(dpkg-architecture -q DEB_HOST_MULTIARCH); \
    cat <<EOF > /usr/local/bin/autest-all.sh
#!/bin/bash
set -eu
cd ${SRC_DIR}/trafficserver
cmake --build ${build_dir} --target autest --verbose
EOF

RUN build_dir_fullpath=${SRC_DIR}/trafficserver/debian/build-$(dpkg-architecture -q DEB_HOST_MULTIARCH); \
    arch=$(dpkg --print-architecture); \
  if [ $(lsb_release -is) = "Ubuntu" ]; then \
    pipenv=${SRC_DIR}/.local/bin/pipenv; \
  else \
    pipenv=/usr/bin/pipenv; \
  fi; \
  cat <<EOF > /usr/local/bin/my-autest.sh
#!/bin/bash
set -eu
cd ${build_dir_fullpath}/tests
PIPENV_VENV_IN_PROJECT=True ${pipenv} install 
PIPENV_VENV_IN_PROJECT=True ${pipenv} run env autest "\$@" \
  --directory /src/trafficserver/tests/gold_tests \
  --ats-bin=/opt/trafficserver/bin \
  --proxy-verifier-bin ${build_dir_fullpath}/proxy-verifier-v2.10.1/linux-${arch} \
  --build-root ${build_dir_fullpath} \
  --sandbox ${build_dir_fullpath}/_sandbox
EOF
RUN chmod +x /usr/local/bin/autest-all.sh /usr/local/bin/my-autest.sh

USER ${BUILD_USER}
ENV LANG=C
RUN QUILT_PATCHES=debian/patches quilt push -a
