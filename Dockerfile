# Base image from Swiftenv with Swift version 3.0.2

FROM swiftdocker/swift
MAINTAINER Pinterest

# Vim config so we have an editor available
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        vim clang libicu-dev libcurl4-openssl-dev libssl-dev

# Install plank
COPY . /usr/local/plank
RUN cd /usr/local/plank && swift build -c release

ENV plank_HOME /usr/local/plank
ENV PATH ${plank_HOME}/.build/release:${PATH}

# Uncomment to make `plank` the default action of `docker run [image_name]`
#ENTRYPOINT ["plank"]
#CMD ["help"]
