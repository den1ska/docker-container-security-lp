-include .env

IMAGE_NAME = lp/hugo-builder
PORT ?= 1313
IP ?= 127.0.0.1
BASEURL ?= http://localhost
CLAIRSCANNER ?= $(shell which clair-scanner)

default: build

builder: Dockerfile lint
	@echo "Building Hugo Builder container..."
	@docker build -t lp/hugo-builder .
	@echo "Hugo Builder container built!"
	@docker images $(IMAGE_NAME)

build: builder
	@echo "Building OrgDocs website..."
	@docker run --rm -d --name orgdocs-builder -v$(shell pwd)/orgdocs:/src $(IMAGE_NAME) hugo --minify
	@echo "OrgDocs website successfully built"

start: build stop
	@echo "Starting OrgDocs website..."
	@docker run --rm -d --name orgdocs \
    -v$(shell pwd)/orgdocs:/src \
    -p $(IP):$(PORT):1313 $(IMAGE_NAME) hugo server --minify --bind=0.0.0.0 --baseURL=$(BASEURL)
	@echo "OrgDocs website started"

stop:
ifeq ($(shell docker container inspect -f '{{.State.Status}}' orgdocs 2>/dev/null), running)
	@echo "Stopping OrgDocs website..."
	@docker stop orgdocs
	@echo "OrgDocs website stopped"
endif


lint:
	@echo "Run Static Analysis..."
	@docker run --rm -i -v$(shell pwd)/hadolint.yaml:/.hadolint.yaml hadolint/hadolint hadolint - < Dockerfile
	@docker run --rm -i -v$(shell pwd):/root projectatomic/dockerfile-lint dockerfile_lint -r policies/all_rules.yml
	@echo "No issues found"

security-scan:
ifneq ($(CLAIRSCANNER),)
	@echo "Run Security Scanning..."
	@$(CLAIRSCANNER) --ip $(IP) $(IMAGE_NAME)
else
	$(error CLAIRSCANNER is not found)
endif

.PHONY: builder build lint stop start security-scan

