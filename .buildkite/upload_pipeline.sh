#!/bin/bash

# Only run pipeline uploads in buildkite environments
if [[ -e ${BUILDKITE_BUILD_NUMBER} ]];
    buildkite-agent pipeline upload .buildkite/plank-pipeline.yml
fi

