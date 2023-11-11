ARG FROM=ubuntu:22.04
FROM ${FROM}

RUN apt-get update \
 && apt-get -y install g++ cmake make pkg-config libpcre3-dev libssl-dev zlib1g-dev git

ARG SRC_DIR=/src
ARG BUILD_USER=build
RUN useradd -m -d ${SRC_DIR} ${BUILD_USER}

USER ${BUILD_USER}
WORKDIR ${SRC_DIR}
ARG REPO_URL=https://github.com/apache/trafficserver
RUN git clone --depth 1 ${REPO_URL}
WORKDIR ${SRC_DIR}/trafficserver
ARG BUILD_DIR=build
ARG MAX_JOBS=24
RUN n=$(nproc); jobs=$(( $n > $MAX_JOBS ? $MAX_JOBS : $n )); (cmake -B ${BUILD_DIR} && cmake --build ${BUILD_DIR} --verbose --parallel $jobs) 2>&1 | tee ${SRC_DIR}/trafficserver-build.log

USER root
RUN cmake --install ${BUILD_DIR}
