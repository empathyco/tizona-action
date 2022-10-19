#!/bin/bash

TRIVY_SCANREF=$1
TRIVY_IGNORE=$2
TRIVY_SEVERITY=$3
TRIVY_VULN=$4
TRIVY_TIMEOUT=$5
TRIVY_OUTPUT='trivy-results-repo.sarif'
ARGS=""
TIMEOUT=""

set -e

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

echo "Building SARIF repository report"
echo "trivy --quiet ${TIMEOUT} fs --format sarif --output ${TRIVY_OUTPUT} ${ARGS} ${TRIVY_SCANREF}"
trivy --quiet ${TIMEOUT} fs --format sarif --output ${TRIVY_OUTPUT} ${ARGS} ${TRIVY_SCANREF}

echo "Upload trivy repository scan result to Github"

jq '.runs[0].results[] | "\(.level):\(.locations[0].physicalLocation.artifactLocation.uri):\(.locations[0].physicalLocation.region.endLine):\(.locations[0].physicalLocation.region.startColumn): \(.message.text)"' < ${TRIVY_OUTPUT} | sed 's/"//g' |  reviewdog -efm="%t%.%+:%f:%l:%c: %m" -reporter=github-pr-check -fail-on-error
