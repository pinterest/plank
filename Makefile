# This makefile exposes targets that unify building, testing and archiving of
# PINModel


.PHONY: all clean build test archive

all: clean build test archive

clean:
	xcrun swift build --clean

lint:
	./Utility/lint.sh

build: lint
	xcrun swift build -v -Xswiftc -static-stdlib

test: build_test_index_linux build
	xcrun swift test

archive:
	xcrun swift build -c release -Xswiftc -static-stdlib

build_test_index_linux:
	swift Utility/GenerateTestCaseProvider.swift $(PWD)/Tests/CoreTests

archive_linux:
	swift build -c release
