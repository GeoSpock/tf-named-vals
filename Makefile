# MIT license
# Copyright (c) 2019 GeoSpock Ltd.

.PHONY: all clean e2e-test bdist

all: tf-named-vals

clean:
	$(RM) -r build
	$(RM) -r dist
	$(RM) tf-named-vals

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
