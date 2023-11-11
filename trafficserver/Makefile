run-deb12: build-deb12
	docker run --rm -it ats-deb12 bash

build-deb12:
	docker build --build-arg FROM=debian:12 -t ats-deb12 .

run-ubuntu2204: build-ubuntu2204
	docker run --rm -it ats-ubuntu2204 bash

build-ubuntu2204:
	docker build --build-arg FROM=ubuntu:22.04 -t ats-ubuntu2204 .

exec:
	docker exec -it $$(docker ps -q) bash

.PHONY: run-deb12 build-deb12 run-ubuntu2204 build-ubuntu2204 exec
