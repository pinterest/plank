# This makefile exposes targets that unify building, testing and archiving of
# PINModel

SWIFT_LINT_EXEC=`which swiftlint`

.PHONY: all clean build test archive

all: clean build test archive

clean:
	swift build --clean

lint:
	$(SWIFT_LINT_EXEC) lint --reporter emoji

build: lint
	swift build

build_test_index_linux:
	swift Utility/GenerateTestCaseProvider.swift $(PWD)/Tests/CoreTests

test: build_test_index_linux build
	swift test

archive: lint
	swift build -c release -Xswiftc -static-stdlib

archive_linux: clean
	swift build -c release
