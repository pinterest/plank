#!/bin/sh

# Generate Objective-C files
JSON_FILES=`ls -d Examples/PDK/*.json`

# Generate Objective-C models
.build/debug/plank  --output_dir=Examples/Cocoa/Objc/Sources/objc $JSON_FILES

# Generate flow types for models
.build/debug/plank --lang flow  --output_dir=Examples/JS/flow/ $JSON_FILES

# Generate Swift models
.build/debug/plank --lang swift  --output_dir=Examples/Cocoa/Swift/Sources/swifty $JSON_FILES

# Verify flow types
if [ -x "$(command -v flow)" ]; then
  pushd Examples/JS/flow
  flow
  popd
fi

# Move headers in the right place for the Swift PM
mv Examples/Cocoa/Objc/Sources/objc/*.h Examples/Cocoa/Objc/Sources/objc/include

# Build the Obj-c library
pushd Examples/Cocoa/Objc
swift build
swift test
popd

# Build the Swift library
pushd Examples/Cocoa/Swift
swift build
swift test
popd
