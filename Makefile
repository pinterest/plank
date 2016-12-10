# This makefile exposes targets that unify building, testing and archiving of
# PINModel

.PHONY: all clean build test archive

all: clean build test archive

clean:
	swift build --clean

build:
	swift build

build_test_index_linux:
	swift Utility/GenerateTestCaseProvider.swift $(PWD)/Tests/CoreTests

test: build_test_index_linux build
	swift test

archive: clean
	swift build -c release -Xswiftc -static-stdlib

archive_linux: clean
	swift build -c release
