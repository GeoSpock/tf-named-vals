# MIT license
# Copyright (c) 2019 GeoSpock Ltd.

SHELL := $(shell command -v bash || echo /bin/bash)

PIPENV_CMD = pipenv

LDFLAGS ?= -ldflags "-X main.Version=$(shell cat VERSION)"

check_deps = @for cmd in $(1); do if ! command -v "$$cmd" &>/dev/null; then printf 'Command %s not found! Aborting.\n' "$$cmd"; exit 1; fi; done

.PHONY: all clean e2e-test bdist develop update-deps pipenv-cmd

all: tf-named-vals

pipenv-cmd:
	$(call check_deps,$(PIPENV_CMD))

clean:
	$(RM) -r build
	$(RM) -r dist
	$(RM) tf-named-vals

develop: | pipenv-cmd
	$(PIPENV_CMD) install --dev

update-deps: | pipenv-cmd
	$(PIPENV_CMD) update

tf-named-vals: $(wildcard *.go)
	go build $(LDFLAGS)

e2e-test: tf-named-vals
	./e2e/functional.sh

build/tf-named-vals-linux-amd64: $(wildcard *.go)
	GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o "$@"
	chmod +x "$@"

build/tf-named-vals-darwin-amd64: $(wildcard *.go)
	GOOS=darwin GOARCH=amd64 go build $(LDFLAGS) -o "$@"
	chmod +x "$@"

bdist: build/tf-named-vals-linux-amd64 build/tf-named-vals-darwin-amd64
	mkdir -p dist
	tar czf dist/tf-named-vals-linux-amd64.tar.gz -C build tf-named-vals-linux-amd64
	tar czf dist/tf-named-vals-darwin-amd64.tar.gz -C build tf-named-vals-darwin-amd64

.PHONY: publish publish-sdist publish-lambda

# Release
.PHONY: release-start release-finish

release-start: e2e-test | pipenv-cmd
	$(PIPENV_CMD) run lase --remote origin start $${RELEASE_VERSION:+--version "$${RELEASE_VERSION}"}

release-finish: e2e-test | pipenv-cmd
	$(PIPENV_CMD) run lase --remote origin finish
