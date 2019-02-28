#!/bin/bash

set -eou pipefail

echo "Checking for lint errors with SwiftLint"
swift run swiftlint lint --reporter emoji

echo "Checking for formatting errors with SwiftFormat"
swift run swiftformat --lint .
