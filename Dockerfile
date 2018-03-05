# Base image from SwiftDocker
# https://hub.docker.com/r/swiftdocker/swift/
FROM library/swift
MAINTAINER Pinterest

ENV plank_HOME /usr/local/plank
ENV PATH ${plank_HOME}/.build/release:${PATH}

# Copy plank sources
WORKDIR /plank

