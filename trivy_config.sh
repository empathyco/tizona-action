#!/usr/bin/env bash

TRIVY_SCANREF=$1
TRIVY_SEVERITY=$2
TRIVY_TIMEOUT=$3
REVIEWDOG_GIT_TOKEN=$4
TRIVY_OUTPUT='trivy-results-config.sarif'
ARGS=""
TIMEOUT=""

set -e

export REVIEWDOG_GITHUB_API_TOKEN="${REVIEWDOG_GIT_TOKEN}"

if [ $TRIVY_SEVERITY ];then
  ARGS="$ARGS --severity $TRIVY_SEVERITY"
fi

if [ $TRIVY_TIMEOUT ];then
  TIMEOUT="$TIMEOUT --timeout $TRIVY_TIMEOUT"
fi

echo "TIZONA - Trivy configuration analysis: Building SARIF config report"
trivy --quiet ${TIMEOUT} config --format sarif --output ${TRIVY_OUTPUT} ${ARGS} ${TRIVY_SCANREF}

echo "TIZONA - Trivy configuration analysis: Upload trivy config scan result to Github"

set +Eeuo pipefail

jq '.runs[0].results[] | "\(.level):\(.locations[0].physicalLocation.artifactLocation.uri):\(.locations[0].physicalLocation.region.endLine):\(.locations[0].physicalLocation.region.startColumn): \(.message.text)"' < ${TRIVY_OUTPUT} | sed 's/"//g' |  reviewdog -efm="%t%.%+:%f:%l:%c: %m" -reporter=github-pr-check -fail-on-error=true

reviewdog_return="${PIPESTATUS[3]}" exit_code=$?

echo "TIZONA - Trivy configuration analysis: set-output name=reviewdog-return-code: ${reviewdog_return}"

echo "TIZONA - Trivy configuration analysis: Trivy config exit ${exit_code}"
exit ${exit_code}