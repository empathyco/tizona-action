#!/bin/bash

REVIEWDOG_GIT_TOKEN=$1

set -e

export REVIEWDOG_GITHUB_API_TOKEN="${REVIEWDOG_GIT_TOKEN}"

echo "Secrets leaks discovery"

FILE_REPORT=report-secrets.json

echo "Running gitleaks"
/gitleaks detect -f sarif --exit-code 0 -r $FILE_REPORT

echo "Formatting findings"
jq '.runs[0].results[] | "\(.locations[0].physicalLocation.artifactLocation.uri):\(.locations[0].physicalLocation.region.endLine):\(.locations[0].physicalLocation.region.startColumn): \(.message.text)"' < $FILE_REPORT | sed 's/"//g'

echo "Runnning reviredog"
jq '.runs[0].results[] | "\(.locations[0].physicalLocation.artifactLocation.uri):\(.locations[0].physicalLocation.region.endLine):\(.locations[0].physicalLocation.region.startColumn): \(.message.text)"' < $FILE_REPORT | sed 's/"//g' |  reviewdog -efm="%f:%l:%c: %m" -reporter=github-pr-check
