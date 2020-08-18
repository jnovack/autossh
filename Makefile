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

.PHONY: build all
.DEFAULT_GOAL := all

all: build

test:
	echo $(PACKAGE)

build:
	docker rmi ${APPLICATION}:${BRANCH} || true
	docker build ${DOCKER_BUILD_ARGS} -t ${APPLICATION}:${BRANCH} .

# hooks copies in the newest version of any multi-arch hooks from a different repository
hooks:
	curl -Lo hooks/build https://github.com/jnovack/docker-multi-arch-hooks/raw/master/hooks/build
	curl -Lo hooks/post_checkout https://github.com/jnovack/docker-multi-arch-hooks/raw/master/hooks/post_checkout
	curl -Lo hooks/post_push https://github.com/jnovack/docker-multi-arch-hooks/raw/master/hooks/post_push
