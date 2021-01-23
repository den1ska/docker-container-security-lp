-include .env

NS ?= lp
IMAGE_NAME ?= hugo-builder
VERSION ?= 1.0
REVISION = $(shell git rev-parse HEAD)
CREATED_AT =$(shell date --utc --iso-8601=seconds)
PORT ?= 1313
IP ?= 127.0.0.1
BASEURL ?= http://localhost
CLAIRSCANNER ?= $(shell which clair-scanner)
SIGNER_PASSPHRASE ?=
DOCKER_CONTENT_TRUST ?= 0

ifndef SIGNER_PASSPHRASE
$(error SIGNER_PASSPHRASE is not defined)
endif

default: build

builder: Dockerfile lint
	@echo "Building Hugo Builder container..."
	@docker build -t $(NS)/$(IMAGE_NAME):$(VERSION) . --build-arg VERSION=$(VERSION) --build-arg CREATED_AT=$(CREATED_AT) --build-arg REVISION=$(REVISION)
	@echo "Hugo Builder container built!"
	@docker images $(NS):$(IMAGE_NAME)

build: builder
	@echo "Building OrgDocs website..."
	@docker run --rm -d --name orgdocs-builder -v$(shell pwd)/orgdocs:/src $(NS)/$(IMAGE_NAME):$(VERSION) hugo --minify
	@echo "OrgDocs website successfully built"

start: build stop
	@echo "Starting OrgDocs website..."
	@docker run --rm -d --name orgdocs \
    -v$(shell pwd)/orgdocs:/src \
    -p $(IP):$(PORT):1313 $(NS)/$(IMAGE_NAME):$(VERSION) hugo server --minify --bind=0.0.0.0 --baseURL=$(BASEURL)
	@echo "OrgDocs website started"

stop:
ifeq ($(shell docker container inspect -f '{{.State.Status}}' orgdocs 2>/dev/null), running)
	@echo "Stopping OrgDocs website..."
	@docker stop orgdocs
	@echo "OrgDocs website stopped"
endif


lint:
	@echo "Run Static Analysis..."
	@DOCKER_CONTENT_TRUST=0 docker run --rm -i -v$(shell pwd)/hadolint.yaml:/.hadolint.yaml hadolint/hadolint hadolint - < Dockerfile
	@DOCKER_CONTENT_TRUST=0 docker run --rm -i -v$(shell pwd):/root projectatomic/dockerfile-lint dockerfile_lint -r policies/all_rules.yml
	@echo "No issues found"

security-scan:
ifneq ($(CLAIRSCANNER),)
	@echo "Run Security Scanning..."
	@$(CLAIRSCANNER) --ip $(IP) $(NS)/$(IMAGE_NAME):$(VERSION)
else
	$(error CLAIRSCANNER is not found)
endif

sign:
	@echo "Signing the image..."
	@DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE="$(SIGNER_PASSPHRASE)" docker trust sign $(NS)/$(IMAGE_NAME):$(VERSION)

inspect-labels:
	@echo "Inspecting labels..."
	@docker inspect --format '{{range $$k, $$v := .Config.Labels}}{{$$k}} = {{$$v}}{{printf "\n"}}{{end}}' $(NS)/$(IMAGE_NAME):$(VERSION)

inspect-keys:
	@echo "Inspecting keys..."
	@docker trust inspect --pretty $(NS)/$(IMAGE_NAME)

bom:
	@echo Generating Bill of Materials...
	@docker run --privileged --rm --device /dev/fuse -v /var/run/docker.sock:/var/run/docker.sock ternd report -f spdxtagvalue -i $(NS)/$(IMAGE_NAME):$(VERSION) > $(IMAGE_NAME).bom

.PHONY: builder build lint stop start security-scan sign inspect-labels inspect-keys

