SHELL := bash
.ONESHELL:
#.SILENT:
.SHELLFLAGS := -eu -o pipefail -c
#.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
.DEFAULT_GOAL := help

ifeq ($(origin .RECIPEPREFIX), undefined)
  $(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif
.RECIPEPREFIX = >

# Defaults
SSH_PUBLIC_KEY_FILE ?= "${HOME}/.ssh/id_rsa.pub"
SSH_PRIVATE_KEY_FILE ?= "${HOME}/.ssh/id_rsa"
IF0_ENVIRONMENT ?= zero
ENVIRONMENT_DIR ?= ${HOME}/.if0/.environments/zero
DOCKER_SHELLFLAGS ?= run --rm -it -e IF0_ENVIRONMENT=${IF0_ENVIRONMENT} --name lake0-${IF0_ENVIRONMENT} -v ${PWD}:/data -v ${PWD}:/lake0 -v ${HOME}/.if0/.environments/${IF0_ENVIRONMENT}:/root/.if0/.environments/zero -v ${HOME}/.gitconfig:/root/.gitconfig lake0
export DOCKER_BUILDKIT=1
VERBOSITY ?= 0

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: load
load: /tmp/.loaded.sentinel

/tmp/.loaded.sentinel: $(shell find ${ENVIRONMENT_DIR} -type f -name '*.env') ## help
> @if [ ! -z $$IF0_ENVIRONMENT ]; then echo "Loading Environment ${IF0_ENVIRONMENT}"; fi
> @touch /tmp/.loaded.sentinel

# Development
.PHONY: build
build:
> @docker build -t lake0 .

.PHONY: dev
dev: .SHELLFLAGS = ${DOCKER_SHELLFLAGS}
dev: SHELL := docker
dev:
> @ash

.PHONY: ssh
ssh: ${ENVIRONMENT_DIR}/.ssh/id_rsa ${ENVIRONMENT_DIR}/.ssh/id_rsa.pub

${ENVIRONMENT_DIR}/.ssh/:
> @mkdir ${ENVIRONMENT_DIR}/.ssh/

${ENVIRONMENT_DIR}/.ssh/id_rsa ${ENVIRONMENT_DIR}/.ssh/id_rsa.pub: ${ENVIRONMENT_DIR}/.ssh/
> @ssh-keygen -b 4096 -t rsa -q -N "" -f ${ENVIRONMENT_DIR}/.ssh/id_rsa 