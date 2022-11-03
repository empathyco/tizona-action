#!/usr/bin/env bash

TRIVY_SCANREF=$1
TRIVY_IGNORE=$2
TRIVY_SEVERITY=$3
TRIVY_VULN=$4
TRIVY_TIMEOUT=$5
REVIEWDOG_GIT_TOKEN=$6
TRIVY_OUTPUT='trivy-results-repo.sarif'
ARGS=""
TIMEOUT=""

set -e

export REVIEWDOG_GITHUB_API_TOKEN="${REVIEWDOG_GIT_TOKEN}"

if [[ ${TRIVY_IGNORE} == *"true"* ]]; then
  ARGS="$ARGS --ignore-unfixed"
fi

if [ $TRIVY_SEVERITY ];then
  ARGS="$ARGS --severity $TRIVY_SEVERITY"
fi

if [ $TRIVY_VULN ];then
  ARGS="$ARGS --vuln-type $TRIVY_VULN"
fi

if [ $TRIVY_TIMEOUT ];then
  TIMEOUT="$TIMEOUT --timeout $TRIVY_TIMEOUT"
fi

echo "TIZONA - Trvy repository analysis: Building SARIF repository report"
trivy --quiet ${TIMEOUT} fs --format sarif --output ${TRIVY_OUTPUT} ${ARGS} ${TRIVY_SCANREF}

echo "TIZONA - Trvy repository analysis: Upload trivy repository scan result to Github"

set +Eeuo pipefail

jq '.runs[0].results[] | "\(.level):\(.locations[0].physicalLocation.artifactLocation.uri):\(.locations[0].physicalLocation.region.endLine):\(.locations[0].physicalLocation.region.startColumn): \(.message.text)"' < ${TRIVY_OUTPUT} | sed 's/"//g' |  reviewdog -efm="%t%.%+:%f:%l:%c: %m" -reporter=github-pr-check -fail-on-error=true

reviewdog_return="${PIPESTATUS[3]}" exit_code=$?

echo "TIZONA - Trvy repository analysis: set-output name=reviewdog-return-code: ${reviewdog_return}"

echo "TIZONA - Trvy repository analysis: Trivy repo exit ${exit_code}"
exit ${exit_code}