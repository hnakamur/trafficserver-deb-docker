PKG_VERSION=10.0.0~20231214
PKG_REL_PREFIX=1hn1
ifdef NO_CACHE
DOCKER_NO_CACHE=--no-cache
endif

LOGUNLIMITED_BUILDER=logunlimited

# Ubuntu 22.04
deb-ubuntu2204: build-ubuntu2204
	docker run --rm -v ./dist-ubuntu2204:/dist ats-ubuntu2204 bash -c \
	"cp /src/trafficserver*${PKG_VERSION}* /dist/"

clang-ubuntu2204: buildkit-logunlimited
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target setup_clang \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=22.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu22.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		-t ats-ubuntu2204 .

build-ubuntu2204: buildkit-logunlimited
	mkdir -p dist-ubuntu2204
	(set -x; \
	git submodule foreach --recursive git remote -v; \
	git submodule status --recursive; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target build_trafficserver \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=22.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu22.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		-t ats-ubuntu2204 . \
	) 2>&1 | tee dist-ubuntu2204/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.build.log
	xz --best --force dist-ubuntu2204/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.build.log

run-ubuntu2204:
	docker run --rm -it ats-ubuntu2204 bash

autest-ubuntu2204: buildkit-logunlimited
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target run_autest \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=22.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu22.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		-t ats-ubuntu2204 .
	docker run --rm -it ats-ubuntu2204 bash

# Debian 12
deb-debian12: build-debian12
	docker run --rm -v ./dist-debian12:/dist ats-debian12 bash -c \
	"cp /src/trafficserver*${PKG_VERSION}* /dist/"

build-debian12: buildkit-logunlimited
	mkdir -p dist-debian12
	(set -x; \
	git submodule foreach --recursive git remote -v; \
	git submodule status --recursive; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target build_trafficserver \
		--build-arg OS_TYPE=debian --build-arg OS_VERSION=12 \
		--build-arg PKG_REL_DISTRIB=debian12 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		-t ats-debian12 . \
	) 2>&1 | tee dist-debian12/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}debian12.build.log
	xz --best --force dist-debian12/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}debian12.build.log

run-debian12:
	docker run --rm -it ats-debian12 bash

autest-debian12: buildkit-logunlimited
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target run_autest \
		--build-arg OS_TYPE=debian --build-arg OS_VERSION=12 \
		--build-arg PKG_REL_DISTRIB=debian12 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		-t ats-debian12 .
	docker run --rm -it ats-debian12 bash

buildkit-logunlimited:
	if ! docker buildx inspect logunlimited 2>/dev/null; then \
		docker buildx create --bootstrap --name ${LOGUNLIMITED_BUILDER} \
			--driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=-1 \
			--driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=-1; \
	fi

exec:
	docker exec -it $$(docker ps -q) bash

.PHONY: deb-debian12 run-debian12 build-debian12 deb-ubuntu2204 run-ubuntu2204 build-ubuntu2204 buildkit-logunlimited exec
