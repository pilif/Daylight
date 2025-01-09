#!/bin/bash

set -euo pipefail
id="$(xcodebuild test -showdestinations -scheme "Daylight Watch App" -target "Daylight Watch AppTests" | grep "watchOS Simulator" | grep "Apple Watch Series 10 (46mm)" | head -n 1 | grep -Eo 'id:.*?,' | sed  's/id://' | sed 's/,$//')"
xcodebuild test -scheme "Daylight Watch App" -target "Daylight Watch AppTests" -destination "platform=watchOS Simulator,id=$id" CODE_SIGNING_ALLOWED='NO'
