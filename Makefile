# This makefile exposes targets that unify building, testing and archiving of
# Plank

.PHONY: all clean lint build test integration_test archive upload_pipeline build_test_index_linux archive_linux install

PREFIX := /usr/local

all: upload_pipeline clean build test integration_test archive

clean:
	xcrun swift package clean

lint:
	@echo "Lint disabled for now since swiftlint breaks the build by failing to detect variables referenced within string interpolation"
	#./Utility/lint.sh

build: lint
	xcrun swift build -v -Xswiftc -static-stdlib

test: build_test_index_linux build
	xcrun swift test

integration_test: build
	./Utility/integration-test.sh

archive:
	xcrun swift build -c release -Xswiftc -static-stdlib --disable-sandbox

upload_pipeline:
	.buildkite/upload_pipeline.sh

build_test_index_linux:
	swift Utility/GenerateTestCaseProvider.swift $(PWD)/Tests/CoreTests

archive_linux:
	swift build -c release --disable-sandbox


install: archive
	mkdir -p $(PREFIX)/bin
	cp .build/release/plank $(PREFIX)/bin/

