PKG_VERSION=10.0.0~20231111
PKG_REL_PREFIX=1hn1
PKG_MAINTAINER="Hiroaki Nakamura <hnakamur@gmail.com>"

# Ubuntu 22.04
deb-ubuntu2204: build-ubuntu2204
	docker run --rm -v ./dist:/dist ats-ubuntu2204 bash -c \
	"cp /src/trafficserver-build.log.gz /dist/trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04_build.log.gz; \
	cp /src/trafficserver/build/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.deb /dist/"

run-ubuntu2204: build-ubuntu2204
	docker run --rm -it ats-ubuntu2204 bash

build-ubuntu2204:
	docker build --build-arg FROM=ubuntu:22.04 --build-arg PKG_MAINTAINER=${PKG_MAINTAINER} \
		--build-arg PKG_VERSION=${PKG_VERSION} --build-arg PKG_RELEASE=${PKG_REL_PREFIX}ubuntu22.04 \
		-t ats-ubuntu2204 .

# Debian 12
deb-debian12: build-debian12
	docker run --rm -v ./dist:/dist ats-debian12 bash -c \
	"cp /src/trafficserver-build.log.gz /dist/trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}debian12_build.log.gz; \
	cp /src/trafficserver/build/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}debian12.deb /dist/"

run-debian12: build-debian12
	docker run --rm -it ats-debian12 bash

build-debian12:
	docker build --build-arg FROM=debian:12 --build-arg PKG_MAINTAINER=${PKG_MAINTAINER} \
		--build-arg PKG_VERSION=${PKG_VERSION} --build-arg PKG_RELEASE=${PKG_REL_PREFIX}debian12 \
		-t ats-debian12 .

exec:
	docker exec -it $$(docker ps -q) bash

.PHONY: run-debian12 build-debian12 run-ubuntu2204 build-ubuntu2204 exec
