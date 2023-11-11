# syntax=docker/dockerfile:1
ARG FROM=ubuntu:22.04
FROM ${FROM}

# Apapted from
# https://github.com/apache/trafficserver/blob/e4ff6cab0713f25290a62aba74b8e1a595b7bc30/ci/docker/deb/Dockerfile#L46-L58
RUN apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata apt-utils; \
    # Compilers
    apt-get -y install  ccache make pkgconf bison flex g++ clang gettext libc++-dev \
    # CMake
    cmake \
    # Various other tools
    dpkg-dev git distcc file wget openssl hwloc intltool-debian; \
    # Devel packages that ATS needs
    apt-get -y install libssl-dev libexpat1-dev libpcre3-dev libcap-dev \
    libhwloc-dev libunwind8 libunwind-dev zlib1g-dev \
    tcl-dev tcl8.6-dev libjemalloc-dev libluajit-5.1-dev liblzma-dev \
    libhiredis-dev libbrotli-dev libncurses-dev libgeoip-dev libmagick++-dev \
    libmaxminddb-dev

ARG SRC_DIR=/src
ARG BUILD_USER=build
RUN useradd -m -d ${SRC_DIR} ${BUILD_USER}

USER ${BUILD_USER}
WORKDIR ${SRC_DIR}
ARG REPO_URL=https://github.com/apache/trafficserver
RUN git clone --depth 1 ${REPO_URL}
WORKDIR ${SRC_DIR}/trafficserver

# modify some instances of CMakeLists.txt
RUN <<EOF cat >> ${SRC_DIR}/trafficserver/CMakeLists.txt

# Packaging
include(CPack)
EOF

ARG BUILD_DIR=${SRC_DIR}/trafficserver/build
ARG MAX_JOBS=24
ARG INSTALL_PREFIX=/opt/trafficserver
ARG INSTALL_BINDIR=bin
ARG INSTALL_SBINDIR=bin
ARG INSTALL_LIBDIR=lib
ARG INSTALL_LIBEXECDIR=lib/modules
ARG INSTALL_SYSCONFDIR=etc
ARG INSTALL_LOCALSTATEDIR=var
ARG INSTALL_RUNSTATEDIR=var/run
ARG INSTALL_DATAROOTDIR=share
ARG INSTALL_DATADIR=share/data
ARG INSTALL_DOCDIR=share/doc
ARG INSTALL_LOGDIR=var/log
ARG INSTALL_CACHEDIR=var/cache
# Compiler flags for CMAKE_BUILD_TYPE
# Release:        -O3 -DNDEBUG
# RelWithDebInfo: -O2 -g -DNDEBUG
ARG CMAKE_BUILD_TYPE=Release
RUN n=$(nproc); jobs=$(( $n > $MAX_JOBS ? $MAX_JOBS : $n )); \
  (set -x; \
  git log -1; \
  cmake -B ${BUILD_DIR} \
    -D CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    -D CMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -D CMAKE_INSTALL_BINDIR=${INSTALL_BINDIR} \
    -D CMAKE_INSTALL_SBINDIR=${INSTALL_SBINDIR} \
    -D CMAKE_INSTALL_LIBDIR=${INSTALL_LIBDIR} \
    -D CMAKE_INSTALL_LIBEXECDIR=${INSTALL_LIBEXECDIR} \
    -D CMAKE_INSTALL_SYSCONFDIR=${INSTALL_SYSCONFDIR} \
    -D CMAKE_INSTALL_LOCALSTATEDIR=${INSTALL_LOCALSTATEDIR} \
    -D CMAKE_INSTALL_RUNSTATEDIR=${INSTALL_RUNSTATEDIR} \
    -D CMAKE_INSTALL_DATAROOTDIR=${INSTALL_DATAROOTDIR} \
    -D CMAKE_INSTALL_DATADIR=${INSTALL_DATADIR} \
    -D CMAKE_INSTALL_DOCDIR=${INSTALL_DOCDIR} \
    -D CMAKE_INSTALL_LOGDIR=${INSTALL_LOGDIR} \
    -D CMAKE_INSTALL_CACHEDIR=${INSTALL_CACHEDIR} \
    -D ENABLE_WCCP=ON \
    -D ENABLE_MAXMIND_ACL=ON \
  && cmake --build ${BUILD_DIR} --verbose --parallel $jobs) \
  2>&1 | tee ${SRC_DIR}/trafficserver-build.log
RUN gzip --best ${SRC_DIR}/trafficserver-build.log

USER root
ARG DEST_DIR=${SRC_DIR}/trafficserver/dist
RUN DESTDIR=${DEST_DIR} cmake --install ${BUILD_DIR}
WORKDIR ${BUILD_DIR}
RUN mkdir -p debian
RUN touch debian/control
RUN dpkg-shlibdeps --ignore-missing-info -l${DEST_DIR}${INSTALL_PREFIX}/${INSTALL_LIBDIR} \
  ${DEST_DIR}${INSTALL_PREFIX}/${INSTALL_BINDIR}/traffic_server

ARG PKG_NAME=trafficserver
ARG PKG_DESCRIPTION="fast, scalable and extensible HTTP/1.1 and HTTP/2 compliant caching proxy server"
ARG PKG_VERSION
ARG PKG_RELEASE
ARG PKG_MAINTAINER
RUN DESTDIR=${DEST_DIR} cpack -G DEB \
  -D CPACK_PACKAGING_INSTALL_PREFIX=${INSTALL_PREFIX} \
  -D CPACK_DEBIAN_PACKAGE_DEPENDS="$(sed 's/^shlibs:Depends=//' debian/substvars)" \
  -D CPACK_DEBIAN_PACKAGE_NAME=${PKG_NAME} \
  -D CPACK_DEBIAN_PACKAGE_VERSION=${PKG_VERSION} \
  -D CPACK_DEBIAN_PACKAGE_RELEASE=${PKG_RELEASE} \
  -D CPACK_DEBIAN_FILE_NAME=${PKG_NAME}_${PKG_VERSION}-${PKG_RELEASE}.deb \
  -D CPACK_PACKAGE_DESCRIPTION="${PKG_DESCRIPTION}" \
  -D CPACK_PACKAGE_CONTACT="${PKG_MAINTAINER}"
