# Base image from Swiftenv with Swift version 3.0.1

FROM kylef/swiftenv
MAINTAINER Pinterest
RUN swiftenv install 3.0.1

# Vim config so we have an editor available
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        vim clang libicu-dev libcurl4-openssl-dev libssl-dev

# Install PINModel
COPY . /usr/local/pinmodel
RUN cd /usr/local/pinmodel && swift build -c release

ENV PINMODEL_HOME /usr/local/pinmodel
ENV PATH ${PINMODEL_HOME}/.build/release:${PATH}

ENTRYPOINT ["pinmodel"]
CMD ["help"]
