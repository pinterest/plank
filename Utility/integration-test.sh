#!/bin/sh

# Generate Objective-C files
JSON_FILES=`ls -d Examples/PDK/*.json`

# Generate Objective-C models
.build/debug/plank  --output_dir=Examples/Cocoa/Sources/objc/ $JSON_FILES

# Generate flow types for models
.build/debug/plank --lang flow  --output_dir=Examples/JS/flow/ $JSON_FILES

ROOT_DIR="${PWD}"

# Verify flow types
if [ -x "$(command -v flow)" ]; then
  cd Examples/JS/flow
  flow
  cd "${ROOT_DIR}"
fi

# Move headers in the right place for the Swift PM
mv Examples/Cocoa/Sources/objc/*.h Examples/Cocoa/Sources/objc/include

# Build the ObjC library
cd Examples/Cocoa
swift build
swift test
cd "${ROOT_DIR}"
