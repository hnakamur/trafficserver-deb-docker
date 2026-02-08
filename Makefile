PKG_VERSION=9.2.12
PKG_REL_PREFIX=1hn1
ifdef NO_CACHE
DOCKER_NO_CACHE=--no-cache
endif

LUAJIT_DEB_VERSION=2.1.20250117-1hn1
NLOHMANN_JSON_VERSION=3.11.3
PROTOBUF_VERSION=3.21.12
OTEL_CPP_VERSION=1.3.0

LOGUNLIMITED_BUILDER=logunlimited

# Ubuntu 24.04
deb-ubuntu2404: build-ubuntu2404
	docker run --rm -v ./trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04:/dist ats9-ubuntu2404 bash -c \
	"cp /src/trafficserver*${PKG_VERSION}* /dist/"
	sudo tar zcf trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04.tar.gz ./trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04/

build-ubuntu2404: buildkit-logunlimited
	sudo mkdir -p trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04
	(set -x; \
	git submodule foreach --recursive git remote -v; \
	git submodule status --recursive; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target build_trafficserver \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=24.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu24.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=ubuntu24.04 \
		--build-arg NLOHMANN_JSON_VERSION=${NLOHMANN_JSON_VERSION} \
		--build-arg PROTOBUF_VERSION=${PROTOBUF_VERSION} \
		--build-arg OTEL_CPP_VERSION=${OTEL_CPP_VERSION} \
		-t ats9-ubuntu2404 . \
	) 2>&1 | sudo tee trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04.build.log
	sudo xz --force trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04.build.log

run-ubuntu2404:
	docker run --rm -it ats9-ubuntu2404 bash

autest-ubuntu2404: buildkit-logunlimited
	(set -x; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target run_autest \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=24.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu24.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=ubuntu24.04 \
		-t ats9-ubuntu2404 . \
	) 2>&1 | sudo tee trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04.autest.log
	sudo xz --force trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04.autest.log

# Ubuntu 22.04
deb-ubuntu2204: build-ubuntu2204
	docker run --rm -v ./trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04:/dist ats9-ubuntu2204 bash -c \
	"cp /src/trafficserver*${PKG_VERSION}* /dist/"
	sudo tar zcf trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.tar.gz ./trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04/

clang-ubuntu2204: buildkit-logunlimited
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target setup_clang \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=22.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu22.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		-t ats9-ubuntu2204 .

build-ubuntu2204: buildkit-logunlimited
	sudo mkdir -p trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04
	(set -x; \
	git submodule foreach --recursive git remote -v; \
	git submodule status --recursive; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target build_trafficserver \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=22.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu22.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=ubuntu22.04 \
		--build-arg NLOHMANN_JSON_VERSION=${NLOHMANN_JSON_VERSION} \
		--build-arg PROTOBUF_VERSION=${PROTOBUF_VERSION} \
		--build-arg OTEL_CPP_VERSION=${OTEL_CPP_VERSION} \
		-t ats9-ubuntu2204 . \
	) 2>&1 | sudo tee trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.build.log
	sudo xz --force trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.build.log

run-ubuntu2204:
	docker run --rm -it ats9-ubuntu2204 bash

autest-ubuntu2204: buildkit-logunlimited
	(set -x; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target run_autest \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=22.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu22.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=ubuntu22.04 \
		-t ats9-ubuntu2204 . \
	) 2>&1 | sudo tee trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.autest.log
	sudo xz --force trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.autest.log

buildkit-logunlimited:
	if ! docker buildx inspect logunlimited 2>/dev/null; then \
		docker buildx create --bootstrap --name ${LOGUNLIMITED_BUILDER} \
			--driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=-1 \
			--driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=-1; \
	fi

exec:
	docker exec -it $$(docker ps -q) bash

.PHONY: deb-ubuntu2404 run-ubuntu2404 build-ubuntu2404 autest-ubuntu2404 deb-ubuntu2204 run-ubuntu2204 build-ubuntu2204 autest-ubuntu2204 buildkit-logunlimited exec
