#!/bin/bash

set -eou pipefail

update_current_line() {
    printf "\033[1A"  # move cursor one line up
    printf "\033[K"   # delete till end of line
    echo "$1"
}

log_err() {
  echo "❌ $1"
}

log_success() {
  update_current_line "✅ $1"
}

echo "Checking for lint errors with SwiftLint"
swift run swiftlint lint --reporter emoji

echo "Checking for formatting errors with SwiftFormat"
swift run swiftformat --lint .

echo "Checking if linux test index needs to be updated"
readonly TEMP_DIR=$(mktemp -d)
cp -R Tests "${TEMP_DIR}"
cp -R Utility "${TEMP_DIR}"
cp Makefile "${TEMP_DIR}"
(cd "${TEMP_DIR}" &&  make build_test_index_linux > /dev/null)
# Check if files changed, fail
if ! diff -r "${TEMP_DIR}/Tests" "Tests"; then
  log_err "Linux test index is out-of-date. Please update with 'make build_test_index_linux' and commit the changes"
  exit 1 
else 
  log_success "Linux test index is up-to-date!"
fi


