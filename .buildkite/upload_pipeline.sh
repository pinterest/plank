#!/bin/bash

# Only run pipeline uploads in buildkite environments
if [[ ! -z ${BUILDKITE} ]]; then
    buildkite-agent pipeline upload .buildkite/plank-pipeline.yml
fi

