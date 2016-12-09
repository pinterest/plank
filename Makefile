# This makefile exposes targets that unify building, testing and archiving of
# PINModel

.PHONY: all clean build test archive

all: clean build test archive

clean:
	swift build --clean

build:
	swift build

test: build
	swift test

archive: clean
	swift build -Xswiftc -static-stdlib # static linking required for distribution

