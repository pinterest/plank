#!/bin/bash

set -eo pipefail

PLANK_BIN=.build/debug/plank
# Generate Objective-C files
JSON_FILES=$(ls -d Examples/PDK/*.json)

# Generate Objective-C models
$PLANK_BIN --output_dir=Examples/Cocoa/Sources/Objective_C/ $JSON_FILES

# Move headers in the right place for the Swift PM
mv Examples/Cocoa/Sources/Objective_C/*.h Examples/Cocoa/Sources/Objective_C/include

# Generate flow types for models
$PLANK_BIN --lang flow  --output_dir=Examples/JS/flow/ $JSON_FILES

# Generate flow types for models
$PLANK_BIN --lang java --java_package_name com.pinterest.models --java_nullability_annotation_type androidx --output_dir=Examples/Java/Sources/ $JSON_FILES

ROOT_DIR="${PWD}"

# Build the ObjC library (macOS only)
if [[ $OSTYPE == darwin* ]]; then
  cd Examples/Cocoa
  swift package clean
  swift build
  swift test
  cd "${ROOT_DIR}"
fi

# Verify flow types
if [ -x "$(command -v flow)" ]; then
  echo "Verify flow types"
  cd Examples/JS/flow
  flow
  cd "${ROOT_DIR}"
fi

if [ -n "${ANDROID_HOME}" ]; then
  python tools/bazel build //Examples/Java:example --verbose_failures
fi
