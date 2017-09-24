#!/bin/bash

# Only run pipeline uploads in buildkite environments
if [[ -e ${BUILDKITE} ]]; then
    buildkite-agent pipeline upload .buildkite/plank-pipeline.yml
fi

