#!/bin/bash

set -xeuo pipefail

if [ -d result ]; then
    rm -r result
fi

mkdir -p result

id="$(
    xcrun simctl list devices available |
        awk '/Apple Watch Series 11 \(46mm\)/ {
            match($0, /\([0-9A-F-]{36}\)/)
            id = substr($0, RSTART + 1, RLENGTH - 2)
        } END { print id }'
)"

if [ -z "$id" ]; then
    echo "No available Apple Watch Series 11 (46mm) simulator found" >&2
    exit 1
fi

echo "Running on destination $id"

xcodebuild test \
    -scheme "Daylight Watch App" \
    -target "Daylight Watch AppTests" \
    -destination "platform=watchOS Simulator,id=$id" \
    -resultBundlePath result/test-results.xcresult \
    CODE_SIGNING_ALLOWED='NO'
