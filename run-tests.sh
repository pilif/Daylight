#!/bin/bash

set -xeuo pipefail

if [ -d result ]; then
    rm -r result
fi

mkdir -p result

xcodebuild test -showdestinations -scheme "Daylight Watch App" -target "Daylight Watch AppTests"

id="$(xcodebuild test -showdestinations -scheme "Daylight Watch App" -target "Daylight Watch AppTests" | grep "watchOS Simulator" | grep "Apple Watch Series 11 (46mm)" | head -n 1 | grep -Eo 'id:.*?,' | sed  's/id://' | sed 's/,$//')"
echo "Running on destination $id"

xcodebuild test \
    -scheme "Daylight Watch App" \
    -target "Daylight Watch AppTests" \
    -destination id="$id" \
    -resultBundlePath result/test-results.xcresult \
    CODE_SIGNING_ALLOWED='NO'
