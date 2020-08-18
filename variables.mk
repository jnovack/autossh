APPLICATION := $(shell basename `pwd`)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
BUILD_RFC3339 := $(shell date -u +"%Y-%m-%dT%H:%M:%S+00:00")
PACKAGE := $(shell git remote get-url --push origin | sed -E 's/.+[@|/].+[/|:](.+)\/(.+).git/\1\/\2/')
REVISION := $(shell git rev-parse HEAD)
VERSION := $(shell git describe --tags)
DESCRIPTION := $(shell curl -s https://api.github.com/repos/${PACKAGE} \
    | grep '"description".*' \
    | head -n 1 \
    | cut -d '"' -f 4)
WORKDIR := $(shell pwd)

DOCKER_BUILD_ARGS := \
	--build-arg APPLICATION=${APPLICATION} \
	--build-arg BUILD_RFC3339=${BUILD_RFC3339} \
	--build-arg DESCRIPTION="${DESCRIPTION}" \
	--build-arg PACKAGE=${PACKAGE} \
	--build-arg REVISION=${REVISION} \
	--build-arg VERSION=${VERSION} \
	--progress auto

.PHONY: docker update-hooks

# docker removes and rebuilds the docker container for local development
docker:
	docker rmi ${APPLICATION}:${BRANCH} || true
	docker build ${DOCKER_BUILD_ARGS} -t ${APPLICATION}:${BRANCH} .

# update-hooks downloads the newest version of any multi-arch hooks from the parent template repository
update-hooks:
	curl -Lo hooks/build https://github.com/jnovack/docker-multi-arch-hooks/raw/master/hooks/build
	curl -Lo hooks/post_checkout https://github.com/jnovack/docker-multi-arch-hooks/raw/master/hooks/post_checkout
	curl -Lo hooks/post_push https://github.com/jnovack/docker-multi-arch-hooks/raw/master/hooks/post_push
	curl -Lo variables.mk https://github.com/jnovack/docker-multi-arch-hooks/raw/master/variables.mk
