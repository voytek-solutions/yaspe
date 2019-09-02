include .config.mk

FUNCTION ?= 'not-set'
PROFILE ?= 'default'
VENV ?= .venv

PATH := $(PWD)/$(VENV)/bin:$(PWD)/bin:$(shell printenv PATH)
SHELL := env PATH='$(PATH)' /bin/bash

ifeq ($(FUNCTION), all)
	FUNCTION = $(shell ls -1 src)
endif

## Prints this help
help:
	@awk -v skip=1 \
		'/^##/ { sub(/^[#[:blank:]]*/, "", $$0); doc_h=$$0; doc=""; skip=0; next } \
			skip  { next } \
			/^#/  { doc=doc "\n" substr($$0, 2); next } \
			/:/   { sub(/:.*/, "", $$0); printf "\033[34m%-30s\033[0m\033[1m%s\033[0m %s\n\n", $$0, doc_h, doc; skip=1 }' \
		$(MAKEFILE_LIST)

## Validate local installation and setup
validate: docker $(VENV)
	@echo " :: AWS CLI Version"
	@aws --version
	@echo " :: AWS SAM CLI Version"
	@sam --version
	@echo " :: Docker Version"
	@docker --version
	@echo " :: AWS CLI Profile: $(PROFILE)"

ifeq ($(FUNCTION), all)
test:
	@for f in `ls src`; do $(MAKE) test_function FUNCTION="$$f"; done;
else
## Run tests
# Usage:
#           make test FUNCTION=all
#           make test FUNCTION=hello_world
test:
	$(MAKE) test_function
endif

test_function: src/$(FUNCTION)/.venv
	@echo " :: TESTING $(FUNCTION)"
	@echo " :: Running black"
	cd src/$(FUNCTION) && .venv/bin/black --check --diff .
	@echo " :: Running Unit tests"
	cd src/$(FUNCTION) && echo "no unit tests"
	@echo " :: Running BDD tests"
	cd src/$(FUNCTION) && echo "no BDD"

## Installs a virtual environment and all python dependencies
$(VENV):
	rm -rf $(VENV)
	python3 -m venv .venv
	.venv/bin/pip3 install -r ./.requirements.txt

src/$(FUNCTION)/.venv:
	rm -rf src/$(FUNCTION)/.venv
	python3 -m venv src/$(FUNCTION)/.venv
	src/$(FUNCTION)/.venv/bin/pip3 install -r ./src/$(FUNCTION)/requirements.txt
	src/$(FUNCTION)/.venv/bin/pip3 install -r ./src/$(FUNCTION)/requirements-dev.txt

docker:
	@which docker > /dev/null || (\
		echo "please install docker: https://www.docker.com/products/docker-desktop" \
		&& exit 1 \
	)

.config.mk:
	touch .config.mk
