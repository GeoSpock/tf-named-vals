# MIT license
# Copyright (c) 2019 GeoSpock Ltd.

.PHONY: all clean

all: tf-named-vals

clean:
	$(RM) tf-named-vals

version.go: VERSION version.go.in Makefile
	sed 's/%VERSION%/$(shell cat VERSION)/' version.go.in > version.go

tf-named-vals: version.go $(wildcard *.go)
	go build


