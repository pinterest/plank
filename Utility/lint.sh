#!/bin/sh

if which swiftlint >/dev/null; then
    LINT_ERRS=`swiftlint lint --reporter emoji --quiet`
    if [[ $LINT_ERRS != "" ]]; then
        echo "Error: Fix lint errors from swiftlint"
        echo $LINT_ERRS
        exit 1
    else
        echo "SwiftLint finished: No errors or warnings found."
    fi
else
    echo "Warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
    exit 1
fi
