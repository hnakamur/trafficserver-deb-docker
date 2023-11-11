PKG_VERSION=10.0.0~20231112
PKG_REL_PREFIX=1hn1
PKG_MAINTAINER="Hiroaki Nakamura <hnakamur@gmail.com>"
ifdef USE_DOCKER_CACHE
DOCKER_NO_CACHE=
else
DOCKER_NO_CACHE=--no-cache
endif

# Ubuntu 22.04
deb-ubuntu2204: build-ubuntu2204
	docker run --rm -v ./dist:/dist ats-ubuntu2204 bash -c \
	"cp /src/trafficserver/build/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.deb /dist/"

run-ubuntu2204: build-ubuntu2204
	docker run --rm -it ats-ubuntu2204 bash

build-ubuntu2204:
	mkdir -p dist
	(set -x; BUILDKIT_PROGRESS=plain docker build ${DOCKER_NO_CACHE} \
	    --build-arg FROM=ubuntu:22.04 \
		--build-arg PKG_MAINTAINER=${PKG_MAINTAINER} \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg PKG_RELEASE=${PKG_REL_PREFIX}ubuntu22.04 \
		-t ats-ubuntu2204 . \
	) 2>&1 | tee dist/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04_build.log
	gzip --best --force dist/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04_build.log

# Debian 12
deb-debian12: build-debian12
	docker run --rm -v ./dist:/dist ats-debian12 bash -c \
	"cp /src/trafficserver/build/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}debian12.deb /dist/"

run-debian12: build-debian12
	docker run --rm -it ats-debian12 bash

build-debian12:
	mkdir -p dist
	(set -x; BUILDKIT_PROGRESS=plain docker build ${DOCKER_NO_CACHE} \
	    --build-arg FROM=debian:12 \
		--build-arg PKG_MAINTAINER=${PKG_MAINTAINER} \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg PKG_RELEASE=${PKG_REL_PREFIX}debian12 \
		-t ats-debian12 . \
	) 2>&1 | tee dist/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}debian12_build.log
	gzip --best --force dist/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}debian12_build.log

exec:
	docker exec -it $$(docker ps -q) bash

.PHONY: run-debian12 build-debian12 run-ubuntu2204 build-ubuntu2204 exec
