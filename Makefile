-include .env

PORT ?= 1313
IP ?= 127.0.0.1
BASEURL ?= http://localhost

default: build

builder: Dockerfile lint
	@echo "Building Hugo Builder container..."
	@docker build -t lp/hugo-builder .
	@echo "Hugo Builder container built!"
	@docker images lp/hugo-builder

build: builder
	@echo "Building OrgDocs website..."
	@docker run --rm -d --name orgdocs-builder -v$(shell pwd)/orgdocs:/src lp/hugo-builder hugo
	@echo "OrgDocs website successfully built"

start: build stop
	@echo "Starting OrgDocs website..."
	@docker run --rm -d --name orgdocs -v$(shell pwd)/orgdocs:/src -p $(IP):$(PORT):1313 lp/hugo-builder hugo server -w --bind=0.0.0.0 --baseURL=$(BASEURL)
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
	@echo "No issues found"

.PHONY: builder build lint stop start

