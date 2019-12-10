# MIT license
# Copyright (c) 2019 GeoSpock Ltd.

PIPENV_CMD = pipenv

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

version.go: VERSION version.go.in
	sed 's/%VERSION%/$(shell cat VERSION)/' version.go.in > version.go

tf-named-vals: version.go $(wildcard *.go)
	go build

e2e-test: tf-named-vals
	./e2e/functional.sh

build/tf-named-vals-linux-amd64: version.go $(wildcard *.go)
	GOOS=linux GOARCH=amd64 go build -o "$@"
	chmod +x "$@"

build/tf-named-vals-darwin-amd64: version.go $(wildcard *.go)
	GOOS=darwin GOARCH=amd64 go build -o "$@"
	chmod +x "$@"

bdist: build/tf-named-vals-linux-amd64 build/tf-named-vals-darwin-amd64
	mkdir -p dist
	tar czf dist/tf-named-vals-linux-amd64.tar.gz build/tf-named-vals-linux-amd64
	tar czf dist/tf-named-vals-darwin-amd64.tar.gz build/tf-named-vals-darwin-amd64

.PHONY: publish publish-sdist publish-lambda

# Release
.PHONY: release-start release-finish

release-start: e2e-test | pipenv-cmd
	$(PIPENV_CMD) run lase --remote origin start $${RELEASE_VERSION:+--version "$${RELEASE_VERSION}"}

release-finish: e2e-test | pipenv-cmd
	$(PIPENV_CMD) run lase --remote origin finish
