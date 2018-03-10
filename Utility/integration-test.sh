#!/bin/sh

set -euo pipefail

PLANK_BIN=.build/debug/plank
# Generate Objective-C files
JSON_FILES=`ls -d Examples/PDK/*.json`

# Generate Objective-C models
$PLANK_BIN --output_dir=Examples/Cocoa/Sources/Objective_C/ $JSON_FILES

# Move headers in the right place for the Swift PM
mv Examples/Cocoa/Sources/Objective_C/*.h Examples/Cocoa/Sources/Objective_C/include

# Generate flow types for models
$PLANK_BIN --lang flow  --output_dir=Examples/JS/flow/ $JSON_FILES

# Generate flow types for models
$PLANK_BIN --lang java --java_package_name com.pinterest.models --output_dir=Examples/Java/Sources/ $JSON_FILES

ROOT_DIR="${PWD}"

# Build the ObjC library
cd Examples/Cocoa
xcrun swift package clean
xcrun swift build
xcrun swift test
cd "${ROOT_DIR}"

# Verify flow types
if [ -x "$(command -v flow)" ]; then
  echo "Verify flow types"
  cd Examples/JS/flow
  flow
  cd "${ROOT_DIR}"
fi
