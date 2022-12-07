#!/usr/bin/env bash

REVIEWDOG_GIT_TOKEN=$1

set -e

export REVIEWDOG_GITHUB_API_TOKEN="${REVIEWDOG_GIT_TOKEN}"

echo "TIZONA - Secrets leaks analysis: Secrets leaks discovery"

FILE_REPORT=report-secrets.json
git config --global --add safe.directory /github/workspace

echo "TIZONA - Secrets leaks analysis: Running gitleaks"
/gitleaks detect --no-git -f sarif --exit-code 0 -r $FILE_REPORT

set +Eeuo pipefail

echo "TIZONA - Secrets leaks analysis: Formatting findings"
jq '.runs[0].results[] | "\(.locations[0].physicalLocation.artifactLocation.uri):\(.locations[0].physicalLocation.region.endLine):\(.locations[0].physicalLocation.region.startColumn): \(.message.text)"' < $FILE_REPORT | sed 's/"//g'

echo "TIZONA - Secrets leaks analysis: Runnning reviewdog"
jq '.runs[0].results[] | "\(.locations[0].physicalLocation.artifactLocation.uri):\(.locations[0].physicalLocation.region.endLine):\(.locations[0].physicalLocation.region.startColumn): \(.message.text)"' < $FILE_REPORT | sed 's/"//g' |  reviewdog -efm="%f:%l:%c: %m" -reporter=github-pr-check -fail-on-error=true 

reviewdog_return="${PIPESTATUS[2]}" exit_code=$?

echo "TIZONA - Secrets leaks analysis: set-output name=reviewdog-return-code: ${reviewdog_return}"

echo "TIZONA - Secrets leaks analysis: Gitleaks exit ${exit_code}"
exit ${exit_code}
