# This makefile exposes targets that unify building, testing and archiving of
# PINModel


.PHONY: all clean build test archive

all: clean build test archive

clean:
	swift build --clean

lint:
	./Utility/lint.sh

build: lint
	swift build -v -Xswiftc -static-stdlib


build_test_index_linux:
	swift Utility/GenerateTestCaseProvider.swift $(PWD)/Tests/CoreTests

test: build_test_index_linux build
	swift test

archive: lint
	swift build -v -c release -Xswiftc -static-stdlib

archive_linux: clean
	swift build -c release
