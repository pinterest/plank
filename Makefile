# This makefile exposes targets that unify building, testing and archiving of
# Plank

.PHONY: all clean lint build test integration_test archive upload_pipeline build_test_index_linux archive_linux install output_stability_test ci_tests

PREFIX := /usr/local

all: upload_pipeline clean build test integration_test archive

clean:
	swift package clean

lint:
	./Utility/lint.sh

format:
	swift run swiftformat .

build: 
	swift build -v

test: build
	swift test

integration_test: build
	./Utility/integration-test.sh

output_stability_test: build
	./Utility/stable-output-test.sh

ci_tests: test integration_test output_stability_test

archive:
	swift build -c release -Xswiftc -static-stdlib --disable-sandbox

upload_pipeline:
	.buildkite/upload_pipeline.sh

build_test_index_linux:
	swift Utility/GenerateTestCaseProvider.swift $(PWD)/Tests/CoreTests

archive_linux:
	swift build -c release --disable-sandbox

install: archive
	mkdir -p $(PREFIX)/bin
	cp .build/release/plank $(PREFIX)/bin/

