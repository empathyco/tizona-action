#!/usr/bin/env bash

TRIVY_IGNORE=$1
TRIVY_SEVERITY=$2
TRIVY_VULN=$3
TRIVY_TIMEOUT=$4
REVIEWDOG_GIT_TOKEN=$5
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

TRIVY_DIRS=$(git diff origin/${GITHUB_BASE_REF} origin/${GITHUB_HEAD_REF} --dirstat | awk -F '% ' '{print $2}')

for dir in $TRIVY_DIRS
do 
  echo "TIZONA - Trivy repository analysis of $dir: Building SARIF config report"

  trivy --quiet ${TIMEOUT} fs --format sarif --output ${TRIVY_OUTPUT} ${ARGS} $dir

  echo "TIZONA - Trvy repository analysis of $dir: Upload trivy repository scan result to Github"

  set +Eeuo pipefail

  jq '.runs[0].results[] | "\(.level):\(.locations[0].physicalLocation.artifactLocation.uri):\(.locations[0].physicalLocation.region.endLine):\(.locations[0].physicalLocation.region.startColumn): \(.message.text)"' < ${TRIVY_OUTPUT} | sed 's/"//g' |  reviewdog -efm="%t%.%+:%f:%l:%c: %m" -reporter=github-pr-check -fail-on-error=true

  reviewdog_return="${PIPESTATUS[2]}" exit_code=$?

  echo "TIZONA - Trvy repository analysis of $dir: reviewdog-return-code: ${reviewdog_return}"

  echo "TIZONA - Trvy repository analysis of $dir: Trivy repo exit ${exit_code}"

  if [[ ${exit_code} != *"0"* ]]; then
    echo "TIZONA - Trivy configuration analysis of $dir: exit code is not 0"
    break
  fi

done

exit ${exit_code}