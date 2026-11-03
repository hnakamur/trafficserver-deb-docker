PKG_VERSION=10.2.1
GIT_TAG=10.2.1
PKG_REL_PREFIX=1hn1
ifdef NO_CACHE
DOCKER_NO_CACHE=--no-cache
endif

LUAJIT_DEB_VERSION=2.1.20261021-1hn1

LOGUNLIMITED_BUILDER=logunlimited

# Debian 13
deb-debian13: build-debian13
	docker run --rm -v ./trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}debian13:/dist ats10-debian13 bash -c \
	"cp /src/trafficserver*${PKG_VERSION}* /dist/"
	tar zcf trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}debian13.tar.gz ./trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}debian13/

build-debian13: buildkit-logunlimited
	mkdir -p trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}debian13
	(set -x; \
	git submodule foreach --recursive git remote -v; \
	git submodule status --recursive; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target build_trafficserver \
		--build-arg OS_TYPE=debian --build-arg OS_VERSION=13 \
		--build-arg PKG_REL_DISTRIB=debian13 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg GIT_TAG=${GIT_TAG} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=debian13 \
		--build-arg LLVM_MAJOR_VERSION=22 \
		-t ats10-debian13 . \
	) 2>&1 | tee trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}debian13/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}debian13.build.log
	xz --force trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}debian13/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}debian13.build.log

run-debian13:
	docker run --rm -it ats10-debian13 bash

autest-debian13: buildkit-logunlimited
	(set -x; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target run_autest \
		--build-arg OS_TYPE=debian --build-arg OS_VERSION=13 \
		--build-arg PKG_REL_DISTRIB=debian13 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg GIT_TAG=${GIT_TAG} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=debian13 \
		-t ats10-debian13 . \
	) 2>&1 | tee trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}debian13/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}debian13.autest.log
	xz --force trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}debian13/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}debian13.autest.log

# Ubuntu 26.04
deb-ubuntu2604: build-ubuntu2604
	docker run --rm -v ./trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu26.04:/dist ats10-ubuntu2604 bash -c \
	"cp /src/trafficserver*${PKG_VERSION}* /dist/"
	tar zcf trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu26.04.tar.gz ./trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu26.04/

build-ubuntu2604: buildkit-logunlimited
	mkdir -p trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu26.04
	(set -x; \
	git submodule foreach --recursive git remote -v; \
	git submodule status --recursive; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target build_trafficserver \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=26.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu26.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg GIT_TAG=${GIT_TAG} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=ubuntu26.04 \
		--build-arg LLVM_MAJOR_VERSION=22 \
		-t ats10-ubuntu2604 . \
	) 2>&1 | tee trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu26.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu26.04.build.log
	xz --force trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu26.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu26.04.build.log

run-ubuntu2604:
	docker run --rm -it ats10-ubuntu2604 bash

autest-ubuntu2604: buildkit-logunlimited
	(set -x; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target run_autest \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=26.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu26.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg GIT_TAG=${GIT_TAG} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=ubuntu26.04 \
		-t ats10-ubuntu2604 . \
	) 2>&1 | tee trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu26.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu26.04.autest.log
	xz --force trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu26.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu26.04.autest.log

# Ubuntu 24.04
deb-ubuntu2404: build-ubuntu2404
	docker run --rm -v ./trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04:/dist ats10-ubuntu2404 bash -c \
	"cp /src/trafficserver*${PKG_VERSION}* /dist/"
	tar zcf trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04.tar.gz ./trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04/

build-ubuntu2404: buildkit-logunlimited
	mkdir -p trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04
	(set -x; \
	git submodule foreach --recursive git remote -v; \
	git submodule status --recursive; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target build_trafficserver \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=24.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu24.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg GIT_TAG=${GIT_TAG} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=ubuntu24.04 \
		-t ats10-ubuntu2404 . \
	) 2>&1 | tee trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04.build.log
	xz --force trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04.build.log

run-ubuntu2404:
	docker run --rm -it ats10-ubuntu2404 bash

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
		-t ats10-ubuntu2404 . \
	) 2>&1 | tee trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04.autest.log
	xz --force trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu24.04.autest.log

# Ubuntu 22.04
deb-ubuntu2204: build-ubuntu2204
	docker run --rm -v ./trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04:/dist ats10-ubuntu2204 bash -c \
	"cp /src/trafficserver*${PKG_VERSION}* /dist/"
	tar zcf trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.tar.gz ./trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04/

build-ubuntu2204: buildkit-logunlimited
	mkdir -p trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04
	(set -x; \
	git submodule foreach --recursive git remote -v; \
	git submodule status --recursive; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--target build_trafficserver \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=22.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu22.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg GIT_TAG=${GIT_TAG} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=ubuntu22.04 \
		-t ats10-ubuntu2204 -f Dockerfile . \
	) 2>&1 | tee trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.build.log
	xz --force trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.build.log

run-ubuntu2204:
	docker run --rm -it ats10-ubuntu2204 bash

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
		-t ats10-ubuntu2204 -f Dockerfile . \
	) 2>&1 | tee trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.autest.log
	xz --force trafficserver-${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04/trafficserver_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.autest.log

buildkit-logunlimited:
	if ! docker buildx inspect logunlimited 2>/dev/null; then \
		docker buildx create --bootstrap --name ${LOGUNLIMITED_BUILDER} \
			--driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=-1 \
			--driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=-1; \
	fi

exec:
	docker exec -it $$(docker ps -q) bash

.PHONY: deb-ubuntu2604 run-ubuntu2604 build-ubuntu2604 autest-ubuntu2604 deb-ubuntu2404 run-ubuntu2404 build-ubuntu2404 autest-ubuntu2404 deb-ubuntu2204 run-ubuntu2204 build-ubuntu2204 autest-ubuntu2204 buildkit-logunlimited exec
